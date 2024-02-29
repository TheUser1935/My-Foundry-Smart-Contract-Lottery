// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/** @title HelperConfig
    @author TheUser1935
    @notice HelperConfig file will be called upon by DeployRaffle.s.sol to allow us to be able to deploy the Raffle contract across different chains programmatically and automatically
    @dev This script will enable DeployRaffle.s.sol to deploy the Raffle contract across local, testnet and mainnet chains
*/

import {Script} from "lib/forge-std/src/Script.sol";

contract HelperConfig {

    NetworkConfig activeNetworkConfig;

    struct NetworkConfig {
        uint256 entranceFee; 
        uint256 interval;
        address vrfCoordinator; 
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    constructor () {
        if (block.chainid == 31337) {
            activeNetworkConfig = getOrCreateAnvilConfig();
        } 
        else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        }
    }
    

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 240 seconds,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, 
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,
            callbackGasLimit: 500000            
        });
    }


    //Local chain requires us to use mocks
    function getOrCreateAnvilConfig() public view returns (NetworkConfig memory) {

        //Already have an active network config
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        return NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 240 seconds,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, 
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,
            callbackGasLimit: 500000            
        });
    }
}