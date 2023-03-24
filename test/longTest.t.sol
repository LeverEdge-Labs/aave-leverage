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

    IPOOL public aaveV3 = IPOOL(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    Leverage leverage;


    function setUp() public {
        ethFork = vm.createSelectFork(ETH_RPC);
        leverage = new Leverage();
    }

    function testOpenLong() public {
        // vm.selectFork(ethFork);

        // leverage = new Leverage();


        // STEP #1 Get WETH
        IERC20 weth = IERC20(WETH);
        address user = 0xE831C8903de820137c13681E78A5780afDdf7697;
        uint balance = weth.balanceOf(user);
        vm.prank(user);
        weth.approve(address(this), balance);
        vm.prank(user);
        weth.transfer(address(this), balance);

        console.log("Balance WETH");
        console.log(weth.balanceOf(address(this)));


        console.log(address(leverage));

        // STEP #2 Open Long
        leverage.long(USDC, WETH, 1e18, ud(2e18));
        


        // console.log("FL");




    }

/* 
    function testOpenLong() public {
        vm.selectFork(ethFork);

        IERC20 usdc = IERC20(USDC);
        address user = 0x28f1d5FE896dB571Cba7679863DD4E1272d49eAc;
        uint usdcBalance = usdc.balanceOf(user);
        vm.prank(user);
        usdc.approve(address(this), usdcBalance);
        vm.prank(user);
        usdc.transfer(address(this), usdcBalance);

        console.log("HERE");
        console.log(usdc.balanceOf(address(this)));


        // console.log("FL");

    }

 */
}