// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {CNHPriceFeed} from "../../src/oracle/CNHPriceFeed.sol";

/**
 * @title DeployCNHPriceFeed
 * @notice Deploy CNH/USD oracle (8 decimals, e.g. 14492754 = 0.14492754 USD per CNH)
 * @dev forge script script/deploy/DeployCNHPriceFeed.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
 *      Optional: CNH_PRICE_USD_8 env (default 14492754 ≈ 1/6.9 USD)
 */
contract DeployCNHPriceFeed is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // 1 CNH = 1/6.9 USD ≈ 0.14492754 USD => 14492754 (8 decimals)
        uint256 priceUsd8 = vm.envOr("CNH_PRICE_USD_8", uint256(14492754));

        vm.startBroadcast(deployerPrivateKey);

        CNHPriceFeed feed = new CNHPriceFeed(priceUsd8);
        console.log("CNHPriceFeed deployed at:", address(feed));
        console.log("Initial price (8 decimals):", priceUsd8);

        vm.stopBroadcast();

        console.log("Next: setTokenPriceFeed(CNH_ADDRESS, %s)", address(feed));
    }
}
