// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/token/IERC20.sol";
import "yield-utils-v2/token/IERC20Metadata.sol";

/// @notice The operation failed because a transfer with inner tokens could not
///     be completed.
error TokenTransferFailed();
/// @notice The operation failed because the caller did not have sufficient
///     balance in terms of liquidity tokens, or allowance.
error InsufficientBalanceOrAllowance();

/// @title An Automated Market Maker contract.
/// @notice Provides capability to supply liquidity and to exchange tokens.
///     A nice property of AMM's is that liquidity never runs out by selling
///     tokens; the price goes to infinity as tokens of one type run out.
/// @dev Any function of this contract rounds in favour of the contract. It may
///     be possible to profit from this contract, for example by holding
///     liquidity tokens while these rounding errors accumulate.
contract Market is IERC20Metadata {
    event Initialized(address indexed to, uint256 amount1, uint256 amount2);
    event Minted(
        address indexed to,
        uint256 amount1,
        uint256 amount2,
        uint256 shares
    );
    event Burned(
        address indexed to,
        uint256 amount1,
        uint256 amount2,
        uint256 shares
    );
    event SoldX(
        address indexed account,
        uint256 amount1,
        uint256 amount2
    );
    event SoldY(
        address indexed account,
        uint256 amount1,
        uint256 amount2
    );

    /// @notice The first token that can be exchanged with the other,
    ///     `token_y`.
    IERC20 immutable token_x;

    /// @notice The second token that can be exchanged with the other,
    ///     `token_x`.
    IERC20 immutable token_y;

    // # ERC20 properties
    /// @notice The name of the liquidity tokens issued by the contract.
    string public constant name = "MarketToken";
    /// @notice The symbol for the liquidity tokens.
    string public constant symbol = "MART";
    /// @notice The number of decimals for liquidity tokens.
    uint8 public constant decimals = 18;

    /// @notice The total supply of liquidity tokens.
    /// @dev Equal to the balance in terms of `token_x` multiplied by the
    ///     balance in terms of `token_y`. Or, due to rounding, this number may
    ///     be lower. Doesn't change when tokens are exchanged, but changes
    ///     when liquidity is added/removed, proportionally.
    ///
    ///     If this is zero, the contract can be `initialized` using the
    ///     function with the same name. If and only if this value is non-zero
    ///     tokens can be exchanged using this contract.
    uint256 public totalSupply = 0;

    /// @notice The balance of the account in terms of liquidity tokens.
    mapping(address => uint256) public balanceOf;

    /// @notice The allowance of the account in terms of liquidity tokens.
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice Initialize this contract.
    /// @param _token_x The first token.
    /// @param _token_y The second token.
    constructor(IERC20 _token_x, IERC20 _token_y) {
        token_x = _token_x;
        token_y = _token_y;
    }

    /// @notice Initialize this contract by supplying initial liquidity. This
    ///     will also determine the intial price: `x` of token X and `y` of
    ///     token Y should have equal value. This function can only be called
    ///     if there is no liquidity.
    ///
    ///     The caller should have given sufficient allowance to the contract.
    /// @param x The amount of tokens of `tokenX`.
    /// @param y The amount of tokens of `tokenY`.
    function initialize(uint256 x, uint256 y) external {
        require(totalSupply == 0);

        uint256 z = x * y;
        balanceOf[msg.sender] = z;
        totalSupply = z;

        if (
            token_x.transferFrom(msg.sender, address(this), x) &&
            token_y.transferFrom(msg.sender, address(this), y)
        ) {
            emit Initialized(msg.sender, x, y);
        } else {
            revert TokenTransferFailed();
        }
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
        if (_senderBalance < amount) {
            revert InsufficientBalanceOrAllowance();
        }

        unchecked {
            // Does not underflow as _senderBalance >= amount.
            balanceOf[msg.sender] = _senderBalance - amount;
        }
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
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
        if (_senderBalance < amount || _allowance < amount) {
            revert InsufficientBalanceOrAllowance();
        }
        unchecked {
            // Does not overflow due to the above checks
            allowance[sender][msg.sender] = _allowance - amount;
            balanceOf[sender] = _senderBalance - amount;
        }
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
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

    /// @notice Mint liquidity tokens in proportion to the current price in the
    ///     contract. If the amounts of tokenX and tokenY are not supplied in
    ///     the exact proportions, the more valuable side will be capped to
    ///     have equal value.
    /// @param x The amount of tokenX to supply.
    /// @param y The amount of tokenY to supply.
    /// @return z The amount of liquidity tokens returned.
    /// @dev The amount of subtracted x and y tokens is computed by setting the
    ///     values of both equal to that with lesser value. The amount of
    ///     returned `z` tokens is rounded down from the correct value.
    function mint(uint256 x, uint256 y) external returns (uint256 z) {
        require(totalSupply > 0);

        // The user should supply x and y in the same ratio as is currenly in
        // the contract. That means
        //      x / y = x_0 / y_0
        // or,
        //      x * y_0 = y * x_0
        // Shrink x or y to make the equation equal on both sides. Call the
        // left side z_x and the right side z_y.

        // The current supply is given by
        //      z_0 = x_0 * y_0
        // The new amount of tokens should be proportional to
        //      x / x_0 = y / y_0
        // So,
        //      z = z_0 * (x / x_0) = z_0 * (y / y_0)
        //          = x_0 * y
        //          = y_0 * x

        uint256 x_0 = token_x.balanceOf(address(this));
        uint256 y_0 = token_y.balanceOf(address(this));

        uint256 z_x = x * y_0;
        uint256 z_y = y * x_0;

        if (z_x > z_y) {
            x = z_y / y_0;
            unchecked {
                // Safe as we have just obtained x via division.
                // Can be slightly smaller than z_y, due to rounding.
                // Compute to ensure we don't give out too many liquidity tokens.
                // We have z <= z_y < z_x
                z = x * y_0;
            }
        } else {
            y = z_x / x_0;
            unchecked {
                // Safe as we have just obtained y via division.
                // Can be slightly smaller than z_x, due to rounding.
                // Compute to ensure we don't give out too many liquidity tokens.
                // We have z <= z_x <= z_y
                z = y * x_0;
            }
        }

        balanceOf[msg.sender] += z;
        totalSupply += z;

        if (
            token_x.transferFrom(msg.sender, address(this), x) &&
            token_y.transferFrom(msg.sender, address(this), y)
        ) {
            emit Minted(msg.sender, x, y, z);
        } else {
            revert TokenTransferFailed();
        }
    }

    /// @notice Burn liquidity tokens in exchange for tokenX and tokenY in
    ///     proportion to the current supply in the contract.
    /// @param z The amount of liquidity tokens to burn.
    /// @return x The amount of tokenX that was sent to the account.
    /// @return y The amount of tokenY that was send to the account.
    /// @dev The tokens X and Y that are returned to the owner are rounded down
    ///     from the "real" value.
    function burn(uint256 z) external returns (uint256 x, uint256 y) {
        uint256 _balance = balanceOf[msg.sender];

        // We know that the total supply is at least equal to the balance, so
        // to save gas, check the balance which has already been loaded.
        require(_balance > 0);

        if (_balance < z) {
            revert InsufficientBalanceOrAllowance();
        }

        uint256 _totalSupply = totalSupply;

        // Update the balance, totalSupply
        unchecked {
            // Unchecked as we have checked the balance, and the total
            // supply is equal to the sum of balances.
            balanceOf[msg.sender] = _balance - z;
            totalSupply = _totalSupply - z;
        }

        // Compute how many tokens should be returned.
        x = (token_x.balanceOf(address(this)) * z) / _totalSupply;
        y = (token_y.balanceOf(address(this)) * z) / _totalSupply;

        if (
            token_x.transfer(msg.sender, x) &&
            token_y.transfer(msg.sender, y)
        ) {
            emit Burned(msg.sender, x, y, z);
        } else {
            revert TokenTransferFailed();
        }
    }

    /// @notice Sell tokenX in exchange for tokenY. The price in the contract
    ///     will be determined such that the new product of balance of tokenX
    ///     and tokenY is equal to the old product. Requires sufficient
    ///     approval for this contract to send itself tokenX.
    /// @param x The amount of tokenX to sell.
    /// @return y The amount of tokenY that has been transferred.
    /// @dev Due to rounding, the amount of returned `y` tokens can only be
    ///     smaller than the "real" value.
    function sell_x(uint256 x) external returns (uint256 y) {
        require(totalSupply > 0);

        // Here, we need
        //      x_0 * y_0 = (x_0 + x) * (y_0 - y)
        //      (x_0 * y_0) / (x_0 + x) = y_0 - y
        //      y = y_0 - (x_0 * y_0) / (x_0 + x)
        //      y = y_0(x_0 + x - x_0) / (x_0 + x)
        //      y = y_0 * x / (x_0 + x)

        uint256 x_1 = token_x.balanceOf(address(this)) + x;
        y = token_y.balanceOf(address(this)) * x / x_1;

        if (
            token_x.transferFrom(msg.sender, address(this), x) &&
            token_y.transfer(msg.sender, y)
        ) {
            emit SoldX(msg.sender, x, y);
        } else {
            revert TokenTransferFailed();
        }
    }

    /// @notice Sell tokenY in exchange for tokenX. The price in the contract
    ///     will be determined such that the new product of balance of tokenX
    ///     and tokenY is equal to the old product. Requires sufficient
    ///     approval for this contract to send itself tokenY.
    /// @param y The amount of tokenY to sell.
    /// @return x The amount of tokenX that has been transferred.
    /// @dev Due to rounding, the amount of returned `x` tokens can only be
    ///     smaller than the "real" value.
    function sell_y(uint256 y) external returns (uint256 x) {
        require(totalSupply > 0);

        uint256 y_1 = token_y.balanceOf(address(this)) + y;
        x = token_x.balanceOf(address(this)) * y / y_1;
        
        if (
            token_y.transferFrom(msg.sender, address(this), y) &&
            token_x.transfer(msg.sender, x)
        ) {
            emit SoldY(msg.sender, x, y);
        } else {
            revert TokenTransferFailed();
        }
    }
}
