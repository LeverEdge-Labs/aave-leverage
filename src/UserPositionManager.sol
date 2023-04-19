// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// openzeppelin 
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "./interfaces/IAave.sol";


contract UserPositionManager {

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

    // deployer address == owner
    address public owner;

    // address pair v1core => address user => ID => Position
    mapping(address => mapping(address => mapping(uint => Position))) public positions;

    // address user => positions
    mapping(address => uint[]) public IDs;

    IPOOL public aaveV3;

    address router;

    address leverage;


    constructor (address _owner, address _router) {
        owner = _owner;
        router = _router;
    }

    modifier OnlyRouter {
        require(msg.sender == router, "Not Router");
        _;
    }


    function long(address token0, address token1, uint amount, UD60x18 leverage) external OnlyRouter returns (bool) {
        
        (bool success, bytes memory data) = leverage.delegatecall(
            abi.encodeWithSignature("long(address,address,uint256,uint256)", token0, token1, amount, leverage)
        );


    }
}