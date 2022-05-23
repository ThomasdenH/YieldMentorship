// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/mocks/ERC20Mock.sol";
import "yield-utils-v2/token/ERC20.sol";

/// @notice DisablableCoin is a coin of which transfers can be disabled.
/// @dev The functionality is accomplished by overriding the transfer methods.
contract DisablableCoin is ERC20Mock {
    /// @notice This boolean indicates whether transfers are currently
    ///     disabled.
    bool public transfersDisabled = false;

    constructor() ERC20Mock("DisablableCoin", "DIS") {}

    /// @notice Transfer `amount` from `msg.sender` to `recipient`. This
    ///     function acts identically to the `ERC20Mock` contract if transfers
    ///     are enabled, or return `false` otherwise.
    /// @param recipient The recipient of the tokens.
    /// @param amount The amount to transfer to the recipient.
    /// @dev The function is external and as such cannot be called using
    ///     `super`. Fortunately here it is pretty much a wrapper for
    ///     `_transfer`.
    /// @return success Whether the transfer was successful.
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        if (transfersDisabled) {
            return false;
        } else {
            // `transfer` is external, so no simple call to super.transfer() unfortunately.
            return _transfer(msg.sender, recipient, amount);
        }
    }

    /// @notice Transfer `amount` from `sender` to `recipient`. The allowance
    ///     should be high enough.
    ///
    ///     If transfers are disabled, this always returns `false` without any
    ///     other effects. Otherwise, the behaviour is identical to that of
    ///     `ERC20Mock`.
    /// @param sender The address to take the tokens from.
    /// @param recipient The address to send the tokens to.
    /// @param amount The amount of tokens to send.
    /// @dev The `else` branch contains the contents of the `transferFrom`
    ///     method on `ERC20Mock`. Unfortunately a `super` call is not possible
    ///     as the function is marked `external`.
    /// @return success Whether the transfer was successful.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (transfersDisabled) {
            return false;
        } else {
            // `transferFrom` is external, so no simple call to super.transferFrom() unfortunately.
            _decreaseAllowance(sender, amount);
            return _transfer(sender, recipient, amount);
        }
    }

    /// @notice Enable or disable transfers.
    /// @param disabled If `true`, this will disable token transfers.
    /// @dev This function sets the boolean `transfersDisabled`, which is
    ///     checked before each transfer.
    function setTransfersDisabled(bool disabled) external {
        transfersDisabled = disabled;
    }
}
