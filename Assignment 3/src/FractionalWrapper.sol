// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/EIP4626.sol";

contract FractionalWrapper is EIP4626 {
    error TransferFailed();
    error DepositFailed();
    error WithdrawalFailed();

    /// @notice The asset that is used as underlying in this contract.
    IERC20 immutable public token;

    /// @notice The asset that is used as underlying in this contract.
    /// @dev This returns the same as `token`, except for the type. This
    ///     function exists purely to comply with `EIP4626`.
    function asset() external override view returns (address) {
        return address(token);
    }

    string public constant override name = "FractionalWrapper";
    string public constant override symbol = "FWRAP";
    uint8 public constant override decimals = 18;

    /// @notice The fraction at which the wrapped tokens are minted for the
    ///     underlying.
    /// @dev Denoted in increments of 1e-27.
    uint256 public immutable fraction;
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
        if (balanceOf[msg.sender] >= amount) {
            balanceOf[msg.sender] -= amount;
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
        if (balanceOf[sender] >= amount && allowance[sender][msg.sender] >= amount) {
            allowance[sender][msg.sender] -= amount;
            balanceOf[sender] -= amount;
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
        if (!token.transferFrom(msg.sender, address(this), assets)) {
            revert DepositFailed();
        }
    }

    /// @notice The maximal amount that can be minted.
    /// @dev There is no maximal mint amount.
    function maxMint(address) external override pure returns (uint256 maxShares) {
        return type(uint256).max;
    }

    function previewMint(uint256 shares) external override view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    function mint(uint256 shares, address receiver) external override returns (uint256 assets) {
        assets = convertToAssets(shares);
        balanceOf[receiver] += shares;
        totalSupply += shares;
        if (!token.transferFrom(msg.sender, address(this), assets)) {
            revert DepositFailed();
        }
    }

    /// @notice The maximal amount that can be withdrawn.
    /// @param owner The withdrawer-to-be.
    function maxWithdraw(address owner) external override view returns (uint256 maxAssets) {
        return convertToAssets(balanceOf[owner]);
    }

    function previewWithdraw(uint256 assets) external override view returns (uint256 shares) {
        return convertToShares(assets);
    }

    function withdraw(uint256 assets, address receiver, address owner) external override returns (uint256 shares) {
        shares = convertToShares(assets);
        if (
            // The sender should be the owner or have sufficient allowance.
            (msg.sender == owner || allowance[owner][msg.sender] >= shares)
            // The balance of the owner should be high enough.
            && balanceOf[owner] >= shares
        ) {
            balanceOf[owner] -= shares;
            totalSupply -= shares;
            token.transfer(receiver, assets);
        } else {
            revert WithdrawalFailed();
        }
    }

    /// @notice The maximal amount that can be redeemed by an account.
    /// @param owner The potential redeemer.
    function maxRedeem(address owner) external override view returns (uint256 maxShares) {
        return balanceOf[owner];
    }

    function previewRedeem(uint256 shares) external override view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    function redeem(uint256 shares, address receiver, address owner) external override returns (uint256 assets) {
        assets = convertToAssets(shares);
        if (
            (msg.sender == owner || allowance[owner][msg.sender] >= shares)
            && balanceOf[owner] >= shares
        ) {
            balanceOf[owner] -= shares;
            totalSupply -= shares;
            token.transfer(receiver, assets);
        } else {
            revert WithdrawalFailed();
        }
    }
}
