pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "yield-utils-v2/token/IERC20.sol";
import "src/Market.sol";

contract Deploy is Script {
    Market market;

    IERC20 constant weth = IERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    IERC20 constant dai = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);

    function run() external {
        vm.startBroadcast();

        // Deploy the market
        market = new Market(weth, dai);

        // Approve token transfers
        uint256 wethAmount = 1_000_000_000_000;
        uint256 daiAmount = 1_000_000_000_000_000;
        weth.approve(address(market), wethAmount);
        dai.approve(address(market), daiAmount);

        // Initialize market
        market.initialize(wethAmount, daiAmount);

        vm.stopBroadcast();
    }
}
