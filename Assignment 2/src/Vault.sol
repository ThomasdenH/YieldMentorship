// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/token/IERC20.sol";

/// @title A vault that can store tokens.
/// @notice This vault allows users to deposit and withdraw tokens.
/// @author Thomas den Hollander
/// @dev Deposits are implemented using a mapping. This is the only (mutable)
///     state that is kept by the contract.
///
///     Amounts are stored with the same decimals as the token contract that
///     was used to initialize the `Vault`.
contract Vault {
    /// @notice The token that is stored in the vault.
    IERC20 public immutable token;

    /// @notice This event is emitted when a successful deposit is made. It
    ///     contains the account that made the deposit and the amount that was
    ///     deposited.
    event Deposit(address indexed account, uint256 deposited);

    /// @notice This event is emitted when a successful withdrawal is
    ///     performed. The first argument is the account that made the
    ///     withdrawal and the second argument is the amount that was
    ///     withdrawn.
    event Withdrawal(address indexed account, uint256 withdrawn);

    /// @notice Deposits made using `deposit` can be reverted with this error
    ///     if the transfer failed.
    /// @dev This error is thrown if `transferFrom` returns `false`. Instead of
    ///     returning false however, it is possible that the `IERC20` reverts,
    ///     for example when attempting to transfer more than the allowance.
    ///     So: not all failed deposits will throw this error.
    error DepositFailed(address account, uint256 amount);
    /// @notice Withdrawals made using `withdraw` can be reverted with this
    ///     error if the amount is too low or if the transfer fails for
    ///     whatever reason. Like with deposits, it is possible that transfers
    ///     revert before this error can be thrown. See also `DepositFailed`.
    error WithdrawalFailed(address account, uint256 amount);

    /// @notice The balance, the size of the deposit for an address.
    mapping(address => uint256) public depositOf;

    /// @notice Deploy the contract.
    /// @param _token The token that should be accepted in the vault.
    constructor(IERC20 _token) {
        token = _token;
    }

    /// @notice Deposit tokens into the vault and add them to the vault
    ///     balance. Make sure that this contract is allowed to transfer the
    ///     tokens.
    ///
    //      This function may revert, for example by throwing an
    ///     `DepositFailed`. However, it may fail if the token transfer fails.
    ///     See also the documentation for `DepositFailed`.
    ///
    /// @param amount The amount of tokens to transfer.
    /// @dev Follows the Checks-Effects-Interactions Pattern.
    function deposit(uint256 amount) external {
        // Add to the deposit
        depositOf[msg.sender] += amount;
        // Transfer the tokens to this contract
        bool successful = token.transferFrom(msg.sender, address(this), amount);

        // Finally, check if the transfer was successful to either revert with
        // an error or emit an event.
        if (successful) {
            emit Deposit(msg.sender, amount);
        } else {
            revert DepositFailed(msg.sender, amount);
        }
    }

    /// @notice Withdraw tokens from the vault and transfer them back to the
    ///     calling address.
    ///
    ///     This function will fail with `WithdrawalFailed` if the amount to be
    ///     withdrawn is more than the balance of the address. It will also
    ///     fail if the `transfer` function returns `false`.
    /// @param amount The amount to withdraw.
    /// @dev Follows the Checks-Effects-Interactions Pattern.
    ///
    ///     The `else` branches could be combined by adding a `return`, but to
    ///     keep the control flow as obvious as possible they aren't.
    function withdraw(uint256 amount) external {
        if (depositOf[msg.sender] >= amount) {
            depositOf[msg.sender] -= amount;
            if (token.transfer(msg.sender, amount)) {
                emit Withdrawal(msg.sender, amount);
            } else {
                revert WithdrawalFailed(msg.sender, amount);
            }
        } else {
            revert WithdrawalFailed(msg.sender, amount);
        }
    }
}
