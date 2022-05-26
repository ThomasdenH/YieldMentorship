// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "yield-utils-v2/mocks/ERC20Mock.sol";
import "src/FractionalWrapper.sol";

/// @dev In this state, the contract has been initialized and user 1 starts
///     with some tokens.
abstract contract ZeroState is Test {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    ERC20Mock token;
    FractionalWrapper wrapper;

    uint256 constant fraction = 7 * (10**26);

    /// @notice The amount of tokens owned by the user.
    uint256 constant tokensMinted = 1_000_000_000_000_000_000;

    address constant user1 = address(1);
    address constant user2 = address(2);
    address constant user3 = address(3);

    function setUp() public virtual {
        token = new ERC20Mock("Token", "TOK");
        wrapper = new FractionalWrapper(token, fraction);

        // Give user 1 some tokens
        token.mint(user1, tokensMinted);
    }
}

/// @dev In this state, the user has deposited some tokens.
abstract contract WrappedTokensMintedState is ZeroState {
    /// @notice The amount of wrapped tokens minted by depositing assets into
    ///     the contract.
    uint256 wrapperTokens;

    function setUp() public override {
        super.setUp();

        // Deposit some tokens
        vm.startPrank(user1);
        token.approve(address(wrapper), tokensMinted);
        wrapperTokens = wrapper.deposit(tokensMinted, user1);
        vm.stopPrank();
    }
}

contract ZeroStateTest is ZeroState {
    function testToken() public {
        assertEq(address(wrapper.token()), address(token));
    }

    function testAsset() public {
        assertEq(wrapper.asset(), address(token));
    }

    function testFraction() public {
        assertEq(wrapper.fraction(), fraction);
    }

    function testTotalSupplyAndAssets() public {
        assertEq(wrapper.totalSupply(), 0);
        assertEq(wrapper.totalAssets(), 0);
    }

    function testAllowance(address owner, address spender) public {
        assertEq(wrapper.allowance(owner, spender), 0);
    }

    function testBalance(address account) public {
        assertEq(wrapper.balanceOf(account), 0);
    }

    /// @dev The `convertToShares` function is very simple. Changing this into
    ///     a fuzz test would basically mean duplicating the entire function.
    ///     Instead, just test some examples: here we should get
    ///     `floor(x * 7 / 10)`. That way, we can explicitely see interaction
    ///     with rounding.
    function testConvertToShares() public {
        // 100 => 70
        assertEq(wrapper.convertToShares(100), 70);
        // 19 => 13.3
        assertEq(wrapper.convertToShares(19), 13);
        // 8 => 5.6
        assertEq(wrapper.convertToShares(8), 5);
        // 7 => 4.9
        assertEq(wrapper.convertToShares(7), 4);
        // 2 => 1.4
        assertEq(wrapper.convertToShares(2), 1);

        // 9 => 6.3
        assertEq(wrapper.convertToShares(9), 6);
        // 81 => 56.7
        assertEq(wrapper.convertToShares(9 * 9), 56);
        // 729 => 510.3
        assertEq(wrapper.convertToShares(9 * 9 * 9), 510);
    }

    /// @dev Same as `testConvertToShares`. Here we compute
    ///     `floor(x * 10 / 7)`.
    function testConvertToAssets() public {
        // 7 => 10
        assertEq(wrapper.convertToAssets(7), 10);
        // 700 => 1000
        assertEq(wrapper.convertToAssets(700), 1000);

        // 1 / 7 = 0.142857... (repeating)
        assertEq(wrapper.convertToAssets(100_000), 142_857);
        assertEq(wrapper.convertToAssets(10_000), 14_285);
        assertEq(wrapper.convertToAssets(1_000), 1_428);
        assertEq(wrapper.convertToAssets(100), 142);
        assertEq(wrapper.convertToAssets(10), 14);
        assertEq(wrapper.convertToAssets(1), 1);
    }

    function testDeposit(address receiver) public {
        vm.startPrank(user1);
        token.approve(address(wrapper), tokensMinted);

        vm.expectEmit(true, true, true, true);
        emit Deposit(
            user1,
            receiver,
            tokensMinted,
            wrapper.convertToShares(tokensMinted)
        );

        wrapper.deposit(tokensMinted, receiver);
        vm.stopPrank();

        assertEq(
            wrapper.balanceOf(receiver),
            wrapper.convertToShares(tokensMinted)
        );
        assertEq(token.balanceOf(user1), 0);
    }

    function testMint(address receiver) public {
        vm.startPrank(user1);
        token.approve(address(wrapper), tokensMinted);
        uint256 shares = wrapper.convertToShares(tokensMinted);

        vm.expectEmit(true, true, true, true);
        emit Deposit(user1, receiver, tokensMinted, shares);

        wrapper.mint(shares, receiver);
        vm.stopPrank();

        assertEq(wrapper.balanceOf(receiver), shares);
        assertEq(token.balanceOf(user1), 0);
    }

    function testApprove(
        uint256 value,
        address from,
        address to
    ) public {
        vm.expectEmit(true, true, true, true);
        emit Approval(from, to, value);

        vm.prank(from);
        assertEq(wrapper.approve(to, value), true);
        assertEq(wrapper.allowance(from, to), value);
    }

    function testMaxDeposit(address account) public {
        assertEq(wrapper.maxDeposit(account), type(uint256).max);
    }

    /// @dev Just test if this function is equivalent to `convertToShares`.
    function testPreviewDeposit(uint256 assets) public {
        vm.assume(assets <= 10**36);
        assertEq(
            wrapper.previewDeposit(assets),
            wrapper.convertToShares(assets)
        );
    }

    function testMaxMint(address account) public {
        assertEq(wrapper.maxDeposit(account), type(uint256).max);
    }

    /// @dev Just test if this function is equivalent to `convertToAssets`.
    function testPreviewMint(uint256 shares) public {
        vm.assume(shares <= 10**36);
        assertEq(wrapper.previewMint(shares), wrapper.convertToAssets(shares));
    }

    function testInitialMaxWithdraw(address owner) public {
        assertEq(wrapper.maxWithdraw(owner), 0);
    }

    /// @dev Just test if this function is equivalent to `convertToShares`.
    function testPreviewWithdraw(uint256 assets) public {
        vm.assume(assets <= 10**36);
        assertEq(
            wrapper.previewWithdraw(assets),
            wrapper.convertToShares(assets)
        );
    }

    function testInitialMaxRedeem(address owner) public {
        assertEq(wrapper.maxRedeem(owner), 0);
    }

    /// @dev Just test if this function is equivalent to `convertToAssets`.
    function testPreviewRedeem(uint256 shares) public {
        vm.assume(shares <= 10**36);
        assertEq(
            wrapper.previewRedeem(shares),
            wrapper.convertToAssets(shares)
        );
    }
}

