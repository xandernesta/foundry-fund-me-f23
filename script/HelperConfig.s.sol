//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/* 
    What we want this script to do:
1. Deploy mocks when we are on local anvil chain
2. keep track of contract address across different chains 
    i.e. Sepolia ETH/USD Pricefeed, Mainnet ETH/USD Pricefeed
 */
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on local chain deploy mocks
    // Else, grab existing contract addresses from the live chain we are using

    // Variables for MockV3Aggregator input
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    NetworkConfig public activeNetworkConfig;
    // Keep a special type/struct for these functions incase we need more than just pricefeed, like vrf or gas

    struct NetworkConfig {
        address priceFeed; //ETH/USD p rice feed address
    }

    // Constructor
    constructor() {
        if (block.chainid == 11155111) {
            // Sepolia's ChainId is 11155111
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            // Since we only have 2 configs currently, we will use our catchall as local config.
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // pricefeed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
            // 1. Deploy the mocks
            // 2. Return the mock address
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE); // 8 decimals for price, and initial EthUsd price of $2000
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }
}
