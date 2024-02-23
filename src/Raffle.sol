// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @title Raffle
 *  @author TheUser1935
 *  @notice This is my version of the smart contract lottery covered in the Cyfrin Updraft course
 *  @dev The Raffle contract implements Chainlink VRF v2
*/


contract Raffle {

    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee){

        i_entranceFee = entranceFee;
    }


    function enterRaffle() public payable {

    }


    function pickWinner() public {

    }



    /** GETTER FUNCTIONS */
    
    function getTicketPrice() public view returns(uint256){
        return i_entranceFee;
    }

}