// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract getTokens is Test {

    address WETH = vm.envAddress("WETH_ETH");
    address USDC = vm.envAddress("USDC_ETH");

    
    function getWETH() internal {
        IERC20 weth = IERC20(WETH);
        address user = 0xc1C736F2Ac0e0019A188982c7c8C063976A4d8d9;
        uint balance = weth.balanceOf(user);
        assert(balance > 0);
        vm.prank(user);
        weth.approve(address(this), balance);
        vm.prank(user);
        weth.transfer(address(this), balance);

        console.log("Balance WETH");
        console.log(weth.balanceOf(address(this)));
    }


    function getUSDC() internal {
        IERC20 usdc = IERC20(USDC);
        address user = 0x203520F4ec42Ea39b03F62B20e20Cf17DB5fdfA7;
        uint balance = usdc.balanceOf(user);
        assert(balance > 0);
        vm.prank(user);
        usdc.approve(address(this), balance);
        vm.prank(user);
        usdc.transfer(address(this), 10000e6);

        console.log("Balance USDC");
        console.log(usdc.balanceOf(address(this)));
    }


    function run() public {
        getWETH();
        getUSDC();


        IERC20(WETH).transfer(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 10e18);
        IERC20(USDC).transfer(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 10000e6);


        console.log(IERC20(WETH).balanceOf(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));

    }

}