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

import{VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";


contract Raffle {
    uint256 private constant REQUEST_CONFIRMATIONS = 3;
    uint256 private constant NUMBER_OF_WORDS = 1;

    uint256 private immutable i_entranceFee;
    //@dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    address private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] s_players;
    uint256 private s_lastTimeStamp;

    //Events can have up to 3 indexed parameters - indexed paramters AKA Topics
            //Indexed Params are searchable
    event RafflePickedWinner(uint256 indexed winner);
    event EnteredRaffle(address indexed player);

    //Custom error to use when not enough ETH sent
    error Raffle_NotEnoughETHSent();

    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane, 
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = vrfCoordinator;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        //Set the last time stamp upon deploying the contract
        s_lastTimeStamp = block.timestamp;
    }


    function enterRaffle() external payable {
        // require() is LESS gas efficient than a custom error, therefore, should use revert and custom errors
        //require(msg.value >= i_entranceFee, "Not enough ETH sent");
        if(msg.value < i_entranceFee) {
            revert Raffle_NotEnoughETHSent();
        }
        s_players.push(payable(msg.sender));

        /*Rule of thumb: Whenever make a storage update, we should emit an event (about to learn about these for the first time!)
        2 main reasons for events:
            1. Makes mitigation/updating easier
            2. Makes front end 'indexing' easier
        */
        emit EnteredRaffle(msg.sender);


    }

    /**GOALS FOR FUNCTION
    1. Get a random number
    2. Use the random number to pick a player
    3. Be automatically called by the contract
    */
    function pickWinner() external {
        //Check to see if enough time has passed since last lottery
        //Get current time
        if(block.timestamp - s_lastTimeStamp < i_interval) {
            //Revert - Not enough time has passed
            revert();
        }

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



    /** GETTER FUNCTIONS */
    
    function getTicketPrice() public view returns(uint256){
        return i_entranceFee;
    }

}