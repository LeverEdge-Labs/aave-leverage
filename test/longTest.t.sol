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

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    Leverage leverage;

    function setUp() public {
        ethFork = vm.createSelectFork(ETH_RPC);
        leverage = new Leverage();
    }


    // @dev Helper functions
    function getWETH() internal {
        IERC20 weth = IERC20(WETH);
        address user = 0xE831C8903de820137c13681E78A5780afDdf7697;
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
        leverage.closePosition(0);
        console.log("Position Closed");
    }


}