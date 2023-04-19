pragma solidity ^0.8.19;

// openzeppelin 
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// console log
import "forge-std/console.sol";

contract LeverageTest {

    // mapping(address => uint) public Positions;
    uint public test;
    
    function long(address token0, address token1, uint amount, uint leverageAmount) public returns (bool) {
        console.log("inside leverage test");

        // Positions[token0] = amount;
        test = amount;

        return true;
    }

}

contract Child {

    uint public test;
    // mapping(address => uint) public Positions;

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

        console.log("INSIDE CHILD");

        console.log(leverage);

        (bool success, bytes memory data) = leverage.delegatecall(abi.encodeWithSignature("long(address,address,uint,uint)", token0, token1, amount, leverageAmount));

        console.log("HERE");
        // require(success, "failed");

        // bool res = abi.decode(data, (bool));

        console.log(success);

        //console.log("result");
        // console.log(res);

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

            console.log("inside router");
        } else {
            Child child = Child(UserContracts[msg.sender]);

            child.long(token0, token1, amount, leverageAmount);
        }
    }


}
