// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/token/ERC20.sol";
import "yield-utils-v2/token/TransferHelper.sol";
import "yield-utils-v2/token/IERC20.sol";

using TransferHelper for IERC20;

/// @title An Automated Market Maker contract.
/// @notice Provides capability to supply liquidity and to exchange tokens.
///     A nice property of AMM's is that liquidity never runs out by selling
///     tokens; the price goes to infinity as tokens of one type run out.
/// @dev Any function of this contract rounds in favour of the contract. It may
///     be possible to profit from this contract, for example by holding
///     liquidity tokens while these rounding errors accumulate.
contract Market is ERC20("MarketToken", "MART", 18) {
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
    function initialize(uint256 x, uint256 y) external returns (uint256 z) {
        require(_totalSupply == 0);

        z = x * y;

        _mint(msg.sender, z);
        token_x.safeTransferFrom(msg.sender, address(this), x);
        token_y.safeTransferFrom(msg.sender, address(this), y);

        emit Minted(msg.sender, x, y, z);
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
        require(_totalSupply > 0);

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

        _mint(msg.sender, z);
        token_x.safeTransferFrom(msg.sender, address(this), x);
        token_y.safeTransferFrom(msg.sender, address(this), y);

        emit Minted(msg.sender, x, y, z);
    }

    /// @notice Burn liquidity tokens in exchange for tokenX and tokenY in
    ///     proportion to the current supply in the contract.
    /// @param z The amount of liquidity tokens to burn.
    /// @return x The amount of tokenX that was sent to the account.
    /// @return y The amount of tokenY that was send to the account.
    /// @dev The tokens X and Y that are returned to the owner are rounded down
    ///     from the "real" value.
    function burn(uint256 z) external returns (uint256 x, uint256 y) {
        uint256 x_0 = token_x.balanceOf(address(this));
        // x = x_0 * (z / z_0)
        x = (x_0 * z) / _totalSupply;
        // y = y_0 * (z / z_0) = y_0 * z / (x_0 * y_0) = z / x_0
        y = z / x_0;

        _burn(msg.sender, z);
        token_x.safeTransfer(msg.sender, x);
        token_y.safeTransfer(msg.sender, y);

        emit Burned(msg.sender, x, y, z);
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
        require(_totalSupply > 0);

        // Here, we need
        //      x_0 * y_0 = (x_0 + x) * (y_0 - y)
        //      (x_0 * y_0) / (x_0 + x) = y_0 - y
        //      y = y_0 - (x_0 * y_0) / (x_0 + x)
        //      y = y_0(x_0 + x - x_0) / (x_0 + x)
        //      y = y_0 * x / (x_0 + x)

        uint256 x_0 = token_x.balanceOf(address(this));
        y = _totalSupply * x / (x_0 * (x_0 + x));

        // uint256 x_1 = token_x.balanceOf(address(this)) + x;
        // y = token_y.balanceOf(address(this)) * x / x_1;

        token_x.safeTransferFrom(msg.sender, address(this), x);
        token_y.transfer(msg.sender, y);

        emit SoldX(msg.sender, x, y);
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
        require(_totalSupply > 0);
        
        uint256 y_0 = token_y.balanceOf(address(this));
        x = _totalSupply * y / (y_0 * (y_0 + y));

        token_y.safeTransferFrom(msg.sender, address(this), y);
        token_x.transfer(msg.sender, x);

        emit SoldY(msg.sender, x, y);
    }
}
