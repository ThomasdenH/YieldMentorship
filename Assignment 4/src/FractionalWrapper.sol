// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/EIP4626.sol";

error TransferFailed();
error DepositFailed();
error WithdrawalFailed();

/// @title A fractional wrapper.
/// @notice Wraps a token in a new token with a different denomination.
///     Implements ERC20 as well as the vault standard EIP4626.
/// @author Thomas den Hollander
/// @dev The fraction is set in the constructor. Apart from the `convert*` 
///     functions that do the fractional computation, the vault behaviour is
///     pretty standard. 
contract FractionalWrapper is EIP4626 {
    /// @notice The asset that is used as underlying in this contract.
    IERC20 immutable public token;

    /// @notice The asset that is used as underlying in this contract.
    /// @dev This returns the same as `token`, except for the type. This
    ///     function exists purely to comply with `EIP4626`.
    function asset() external override view returns (address) {
        return address(token);
    }

    /// @notice The name of the wrapper token.
    string public constant override name = "FractionalWrapper";
    /// @notice The symbol of the wrapper token.
    string public constant override symbol = "FWRAP";
    /// @notice The number of decimals of the wrapper token.
    uint8 public constant override decimals = 18;

    /// @notice The fraction at which the wrapped tokens are minted for the
    ///     underlying.
    /// @dev Denoted in increments of 1e-27. `fractionDenominator` gives the
    //      unit (corresponding to a fraction of 1:1).
    ///
    ///     Note: This conversion happens in terms of the smallest unit of the
    ///     token. The wrapping token has a fixed number of decimals that may
    ///     be different to the number of decimals of the underlying. If that
    ///     is the case, an unintended conversion may happen. For example,
    ///     wrapping a token with 0 decimals into a wrapper with 18 decimals
    ///     will effectively correspond to a fraction of
    ///     `1 / 1e-18 * fractionDenominator`.
    uint256 public immutable fraction;
    /// @notice The unit corresponding to a fraction of 1 in terms of the
    ///     smallest token unit. See also `fraction`.
    uint256 constant fractionDenominator = 10**27;

    /// @notice The total amount of wrapped tokens in existence.
    uint256 public override totalSupply = 0;

    /// @notice The total amount of assets managed by the vault.
    /// @dev This simply calls the balance of this address. This means that not
    ///     all assets may be redeemable by an account: we could have received
    ///     a generous gift. These would still add up to the total.
    /// @return totalManagedAssets The assets managed by this contract.
    function totalAssets() external override view returns (uint256 totalManagedAssets) {
        return token.balanceOf(address(this));
    }

    /// @notice The current allowance by the owner to spend by the spender.
    ///     Access as follows:
    ///     - owner: The owner of the tokens. Note: The allowance may be higher
    ///         than their current balance.
    ///     - spender: The spender of the tokens.
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @notice The balance of addresses in terms of wrapper tokens.
    mapping(address => uint256) public override balanceOf;

    /// @notice Create a new wrapper.
    /// @param _token The token to use as collateral.
    /// @param _fraction The fraction at which to mint/withdraw the tokens.
    /// @dev See the caveats on `fraction` for how to use the `_fraction`
    ///     parameter.
    constructor(IERC20 _token, uint256 _fraction) {
        token = _token;
        fraction = _fraction;
    }

    /// @notice Transfer tokens to another account.
    ///
    ///     Fails with `TransferFailed` if the balance of the caller is not
    ///     high enough.
    /// @param recipient The tokens' new owner.
    /// @param amount The amount of tokens to transfer. This is denominated in
    ///     shares, not collateral!
    /// @return successful whether the transfer was succesful. If the
    ///     transaction did not revert, this always returns true.
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        uint256 _senderBalance = balanceOf[msg.sender];
        if (_senderBalance >= amount) {
            balanceOf[msg.sender] = _senderBalance - amount;
            balanceOf[recipient] += amount;
            emit Transfer(msg.sender, recipient, amount);
            return true;
        } else {
            revert TransferFailed();
        }
    }

    /// @notice Transfer tokens from one account to another account. Requires
    ///     sufficient allowance by the spending party. The amount is
    ///     subtracted from the allowance.
    ///     
    ///     Fails with `TransferFailed` if the balance is not high enough, or
    ///     if the allowance is not sufficient.
    /// @param sender The account to take tokens from.
    /// @param recipient The account to send tokens to.
    /// @param amount The amount of tokens to send.
    /// @return success whether the transfer was succesful. If the
    ///     transaction did not revert, this always returns true.
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool success) {
        uint256 _senderBalance = balanceOf[sender];
        uint256 _allowance = allowance[sender][msg.sender];
        if (_senderBalance >= amount && _allowance >= amount) {
            allowance[sender][msg.sender] = _allowance - amount;
            balanceOf[sender] = _senderBalance - amount;
            balanceOf[recipient] += amount;
            emit Transfer(sender, recipient, amount);
            return true;
        } else {
            revert TransferFailed();
        }
    }

    /// @notice Allow an address to spend `value` tokens. This sets the
    ///     allowance to the new value. Be mindful of ordering attacks when
    ///     using this function: https://github.com/yieldprotocol/yield-utils-v2/blob/main/contracts/token/IERC20.sol#L42
    /// @param spender The spender of the tokens owned by the caller.
    /// @param value The total value that may be spent, possibly across several
    ///     transactions.
    /// @return successful whether the approval was successful. In our case
    ///     this is always true.
    function approve(address spender, uint256 value) external override returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /// @notice Compute how many shares have the value of a given amount of assets.
    /// @param assets The amount of assets to do the calculation with.
    /// @return shares The amount of shares, denoted a precision of `decimals`.
    function convertToShares(uint256 assets) public override view returns (uint256 shares) {
        return (assets * fraction) / fractionDenominator;
    }

    /// @notice Compute how many assets have the value of a given amount of shares.
    /// @param shares The shares to do the computation on.
    /// @return assets How many assets are worth the provided `shares`.
    function convertToAssets(uint256 shares) public override view returns (uint256 assets) {
        return (shares * fractionDenominator) / fraction;
    }

    /// @notice The maximal deposit.
    /// @dev There is no maximal deposit.
    function maxDeposit(address) external override pure returns (uint256 maxAssets) {
        return type(uint256).max;
    }

    /// @notice Compute how many shares would be obtained by depositing in the
    ///     contract.
    /// @param assets The amount of assets to be deposited.
    /// @dev For this contract, this is is the same as `convertToShares`.
    function previewDeposit(uint256 assets) external override view returns(uint256 shares) {
        return convertToShares(assets);
    }

    /// @notice Deposit assets into the contract to receive shares in return.
    /// @param assets The amount of assets to deposit. This contract should be
    ///     allowed to send itself at least this many of the underlying.
    /// @param receiver The recipient of the shares.
    function deposit(uint256 assets, address receiver) external override returns (uint256 shares) {
        shares = convertToShares(assets);
        balanceOf[receiver] += shares;
        totalSupply += shares;
        if (token.transferFrom(msg.sender, address(this), assets)) {
            emit Deposit(msg.sender, receiver, assets, shares);
        } else {
            revert DepositFailed();
        }
    }

    /// @notice The maximal amount that can be minted.
    /// @dev There is no maximal mint amount.
    function maxMint(address) external override pure returns (uint256 maxShares) {
        return type(uint256).max;
    }

    /// @notice Preview the amount of assets that would be necessary when
    ///     minting `shares`. For this contract, this returns the same as
    ///     `convertToAssets`.
    /// @param shares The shares to use for the mint preview.
    /// @return assets The assets that were required as underlying.
    function previewMint(uint256 shares) external override view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    /// @notice Mint `shares` number of shares to the `receiver`.
    /// @param shares The shares to mint.
    /// @param receiver The owner of the new shares.
    /// @return assets The assets that were required as underlying.
    function mint(uint256 shares, address receiver) external override returns (uint256 assets) {
        assets = convertToAssets(shares);
        balanceOf[receiver] += shares;
        totalSupply += shares;
        if (token.transferFrom(msg.sender, address(this), assets)) {
            emit Deposit(msg.sender, receiver, assets, shares);
        } else {
            revert DepositFailed();
        }
    }

    /// @notice The maximal amount that can be withdrawn.
    /// @param owner The withdrawer-to-be.
    /// @return maxAssets The maximum amount of assets.
    /// @dev The maximum is determined solely by the balance of the user.
    function maxWithdraw(address owner) external override view returns (uint256 maxAssets) {
        return convertToAssets(balanceOf[owner]);
    }

    /// @notice Preview how many shares would be minted with the given assets.
    ///     For this contract, this function does the same as
    ///     `convertToShares`.
    /// @param assets How many assets would be put into the wrapper.
    /// @return shares The shares that would be minted.
    function previewWithdraw(uint256 assets) external override view returns (uint256 shares) {
        return convertToShares(assets);
    }

    /// @notice Internal withdraw function. Used by `withdraw` and `redeem`
    ///     since they are identical except for the computation of
    ///     assets/shares.
    /// @param assets The amount of assets to withdraw.
    /// @param shares Shares corresponding to the assets.
    /// @param receiver The receiver of the underlying.
    /// @param owner The owner of the wrapper tokens.
    /// @dev This function checks the following:
    ///     - The caller should be the owner or have sufficient allowance.
    ///         The allowance should be subtracted.
    ///     - The balance of the owner in shares should be sufficient.
    ///     - The token transfer should be successful.
    ///     In all other cases the withdrawal should revert.
    function _withdraw(uint256 assets, uint256 shares, address receiver, address owner) internal {
        // First check ownership/permission:
        if (msg.sender != owner) {
            // Not the owner, try to subtract allowance.
            uint256 _allowance = allowance[owner][msg.sender];
            if (_allowance >= shares) {
                allowance[owner][msg.sender] = _allowance - shares;
            } else {
                revert WithdrawalFailed();
            }
        }

        // At this point the sender is the owner, or the allowance has been
        // withdrawn.

        // Check the balance
        uint256 _balance = balanceOf[owner];
        if (_balance < shares) {
            revert WithdrawalFailed();
        }

        // Update the state
        balanceOf[owner] = _balance - shares;
        totalSupply -= shares;

        if (token.transfer(receiver, assets)) {
            emit Withdraw(msg.sender, receiver, owner, assets, shares);
        } else {
            revert WithdrawalFailed();
        }
    }

    /// @notice Withdraw assets from the vault. Can be called by the owner or
    ///     by another account that has sufficient allowance from the owner.
    ///     
    ///     Emits the `Withdraw` event.
    /// @param assets The assets that should be withdrawn.
    /// @param receiver The receiver of the assets.
    /// @param owner The current owner of the shares.
    /// @return shares The shares that were burned to return the assets.
    function withdraw(uint256 assets, address receiver, address owner) external override returns (uint256 shares) {
        shares = convertToShares(assets);
        _withdraw(assets, shares, receiver, owner);
    }

    /// @notice The maximal amount that can be redeemed by an account.
    /// @param owner The potential redeemer.
    function maxRedeem(address owner) external override view returns (uint256 maxShares) {
        return balanceOf[owner];
    }

    /// @notice Preview how many assets would be returned when redeeming shares.
    /// @param shares The amount of shares to be redeemed.
    /// @return assets The assets that would be returned.
    function previewRedeem(uint256 shares) external override view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    /// @notice Redeem shares for assets.
    ///
    ///     Emits the withdraw event.
    /// @param shares The amount of shares to be redeemed.
    /// @param receiver The receiver of the underlying.
    /// @param owner The owner of the shares.
    /// @return assets The amount of underlying that was returned.
    /// @dev This function is the same as `withdraw` except that it accepts
    ///     `shares` instead of `assets` to compute the other from.
    function redeem(uint256 shares, address receiver, address owner) external override returns (uint256 assets) {
        assets = convertToAssets(shares);
        _withdraw(assets, shares, receiver, owner);
    }
}
