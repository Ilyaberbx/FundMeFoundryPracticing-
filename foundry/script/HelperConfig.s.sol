// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

struct NetworkConfig {
    address priceFeed;
}

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
            return;
        }

        activeNetworkConfig = getAnvilEthConfig();
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function getAnvilEthConfig() public pure returns (NetworkConfig memory) {}
}
