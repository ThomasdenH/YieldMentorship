// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "yield-utils-v2/token/IERC20.sol";
import "yield-utils-v2/mocks/ERC20Mock.sol";
import "src/Market.sol";

abstract contract ZeroState is Test {
    ////////////////////////////
    // Events from Market.sol //
    event Initialized(address indexed to, uint256 xAmount, uint256 yAmount);
    event Minted(
        address indexed to,
        uint256 xAmount,
        uint256 yAmount,
        uint256 shares
    );
    event Burned(
        address indexed to,
        uint256 xAmount,
        uint256 yAmount,
        uint256 shares
    );
    event SoldX(address indexed account, uint256 xAmount, uint256 yAmount);
    event SoldY(address indexed account, uint256 xAmount, uint256 yAmount);
    ////////////////////////////

    Market market;
    ERC20Mock tokenX;
    ERC20Mock tokenY;

    uint256 tokenBalanceX = 10**16;
    uint256 tokenBalanceY = 10**16;

    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);

    function setUp() public virtual {
        tokenX = new ERC20Mock("Token X", "X");
        tokenY = new ERC20Mock("Token Y", "Y");
        market = new Market(tokenX, tokenY);

        // Mint some tokens
        tokenX.mint(user1, tokenBalanceX);
        tokenY.mint(user1, tokenBalanceY);
    }

    /// @notice Compute the invariant of the product of the token supplies.
    function computeK() internal view returns (uint256) {
        return
            tokenX.balanceOf(address(market)) *
            tokenY.balanceOf(address(market));
    }
}

abstract contract DepositedState is ZeroState {
    uint256 depositedX = 10**15;
    uint256 depositedY = (2 * depositedX) / 3;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(user1);
        tokenX.approve(address(market), depositedX);
        tokenY.approve(address(market), depositedY);
        market.initialize(depositedX, depositedY);
        vm.stopPrank();
    }
}

/// @dev Mint more tokens, so that the invariant is not equal to the total
///     supply of liquidity tokens. The price however, should still be
///     identical.
abstract contract MintedState is DepositedState {
    uint256 mintedX = 24**15;
    uint256 mintedY = (2 * mintedX) / 3;

    function setUp() public override {
        super.setUp();

        vm.startPrank(user1);
        tokenX.mint(user1, mintedX);
        tokenX.approve(address(market), mintedX);
        tokenY.mint(user1, mintedY);
        tokenY.approve(address(market), mintedY);
        market.mint(mintedX, mintedY);
        vm.stopPrank();
    }
}

contract ContractTest is ZeroState {
    /// @notice Test initialization using fuzzing
    function testInitialize(uint256 inputX, uint256 inputY) public {
        vm.assume(inputX < tokenBalanceX);
        vm.assume(inputY < tokenBalanceY);

        vm.startPrank(user1);
        tokenX.approve(address(market), inputX);
        tokenY.approve(address(market), inputY);

        vm.expectEmit(true, true, true, true);
        emit Initialized(user1, inputX, inputY);

        // Initialize by adding liquidity with the two tokens.
        market.initialize(inputX, inputY);

        vm.stopPrank();

        assertEq(market.balanceOf(user1), inputX * inputY);
        assertEq(tokenX.balanceOf(address(market)), inputX);
        assertEq(tokenY.balanceOf(address(market)), inputY);
    }

    /// @dev Test a specific input
    function testInitialize1() public {
        uint256 inputX = 10**15;
        uint256 inputY = 2 * inputX;
        testInitialize(inputX, inputY);
    }

    /// @dev Test that tokens can't be minted without liquidity.
    function testMintFailOnUninitialized() public {
        uint256 inputX = 10**15;
        uint256 inputY = 2 * inputX;

        vm.startPrank(user1);

        // Approve token transfers
        tokenX.approve(address(market), inputX);
        tokenY.approve(address(market), inputY);

        // Mint, we expect an error message
        vm.expectRevert(Uninitialized.selector);
        market.mint(inputX, inputY);

        vm.stopPrank();
    }

    function testBurnFailOnUninitialized(uint256 z) public {
        // We expect an error message
        vm.expectRevert(Uninitialized.selector);
        market.burn(z);
    }
}

