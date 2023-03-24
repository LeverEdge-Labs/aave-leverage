// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// openzeppelin 
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

// aave v3 interface
import "./interfaces/IAave.sol";

// swapper
import "./Swapper.sol";

// console log
import "forge-std/console.sol";


contract Leverage is Swapper {

    struct Position {
        address baseAsset;
        address leveragedAsset;
        uint baseAssetAmount;
        UD60x18 leverage;
        bool isLong;
        uint initialAmount;
        bool isClosed;
    }

    struct flashloanParams {
        address user;
        address nonCollateralAsset;
        uint amountBase;
        UD60x18 leverage;
        bool isLong;
        bool isClose;
    }

    // address pair v1core => address user => ID => Position
    mapping(address => mapping(address => mapping(uint => Position))) public positions;

    // address user => positions
    mapping(address => uint[]) public IDs;

    IPOOL public aaveV3;

    constructor () {
        aaveV3 = IPOOL(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    }

    function getUserPositions(address user) external view returns (uint numberPositions) {
        return IDs[user].length;
    }

    function long(
        address baseAsset,
        address leveragedAsset,
        uint amountBase,
        UD60x18 leverage
    ) external returns (bool) {

        console.log("HERE");

        IERC20(leveragedAsset).transferFrom(msg.sender, address(this), amountBase);

        uint flashloanAmount = unwrap(ud(amountBase).mul(leverage)); 

        uint ID = IDs[msg.sender].length;
        IDs[msg.sender].push(ID);

        Position memory position = Position(baseAsset, leveragedAsset, amountBase, leverage, true, flashloanAmount, false);
        positions[address(0)][msg.sender][ID] = position;

        // user, baseAsset, amountBase, leverage, isLong, isClose 
        // @dev is leverage needed in params?
        flashloanParams memory flashParams = flashloanParams(
                                                msg.sender,
                                                baseAsset,
                                                (amountBase + flashloanAmount),
                                                leverage,
                                                true,
                                                false);

        bytes memory params = abi.encode(flashParams);
        getflashloan(leveragedAsset, flashloanAmount, params);
        return true;
    }


    function executeLong(
        address flashloanAsset,
        uint flashloanAmount,
        uint liquidityBase,
        address baseAsset
    ) private {
        IERC20(flashloanAsset).approve(address(aaveV3), liquidityBase);
        aaveV3.supply(flashloanAsset, liquidityBase, address(this), 0);

        uint price = getPrice(flashloanAsset, baseAsset);
        uint borrowAmount = flashloanAmount * price * 1.0039e17 / 1e35;//  / 1e35; //  * 1.0055024999999997e17 / 1e18 * 10;

        aaveV3.borrow(baseAsset, borrowAmount, 2, 0, address(this));

        // @dev what to do with amountOut?
        // uint amountOut = swapExactInputSingle(baseAsset, flashloanAsset, borrowAmount);
        // uint amountOut = 
        swapExactInputSingle(baseAsset, flashloanAsset, borrowAmount);

    }


    function executeCloseLong(
        flashloanParams memory flashParams,
        uint flashloanAmount,
        uint loanAmount
    ) private {
        Position memory positionParams = positions[address(0)][flashParams.user][0];

        IERC20(positionParams.baseAsset).approve(address(aaveV3), flashloanAmount);
        aaveV3.repay(positionParams.baseAsset, flashloanAmount, 2, address(this));

        uint swapAmount;
        {
            uint balance_t0 = IERC20(positionParams.leveragedAsset).balanceOf(address(this));
            aaveV3.withdraw(positionParams.leveragedAsset, type(uint).max, address(this));
            uint balance_t1 = IERC20(positionParams.leveragedAsset).balanceOf(address(this));

            swapAmount = balance_t1 - balance_t0;
        }
        // swap leveraged asset for base
        uint amountOut = swapExactInputSingle(positionParams.leveragedAsset, positionParams.baseAsset, swapAmount);
        uint userDebit = amountOut - loanAmount;

        IERC20(positionParams.baseAsset).transfer(flashParams.user, userDebit);
    }


    function short(
        address baseAsset,
        address leveragedAsset,
        uint amountBase,
        UD60x18 leverage
    ) external returns (bool) {
        IERC20(baseAsset).transferFrom(msg.sender, address(this), amountBase);
        uint flashloanAmount = unwrap(ud(amountBase).mul(leverage));

        uint ID = IDs[msg.sender].length;
        IDs[msg.sender].push(ID);

        Position memory position = Position(baseAsset, leveragedAsset, amountBase, leverage, false, flashloanAmount, false);
        positions[address(0)][msg.sender][ID] = position;

        flashloanParams memory flashParams = flashloanParams(
                                                msg.sender,
                                                leveragedAsset,
                                                (amountBase + flashloanAmount),
                                                leverage,
                                                false,
                                                false);

        bytes memory params = abi.encode(flashParams);
        getflashloan(baseAsset, flashloanAmount, params);
        return true;
    }


    function executeShort(
        address baseAsset,
        uint flashloanAmount,
        uint liquidityBase, 
        address leveragedAsset
    ) private {
        IERC20(baseAsset).approve(address(aaveV3), liquidityBase);
        aaveV3.supply(baseAsset, liquidityBase, address(this), 0);

        uint price = getPrice(leveragedAsset, baseAsset);
        uint decimals = IERC20Metadata(leveragedAsset).decimals() - IERC20Metadata(baseAsset).decimals();
        uint borrowAmount = (((flashloanAmount * 10**decimals) / price) * 1.00433e18) / (10**decimals);

        aaveV3.borrow(leveragedAsset, borrowAmount, 2, 0, address(this));

        // uint amountOut = swapExactInputSingle(leveragedAsset, baseAsset, borrowAmount);
        swapExactInputSingle(leveragedAsset, baseAsset, borrowAmount);
    }


    function executeCloseShort(
        flashloanParams memory flashParams,
        uint flashloanAmount,
        uint loanAmount
    ) private {
        Position memory positionParams = positions[address(0)][flashParams.user][0];
        IERC20(positionParams.leveragedAsset).approve(address(aaveV3), flashloanAmount);
        aaveV3.repay(positionParams.leveragedAsset, flashloanAmount, 2, address(this));

        console.log("HERE!!");
        viewAccountData();

        uint swapAmount;
        {
            uint balance_t0 = IERC20(positionParams.baseAsset).balanceOf(address(this));
            aaveV3.withdraw(positionParams.baseAsset, type(uint).max, address(this));
            uint balance_t1 = IERC20(positionParams.baseAsset).balanceOf(address(this));

            swapAmount = balance_t1 - balance_t0;
        }
        // swap leveraged asset for base
        uint amountOut = swapExactInputSingle(positionParams.baseAsset, positionParams.leveragedAsset, swapAmount);

        console.log("CLOSE SHORT");
        console.logUint(amountOut);
        console.logUint(loanAmount);

        uint userDebit = amountOut - loanAmount;

        IERC20(positionParams.leveragedAsset).transfer(flashParams.user, userDebit);
    }


    // @dev takes in ID of position, address == msg.sender
    function closePosition(uint ID) external returns (bool) {
        // @dev address(0) is currently a placeholder for pair address
        require(positions[address(0)][msg.sender][ID].baseAsset != address(0), "no position found");
        positions[address(0)][msg.sender][ID].isClosed = true;
        Position memory pos_params = positions[address(0)][msg.sender][ID];

        ( , uint totalDebtBase, , , , ) = aaveV3.getUserAccountData(address(this));

        // flashloan amount is different for if long or short
        // @dev for long
        // uint flashloanAmount = totalCollateralBase - totalDebtBase;

        address flashloanAsset;
        uint flashloanAmount;
        // this is only for USDC and WETH (1e6, 1e18)
        if (pos_params.isLong == true) {
            flashloanAsset = pos_params.baseAsset;

            flashloanAmount = totalDebtBase / 1e2 * 1.05e18 / 1e18; // Fixes revert with error 35 (1.0005e18)
            // flashloanAmount = totalDebtBase / 1e2; // sometimes reverts with error 35
            //console.log(flashloanAmount);
        } else {
            flashloanAsset = pos_params.leveragedAsset;
            uint price = getPrice(flashloanAsset, pos_params.baseAsset);
            flashloanAmount = totalDebtBase * 1.05e16 / price;
        }
        // @dev 0 because leverage is not needed for closing position
        flashloanParams memory flashParams = flashloanParams(msg.sender, flashloanAsset, flashloanAmount, ud(0), pos_params.isLong, true);
        bytes memory params = abi.encode(flashParams);
        getflashloan(flashloanAsset, flashloanAmount, params);
        return true;
    }


    function getflashloan(address asset, uint amount, bytes memory params) private {
        address[] memory assets = new address[](1);
        assets[0] = asset;

        uint[] memory amounts = new uint[](1);
        amounts[0] = amount;

        uint[] memory modes = new uint[](1);
        modes[0] = 0;

        aaveV3.flashLoan(address(this), assets, amounts, modes, address(this), params, 0);
    }


    function executeOperation (
        address[] calldata assets,
        uint[] calldata amounts,
        uint[] calldata premiums,
        address initiator,
        bytes calldata _params
    ) external returns (bool) {
        require(msg.sender == address(aaveV3), "not aave");
        require(initiator == address(this), "only from this contract");

        flashloanParams memory params = abi.decode(_params, (flashloanParams));

        if (params.isClose == false) {
            if (params.isLong) {
                executeLong(assets[0], amounts[0] + premiums[0], params.amountBase, params.nonCollateralAsset);
            } else {
                executeShort(assets[0], amounts[0] + premiums[0], params.amountBase, params.nonCollateralAsset); 
            }
        } else {
            if (params.isLong) {
                executeCloseLong(params, amounts[0], amounts[0] + premiums[0]);
            } else {
                executeCloseShort(params, amounts[0], amounts[0] + premiums[0]);
            }
        }
        console.log("END of flashloan");
        console.log(amounts[0] + premiums[0]);

        IERC20(assets[0]).approve(address(aaveV3), amounts[0] + premiums[0]);
        return true;
    }


// ##################### VIEW FUNCTIONS ######################

/*     // returns price now and price of liquidation
    function getLiquidationPrice(address user, uint ID) public view returns (uint, UD60x18) {
        Position memory positionParams = positions[address(0)][user][ID];

        (uint totalCollateralBase,
        uint totalDebtBase, 
        ,
        ,
        uint ltv,
        ) = aaveV3.getUserAccountData(address(this));

        // uint healthFactor1 = totalCollateralBase * currentLiquidationThreshold / totalDebtBase; // Div by some conversion factor

        uint price = getPrice(positionParams.leveragedAsset, positionParams.baseAsset);

        // liquidationPrice = price * (0.825 - (debt / collateral)) - price

        uint liquidationPrice;
        if (positionParams.isLong == true) {
            // liquidationPrice = (price * 1e12) - (price * 1e12).mul(ltv * 1e14 - totalDebtBase.div(totalCollateralBase)); 

            UD60x18 liquidationPrice = ud(price * 1e12). mul(ud(825e15).sub(ud(totalDebtBase).div(totalCollateralBase)));

        } else {
            // liquidationPrice = (price * 1e12).mul(ltv * 1e14 - totalDebtBase.div(totalCollateralBase)) + (price * 1e12);
            UD60x18 liquidationPrice = ud(price * 1e12). mul(ud(825e15).sub(ud(totalDebtBase).div(totalCollateralBase)));
        }

        return (price, liquidationPrice);
    }
 */

    function viewAccountData() public view {
        (uint totalCollateralBase,
        uint totalDebtBase, 
        uint availableBorrowBase,
        uint currentLiquidationThreshold,
        uint ltv,
        uint healthFactor) = aaveV3.getUserAccountData(address(this));

        console.logUint(totalCollateralBase);
        console.logUint(totalDebtBase);
        console.logUint(availableBorrowBase);
        console.logUint(currentLiquidationThreshold);
        console.logUint(ltv);
        console.logUint(healthFactor);
    }


/*     function calculateLiquidationPrice(address user) public view returns (uint, uint) {
        Position memory positionParams = positions[address(0)][user][0];

        (uint totalCollateralBase,
        uint totalDebtBase, 
        ,
        uint currentLiquidationThreshold,
        uint ltv,
        uint healthFactor) = aaveV3.getUserAccountData(address(this));

        // uint healthFactor1 = totalCollateralBase * currentLiquidationThreshold / totalDebtBase; // Div by some conversion factor
        uint price = getPrice(positionParams.leveragedAsset, positionParams.baseAsset);

        // liquidationPrice = price * (0.825 - (debt / collateral)) - price

        uint liquidationPrice;
        if (positionParams.isLong == true) {
            liquidationPrice = (price * 1e12) - (price * 1e12).mul(ltv * 1e14 - totalDebtBase.div(totalCollateralBase)); 
        } else {
            liquidationPrice = (price * 1e12).mul(ltv * 1e14 - totalDebtBase.div(totalCollateralBase)) + (price * 1e12);
        }
        return (liquidationPrice, price);
    }
 */
}




