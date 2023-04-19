pragma solidity ^0.8.19;

// openzeppelin 
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Leverage
import "./Factory.sol";

// User Position Manager
import "./UserPositionManager.sol";

// console log
import "forge-std/console.sol";


/// @title Algorithmic Leverage Trade Builder
/// @author LeverEdge Labs
/// @dev This contract is currently in development

contract Router is Factory {
    
    // address user => address leverage contract
    // mapping(address => address) leverageContracts;

    address public leverageContract;

    constructor (address _leverageContract) {
        leverageContract = _leverageContract;
    }


    function long(
        address baseAsset,
        address leveragedAsset,
        uint amount,
        UD60x18 leverage
    ) external {
        if (UserPositionContracts[msg.sender] == address(0)) {
            UserPositionManager manager = new UserPositionManager(leverageContract, address(this), msg.sender);
            UserPositionContracts[msg.sender] = address(manager);

            console.log("First Time User calling Router");

            // Calling Child contract
            manager.long(baseAsset, leveragedAsset, amount, leverage);
            
        } else {
            UserPositionManager manager = UserPositionManager(UserPositionContracts[msg.sender]);
            manager.long(baseAsset, leveragedAsset, amount, leverage);
        }

    }
}
