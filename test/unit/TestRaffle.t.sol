// SPDX-License-Identifier: MIT

/**@dev Test structure
1. Arrange
2. Act
3. Assert
*/


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
    address linkToken;

    Raffle raffle;
    HelperConfig helperConfig;

    //Create player for raffle contract and give funds
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    // EVENTS
    event EnteredRaffle(address indexed player);

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
        callbackGasLimit,
        linkToken
        ) = helperConfig.activeNetworkConfig();



    }

    function testRaffleInitialisesInOpenState() public {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
    
    //////////////////////////////////
    // ENTER RAFFLE                 //
    //////////////////////////////////
    function testRaffleRevertsWhenNotEnoughFunds() public {
        //Arrange
        vm.prank(PLAYER);

        //Act/Assert
        vm.expectRevert(Raffle.Raffle_NotEnoughETHSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhoEntered() public {
        //Arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        //Act
        
        raffle.enterRaffle{value: entranceFee}();
        
        address playerRecorded = raffle.getPlayer(0);
        

        //Assert
        //Should be same address
        assert(playerRecorded == PLAYER);

    }

    function testEmitWhenPlayerEntered() public {
        //Arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        //Act
        /* @note vm.expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter) ----->   Assert a specific log is emitted during the next call.

        1. Call the cheat code, specifying whether we should check the first, second or third topic, and the log data (expectEmit() checks them all). Topic 0 is always checked.
        2. Emit the event we are supposed to see during the next call.
        3. Perform the call.
        */
        vm.expectEmit(true,false,false,false,address(raffle));
        emit EnteredRaffle(PLAYER);

        raffle.enterRaffle{value: entranceFee}();

    }


    //@note Need to change state to calculating before assertion
    function testRaffleRevertWhenRaffleNotOpen() public {
        //Arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();

        /** vm.warp(uint256) allows us to modify the block.timestamp
            ---> In our case, we have an interval set for the raffle which can impact testing, so we can use this cheatcode to change the timestamp to trigger the change in the state that we want for our testing */
        vm.warp(block.timestamp + interval + 1);

        /** vm.roll(uint256) sets the block number. P. Collins often uses vm.roll to change the current block if he is going to be changing the timestamp.*/
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        //Act/Assert
        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
    


    //////////////////////////////////
    // ENTER RAFFLE                 //
    //////////////////////////////////



    //////////////////////////////////
    // ENTER RAFFLE                 //
    //////////////////////////////////

}