// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/** @title DeployRaffle
    @author TheUser1935
    @notice Deploy script for the Raffle contract as part of the Cyfrin Updraft course
    @dev This script will be able to deploy the Raffle contract across local, testnet and mainnet chains

    @note Goals for this Deploy script:
        1. Be able to deploy the Raffle contract across local, testnet and mainnet chains
        2. Be able to supply appropriate constructor args for each chain to deploy to
        3. Use a re-useability approach for design with scalability in mind
*/

/** @dev Raffle.sol constructor args:
    - uint256 entranceFee, 
    - uint256 interval, 
    - address vrfCoordinator, 
    - bytes32 gasLane, 
    - uint64 subscriptionId,
    - uint32 callbackGasLimit
*/

/** @dev Function statement order - CEI:
1. Checks
2. Effects - on own contract/state
3. Interactions - interactions with other contracts
*/

/*@note will build out logic to handle subscription Id, as of 7pm 01/03/24 have not built this logic out */

import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription,FundSubscription,AddConsumer} from "script/interactions.s.sol";


contract DeployRaffle is Script {

    function run() external returns (Raffle, HelperConfig) {
        //Get the network config
        HelperConfig hc = new HelperConfig();

        (
        uint256 entranceFee, 
        uint256 interval,
        address vrfCoordinator, 
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address linkToken,
        uint256 deployerKey
        ) = hc.activeNetworkConfig();

        //Create subscription if not already created
        if(subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator, deployerKey);

            //Fund the subscription
            FundSubscription deployedFundSubscription = new FundSubscription();
            deployedFundSubscription.fundSubscription(vrfCoordinator, subscriptionId, linkToken, deployerKey);

            
        }

        


        //Start broadcast to deploy Raffle contract
        vm.startBroadcast(deployerKey);

        Raffle deployedRaffle = new Raffle(entranceFee, interval, vrfCoordinator, gasLane, subscriptionId, callbackGasLimit);

        vm.stopBroadcast();

        //Add consumer to subscription
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(vrfCoordinator, address(deployedRaffle), subscriptionId, deployerKey);


        return (deployedRaffle, hc);
    }

    


}