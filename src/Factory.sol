pragma solidity ^0.8.19;

// openzeppelin 
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Leverage
import "./Leverage.sol"; 

// console log
import "forge-std/console.sol";

/// @title Algorithmic Leverage Trade Builder
/// @author LeverEdge Labs
/// @dev This contract is currently in development

contract Factory {
    
    // address user => address leverage contract
    mapping(address => address) UserPositionContracts;

    address public aaveV3;

    function getLeverageContractAddress(address user) external view returns (address) {
        return UserPositionContracts[user];
    }

    function isUserPresent(address user) external view returns (bool) {
        if (UserPositionContracts[user] != address(0)) {
            return true;
        } else {
            return false;
        }
    }

/*     function deployLeverage() public returns(address) {
        Leverage leverage = new Leverage(aaveV3);
        UserPositionContracts[msg.sender] = address(leverage);
        return address(leverage);
    }

 */
}
