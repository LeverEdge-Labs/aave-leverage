// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "src/RouterTest.sol";

contract deployRouterTest is Test {

    LeverageTest leverage;
    RouterTest router;

    function setUp() public {
        leverage = new LeverageTest();
        router = new RouterTest(address(leverage));
    }
/* 
    function testCallLongOnce() public {
        router.long(address(0), address(1), 1e18, 1e18);
    }
 */
    function testCallLongTwice() public {
        // first time
        router.long(address(0), address(1), 1e18, 1e18);

        console.log(router.UserContracts(address(this)));

        // second time
        router.long(address(0), address(1), 1e18, 1e18);

    }
}
