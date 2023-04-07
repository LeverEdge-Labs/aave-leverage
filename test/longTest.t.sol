// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "src/Leverage.sol";

contract longTest is Test {
    uint ethFork;
    string ETH_RPC = vm.envString("ETH_RPC");

    address WETH = vm.envAddress("WETH_ETH");
    address USDC = vm.envAddress("USDC_ETH");

    Leverage leverage;

    address aaveV3_pool = vm.envAddress("AAVEV3_POOL_ETH");

    function setUp() public {
        ethFork = vm.createSelectFork(ETH_RPC);
        leverage = new Leverage(aaveV3_pool);
    }


    // @dev Helper functions
    function getWETH() internal {
        IERC20 weth = IERC20(WETH);
        address user = 0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3;
        uint balance = weth.balanceOf(user);
        assert(balance > 0);
        vm.prank(user);
        weth.approve(address(this), balance);
        vm.prank(user);
        weth.transfer(address(this), balance);

        console.log("Balance WETH");
        console.log(weth.balanceOf(address(this)));
    }


    function testOpenLong() public {
        // STEP #1 Get WETH
        getWETH();

        // STEP #2 Approve leverage
        IERC20(WETH).approve(address(leverage), type(uint).max);

        // STEP #3 Open Long
        // USDC WETH 1ETH 2x long
        leverage.long(USDC, WETH, 1e18, ud(2e18));

        // STEP #4 Close Long
        // ID of position 0
        // leverage.closePosition(0);
        //console.log("Position Closed");
    }


}