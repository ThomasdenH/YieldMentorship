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

    /// @notice Emitted when the market gets initialized. This can happen
    ///     multiple times if the contracts liquidity gets emptied entirely!
    event Initialized(address indexed to, uint256 amount1, uint256 amount2);
    /// @notice Emitted when the market receives liquidity while it is already
    ///     initialized.
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
    IERC20 immutable tokenX;

    /// @notice The second token that can be exchanged with the other,
    ///     `token_x`.
    IERC20 immutable tokenY;

    /// @notice Initialize this contract to create an exchange between the two
    ///     supplied tokens.
    /// @param _tokenX The first token.
    /// @param _tokenY The second token.
    constructor(IERC20 _tokenX, IERC20 _tokenY) {
        tokenX = _tokenX;
        tokenY = _tokenY;
    }

    /// @notice Initialize this contract by supplying initial liquidity. This
    ///     will also determine the intial price: `x` of token X and `y` of
    ///     token Y should have equal value. This function can only be called
    ///     if there is no liquidity.
    ///
    ///     The caller should have given sufficient allowance to the contract.
    ///
    ///     This function can be called anytime there is no liquidity in the
    ///     contract. (In the form of liquidity tokens, which is not the same
    ///     as this contract having empty balances of `tokenX` and `tokenY` due
    ///     to rounding.)
    /// @param x The amount of tokens of `tokenX`.
    /// @param y The amount of tokens of `tokenY`.
    function initialize(uint256 x, uint256 y) external returns (uint256 z) {
        require(_totalSupply == 0);

        z = x * y;

        _mint(msg.sender, z);
        tokenX.safeTransferFrom(msg.sender, address(this), x);
        tokenY.safeTransferFrom(msg.sender, address(this), y);

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
        //      x / y = x0 / y0
        // or,
        //      x * y0 = y * x0
        // Shrink x or y to make the equation equal on both sides. Call the
        // left side z_x and the right side zY.

        // The current supply is given by
        //      z0 = x0 * y0
        // The new amount of tokens should be proportional to
        //      x / x0 = y / y0
        // So,
        //      z = z0 * (x / x0) = z0 * (y / y0)
        //          = x0 * y
        //          = y0 * x

        uint256 x0 = tokenX.balanceOf(address(this));
        uint256 y0 = tokenY.balanceOf(address(this));

        uint256 zX = x * y0;
        uint256 zY = y * x0;

        if (zX > zY) {
            x = zY / y0;
            unchecked {
                // Safe as we have just obtained x via division.
                // Can be slightly smaller than z_y, due to rounding.
                // Compute to ensure we don't give out too many liquidity tokens.
                // We have z <= zY < zX
                z = x * y0;
            }
        } else {
            y = zX / x0;
            unchecked {
                // Safe as we have just obtained y via division.
                // Can be slightly smaller than z_x, due to rounding.
                // Compute to ensure we don't give out too many liquidity tokens.
                // We have z <= zX <= zY
                z = y * x0;
            }
        }

        _mint(msg.sender, z);
        tokenX.safeTransferFrom(msg.sender, address(this), x);
        tokenY.safeTransferFrom(msg.sender, address(this), y);

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
        uint256 x0 = tokenX.balanceOf(address(this));
        // x = x0 * (z / z0)
        x = (x0 * z) / _totalSupply;
        // y = y0 * (z / z0) = y0 * z / (x0 * y0) = z / x0
        y = z / x0;

        _burn(msg.sender, z);
        tokenX.safeTransfer(msg.sender, x);
        tokenY.safeTransfer(msg.sender, y);

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
    function sellX(uint256 x) external returns (uint256 y) {
        require(_totalSupply > 0);

        // Here, we need
        //      x0 * y0 = (x0 + x) * (y0 - y)
        //      y = y0 - x0 * y0 / (x0 + x)
        //        = y0 * x / (x0 + x)
        //        = z0 * x / (x0 (x0 + x))

        uint256 x0 = tokenX.balanceOf(address(this));
        y = _totalSupply * x / (x0 * (x0 + x));

        tokenX.safeTransferFrom(msg.sender, address(this), x);
        tokenY.transfer(msg.sender, y);

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
    function sellY(uint256 y) external returns (uint256 x) {
        require(_totalSupply > 0);
        
        uint256 y0 = tokenY.balanceOf(address(this));
        x = _totalSupply * y / (y0 * (y0 + y));

        tokenY.safeTransferFrom(msg.sender, address(this), y);
        tokenX.transfer(msg.sender, x);

        emit SoldY(msg.sender, x, y);
    }
}
