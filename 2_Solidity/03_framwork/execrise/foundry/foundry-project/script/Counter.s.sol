// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol"; 
import {Counter} from "../src/Counter.sol";

contract DeployCounter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying from:", deployer);
        console.log("Balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        Counter counter = new Counter();
        
        // 部署后调用初始化函数
        counter.setNumber(100);
        
        vm.stopBroadcast();
        
        console.log("Counter deployed at:", address(counter));
        console.log("Initial number:", counter.number());
    }
}