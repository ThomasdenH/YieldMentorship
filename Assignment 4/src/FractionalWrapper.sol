// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/access/Ownable.sol";
import "yield-utils-v2/token/ERC20.sol";
import "yield-utils-v2/token/TransferHelper.sol";
import "src/EIP4626.sol";

error TransferFailed();
error DepositFailed();
error WithdrawalFailed();

using TransferHelper for IERC20;

/// @title A fractional wrapper.
/// @notice Wraps a token in a new token with a different denomination.
///     Implements ERC20 as well as the vault standard EIP4626.
/// @author Thomas den Hollander
/// @dev The fraction is set in the constructor. Apart from the `convert*`
///     functions that do the fractional computation, the vault behaviour is
///     pretty standard.
contract FractionalWrapper is
    EIP4626,
    ERC20("FractionalWrapper", "FWRAP", 18),
    Ownable
{
    /// @notice The asset that is used as underlying in this contract.
    IERC20 public immutable token;

    /// @notice The asset that is used as underlying in this contract.
    /// @dev This returns the same as `token`, except for the type. This
    ///     function exists purely to comply with `EIP4626`.
    function asset() external view override returns (address) {
        return address(token);
    }

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
    uint256 public fraction;

    /// @notice The unit corresponding to a fraction of 1 in terms of the
    ///     smallest token unit. See also `fraction`.
    uint256 constant fractionDenominator = 10**27;

    /// @notice The total amount of assets managed by the vault.
    /// @dev This simply calls the balance of this address. This means that not
    ///     all assets may be redeemable by an account: we could have received
    ///     a generous gift. These would still add up to the total.
    /// @return totalManagedAssets The assets managed by this contract.
    function totalAssets()
        external
        view
        override
        returns (uint256 totalManagedAssets)
    {
        return token.balanceOf(address(this));
    }

    /// @notice Create a new wrapper.
    /// @param _token The token to use as collateral.
    /// @param _fraction The fraction at which to mint/withdraw the tokens.
    /// @dev See the caveats on `fraction` for how to use the `_fraction`
    ///     parameter.
    constructor(IERC20 _token, uint256 _fraction) {
        token = _token;
        fraction = _fraction;
    }

    /// @notice Update the fraction at which shares can be minted/burned. This
    ///     function can only be called by the current owner of the contract.
    /// @param _fraction The new fraction at which shares can be minted and
    ///     burned.
    /// @dev See the caveats on `fraction` for how to use the `_fraction`
    ///     parameter.
    function setFraction(uint256 _fraction) external onlyOwner {
        fraction = _fraction;
    }

    /// @notice Compute how many shares have the value of a given amount of assets.
    /// @param assets The amount of assets to do the calculation with.
    /// @return shares The amount of shares, denoted a precision of `decimals`.
    function convertToShares(uint256 assets)
        public
        view
        override
        returns (uint256 shares)
    {
        return (assets * fraction) / fractionDenominator;
    }

    /// @notice Compute how many assets have the value of a given amount of shares.
    /// @param shares The shares to do the computation on.
    /// @return assets How many assets are worth the provided `shares`.
    function convertToAssets(uint256 shares)
        public
        view
        override
        returns (uint256 assets)
    {
        return (shares * fractionDenominator) / fraction;
    }

    /// @notice The maximal deposit.
    /// @dev There is no maximal deposit.
    function maxDeposit(address)
        external
        pure
        override
        returns (uint256 maxAssets)
    {
        return type(uint256).max;
    }

    /// @notice Compute how many shares would be obtained by depositing in the
    ///     contract.
    /// @param assets The amount of assets to be deposited.
    /// @dev For this contract, this is is the same as `convertToShares`.
    function previewDeposit(uint256 assets)
        external
        view
        override
        returns (uint256 shares)
    {
        return convertToShares(assets);
    }

    /// @notice Deposit assets into the contract to receive shares in return.
    /// @param assets The amount of assets to deposit. This contract should be
    ///     allowed to send itself at least this many of the underlying.
    /// @param receiver The recipient of the shares.
    function deposit(uint256 assets, address receiver)
        external
        override
        returns (uint256 shares)
    {
        shares = convertToShares(assets);

        // Mint share tokens to the receiver
        _mint(receiver, shares);

        // Transfer the underlying to the contract
        token.safeTransferFrom(msg.sender, address(this), assets);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice The maximal amount that can be minted.
    /// @dev There is no maximal mint amount.
    function maxMint(address)
        external
        pure
        override
        returns (uint256 maxShares)
    {
        return type(uint256).max;
    }

    /// @notice Preview the amount of assets that would be necessary when
    ///     minting `shares`. For this contract, this returns the same as
    ///     `convertToAssets`.
    /// @param shares The shares to use for the mint preview.
    /// @return assets The assets that were required as underlying.
    function previewMint(uint256 shares)
        external
        view
        override
        returns (uint256 assets)
    {
        return convertToAssets(shares);
    }

    /// @notice Mint `shares` number of shares to the `receiver`.
    /// @param shares The shares to mint.
    /// @param receiver The owner of the new shares.
    /// @return assets The assets that were required as underlying.
    function mint(uint256 shares, address receiver)
        external
        override
        returns (uint256 assets)
    {
        assets = convertToAssets(shares);

        // Mint share tokens to the receiver
        _mint(receiver, shares);

        // Transfer the underlying to the contract
        token.safeTransferFrom(msg.sender, address(this), assets);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice The maximal amount that can be withdrawn.
    /// @param owner The withdrawer-to-be.
    /// @return maxAssets The maximum amount of assets.
    /// @dev The maximum is determined solely by the balance of the user.
    function maxWithdraw(address owner)
        external
        view
        override
        returns (uint256 maxAssets)
    {
        return convertToAssets(_balanceOf[owner]);
    }

    /// @notice Preview how many shares would be minted with the given assets.
    ///     For this contract, this function does the same as
    ///     `convertToShares`.
    /// @param assets How many assets would be put into the wrapper.
    /// @return shares The shares that would be minted.
    function previewWithdraw(uint256 assets)
        external
        view
        override
        returns (uint256 shares)
    {
        return convertToShares(assets);
    }

    /// @notice Withdraw assets from the vault. Can be called by the owner or
    ///     by another account that has sufficient allowance from the owner.
    ///
    ///     Emits the `Withdraw` event.
    /// @param assets The assets that should be withdrawn.
    /// @param receiver The receiver of the assets.
    /// @param owner The current owner of the shares.
    /// @return shares The shares that were burned to return the assets.
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external override returns (uint256 shares) {
        shares = convertToShares(assets);
        
        // Confirm the sender is the owner or else decrease the allowance.
        _decreaseAllowance(owner, shares);

        // Burn shares and transfer tokens
        _burn(owner, shares);
        token.safeTransfer(receiver, assets);
        
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @notice The maximal amount that can be redeemed by an account.
    /// @param owner The potential redeemer.
    function maxRedeem(address owner)
        external
        view
        override
        returns (uint256 maxShares)
    {
        return _balanceOf[owner];
    }

    /// @notice Preview how many assets would be returned when redeeming shares.
    /// @param shares The amount of shares to be redeemed.
    /// @return assets The assets that would be returned.
    function previewRedeem(uint256 shares)
        external
        view
        override
        returns (uint256 assets)
    {
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
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external override returns (uint256 assets) {
        assets = convertToAssets(shares);

        // Confirm the sender is the owner or else decrease the allowance.
        _decreaseAllowance(owner, shares);

        // Burn shares and transfer tokens
        _burn(owner, shares);
        token.safeTransfer(receiver, assets);
        
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}
