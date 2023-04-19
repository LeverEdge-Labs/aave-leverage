// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/console.sol";

// NOTE: Deploy this contract first
contract B {
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;

    function setVars(uint _num) public returns (uint) {
        num = _num;
        sender = msg.sender;

        return _num;
    }
}

contract A {
    uint public num;
    address public sender;

    function setVars(address _contract, uint _num) public {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        console.log("RETURN VALS");

        uint res = abi.decode(data, (uint));

        console.log(success);
        console.log(num);
        console.log(res);
    }
}
