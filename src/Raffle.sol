// SPDX-License-Identifier: MIT

/*
Contract elements should be laid out in the following order:
1. Pragma statements
2. Import statements
3. Events
4. Errors
5. Interfaces
6. Libraries
7. Contracts

Inside each contract, library or interface, use the following order:
1. Type declarations
2. State variables
3. Events
4. Errors
5. Modifiers
6. Functions

Functions should be grouped according to their visibility and ordered:
1. constructor
2. receive function (if exists)
3. fallback function (if exists)
4. external
5. public
6. internal
7. private

The modifier order for a function should be:
1. Visibility
2. Mutability
3. Virtual
4. Override
5. Custom modifiers

*/

pragma solidity ^0.8.18;

/** @title Raffle
 *  @author TheUser1935
 *  @notice This is my version of the smart contract lottery covered in the Cyfrin Updraft course
 *  @dev The Raffle contract implements Chainlink VRF v2
*/

/*@note I HAVE WASTED HOURS TRYING TO RESOLVE PATH ISSUES RELATED TO JUAN BLANCO EXTENSION THAT LED TO ME CAUSIONG ISSUES WITH FORGE REMAPPINGS. SOMEHOW EVEN THOUGH MY REMAPPINGS IS CORRECT IT FAILS TO COMPILE. I'VE HAD IT, I'M USING THIS PATH SO I CAN ATLEAST KEEP LEARNING!!!*/
import {VRFCoordinatorV2Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFCoordinatorV2.sol";

/*@note The VRFConsumerBaseV2 contract is an abstract contract, therfore this Raffle contract must inherit from it and become 'is' VRFConsumerBaseV2
We must be careful when inheriting from an abstract contract to understand what i contains and what params for the constructor it may have.
If what this contract 'is' has params in the inheritance it must be in the constructor of this contract*/
import {VRFConsumerBaseV2} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract Raffle is VRFConsumerBaseV2 {

    //Type declarations (includes enums)
    /*@note Enums allow us to create our own type of something and assign constants to that type. In our case, we want to create an enum for the state of the raffle which will help us in controlling any interactions with our contracts by having the ability to use our custom enum type to set the state that the raffle contract is in. 
    Remember each constant in an enum has an index beginning from zero
    For further info and demo, look at the README.md
    */
    enum RaffleState {
        OPEN,              //index 0
        CALCULATING_WINNER //index 1
        }

    //Constants
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUMBER_OF_WORDS = 1;

    //immutable variables
    uint256 private immutable i_entranceFee;
    //@dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    //storage variables
    address payable[] s_players;
    uint256 private s_lastTimeStamp;
    address private s_lastWinner;
    RaffleState private s_raffleState;

    //Events can have up to 3 indexed parameters - indexed paramters AKA Topics
            //Indexed Params are searchable
    event RafflePickedWinner(address indexed winner);
    event EnteredRaffle(address indexed player);

    //Custom error to use when not enough ETH sent
    error Raffle_NotEnoughETHSent();
    //Transfer to winner failed
    error Raffle_TransferToWinnerFailed();
    //Raffle not open (enum state)
    error Raffle_RaffleNotOpen();
    //Upkeep not needed (FALSE value returned)
    error Raffle_UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    /*@note notice how we are inheriting from VRFConsumerBaseV2 and have it as part of our constructor, however, because we are inherritting it it is ouside the params but before the contents of what we do in the constructor. The VRFConsumerBaseV2 requires the address of the VRFCoordinatorV2Interface - which is part of our constructor*/
    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane, 
        uint64 subscriptionId,
        uint32 callbackGasLimit        
    ) VRFConsumerBaseV2(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        //Set the last time stamp upon deploying the contract
        s_lastTimeStamp = block.timestamp;
        //Set the default state of the raffle at construct
        s_raffleState = RaffleState.OPEN;
    }

    
    function enterRaffle() external payable {
        //---------CHECKS-----------
        // require() is LESS gas efficient than a custom error, therefore, should use revert and custom errors
        //require(msg.value >= i_entranceFee, "Not enough ETH sent");
        if(msg.value < i_entranceFee) {
            revert Raffle_NotEnoughETHSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }
        //---------EFFECTS-----------
        s_players.push(payable(msg.sender));

        /*Rule of thumb: Whenever make a storage update, we should emit an event (about to learn about these for the first time!)
        2 main reasons for events:
            1. Makes mitigation/updating easier
            2. Makes front end 'indexing' easier
        */
        emit EnteredRaffle(msg.sender);


    }

    /*@note Following UpKeep functions taken from Chainlink Automation Docs and slightly modified
    How do we use this checkUpKeep function?
    - This checkUpKeep function will be called from the Chainlink Automation Node. It will give us a boolean value to know if we need to perform something -> in our case, if the raffle is ready to pick a winner
    For this function to retunr a TRUE boolean, the following must be true:
    1. Time interval has passed between raffle draws
    2. The raffle is in OPEN state
    3. The raffle has ETH, meaning that there are players in the raffle
    4. We have our Chainlink Automation subscription connected to a wallet and there is enough LINK in our connected wallet

    @note if function requires param that we wont use, we can wrap it in multi-line comment markers to ignore it
    We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.*/

    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool intervalHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool raffleIsOpen = (s_raffleState == RaffleState.OPEN);
        bool raffleHasPlayers = s_players.length > 0;
        bool haveETH = address(this).balance > 0;
        upkeepNeeded = (intervalHasPassed && raffleIsOpen && raffleHasPlayers && haveETH);
        
        return(upkeepNeeded,"0x0");
    }

    /**GOALS FOR FUNCTION
    1. Get a random number
    2. Use the random number to pick a player
    3. Be automatically called by the contract
    */
    function performUpkeep(bytes calldata /* performData */) external {
        //---------CHECKS-----------
        //Check to see if enough time has passed since last lottery
        (bool upKeepNeeded,) = checkUpkeep("");
        if(!upKeepNeeded) {
            //Provide some info that will help with debugging when reverting
            revert Raffle_UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        
        //---------EFFECTS-----------
        //Set the state of the Raffle contract to calculating the winner to prevent users from entering the raffle again while we pick the winner
        s_raffleState = RaffleState.CALCULATING_WINNER;

        //---------INTERACTIONS-----------
        /* Getting a random number to pick a winner is a 2 step process
        1. Request the random number
        2. Get the random number from the Chainlink VRF data
        */

        // Will revert if subscription is not set and funded.
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gas lane
            i_subscriptionId, //id from subcrisption in chainlink
            REQUEST_CONFIRMATIONS, //num of blocks to wait for confirmation
            i_callbackGasLimit, //Gas limit for callback
            NUMBER_OF_WORDS //num of random numbers to return
        );

    }

    /*@note override keyword forces this to be the function with this name that we want to use, disregarding what was inherrited -in this case inherrited from VRFConsumerBaseV2*/
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        //---------CHECKS-----------

        //---------EFFECTS-----------

        /*@note modulo function (%) works by thinking of the syntax as how many times can the RIGHT side number go into the LEFT side number, then the remainder is the result of the modulo operation. The RIGHT side number sets the maximum number that can be the result of the modulo operation
        e.g. 10 % 5 = 0 ------> 5 goes into 10 2 times with a remainder of 0
        e.g. 11 % 5 = 1 ------> 5 goes into 11 2 times with a remainder of 1
        We can use the length of our storage array to get the index of the winner by uisng the length of the array as the RIGHT side number to set the highest number that can be the result of the modulo operation - so in this case we dont exceed the array length
        */
        uint256 indexOfWinner = randomWords[0] % s_players.length;

        //Use the index to set the winner
        address payable winner = s_players[indexOfWinner];
        //Store last winner
        s_lastWinner = winner;

        //Emit that we have picked a winner
        emit RafflePickedWinner(winner);

        //Reset the players array prior to opening the raffle again to prevent users accidentally entering the raffle before being reset
        s_players = new address payable[](0);

        //Set last time stamp to be used for duration of next raffle
        s_lastTimeStamp = block.timestamp;

        //Set the state of the Raffle contract to open to allow users to enter lottery again
        s_raffleState = RaffleState.OPEN;


        //---------INTERACTIONS-----------

        //Pay winner
        /*@note This is a lower level command is able to call just about any function without needing an ABI, for now just going to focus on sending ETH.

        Call is also the reccomended method currently for sending value
        The ("") is used to type in a function name that we might want to call, not useful for this though
        We always see that "Value" exists on the L side of Remix - this is what we want
        This line returns 2 variables - bool (success), bytes (data returned)
        We don't care about the bytes though in this example, so we leave it blank

        Have to ways of verifying the call command:
            1. require statement
            2. if statement
        Preferred method at this time is using if statements due to ability to gas efficiencies that can be achieved and can use custom errors (e.g. custom error called Raffle_TransferToWinnerFailed)
        */
        
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferToWinnerFailed();
        }
        
    }



    /** GETTER FUNCTIONS */
    
    function getTicketPrice() public view returns(uint256){
        return i_entranceFee;
    }

}