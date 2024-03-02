// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/** @title HelperConfig
    @author TheUser1935
    @notice HelperConfig file will be called upon by DeployRaffle.s.sol to allow us to be able to deploy the Raffle contract across different chains programmatically and automatically
    @dev This script will enable DeployRaffle.s.sol to deploy the Raffle contract across local, testnet and mainnet chains
*/

/** @dev Function statement order - CEI:
1. Checks
2. Effects - on own contract/state
3. Interactions - interactions with other contracts
*/

import {Script} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract HelperConfig is Script {

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint256 entranceFee; 
        uint256 interval;
        address vrfCoordinator; 
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address linkToken;
        uint256 deployerKey;
    }

    constructor () {
        if (block.chainid == 31337) {
            activeNetworkConfig = getOrCreateAnvilConfig();
        } 
        else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        }
        else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }
    

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 240 seconds,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, 
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 9598,
            callbackGasLimit: 500000,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint("SEPOLIA_METAMASK_PRIVATE_KEY")      
        });
    }


    //Local chain requires us to use mock version of VRFCoordinatorV2 - Lucky for us, Chainlink already supply a mock to use
    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {

        //Already have an active network config
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }


        vm.startBroadcast();

        /* VRFCoordinatorV2Mock constructor: constructor(uint96 _baseFee, uint96 _gasPriceLink)
            _baseFee = standard fee that the contract gets and is a flat fee it gets
            _gasPriceLink = how much Link the contract gets per gas in the transactions called
        */
        uint96 baseFee = 0.25 ether; // = 0.25 LINK
        uint96 gasPriceLink = 1 gwei; // = 1e9
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);

        vm.stopBroadcast();

        //Deploy LinkTokenMock
        vm.startBroadcast();
        LinkToken deployedLinkToken = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 240 seconds,
            vrfCoordinator: address(vrfCoordinatorMock), 
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0, //our script will add this
            callbackGasLimit: 500000,
            linkToken: address(deployedLinkToken),
            deployerKey: vm.envUint("ANVIL_0_PRIVATE_KEY")            
        });
    }
}