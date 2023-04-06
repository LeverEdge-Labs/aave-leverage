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


    // @dev Helper functions
    function getWETH() internal {
        IERC20 weth = IERC20(WETH);
        address user = 0xD137b746818342eA2C87f070BA0113A2f719A5f0;
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