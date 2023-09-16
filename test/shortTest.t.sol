// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "src/Factory.sol";
import "src/Leverage.sol";


contract shortTest is Test {
    uint ethFork;
    string ETH_RPC = vm.envString("ETH_RPC");

    address WETH = vm.envAddress("WETH_ETH");
    address USDC = vm.envAddress("USDC_ETH");

    Factory factory;
    Leverage leverage;

    address aaveV3_pool = vm.envAddress("AAVEV3_POOL_ETH");

    function setUp() public {
        ethFork = vm.createSelectFork(ETH_RPC);

        // deploy factory
        factory = new Factory(aaveV3_pool);

        // deploy leverage
        leverage = Leverage(factory.createLeverageContract());
    }

    function getUSDC() internal {
        IERC20 usdc = IERC20(USDC);
        address user = 0x7713974908Be4BEd47172370115e8b1219F4A5f0;
        uint balance = usdc.balanceOf(user);
        assert(balance > 0);
        vm.prank(user);
        usdc.approve(address(this), balance);
        vm.prank(user);
        usdc.transfer(address(this), 2000e6);
    }


    function testOpenShort() public {
        // STEP #1 Get USDC 
        getUSDC();

        // STEP #2 Approve leverage
        IERC20(USDC).approve(address(leverage), type(uint).max);

        // STEP #3 Open Short
        // USDC WETH 2000 USDC 2x short
        leverage.short(USDC, WETH, 2000e6, ud(2e18));

    }
    
    function testOpenCloseShort() public {
        // STEP #1 Get USDC 
        getUSDC();

        // STEP #2 Approve leverage
        IERC20(USDC).approve(address(leverage), type(uint).max);

        // STEP #3 Open Short
        // USDC WETH 2000 USDC 2x short
        leverage.short(USDC, WETH, 2000e6, ud(2e18));

        // STEP #4 Close Position
        // ID of position 0
        leverage.closePosition(0);
        console.log("Position Closed");
        
        console.log("balance USDC");
        console.log(IERC20(USDC).balanceOf(address(this)));
        console.log("balance WETH");
        console.log(IERC20(WETH).balanceOf(address(this)));
    }

}