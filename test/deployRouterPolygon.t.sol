// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "src/Leverage.sol";
import "src/Factory.sol";

contract deployRouter is Test {
    uint polyFork;
    string POLY_RPC = vm.envString("Polygon_RPC");

    address WETH = vm.envAddress("WETH_POLY");
    address USDC = vm.envAddress("USDC_POLY");

    Leverage leverage;
    Factory factory;

    address aaveV3 = vm.envAddress("AAVEV3_POOL_POLY");

    function setUp() public {
        polyFork = vm.createSelectFork(POLY_RPC);

        factory = new Factory(aaveV3);

        factory.createLeverageContract();
    }

    function testDeployed() public view {
        address leverageContract = factory.getLeverageContract();
        assert(leverageContract != address(0));
    }


    function testUserInteractionLong() public {
        // 2x WETH USDC 
        // User transfers 1 WETH and has 2 WETH deposited on Aave

        // STEP #1 Get WETH
        deal(WETH, address(this), 1e18);

        // STEP #2 Create Position Manager
        address leverageAddress = factory.getLeverageContract();
        console.log(leverageAddress);

        // STEP #3 Approve Position Manager
        IERC20(WETH).approve(address(leverageAddress), type(uint).max);

        // STEP #3 Open Long
        // USDC WETH 1ETH 2x long
        Leverage(leverageAddress).long(USDC, WETH, 1e18, ud(2e18));

        console.log("Position Opened Successfully");

        // STEP #4 Close Long
        // ID of position 0
        // Leverage(leverageAddress).closePosition(0);
        // console.log("Position Closed");
    }


    function testUserInteractionShort() public {
        // STEP #1 Get WETH
        deal(USDC, address(this), 2000e6);

        // STEP #2 Create Position Manager
        address leverageAddress = factory.getLeverageContract();
        console.log(leverageAddress);

        // STEP #3 Approve Position Manager
        IERC20(USDC).approve(address(leverageAddress), type(uint).max);

        // STEP #3 Open Long
        // USDC WETH 1ETH 2x long
        Leverage(leverageAddress).short(USDC, WETH, 2000e6, ud(2e18));

        console.log("Position Opened Successfully");

        // STEP #4 Close Long
        // ID of position 0
        // Leverage(leverageAddress).closePosition(0);
        // console.log("Position Closed");
    }


}