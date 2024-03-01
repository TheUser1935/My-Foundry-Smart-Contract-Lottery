// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;


//import {Test, console} from "../../lib/forge-std/lib/src/Test.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract TestRaffle is Test {

    uint256 entranceFee; 
    uint256 interval;
    address vrfCoordinator; 
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    Raffle raffle;
    HelperConfig helperConfig;

    //Create player for raffle contract and give funds
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        //Create Deployer
        DeployRaffle deployer = new DeployRaffle();

        //Deploy Raffle contract
        (raffle, helperConfig) = deployer.run();

        //Get the network config so we can test and log those details
        (
        entranceFee, 
        interval,
        vrfCoordinator, 
        gasLane,
        subscriptionId,
        callbackGasLimit
        ) = helperConfig.activeNetworkConfig();



    }

    function testRaffleInitialisesInOpenState() public {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
    

}