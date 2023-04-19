// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "src/Factory.sol";

contract deployTest is Test {
    uint ethFork;
    string ETH_RPC = vm.envString("ETH_RPC");

    address WETH = vm.envAddress("WETH_ETH");
    address USDC = vm.envAddress("USDC_ETH");

    address aaveV3_pool = vm.envAddress("AAVEV3_POOL_ETH");

    Factory factory;

    function setUp() public {
        ethFork = vm.createSelectFork(ETH_RPC);
        factory = new Factory(aaveV3_pool);
    }

    function testDeployCall() public {
        console.log(factory.aaveV3());

        address newLeverage = factory.deployLeverage();

        console.log("leverage address");
        console.log(newLeverage);
    }

}