pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "yield-utils-v2/token/IERC20.sol";
import "yield-utils-v2/mocks/ERC20Mock.sol";
import "src/Market.sol";

interface Weth is IERC20 {
    function deposit(uint wad) payable external;
}

contract Deploy is Script {
    Market market;

    Weth constant weth = Weth(0xd0A1E359811322d97991E03f863a0C30C2cF029C);

    address constant testAccount = 0xE2dAb2268243EB8c0BD74F2Bf4bdFC2eaC0284E8;

    function run() external {
        require(block.chainid == 42, "should be deployed on Kovan");

        vm.startBroadcast();

        ERC20Mock dai = new ERC20Mock("Dai", "DAI");

        // Deploy the market
        market = new Market(weth, dai);

        // Approve token transfers
        uint256 wethAmount = 10_000_000_000_000_000_000;
        uint256 daiAmount = 20_000_000_000_000_000_000_000;
        weth.deposit{ value: wethAmount }(wethAmount);
        weth.approve(address(market), wethAmount);

        // Mint as Dai contract owner
        dai.mint(msg.sender, daiAmount);
        dai.approve(address(market), daiAmount);

        // Initialize market
        market.initialize(wethAmount, daiAmount);

        // Send some dai to the testing account
        dai.mint(testAccount, daiAmount);

        vm.stopBroadcast();
    }
}
