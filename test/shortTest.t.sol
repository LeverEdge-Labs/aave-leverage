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
    uint ethFork;
    string ETH_RPC = vm.envString("ETH_RPC");

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    Leverage leverage;

    address aaveV3_pool = vm.envAddress("AAVEV3_POOL_ETH");


    function setUp() public {
        ethFork = vm.createSelectFork(ETH_RPC);
        leverage = new Leverage(aaveV3_pool);
    }


    function getUSDC() internal {
        IERC20 usdc = IERC20(USDC);
        address user = 0x203520F4ec42Ea39b03F62B20e20Cf17DB5fdfA7;
        uint balance = usdc.balanceOf(user);
        assert(balance > 0);
        vm.prank(user);
        usdc.approve(address(this), balance);
        vm.prank(user);
        usdc.transfer(address(this), balance);

        console.log("Balance USDC");
        console.log(usdc.balanceOf(address(this)));
    }


    function testOpenShort() public {
        // STEP #1 Get WETH
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
    }


}