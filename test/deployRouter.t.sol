// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "src/Leverage.sol";
import "src/Router.sol";


contract deployRouter is Test {

    Leverage leverage;
    Router router;

    address aaveV3 = vm.envAddress("AAVEV3_POOL_ETH");

    function setUp() public {
        leverage = new Leverage(aaveV3);
        router = new Router(address(leverage));
    }

    function testDeployed() public {
        address leverageContract = router.leverageContract();
        assert(leverageContract != address(0));
    }

    function testUserInteractionLong() public {
        address base = address(0);
        address vol = address(0);
        uint amount = 1e18;
        UD60x18 leverageAmount = ud(1e18);

        router.long(base, vol, amount, leverageAmount);
    }

    function testUserInteractionShort() public {
        address base = address(0);
        address vol = address(0);
        uint amount = 1e18;
        UD60x18 leverageAmount = ud(1e18);

        router.short(base, vol, amount, leverageAmount);
    }


    function testUserInteractionClose() public {
        uint ID = 0; 

        router.closePosition(ID);
        
    }


}