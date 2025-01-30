//SPDX-License-Identifer:MIT
pragma solidity  ^0.8.18;

import{Script} from "forge-std/Script.sol";
import{x1Coin} from "../src/x1Coin.sol";
import{x1Engine} from "../src/x1Engine.sol";

contract DeployX1Coin is Script{

    uint256 owner = vm.envUint("PRIVATE_KEY");

    function run() external returns (x1Coin,x1Engine) {
        vm.startBroadcast(owner);
        x1Coin coin = new x1Coin();
        x1Engine engine = new x1Engine(address(coin));

        coin.transfer(address(engine), 1_000_000_000 * 10**18);

        coin.transferOwnership(address(engine));
        vm.stopBroadcast();
        return(coin,engine);
    }
}
