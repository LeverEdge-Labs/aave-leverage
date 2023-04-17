// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

interface IAaveOracle {
    function getAssetPrice(address asset) external returns (uint);
}

contract AaveOracleTest is Test {
    uint ethFork;
    string ETH_RPC = vm.envString("ETH_RPC");

    address WETH = vm.envAddress("WETH_ETH");
    address USDC = vm.envAddress("USDC_ETH");

    address aaveV3_oracle = vm.envAddress("AAVEV3_ORACLE_ETH");

    IAaveOracle oracle;

    function setUp() public {
        ethFork = vm.createSelectFork(ETH_RPC);
        oracle = IAaveOracle(aaveV3_oracle);
    }

    function testGetPrice() public {
        uint price = oracle.getAssetPrice(WETH);
        console.log("WETH PRICE");
        console.log(price);
    }

}
