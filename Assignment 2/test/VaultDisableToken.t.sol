// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Vault.sol";
import "src/DisablableCoin.sol";
import "yield-utils-v2/token/IERC20.sol";

/// @notice In the `ZeroState`, the vault has been setup, `mintedAmount` of
///     tokens have been minted and transfers are still enabled.
abstract contract ZeroState {
    Vault vault;
    DisablableCoin token;

    event Deposit(address indexed account, uint256 deposited);
    event Withdrawal(address indexed account, uint256 withdrawn);

    uint256 constant mintedAmount = 1_000_000_000_000_000_000;

    function setUp() public virtual {
        token = new DisablableCoin();
        vault = new Vault(token);
        token.mint(address(this), mintedAmount);
    }
}

/// @notice Do some tests for the behaviour when transfers fail, without
///     reverting. Normally a revert happens when the balance or allowance is
///     too low, which means that the `DepositFailed` errors are seldom thrown.
contract ZeroStateTest is ZeroState, Test {
    /// @notice Test the behaviour when a token could not be transferred for
    ///     deposits.
    /// @param amount How many tokens to deposit.
    function testDisabledDeposit(uint256 amount) public {
        // Assume the deposit is possible...
        vm.assume(amount <= mintedAmount);
        // ...but disable transfers on the token.
        token.setTransfersDisabled(true);

        // Do approve
        token.approve(address(vault), amount);

        // And expect a failure on revert.
        vm.expectRevert(
            abi.encodeWithSelector(Vault.DepositFailed.selector, address(this), amount)
        );

        vault.deposit(amount);

        assertEq(vault.depositOf(address(this)), 0);
        assertEq(token.balanceOf(address(this)), mintedAmount);
    }

    /// @notice Test the behavior when a token could not be transferred for
    ///     withdrawals.
    /// @param amount How many tokens to deposit.
    /// @dev Strictly, this tests two things:
    ///     - Valid deposits, as have been tested in `Vault.t.sol`
    ///     - Invalid withdrawals, which has not been tested before.
    ///
    ///     For succinctness, these two are not split using a seperate test
    ///     state.
    function testDisabledWithdrawal(uint256 amount) public {
        // Assume a valid amount to deposit.
        vm.assume(amount <= mintedAmount);

        // Approve and deposit.
        token.approve(address(vault), amount);
        vault.deposit(amount);

        // Now disable transfers.
        token.setTransfersDisabled(true);

        // Expect an error when withdrawing.
        vm.expectRevert(
            abi.encodeWithSelector(Vault.WithdrawalFailed.selector, address(this), amount)
        );
        vault.withdraw(amount);
    }
}
