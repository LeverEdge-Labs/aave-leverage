// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/console.sol";

import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

// NOTE: Deploy this contract first
contract B {
    // NOTE: storage layout must be the same as contract A
    uint public constant x = 2;
}

contract C is B {
    uint public num;
    address public sender;

    function setVars(UD60x18 _num) public returns (uint) {

        console.log("HERE");

        num = x * unwrap(_num);
        console.log(num);
        sender = msg.sender;

        return num;
    }
}

contract A {
    uint public num;
    address public sender;

    function setVars(address _contract, uint _num) public {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", ud(_num))
        );

        console.log("RETURN VALS");

        // uint res = abi.decode(data, (uint));

        console.log(success);
        console.log(num);
        // console.log(res);
    }
}
