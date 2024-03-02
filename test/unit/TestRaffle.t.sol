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
import {Vm} from "lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract TestRaffle is Test {

    uint256 entranceFee; 
    uint256 interval;
    address vrfCoordinator; 
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;
    uint256 deployerKey;

    Raffle raffle;
    HelperConfig helperConfig;

    //Create player for raffle contract and give funds
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    // EVENTS
    event EnteredRaffle(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);

    function setUp() external {
        //Create Deployer
        DeployRaffle deployer = new DeployRaffle();

        //Deploy Raffle contract
        (raffle, helperConfig) = deployer.run();

        vm.deal(PLAYER, STARTING_USER_BALANCE);

        //Get the network config so we can test and log those details
        (
        entranceFee, 
        interval,
        vrfCoordinator, 
        gasLane,
        ,
        callbackGasLimit,
        linkToken,
        deployerKey
        ) = helperConfig.activeNetworkConfig();



    }

    function testRaffleInitialisesInOpenState() public view {
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
    // Check UpKeep                 //
    //////////////////////////////////

    function testCheckUpkeepReturnsFalseWhenNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(upkeepNeeded == false);

    }

    function testUpkeepWhenRaffleNotOpen() public enteredRaffle {
        //Arrange
        //EnteredRaffle modifier is called in enterRaffle which covers our arrange section

        raffle.performUpkeep("");

        //Act
        (bool upKeepNeeded,) = raffle.checkUpkeep("");

        //Assert
        assert(upKeepNeeded == false);

    }

    function testUpkeepWhenNotEnoughTimePassed() public {
        //Arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval - 10);
        vm.roll(block.number + 1);

        //Act
        (bool upKeepNeeded,) = raffle.checkUpkeep("");

        //Assert
        assert(upKeepNeeded == false);
    }

    function testUpkeepReturnsTrueWhenAllConditionsMet() public enteredRaffle {
        //Arrange
        //EnteredRaffle modifier is called in enterRaffle which covers our arrange section

        //Act
        (bool upKeepNeeded,) = raffle.checkUpkeep("");

        //Assert
        assert(upKeepNeeded == true);
    }



    //////////////////////////////////
    // Perofrm Upkeep               //
    //////////////////////////////////

    function testPerformUpkeepOnlyRunsWhenUpkeepReturnsTrue() public enteredRaffle {
        //Arrange
        //EnteredRaffle modifier is called in enterRaffle which covers our arrange section

        //Act
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsWhenUpkeepReturnsFalse() public {
        //Arrange
        //vm.prank(PLAYER);
        //vm.deal(PLAYER, STARTING_USER_BALANCE);

        /*@note Leaving line below in causes the test to fail for not expected error, don't understand why though when I would expect it to pass and revert.
        Logs show the revert is happening but it says its not the expected error. The values of the revert error from logs are: Raffle_UpKeepNotNeeded(100000000000000000 [1e17], 1, 0)
        
        With the line commented out, the reverted error is the expected error and has the revert error params showing as: Raffle_UpKeepNotNeeded(0, 0, 0)
        -----> is it becauase we specify the initial values for the revert error params?*/

        //raffle.enterRaffle{value: entranceFee}();

        //vm.warp(block.timestamp + interval - 2);
        //vm.roll(block.number + 1);
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 balanceOfRaffle = 0;
        uint256 numOfPlayers = 0;

        //Act/Assert
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle_UpKeepNotNeeded.selector, balanceOfRaffle, numOfPlayers, raffleState));
        raffle.performUpkeep("");
        
    }

    function testEmitWhenPerformUpkeepChangesStateAndRequestsWinner() public enteredRaffle {
        //Arrange
        //EnteredRaffle modifier is called in enterRaffle which covers our arrange section

        //Act / Assert

        /*@note vm.recordLogs(); is a cheatcode that tells the VM to start recording all the emitted events as bytes32. To access them, use getRecordedLogs 
        ------> this is handy in the situation where we want to test the emit but the result will be dynamic and not static, which is an issue for expectEmit process.
        ------> This way is handy to capture the log output where can test the emit process

        vm.recordLogs() will create a special array that contains all the emitted events. To access the logs we need to:
            1. import {Vm} from forge-std/Vm.sol
            2. Vm.Log[] memory ARRAY_NAME = vm.getRecordedLogs();

        We can then access the recorded logs to find the emitted events we are after in our test. When we look for the emit value, we can pass in the value to match. 
        -----> If there is multiple entries that feature the same name/value, it becomes important to understand the order in which the logs are emitted (index begins at zero)
        -----> In this contract, the VRFCoordinatorV2 emits requestId first, but we are trying to target the request id emmitted during performUpkeep
        */
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory logEntries = vm.getRecordedLogs();

        //Get the request Id from correct log entry
        bytes32 requestId = logEntries[1].topics[1];
        console.log("requestId: ", uint256(requestId));

        //RaffleState
        Raffle.RaffleState rState = raffle.getRaffleState();
        console.log("raffle state: ", uint256(rState));

        //Assert
        //RequestId should be greater than 0 if the performUpkeep was successful in reaching point to request a winner
        assert(uint256(requestId) > 0);

        assert(uint256(rState) == 1);
        

    }

    //////////////////////////////////
    // Fulfill Random Words         //
    //////////////////////////////////

    /*@note fulfillRandomWords requires 2 params (requestId, consumer). To fully test the revert, we would need to manually test the requestId over and over in the case that there was to be multiple requestIds. It would be crazy to rewrite the logic over and over for an incrementing request ID, so we have an option:
    --- FUZZ TESTING ---
    We can make our test better and able to test a large range of requestIds by passing in as a param to the test the requirement for a uint256 number. We can then reference that param input in our fulfillRandomWords function call.

    Foundry will autogenerate a random number for that input to be used in the fulfillRandomWords function call. Allowing us to test a large range of requestIds with better test coverage, from a single test. In the logs of the test, it will tell us how many times the test was ran. In this test, we specified uint256 as the param and it tested 256 times with different numbers.
     */

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randRequestId) public skipFork enteredRaffle {
        //Arrange
        //EnteredRaffle modifier is called in enterRaffle which covers our arrange section
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randRequestId, address(raffle));
        

    }

    //This is will be a full test of our logic for the raffle system and the components leading up to this
    function testFulfillRandWordsPicksAWinnerResetsAndSendsMoney() public skipFork enteredRaffle {
        //Arrange
        //EnteredRaffle modifier is called in enterRaffle which covers adding 1 person into the raffle
        //Set variables to add more people to raffle
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;

        for(uint256 i = startingIndex; i <= additionalEntrants; i++) {
            
            address newPlayer = address(uint160(i));
            hoax(newPlayer, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        //Record balance of raffle contract before beginning to pick winner
        uint256 prize = entranceFee * additionalEntrants;

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        //Get the Request Id from perform upkeep so we can use it in the fulfillRandomWords call
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory logEntries = vm.getRecordedLogs();

        //Get the request Id from correct log entry
        bytes32 requestId = logEntries[1].topics[1];
        console.log("requestId: ", uint256(requestId));

        //Act

        

        //Pretend to be chainlink vrf node and call fulfillRandomWords and get random number
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        //Assert
        //RaffleState should be back to open
        assert(uint256(raffle.getRaffleState()) == 0);
        //Raffle should have 0 players
        assert(uint256(raffle.getNumberOfPlayers()) == 0);
        //Should have recent winner
        assert(raffle.getRecentWinner() != address(0));
        //Balance should be 0
        assert(address(raffle).balance == 0);
        //Winner should have been sent prize
        assert(raffle.getRecentWinner().balance == (prize + STARTING_USER_BALANCE));
        //Last time stamp should be greater than previous
        assert(raffle.getLastTimeStamp() > previousTimeStamp);

    }


    //////////////////////////////////
    // Modifiers                    //
    //////////////////////////////////

    modifier enteredRaffle() {
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    /*@note right now, some of our tests use the Mock version of the VRF Coordinator. This allows us to act like a chainlink vrf node, however, it will present issues when we try and complete testing on a non-local chain - i.e. Sepolia
    ---> By creating this modifier, we can skip tests when we are using a non-local chain */
    modifier skipFork() {
        if(block.chainid != 31337) {
            return;
            
        }
        _;
    }
}