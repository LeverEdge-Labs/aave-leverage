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

    // function getPositionManager(address user) 
    function getPositionManager() external view returns (address) {
        return UserPositionContracts[msg.sender];
    }

    function createPositionManager() external returns (address) {
        require(UserPositionContracts[msg.sender] == address(0), "PositionManager Already Created");
        UserPositionManager manager = new UserPositionManager(leverageContract, aaveV3, address(this), msg.sender);
        UserPositionContracts[msg.sender] = address(manager);

        return address(manager);
    }
}
