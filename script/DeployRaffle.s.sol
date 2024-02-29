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

import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployRaffle is Script {

    function run() external returns (Raffle) {
        //Get the network config
        HelperConfig hc = new HelperConfig();
    }
}