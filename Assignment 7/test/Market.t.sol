// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "yield-utils-v2/token/IERC20.sol";
import "yield-utils-v2/mocks/ERC20Mock.sol";
import "src/Market.sol";

abstract contract ZeroState is Test {
    Market market;
    ERC20Mock tokenX;
    ERC20Mock tokenY;

    uint256 tokenBalanceX = 10**16;
    uint256 tokenBalanceY = 10**16;

    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);

    function setUp() public virtual {
        tokenX = new ERC20Mock("Token Y", "X");
        tokenY = new ERC20Mock("Token Y", "Y");
        market = new Market(tokenX, tokenY);

        // Mint some tokens
        tokenX.mint(user1, tokenBalanceX);
        tokenY.mint(user1, tokenBalanceY);
    }
}

abstract contract DepositedState is ZeroState {
    uint256 depositedX = 10**15;
    uint256 depositedY = (2 * depositedX) / 3;

    function setUp() public override {
        super.setUp();

        vm.startPrank(user1);
        tokenX.approve(address(market), depositedX);
        tokenY.approve(address(market), depositedY);
        market.initialize(depositedX, depositedY);
        vm.stopPrank();
    }
}

contract ContractTest is ZeroState {
    function testInitialize() public {
        uint256 inputX = 10**15;
        uint256 inputY = 2 * inputX;

        vm.startPrank(user1);
        tokenX.approve(address(market), inputX);
        tokenY.approve(address(market), inputY);
        market.initialize(inputX, inputY);
        vm.stopPrank();

        assertEq(market.balanceOf(user1), inputX * inputY);
        assertEq(tokenX.balanceOf(address(market)), inputX);
        assertEq(tokenY.balanceOf(address(market)), inputY);
    }
}

contract DepositedStateTest is DepositedState {
    /// @dev Test whether selling doesn't give the user too much. Due to
    ///     rounding errors exact comparison is not really possible.
    function testSellX(uint256 x) public {
        vm.assume(x <= 10**40);

        tokenX.mint(user2, x);

        uint256 z = market.totalSupply();

        vm.startPrank(user2);
        tokenX.approve(address(market), x);
        market.sell_x(x);
        vm.stopPrank();

        assert(
            tokenX.balanceOf(address(market)) *
                tokenY.balanceOf(address(market)) >=
                z
        );
    }

    function testSellX1() public {
        // The current supply is x ~ y : 1 ~ 2/3.

        uint256 x = 1000;
        uint256 y = 666;

        tokenX.mint(user2, x);

        uint256 z = market.totalSupply();

        vm.startPrank(user2);
        tokenX.approve(address(market), x);
        uint256 y_real = market.sell_x(x);
        vm.stopPrank();

        // A small increase of
        //      z_0 = 666666666666666000000000000000
        // to
        //      z_1 = 666666666666666666666666000000
        assertEq(
            tokenX.balanceOf(address(market)) *
                tokenY.balanceOf(address(market)),
            z + 666666666000000
        );
        assertEq(tokenX.balanceOf(user2), 0);
        assertEq(tokenY.balanceOf(user2), y);
        assertEq(y_real, y);
    }

    function testSellX2() public {
        // The current supply is x ~ y : 1 ~ 2/3.

        uint256 x = 1234;
        uint256 y = 822;

        tokenX.mint(user2, x);

        uint256 z = market.totalSupply();

        vm.startPrank(user2);
        tokenX.approve(address(market), x);
        uint256 y_real = market.sell_x(x);
        vm.stopPrank();

        // A small increase of
        //      z_0 = 666666666666666000000000000000
        // to
        //      z_1 = 666666666666666666666666000000
        assertEq(
            tokenX.balanceOf(address(market)) *
                tokenY.balanceOf(address(market)),
            z + 666666665651496
        );
        assertEq(tokenX.balanceOf(user2), 0);
        assertEq(tokenY.balanceOf(user2), y);
        assertEq(y_real, y);
    }

    /// @dev Test whether selling doesn't give the user too much. Due to
    ///     rounding errors exact comparison is not really possible.
    function testSellY(uint256 y) public {
        vm.assume(y <= 10**40);

        tokenY.mint(user2, y);

        uint256 z = market.totalSupply();

        vm.startPrank(user2);
        tokenY.approve(address(market), y);
        market.sell_y(y);
        vm.stopPrank();

        assert(
            tokenX.balanceOf(address(market)) *
                tokenY.balanceOf(address(market)) >=
                z
        );
    }

    /// @dev Test whether selling doesn't give the user too much. Due to
    ///     rounding errors exact comparison is not really possible.
    function testSellY1() public {
        uint256 y = 1000;
        uint256 x = 1499;

        tokenY.mint(user2, y);

        uint256 z = market.totalSupply();

        vm.startPrank(user2);
        tokenY.approve(address(market), y);
        uint256 x_real = market.sell_y(y);
        vm.stopPrank();

        assertEq(
            tokenX.balanceOf(address(market)) *
                tokenY.balanceOf(address(market)),
            z + 666666665168666
        );
        assertEq(tokenX.balanceOf(user2), x);
        assertEq(tokenY.balanceOf(user2), 0);
        assertEq(x_real, x);
    }

    function testMint() public {
        uint256 x = 150_000_000;
        uint256 y = 100_000_000;

        vm.startPrank(user1);
        tokenX.approve(address(market), x);
        tokenY.approve(address(market), y);
        uint256 z = market.mint(x, y);
        vm.stopPrank();

        // The tokens should have been subtracted
        assertEq(tokenX.balanceOf(user1), tokenBalanceX - depositedX - x);
        assertEq(tokenY.balanceOf(user1), tokenBalanceY - depositedY - y + 1);

        // The liquidity tokens issued should be proportional to the tokens
        // supplied.
        uint256 x_1 = tokenX.balanceOf(address(market));
        uint256 y_1 = tokenX.balanceOf(address(market));
        uint256 z_1 = market.totalSupply();
        assertEq(z / z_1, x / x_1);
        assertEq(z / z_1, y / y_1);
    }

    function testBurn() public {
        uint256 _balance = market.balanceOf(user1);
        vm.prank(user1);
        (uint256 x, uint256 y) = market.burn(_balance);

        assertEq(x, depositedX);
        assertEq(y, depositedY);
    }
}
