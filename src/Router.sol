pragma solidity ^0.8.19;

// openzeppelin 
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Leverage
// import "./Factory.sol";

// User Position Manager
import "./UserPositionManager.sol";

// console log
import "forge-std/console.sol";


/// @title Algorithmic Leverage Trade Builder
/// @author LeverEdge Labs
/// @dev This contract is currently in development

contract Router {
    
    // address user => address leverage contract
    // mapping(address => address) leverageContracts;

    mapping(address => address) public UserPositionContracts;

    address public leverageContract;
    address public aaveV3;

    constructor (address _leverageContract, address _aaveV3) {
        leverageContract = _leverageContract;
        aaveV3 = _aaveV3;
    }


    function long(
        address baseAsset,
        address leveragedAsset,
        uint amount,
        UD60x18 leverage
    ) external {
        if (UserPositionContracts[msg.sender] == address(0)) {
            UserPositionManager manager = new UserPositionManager(leverageContract, aaveV3, address(this), msg.sender);
            UserPositionContracts[msg.sender] = address(manager);

            console.log("First Time User calling Router");

            // Calling Child contract
            manager.long(baseAsset, leveragedAsset, amount, leverage);
            
        } else {
            UserPositionManager manager = UserPositionManager(UserPositionContracts[msg.sender]);
            manager.long(baseAsset, leveragedAsset, amount, leverage);
        }
    }


    function short(
        address baseAsset,
        address leveragedAsset,
        uint amountBase,
        UD60x18 leverage
    ) external {
        if (UserPositionContracts[msg.sender] == address(0)) {
            UserPositionManager manager = new UserPositionManager(leverageContract, aaveV3, address(this), msg.sender);
            UserPositionContracts[msg.sender] = address(manager);

            console.log("First Time User calling Router");

            // Calling Child contract
            manager.short(baseAsset, leveragedAsset, amountBase, leverage);
            
        } else {
            UserPositionManager manager = UserPositionManager(UserPositionContracts[msg.sender]);
            manager.short(baseAsset, leveragedAsset, amountBase, leverage);
        }
    }


    function closePosition(uint ID) external {
        UserPositionManager manager = UserPositionManager(UserPositionContracts[msg.sender]);
        require(address(manager) != address(0), "User Position Manager Not Found");

        manager.closePosition(ID);
    }
}
