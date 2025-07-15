// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../src/ResponseTrapRepetition.sol";

contract DeployResponseTrapRepetition is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("Deploying ResponseToTransferRepetition...");
        console.log("Deployer address:", msg.sender);
        
        ResponseToTransferRepetition response = new ResponseToTransferRepetition(msg.sender);
        
        console.log("ResponseToTransferRepetition deployed to:", address(response));
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("Contract Name: ResponseToTransferRepetition");
        console.log("Contract Address:", address(response));
        console.log("Deployer:", msg.sender);
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("==========================");
    }
}