contract DepositedStateTest is DepositedState {
    /// @dev Test whether selling doesn't give the user too much. Due to
    ///     rounding errors exact comparison is not really possible while
    ///     using fuzzing.
    ///
    ///     Returns the returned `y` from `sellX` for later reuse.
    function testSellX(uint256 x) public returns (uint256 y) {
        vm.assume(x <= 10**40);

        // First, mint the tokens to sell
        tokenX.mint(user2, x);

        // Compute the invariant for later
        uint256 k = computeK();

        vm.startPrank(user2);
        // Approve transfer
        tokenX.approve(address(market), x);
        // Sell. We don't know the price yet in general so don't check returned
        // y.
        vm.expectEmit(true, true, false, false);
        emit SoldX(user2, x, 0);
        y = market.sellX(x);
        vm.stopPrank();

        // Check invariant
        assert(computeK() >= k);
    }

    /// @dev Here, test selling in a specific case. Here we know the rounding
    ///     to test.
    function testSellX1() public {
        // The current supply is x ~ y : 1 ~ 2/3.
        // Therefore, selling `x` tokenX yields `y` tokenY:
        uint256 x = 1000;
        uint256 y = 666;

        tokenX.mint(user2, x);

        uint256 k = computeK();

        vm.startPrank(user2);
        tokenX.approve(address(market), x);
        vm.expectEmit(true, true, true, true);
        emit SoldX(user2, x, y);
        uint256 yReal = market.sellX(x);
        vm.stopPrank();

        // k only increases
        assertEq(computeK(), k + 666666666000000);

        // Test that the tokens were transferred correctly.
        assertEq(tokenX.balanceOf(user2), 0);
        assertEq(tokenY.balanceOf(user2), y);
        // Test the return parameter.
        assertEq(yReal, y);
    }

    function testSellX2() public {
        // The current supply is x ~ y : 1 ~ 2/3.

        uint256 x = 1234;
        uint256 y = 822;

        tokenX.mint(user2, x);

        uint256 k = computeK();

        vm.startPrank(user2);
        tokenX.approve(address(market), x);
        vm.expectEmit(true, true, true, true);
        emit SoldX(user2, x, y);
        uint256 yReal = market.sellX(x);
        vm.stopPrank();

        // k only increases
        assertEq(computeK(), k + 666666665651496);
        assertEq(tokenX.balanceOf(user2), 0);
        assertEq(tokenY.balanceOf(user2), y);
        assertEq(yReal, y);
    }

    /// @dev Test whether selling doesn't give the user too much. Due to
    ///     rounding errors exact comparison is not really possible.
    function testSellY(uint256 y) public returns (uint256 x) {
        vm.assume(y <= 10**40);

        // Mint tokens
        tokenY.mint(user2, y);

        // Compute invariant for later
        uint256 k = computeK();

        vm.startPrank(user2);
        // Approve
        tokenY.approve(address(market), y);
        // Sell. Don't check for yet unknown `y`.
        vm.expectEmit(true, true, false, false);
        emit SoldY(user2, x, 0);
        x = market.sellY(y);
        vm.stopPrank();

        assert(computeK() >= k);
    }

    /// @dev Test whether selling doesn't give the user too much. Due to
    ///     rounding errors exact comparison is not really possible.
    function testSellY1() public {
        uint256 y = 1000;
        uint256 x = 1499;

        tokenY.mint(user2, y);

        uint256 k = computeK();

        vm.startPrank(user2);
        tokenY.approve(address(market), y);
        vm.expectEmit(true, true, true, true);
        emit SoldY(user2, x, y);
        uint256 xReal = market.sellY(y);
        vm.stopPrank();

        // k only increases
        assertEq(computeK(), k + 666666665168666);
        assertEq(tokenX.balanceOf(user2), x);
        assertEq(tokenY.balanceOf(user2), 0);
        assertEq(xReal, x);
    }

    /// @dev Test whether minting more liquidity tokens takes the correct
    ///     amount of tokens and gives liquidity tokens in the right
    ///     proportion.
    function testMint() public {
        uint256 x = 150_000_000;
        uint256 y = 100_000_000;

        uint256 expectedX = x;
        uint256 expectedY = y - 1;
        uint256 expectedZ = 99_999_999_000_000_000_000_000;

        uint256 startBalanceX = tokenX.balanceOf(user1);
        uint256 startBalanceY = tokenY.balanceOf(user1);
        uint256 startBalanceZ = market.balanceOf(user1);

        vm.startPrank(user1);
        tokenX.approve(address(market), x);
        tokenY.approve(address(market), y);

        vm.expectEmit(true, true, true, true);
        emit Minted(user1, expectedX, expectedY, expectedZ);

        uint256 z = market.mint(x, y);
        vm.stopPrank();

        // The tokens should have been subtracted. Liquidity tokens should have
        // been added.
        assertEq(tokenX.balanceOf(user1), startBalanceX - expectedX);
        assertEq(tokenY.balanceOf(user1), startBalanceY - expectedY);
        assertEq(market.balanceOf(user1), startBalanceZ + expectedZ);

        // The liquidity tokens issued should be proportional to the tokens
        // supplied.
        uint256 x1 = tokenX.balanceOf(address(market));
        uint256 y1 = tokenX.balanceOf(address(market));
        uint256 z1 = market.totalSupply();
        assertEq(z / z1, x / x1);
        assertEq(z / z1, y / y1);
    }

    /// @dev Supply tokens in a different ratio to the current price and see if
    ///     they are subtracted correctly.
    function testMintDifferentRatio() public {
        uint256 x = 10**13;
        uint256 y = 10**15;

        uint256 expectedX = x;
        uint256 expectedY = (x * 2) / 3;
        uint256 expectedZ = 6_666_666_666_666_000_000_000_000_000;

        uint256 startBalanceX = tokenX.balanceOf(user1);
        uint256 startBalanceY = tokenY.balanceOf(user1);
        uint256 startBalanceZ = market.balanceOf(user1);

        vm.startPrank(user1);
        tokenX.approve(address(market), x);
        tokenY.approve(address(market), y);

        vm.expectEmit(true, true, true, true);
        emit Minted(user1, expectedX, expectedY, expectedZ);

        uint256 z = market.mint(x, y);
        vm.stopPrank();

        // The tokens should have been subtracted. Liquidity tokens should have
        // been added.
        assertEq(startBalanceX - tokenX.balanceOf(user1), expectedX);
        assertEq(startBalanceY - tokenY.balanceOf(user1), expectedY);
        assertEq(market.balanceOf(user1) - startBalanceZ, expectedZ);

        // The liquidity tokens issued should be proportional to the tokens
        // supplied.
        uint256 x1 = tokenX.balanceOf(address(market));
        uint256 y1 = tokenX.balanceOf(address(market));
        uint256 z1 = market.totalSupply();
        assertEq(z / z1, x / x1);
        assertEq(z / z1, y / y1);
    }

    function testBurn() public {
        uint256 _balance = market.balanceOf(user1);
        vm.prank(user1);

        vm.expectEmit(true, true, true, true);
        emit Burned(user1, depositedX, depositedY, _balance);
        (uint256 x, uint256 y) = market.burn(_balance);

        assertEq(x, depositedX);
        assertEq(y, depositedY);
    }
}

