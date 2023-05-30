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
    mapping(address => address) leverageContracts;

    address public aaveV3;

    constructor(address _aaveV3) {
        aaveV3 = _aaveV3;
    }

    function getLeverageContract() external view returns (address) {
        return leverageContracts[msg.sender];
    }

    function createLeverageContract() external returns (address) {
        require(
            leverageContracts[msg.sender] == address(0),
            "Leverage contract already created"
        );
        Leverage leverageContract = new Leverage(aaveV3);
        leverageContracts[msg.sender] = address(leverageContract);
        return address(leverageContract);
    }
}
