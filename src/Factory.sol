pragma solidity ^0.8.19;

// openzeppelin 
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Leverage
import "./Leverage.sol"; 


// console log
import "forge-std/console.sol";

/// @title LeverEdge Factory
/// @author LeverEdge Labs
/// @dev This contract is currently in development

contract Factory {
    
    // address user => address leverage contract
    mapping(address => address) leverageContracts;

    address public aaveV3;

    constructor (address _pool) {
        aaveV3 = _pool;
    }

    function getLeverageContractAddress(address user) external view returns (address) {
        return leverageContracts[user];
    }

    function isUserPresent(address user) external view returns (bool) {
        if (leverageContracts[user] != address(0)) {
            return true;
        } else {
            return false;
        }
    }

    function deployLeverage() public returns(address) {
        Leverage leverage = new Leverage(aaveV3);
        leverageContracts[msg.sender] = address(leverage);
        return address(leverage);
    }
    
}
