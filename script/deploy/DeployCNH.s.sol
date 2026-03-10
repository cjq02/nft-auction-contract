// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {CNH} from "../../src/token/CNH.sol";

/**
 * @title DeployCNH
 * @notice Deploy CNH ERC20 token
 * @dev forge script script/deploy/DeployCNH.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
 */
contract DeployCNH is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        CNH cnh = new CNH(deployer);
        console.log("CNH token deployed at:", address(cnh));

        vm.stopBroadcast();

        console.log("Owner:", deployer);
        console.log("Mint: cnh.mint(to, amount)");
    }
}
