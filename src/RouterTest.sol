pragma solidity ^0.8.19;

// openzeppelin 
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// console log
import "forge-std/console.sol";

contract LeverageTest {

    mapping(address => uint) public Positions;
    
    function long(address token0, address token1, uint amount, uint leverageAmount) public returns (bool) {
        console.log("Inside LEVERAGE TEST");

        Positions[token0] = amount;

        return true;
    }

}

contract Child {

    mapping(address => uint) public Positions;

    address public leverage;
    address public router;
    address public owner;

    constructor(address _leverage, address _owner) {
        leverage = _leverage;
        router = msg.sender;
        owner = _owner;
    }

    modifier OnlyRouter() {
        require (msg.sender == router);
        _;
    }

    function long(address token0, address token1, uint amount, uint leverageAmount) external OnlyRouter returns (bool) {
        // LeverageTest(leverage).long(token0, token1, amount, leverageAmount);

        console.log("INSIDE CHILD CONTRACT");

        console.log(leverage);

        (bool success, bytes memory data) = leverage.delegatecall(abi.encodeWithSignature("long(address,address,uint256,uint256)", token0, token1, amount, leverageAmount));

        require(success, "delegate to leverage failed");

        // bool res = abi.decode(data, (bool));

        console.log("logging mapping inside child contract:");
        console.log(Positions[token0]);

        return true;
    }
}

contract RouterTest {

    address public leverage;

    mapping(address => address) public UserContracts;


    constructor(address _leverage) {
        leverage = _leverage;
    }

    function long(address token0, address token1, uint amount, uint leverageAmount) public returns (bool) {
        if (UserContracts[msg.sender] == address(0)) {
            Child child = new Child(leverage, msg.sender);
            UserContracts[msg.sender] = address(child);

            console.log("First Time User calling Router");

            // Calling Child contract
            child.long(token0, token1, amount, leverageAmount);
            
        } else {
            Child child = Child(UserContracts[msg.sender]);

            child.long(token0, token1, amount, leverageAmount);
        }
    }

}
