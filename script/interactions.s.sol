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

contract CreateSubscription is Script {

    
    function run() external returns(uint64) {
        return(createSubscriptionUsingConfig());
    }


    function createSubscriptionUsingConfig() public returns(uint64) {
        HelperConfig hc = new HelperConfig();
        (,,address vrfCoordinator,,,) = hc.activeNetworkConfig();

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