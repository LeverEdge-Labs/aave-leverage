// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// openzeppelin 
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "./interfaces/IAave.sol";

// console log
import "forge-std/console.sol";


contract UserPositionManager {

    // are these structs needed?
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

    // LEVERAGE CONTRACT DELEGATE CALL STORAGE
    // @dev DO NOT CHANGE ORDER OF STORAGE

    // address pair v1core => address user => ID => Position
    mapping(address => mapping(address => mapping(uint => Position))) public positions;

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

    // end of Leverage Contract Storage

    address router;
    address leverageContract;


    constructor (address _leverageContract, address _router, address _owner) {
        leverageContract = _leverageContract;
        router = _router;
        owner = _owner;
    }

    modifier OnlyAuthed{
        require(msg.sender == router || msg.sender == owner, "Not authorized");
        _;
    }

    function long(
        address baseAsset,
        address leveragedAsset,
        uint amount,
        UD60x18 leverage
    ) external OnlyAuthed returns (bool) {
 
        (bool success, bytes memory data) = leverageContract.delegatecall(
            abi.encodeWithSignature("long(address,address,uint256,UD60x18)", baseAsset, leveragedAsset, amount, leverage)
        );
        require(success, "call to leverage logic contract failed");

        console.log(abi.decode(data, (bool)));

        return true;

    }
}