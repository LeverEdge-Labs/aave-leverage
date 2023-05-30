// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// openzeppelin
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// prb-math v3
import {SD59x18, sd} from "@prb/math/SD59x18.sol";
import {UD60x18, ud, unwrap} from "@prb/math/UD60x18.sol";

// aave v3 interface
import "./interfaces/IAave.sol";

// swapper
import "./Swapper.sol";

// console log
import "forge-std/console.sol";

/// @title Algorithmic Leverage Trade Builder
/// @author LeverEdge Labs
/// @dev This contract is currently in development

contract Leverage is Swapper {
    struct Position {
        address baseAsset;
        address leveragedAsset;
        uint amount;
        UD60x18 leverage;
        bool isLong;
        uint initialAmount;
        bool isClosed;
    }

    struct flashloanParams {
        address user;
        address nonCollateralAsset;
        uint amount;
        bool isLong;
        bool isClose;
    }

    // address pair v1core => address user => ID => Position
    mapping(address => mapping(address => mapping(uint => Position)))
        public positions;

    // address user => positions
    mapping(address => uint[]) public IDs;

    IPOOL public aaveV3;

    // deployer address == owner
    address public owner;

    /// @dev fl constant testing purposes only
    // Mainnet values
    // uint openFlashConstant = 1.0033e18;
    // uint closeFlashConstant = 1.009e16;

    uint openFlashConstant = 1.005e18;
    uint closeFlashConstant = 1.009e16;

    function updateFlashConstant(
        uint _openFlashConstant,
        uint _closeFlashConstant
    ) public returns (bool) {
        openFlashConstant = _openFlashConstant;
        closeFlashConstant = _closeFlashConstant;

        return true;
    }

    constructor(address _pool) {
        aaveV3 = IPOOL(_pool);
        owner == msg.sender;
    }

    function getUserPositions(
        address user
    ) external view returns (uint numberPositions) {
        return IDs[user].length;
    }

    /// @notice Intiate long function
    /// @param baseAsset address stable asset
    /// @param leveragedAsset address leveraged asset
    /// @param amount amount of leveraged asset
    /// @param leverage amount in UD60x18 format (1<x<5)
    function long(
        address baseAsset,
        address leveragedAsset,
        uint amount,
        UD60x18 leverage
    ) external returns (bool) {
        IERC20(leveragedAsset).transferFrom(msg.sender, address(this), amount);

        uint flashLoanAmount = unwrap(ud(amount).mul(leverage));

        uint ID = IDs[msg.sender].length;
        IDs[msg.sender].push(ID);

        Position memory position = Position(
            baseAsset,
            leveragedAsset,
            amount,
            leverage,
            true,
            flashLoanAmount,
            false
        );
        positions[address(0)][msg.sender][ID] = position;

        // user, baseAsset, amountBase, isLong, isClose
        flashloanParams memory flashParams = flashloanParams(
            msg.sender,
            baseAsset,
            (amount + flashLoanAmount),
            true,
            false
        );

        bytes memory params = abi.encode(flashParams);

        console.log("HERE");

        getflashloan(leveragedAsset, flashLoanAmount, params);

        return true;
    }

    /// @notice Execute long function
    /// @param leveragedAsset leveraged asset
    /// @param totalAmount total amount of asset
    /// @param flashLoanAmount flash loan amount
    /// @param baseAsset address of base asset
    function executeLong(
        address leveragedAsset,
        uint totalAmount,
        uint flashLoanAmount,
        address baseAsset
    ) private {
        IERC20(leveragedAsset).approve(address(aaveV3), totalAmount);
        aaveV3.supply(leveragedAsset, totalAmount, address(this), 0);

        uint price = getPrice(leveragedAsset, baseAsset);
        console.log("price");
        console.log(price);

        uint borrowAmount = (flashLoanAmount * price * openFlashConstant) /
            1e36;

        aaveV3.borrow(baseAsset, borrowAmount, 2, 0, address(this));

        swapExactInputSingle(baseAsset, leveragedAsset, borrowAmount);
    }

    /// @notice Execute Close Long function
    /// @param flashParams flash loan parameters
    /// @param flashLoanAmount flash loan amount
    /// @param loanAmount flash loan amount plus fee
    function executeCloseLong(
        flashloanParams memory flashParams,
        uint flashLoanAmount,
        uint loanAmount
    ) private {
        Position memory positionParams = positions[address(0)][
            flashParams.user
        ][0];

        IERC20(positionParams.baseAsset).approve(
            address(aaveV3),
            flashLoanAmount
        );
        aaveV3.repay(
            positionParams.baseAsset,
            flashLoanAmount,
            2,
            address(this)
        );

        uint swapAmount;
        {
            uint balance_t0 = IERC20(positionParams.leveragedAsset).balanceOf(
                address(this)
            );
            aaveV3.withdraw(
                positionParams.leveragedAsset,
                type(uint).max,
                address(this)
            );
            uint balance_t1 = IERC20(positionParams.leveragedAsset).balanceOf(
                address(this)
            );

            swapAmount = balance_t1 - balance_t0;
        }
        // swap leveraged asset for base
        uint amountOut = swapExactInputSingle(
            positionParams.leveragedAsset,
            positionParams.baseAsset,
            swapAmount
        );
        uint userDebit = amountOut - loanAmount;

        IERC20(positionParams.baseAsset).transfer(flashParams.user, userDebit);
    }

    /// @notice Initate short function
    /// @param baseAsset address stable asset
    /// @param leveragedAsset address leveraged asset
    /// @param amountBase amount of base asset
    /// @param leverage amount in UD60x18 format (1<x<5)
    function short(
        address baseAsset,
        address leveragedAsset,
        uint amountBase,
        UD60x18 leverage
    ) external returns (bool) {
        IERC20(baseAsset).transferFrom(msg.sender, address(this), amountBase);

        uint flashLoanAmount = unwrap(
            (ud(amountBase).mul(leverage)).sub(ud(amountBase))
        );

        uint ID = IDs[msg.sender].length;
        IDs[msg.sender].push(ID);

        Position memory position = Position(
            baseAsset,
            leveragedAsset,
            amountBase,
            leverage,
            false,
            flashLoanAmount,
            false
        );
        positions[address(0)][msg.sender][ID] = position;

        flashloanParams memory flashParams = flashloanParams(
            msg.sender,
            leveragedAsset,
            (amountBase + flashLoanAmount),
            false,
            false
        );

        bytes memory params = abi.encode(flashParams);

        getflashloan(baseAsset, flashLoanAmount, params);
        return true;
    }

    /// @notice execute short function
    /// @param baseAsset stable asset
    /// @param leveragedAsset amount liquidity of base asset
    /// @param flashLoanAmount flash loan amount
    /// @param leveragedAsset address leveragedAsset
    function executeShort(
        address baseAsset,
        uint liquidityBase,
        uint flashLoanAmount,
        address leveragedAsset
    ) private {
        IERC20(baseAsset).approve(address(aaveV3), liquidityBase);
        aaveV3.supply(baseAsset, liquidityBase, address(this), 0);

        uint price = getPrice(leveragedAsset, baseAsset);
        uint decimals = IERC20Metadata(leveragedAsset).decimals() -
            IERC20Metadata(baseAsset).decimals();

        // the 1.00333 constant depends on the amount of liquidity @ price on uniV3
        // more liquidity @ price => smaller constant
        // need to use swapExactOutput....

        uint borrowAmount = (((flashLoanAmount * 10 ** decimals) / price) *
            openFlashConstant) / (10 ** decimals);

        aaveV3.borrow(leveragedAsset, borrowAmount, 2, 0, address(this));

        swapExactInputSingle(leveragedAsset, baseAsset, borrowAmount);
    }

    /// @notice Execute Close Short function
    /// @param flashParams flash loan parameters
    /// @param flashLoanAmount flash loan amount
    /// @param loanAmount flash loan amount plus fee
    function executeCloseShort(
        flashloanParams memory flashParams,
        uint flashLoanAmount,
        uint loanAmount
    ) private {
        Position memory positionParams = positions[address(0)][
            flashParams.user
        ][0];
        IERC20(positionParams.leveragedAsset).approve(
            address(aaveV3),
            flashLoanAmount
        );
        aaveV3.repay(
            positionParams.leveragedAsset,
            flashLoanAmount,
            2,
            address(this)
        );

        uint swapAmount;
        {
            uint balance_t0 = IERC20(positionParams.baseAsset).balanceOf(
                address(this)
            );
            aaveV3.withdraw(
                positionParams.baseAsset,
                type(uint).max,
                address(this)
            );
            uint balance_t1 = IERC20(positionParams.baseAsset).balanceOf(
                address(this)
            );

            swapAmount = balance_t1 - balance_t0;
        }
        // swap leveraged asset for base
        uint amountOut = swapExactInputSingle(
            positionParams.baseAsset,
            positionParams.leveragedAsset,
            swapAmount
        );
        uint userDebit = amountOut - loanAmount;

        IERC20(positionParams.leveragedAsset).transfer(
            flashParams.user,
            userDebit
        );
    }

    /// @notice Close Position Function
    /// @param ID ID of position
    function closePosition(uint ID) external returns (bool) {
        // @dev address(0) is currently a placeholder for pair address
        require(
            positions[address(0)][msg.sender][ID].baseAsset != address(0),
            "no position found"
        );
        positions[address(0)][msg.sender][ID].isClosed = true;
        Position memory pos_params = positions[address(0)][msg.sender][ID];

        (, uint totalDebtBase, , , , ) = aaveV3.getUserAccountData(
            address(this)
        );

        address flashloanAsset;
        uint flashLoanAmount;
        // this is only for USDC and WETH (1e6, 1e18)
        if (pos_params.isLong == true) {
            flashloanAsset = pos_params.baseAsset;
            flashLoanAmount = (totalDebtBase * closeFlashConstant) / 1e18; // IF ERROR 35 => increase this constant
        } else {
            flashloanAsset = pos_params.leveragedAsset;
            uint price = getPrice(flashloanAsset, pos_params.baseAsset);
            flashLoanAmount = (totalDebtBase * closeFlashConstant) / price; // IF ERROR 35 => increase this constant
        }
        // @dev 0 because leverage is not needed for closing position
        flashloanParams memory flashParams = flashloanParams(
            msg.sender,
            flashloanAsset,
            flashLoanAmount,
            pos_params.isLong,
            true
        );
        bytes memory params = abi.encode(flashParams);

        getflashloan(flashloanAsset, flashLoanAmount, params);
        return true;
    }

    function getflashloan(
        address asset,
        uint amount,
        bytes memory params
    ) private {
        address[] memory assets = new address[](1);
        assets[0] = asset;

        uint[] memory amounts = new uint[](1);
        amounts[0] = amount;

        uint[] memory modes = new uint[](1);
        modes[0] = 0;

        console.log("pre fl");
        aaveV3.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            params,
            0
        );
        console.log("post fl");
    }

    function executeOperation(
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
                executeLong(
                    assets[0],
                    params.amount,
                    amounts[0] + premiums[0],
                    params.nonCollateralAsset
                );
            } else {
                executeShort(
                    assets[0],
                    params.amount,
                    amounts[0] + premiums[0],
                    params.nonCollateralAsset
                );
            }
        } else {
            if (params.isLong) {
                executeCloseLong(params, amounts[0], amounts[0] + premiums[0]);
            } else {
                executeCloseShort(params, amounts[0], amounts[0] + premiums[0]);
            }
        }

        console.log("END OF EXECUTE OPERATION");
        console.log("FL DEBT AMOUNT");
        console.log(amounts[0] + premiums[0]);
        console.log(IERC20(assets[0]).balanceOf(address(this)));

        // repay flashloan to Aave
        IERC20(assets[0]).approve(address(aaveV3), amounts[0] + premiums[0]);

        // Calculate discrepancy of debt vs current balance
        // @dev if there is a balance in this contract, it will be sent to msg.sender.
        // @dev if this underflows it means it wasn't a profitable trade
        // @dev is there a better way?
        uint leftOver = IERC20(assets[0]).balanceOf(address(this)) -
            (amounts[0] + premiums[0]);

        IERC20(assets[0]).transfer(msg.sender, leftOver);

        return true;
    }

    function emergencyWithdraw(address asset) public {
        require(msg.sender == owner, "Not Owner");

        uint balance = IERC20(asset).balanceOf(address(this));
        IERC20(asset).transfer(msg.sender, balance);
    }

    // ##################### VIEW FUNCTIONS ######################

    function viewAccountData() public view {
        (
            uint totalCollateralBase,
            uint totalDebtBase,
            uint availableBorrowBase,
            uint currentLiquidationThreshold,
            uint ltv,
            uint healthFactor
        ) = aaveV3.getUserAccountData(address(this));

        console.logUint(totalCollateralBase);
        console.logUint(totalDebtBase);
        console.logUint(availableBorrowBase);
        console.logUint(currentLiquidationThreshold);
        console.logUint(ltv);
        console.logUint(healthFactor);
    }

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
