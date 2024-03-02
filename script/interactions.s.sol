// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/** @title Interactions
    @author TheUser1935
    @notice Interactions script that will handle interactions across different contracts
    @dev
*/

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
//import {Raffle} from "src/Raffle.sol";

contract CreateSubscription is Script {

    
    function run() external returns(uint64) {
        return(createSubscriptionUsingConfig());
    }


    function createSubscriptionUsingConfig() public returns(uint64) {
        HelperConfig hc = new HelperConfig();
        (,,address vrfCoordinator,,,,) = hc.activeNetworkConfig();

        return(createSubscription(vrfCoordinator));
    }

    function createSubscription(address vrfCoordinator) public returns(uint64) {
        console.log("Creating subscription on chain ID: ",block.chainid);

        vm.startBroadcast();

        uint64 subscriptionId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();

        vm.stopBroadcast();

        console.log("Subscription ID: ",subscriptionId);
        console.log("Please update subscriptionId in HelperConfig.s.sol to: ",subscriptionId);

        return subscriptionId;
    }
}



/** @dev Contract to fund a subscription */

contract FundSubscription is Script {

    uint96 public constant FUND_AMOUNT = 3 ether;

    function run() external {
        fundSubscriptionUsingConfig();
    }


    function fundSubscriptionUsingConfig() public {
        HelperConfig hc = new HelperConfig();
        (,,address vrfCoordinator,,uint64 subscriptionId,,address linkToken) = hc.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }


    function fundSubscription(address vrfCoordinator, uint64 subscriptionId, address linkToken) public {
        console.log("Funding subscription on chain ID: ",block.chainid);
        console.log("Subscription ID: ",subscriptionId);
        console.log("Link Token: ",linkToken);
        console.log("vrfCoordinator",vrfCoordinator);

        if(block.chainid == 31337) {
            console.log("Funding on anvil");
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
            
        }
        else if(block.chainid == 11155111) {
            console.log("Funding Sepolia");
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator,FUND_AMOUNT,abi.encode(subscriptionId));
            vm.startBroadcast();
        }


    }
    
}

// Contract script to add a consumer to a subscription

contract AddConsumer is Script {

    function run() external {

        address raffleAddress = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        //Raffle raffle = Raffle(raffleAddress);

        addConsumerUsingConfig(raffleAddress);
    }


    function addConsumerUsingConfig(address raffleAddress) public {
        HelperConfig hc = new HelperConfig();
        (,,address vrfCoordinator,,uint64 subscriptionId,,address linkToken) = hc.activeNetworkConfig();

        addConsumer(vrfCoordinator, raffleAddress,subscriptionId);
    }


    function addConsumer(address vrfCoordinator,address consumer,uint64 subscriptionId) public {
        console.log("Adding consumer to subscription on chain ID: ",block.chainid);
        console.log("Subscription ID: ",subscriptionId);
        console.log("Consumer (Raffle): ",consumer);
        console.log("vrfCoordinator: ",vrfCoordinator);

       vm.startBroadcast();

       VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subscriptionId, consumer);

       vm.stopBroadcast();
    }
}