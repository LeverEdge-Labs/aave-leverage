// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "src/Leverage.sol";

contract shortTest is Test {
    uint mumbaiFork;
    string MUMBAI_RPC = vm.envString("Mumbai_RPC");

    Leverage leverage;

    address aaveV3_pool_MUMBAI = vm.envAddress("AAVEV3_POOL_MUMBAI");
    address WETH = vm.envAddress("WETH_MUMBAI");
    address USDC = vm.envAddress("USDC_MUMBAI");

    function setUp() public {
        mumbaiFork = vm.createSelectFork(MUMBAI_RPC);
        leverage = new Leverage(aaveV3_pool_MUMBAI);
    }


    function getUSDC() internal {
        IERC20 usdc = IERC20(USDC);
        address user = 0xD137b746818342eA2C87f070BA0113A2f719A5f0;
        uint balance = usdc.balanceOf(user);
        assert(balance > 0);
        vm.prank(user);
        usdc.approve(address(this), balance);
        vm.prank(user);
        usdc.transfer(address(this), 2000e6);

        console.log("Balance USDC");
        console.log(usdc.balanceOf(address(this)));
    }


    function testOpenShort() public {
        // STEP #1 Get USDC 
        getUSDC();

        // STEP #2 Approve leverage
        IERC20(USDC).approve(address(leverage), type(uint).max);

        uint bal0 = IERC20(USDC).balanceOf(address(this));
        console.log("USDC BAL");
        console.log(bal0);

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