contract WrappedTokensMintedStateTest is WrappedTokensMintedState {
    function testTransfer() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(user1, user2, wrapperTokens);

        vm.prank(user1);
        assertEq(wrapper.transfer(user2, wrapperTokens), true);

        assertEq(wrapper.balanceOf(user1), 0);
        assertEq(wrapper.balanceOf(user2), wrapperTokens);
    }

    function testTransferFrom() public {
        vm.expectEmit(true, true, true, true);
        emit Approval(user1, user2, wrapperTokens);

        // Approval by user 1
        vm.prank(user1);
        assertEq(wrapper.approve(user2, wrapperTokens), true);

        vm.expectEmit(true, true, true, true);
        emit Transfer(user1, user3, wrapperTokens);

        // Spending by user 2
        vm.prank(user2);
        assertEq(wrapper.transferFrom(user1, user3, wrapperTokens), true);

        assertEq(wrapper.allowance(user1, user2), 0);
        assertEq(wrapper.balanceOf(user1), 0);
        assertEq(wrapper.balanceOf(user2), 0);
        assertEq(wrapper.balanceOf(user3), wrapperTokens);
    }

    function testMaxWithdraw() public {
        assertEq(wrapper.maxWithdraw(user1), tokensMinted);
    }

    function testMaxRedeem() public {
        assertEq(wrapper.maxRedeem(user1), wrapperTokens);
    }

    function testWithdraw() public {
        address receiver = user2;
        address caller = user3;

        vm.prank(user1);
        wrapper.approve(caller, wrapperTokens);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(caller, receiver, user1, tokensMinted, wrapperTokens);

        vm.prank(caller);
        assertEq(
            wrapper.withdraw(tokensMinted, receiver, user1),
            wrapperTokens
        );

        assertEq(wrapper.allowance(user1, caller), 0);
        assertEq(wrapper.balanceOf(caller), 0);
        assertEq(wrapper.balanceOf(receiver), 0);
        assertEq(wrapper.balanceOf(user1), 0);
        assertEq(token.balanceOf(receiver), tokensMinted);
    }

    function testRedeem() public {
        address receiver = user2;
        address caller = user3;

        vm.prank(user1);
        wrapper.approve(caller, wrapperTokens);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(caller, receiver, user1, tokensMinted, wrapperTokens);

        vm.prank(caller);
        assertEq(wrapper.redeem(wrapperTokens, receiver, user1), tokensMinted);

        assertEq(wrapper.allowance(user1, caller), 0);
        assertEq(wrapper.balanceOf(caller), 0);
        assertEq(wrapper.balanceOf(receiver), 0);
        assertEq(wrapper.balanceOf(user1), 0);
        assertEq(token.balanceOf(receiver), tokensMinted);
    }

    /// @dev Test adjusting the fraction by multiplying it by 2. That means
    ///     assets mint twice as many shares so redeeming should give half as
    ///     many.
    function testSetFraction() public {
        wrapper.setFraction(2 * fraction);

        vm.prank(user1);
        assertEq(wrapper.redeem(wrapperTokens, user1, user1), tokensMinted / 2);

        assertEq(wrapper.balanceOf(user1), 0);
        assertEq(token.balanceOf(user1), tokensMinted / 2);
    }
}
