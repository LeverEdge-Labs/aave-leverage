// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "src/DelegateCallTest.sol";

contract delegateCallTest is Test {

    A a;
    B b;

    function setUp() public {
        a = new A();
        b = new B();
    }

    function testDelegateCall() public {
        a.setVars(address(b), 3);

        


    }



}