contract MintedStateTest is MintedState {
    /// @dev Here, test selling in a specific case. Here we know the rounding
    ///     to test.
    function testSellX() public {
        // The current supply is x ~ y : 1 ~ 2/3.
        // Therefore, selling `x` tokenX yields `y` tokenY:
        uint256 x = 400;
        uint256 y = 266;

        tokenX.mint(user2, x);

        uint256 k = computeK();

        vm.startPrank(user2);
        tokenX.approve(address(market), x);
        vm.expectEmit(true, true, true, true);
        emit SoldX(user2, x, y);
        uint256 yReal = market.sellX(x);
        vm.stopPrank();

        // k only increases
        assertEq(computeK(), k + 336572188637229335616);

        // Test that the tokens were transferred correctly.
        assertEq(tokenX.balanceOf(user2), 0);
        assertEq(tokenY.balanceOf(user2), y);
        // Test the return parameter.
        assertEq(yReal, y);
    }

    /// @dev Test whether selling doesn't give the user too much. Due to
    ///     rounding errors exact comparison is not really possible.
    function testSellY() public {
        uint256 y = 470;
        uint256 x = 705;

        tokenY.mint(user2, y);

        uint256 k = computeK();

        vm.startPrank(user2);
        tokenY.approve(address(market), y);
        vm.expectEmit(true, true, true, true);
        emit SoldY(user2, x, y);
        uint256 xReal = market.sellY(y);
        vm.stopPrank();

        // k only increases
        assertEq(computeK(), k + 236952380);
        assertEq(tokenX.balanceOf(user2), x);
        assertEq(tokenY.balanceOf(user2), 0);
        assertEq(xReal, x);
    }
}
