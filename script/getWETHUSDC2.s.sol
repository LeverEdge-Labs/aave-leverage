// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract getTokens is Test {

    address WETH = vm.envAddress("WETH_ETH");
    address USDC = vm.envAddress("USDC_ETH");


    function run() public {

        deal(address(USDC), 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 10_000e6, true);


        console.log(IERC20(USDC).balanceOf(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));

    }

}