// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Vault.sol";
import "src/Coll.sol";
import "yield-utils-v2/token/IERC20.sol";

/// @title Test state with just an initialized `Vault` contract.
/// @notice This test state sets up a `Vault` with `Coll` as token.
/// @dev The setup is straightforward and happens in `setUp`.
/// @author Thomas den Hollander
abstract contract ZeroState is Test {
    Vault vault;
    Coll token;

    event Deposit(address indexed account, uint256 deposited);
    event Withdrawal(address indexed account, uint256 withdrawn);

    function setUp() public virtual {
        token = new Coll();
        vault = new Vault(token);
    }
}

/// @notice Test state where the contract has minted some tokens.
abstract contract MintedTokenState is ZeroState {
    /// @notice The amount of tokens that the contract should own at the start
    ///     of tests.
    uint256 constant tokensMinted = 1_000_000_000_000_000_000;

    address constant user = address(0x101);

    function setUp() public virtual override {
        super.setUp();
        token.mint(user, tokensMinted);
        vm.label(user, "user");
    }
}

/// @notice Test state where the contract has deposited some tokens. The amount
///     of tokens is equal to `tokensMinted`.
abstract contract DepositedTokenState is MintedTokenState {
    function setUp() public override {
        super.setUp();

        // Approve token transfers and deposit into the vault.
        vm.startPrank(user);
        token.approve(address(vault), tokensMinted);
        vault.deposit(tokensMinted);
        vm.stopPrank();
    }
}

/// @notice Test some simple properties of the contract in the `ZeroState`.
contract ZeroStateTest is ZeroState {
    /// @notice Test whether the token was initialized correctly.
    function testToken() public {
        assertEq(address(token), address(vault.token()));
    }

    /// @notice Test that any deposit start at 0.
    /// @param accountToCheck The account to check the deposit of. Any address
    ///     should have a 0 deposit.
    function testInitialDepositOf(address accountToCheck) public {
        assertEq(vault.depositOf(accountToCheck), 0);
    }
}

/// @notice Test depositing in the `MintedTokenState`.
contract MintedTokenStateTest is MintedTokenState {
    /// @notice Test depositing. We use fuzzing by choosing a random amount to
    ///     deposit (although it must not be more than the amount of minted
    ///     tokens).
    /// @param amountToDeposit The amount of tokens to deposit into the vault.
    function testDepositing(uint256 amountToDeposit) public {
        // Fuzzing should not try to deposit more tokens than we own.
        vm.assume(amountToDeposit <= tokensMinted);

        vm.startPrank(user);

        // Approve transfer
        token.approve(address(vault), amountToDeposit);

        // Expect a `Deposit` event emission.
        vm.expectEmit(true, true, true, true);
        emit Deposit(user, amountToDeposit);

        // Deposit!
        vault.deposit(amountToDeposit);

        vm.stopPrank();

        // And finally, check balances.
        assertEq(vault.depositOf(user), amountToDeposit);
        assertEq(
            token.balanceOf(user),
            tokensMinted - amountToDeposit
        );
    }
}

/// @notice Test withdrawal properties after a deposit has been made.
contract DepositedTokenStateTest is DepositedTokenState {
    /// @notice Test whether withdrawing works.
    function testWithdrawal() public {
        // We expect a withdrawal event.
        vm.expectEmit(true, true, true, true);
        emit Withdrawal(user, tokensMinted);

        // Withdraw.
        vm.prank(user);
        vault.withdraw(tokensMinted);

        // Check new balances.
        assertEq(vault.depositOf(user), 0);
        assertEq(token.balanceOf(user), tokensMinted);
    }

    /// @notice Test partial withdrawals.
    function testPartialWithdrawal(uint256 amountToWithdraw) public {
        // Assume that the withdrawal is valid
        vm.assume(amountToWithdraw < tokensMinted);

        // Expect a withdrawal event.
        vm.expectEmit(true, true, true, true);
        emit Withdrawal(user, amountToWithdraw);

        // Withdraw!
        vm.prank(user);
        vault.withdraw(amountToWithdraw);

        // Check balances. `tokensMinted` is the size of the initial deposit.
        assertEq(
            vault.depositOf(user),
            tokensMinted - amountToWithdraw
        );
        assertEq(token.balanceOf(user), amountToWithdraw);
    }

    /// @notice Test that withdrawing too much fails.
    function testWithdrawalTooHigh(uint256 amount) public {
        // Assume that the amount is too high.
        vm.assume(amount > tokensMinted);

        // Expect a revert containing the address and amount.
        vm.expectRevert(
            abi.encodeWithSelector(
                WithdrawalFailed.selector,
                user,
                amount
            )
        );

        // Try to withdraw!
        vm.prank(user);
        vault.withdraw(amount);
    }
}
