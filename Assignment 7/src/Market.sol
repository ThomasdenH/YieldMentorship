// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/token/ERC20.sol";
import "yield-utils-v2/token/TransferHelper.sol";
import "yield-utils-v2/token/IERC20.sol";

/// @notice Reverted with this error if the contract should be initialized but
///     wasn't.
error Uninitialized();

/// @title An Automated Market Maker contract.
/// @notice Provides capability to supply liquidity and to exchange tokens.
///     A nice property of AMM's is that liquidity never runs out by selling
///     tokens; the price goes to infinity as tokens of one type run out.
/// @dev Any function of this contract rounds in favour of the contract. It may
///     be possible to profit from this contract, for example by holding
///     liquidity tokens while these rounding errors accumulate.
///
///     For derivations, we use x0 and y0 as the starting supply of `tokenX`
///     and `tokenY` and x1 and y1 as the end supply of `tokenX` and `tokenY`.
///     Similarly, z0 and z1 are used to denote the liquidity tokens at the
///     start and end of the call. The products x0 * y0 and x1 * y1 are called
///     k0 and k1, respectively. k1 >= k0 after exchanges and should only
///     increase due to rounding.
contract Market is ERC20("MarketToken", "MART", 18) {
    using TransferHelper for IERC20;

    /// @notice Emitted when the market gets initialized. This can happen
    ///     multiple times if the contracts liquidity gets emptied entirely!
    event Initialized(
        address indexed to,
        uint256 xIn,
        uint256 yIn,
        uint256 sharesOut
    );
    /// @notice Emitted when the market receives liquidity while it is already
    ///     initialized.
    event Minted(
        address indexed to,
        uint256 xIn,
        uint256 yIn,
        uint256 sharesOut
    );
    event Burned(
        address indexed to,
        uint256 xOut,
        uint256 yOut,
        uint256 sharesIn
    );
    event SoldX(address indexed account, uint256 zIn, uint256 yOut);
    event SoldY(address indexed account, uint256 xOut, uint256 yIn);

    /// @notice The first token that can be exchanged with the other,
    ///     `yToken`.
    IERC20 immutable xToken;

    /// @notice The second token that can be exchanged with the other,
    ///     `xToken`.
    IERC20 immutable yToken;

    /// @notice Initialize this contract to create an exchange between the two
    ///     supplied tokens.
    /// @param _xToken The first token.
    /// @param _yToken The second token.
    constructor(IERC20 _xToken, IERC20 _yToken) {
        xToken = _xToken;
        yToken = _yToken;
    }

    /// @notice Initialize this contract by supplying initial liquidity. This
    ///     will also determine the initial price: Supplying `x` of token X and
    ///     `y` of token Y will cause this contract to have an initial price of
    ///     `x / y`. This function can only be called if there is no liquidity.
    ///
    ///     The caller should have given sufficient allowance to the contract.
    ///
    ///     This function can be called anytime there is no liquidity in the
    ///     contract. (In the form of liquidity tokens, which is not the same
    ///     as this contract having empty balances of `xToken` and `yToken` due
    ///     to rounding.)
    /// @param xIn The amount of tokens of `xToken`.
    /// @param yIn The amount of tokens of `yToken`.
    /// @return sharesOut The number of liquidity tokens that will be minted to the
    ///     caller.
    /// @dev Here, liquidity tokens are given out as
    ///     `sharesOut = xIn * yIn`
    function initialize(uint256 xIn, uint256 yIn)
        external
        returns (uint256 sharesOut)
    {
        require(_totalSupply == 0);

        sharesOut = xIn * yIn;

        // Tests that both x and y are unequal to zero and that the contract
        // will be initialized.
        require(sharesOut > 0);

        _mint(msg.sender, sharesOut);

        emit Initialized(msg.sender, xIn, yIn, sharesOut);

        xToken.safeTransferFrom(msg.sender, address(this), xIn);
        yToken.safeTransferFrom(msg.sender, address(this), yIn);
    }

    /// @notice Mint liquidity tokens in proportion to the current price in the
    ///     contract. If the amounts of tokenX and tokenY are not supplied in
    ///     the exact proportions, the more valuable side will be capped to
    ///     have equal value.
    /// @param xIn The amount of tokenX to supply.
    /// @param yIn The amount of tokenY to supply.
    /// @return sharesOut The amount of liquidity tokens returned.
    /// @dev Here, we have the invariant that
    ///         `xInitialBalance / yInitialBalance = xIn / yIn`
    ///     interpreted as the current price. If the user supplied too much of
    ///     `x` or `y`, we want to lower the other value and give out less
    ///     liquidity tokens accordingly.
    ///
    ///     We should have
    ///         `xInitialBalance * yIn = yInitialBalance * xIn`
    ///     so, if the left side (aY) is bigger, decrease yIn and if the right
    ///     side (aX) is bigger, decrease xIn. Take the other value as the true
    ///     value to derive from.
    ///
    ///     By how much? Well, divide the other side by `xInitialBalance` or
    ///     `yInitialBalance`. Do either
    ///         yIn <- (yInitialBalance * xIn) / xInitialBalance
    ///         xIn <- (xInitialBalance * yIn) / yInitialBalance
    ///     to correct the bigger value between `xIn` and `yIn`. Due to
    ///     rounding the new value may be slightly smaller and never bigger
    ///     than the real value.
    ///
    ///     Now we need to give out liquidity tokens in proportion to the new
    ///     liquidity. We need
    ///         `sharesOut / sharesInitialBalance = xIn / xInitialBalance
    ///             = yIn / yInitialBalance`
    ///     Compute `sharesOut` from the smaller of `xIn` and `yIn`, which we
    ///     know was the one just recomputed.
    ///         sharesOut <- sharesBalance * xIn / xInitialBalance
    ///         sharesOut <- sharesBalance * yIn / yInitialBalance
    ///     Like before, we know that by rounding down we can never give too
    ///     many liquidity tokens.
    function mint(uint256 xIn, uint256 yIn)
        external
        returns (uint256 sharesOut)
    {
        uint256 xInitialBalance = xToken.balanceOf(address(this));
        uint256 yInitialBalance = yToken.balanceOf(address(this));

        // Require that both balances are non-zero. For a little more gas,
        // `totalSupply > 0` would be a roughly equivalent check. The advantage
        // is that it could be performed at the top of the function.
        if (xInitialBalance | yInitialBalance == 0) {
            revert Uninitialized();
        }

        uint256 aX = xIn * yInitialBalance;
        uint256 aY = yIn * xInitialBalance;

        if (aX > aY) {
            xIn = aY / yInitialBalance;
            sharesOut = (_totalSupply * xIn) / xInitialBalance;
        } else {
            yIn = aX / xInitialBalance;
            sharesOut = (_totalSupply * yIn) / yInitialBalance;
        }

        _mint(msg.sender, sharesOut);

        emit Minted(msg.sender, xIn, yIn, sharesOut);

        xToken.safeTransferFrom(msg.sender, address(this), xIn);
        yToken.safeTransferFrom(msg.sender, address(this), yIn);
    }

    /// @notice Burn liquidity tokens in exchange for tokenX and tokenY in
    ///     proportion to the current supply in the contract.
    ///
    ///     Fails if the contract is unitialized.
    /// @param sharesIn The amount of liquidity tokens to burn.
    /// @return xOut The amount of tokenX that was sent to the account.
    /// @return yOut The amount of tokenY that was send to the account.
    /// @dev We have the invariant that
    ///         x / x0 = y / y0 = z / z0
    ///     if we ignore rounding.
    ///
    ///     Compute by rewriting the above equation directly:
    ///         x <- x0 * z / z0
    ///         y <- y0 * z / z0
    ///     Rounding means we can never give out too much of the underlying
    ///     supply.
    function burn(uint256 sharesIn)
        external
        returns (uint256 xOut, uint256 yOut)
    {
        uint256 tSup = _totalSupply;
        // We don't strictly have to check this: division by zero in the
        // following lines will revert anyway. However, for UX revert with the
        // correct message. The overhead is 16 gas.
        if (tSup == 0) {
            revert Uninitialized();
        }
        xOut = (xToken.balanceOf(address(this)) * sharesIn) / tSup;
        yOut = (yToken.balanceOf(address(this)) * sharesIn) / tSup;

        _burn(msg.sender, sharesIn);

        emit Burned(msg.sender, xOut, yOut, sharesIn);

        xToken.safeTransfer(msg.sender, xOut);
        yToken.safeTransfer(msg.sender, yOut);
    }

    /// @notice Sell tokenX in exchange for tokenY. The price in the contract
    ///     will be determined such that the new product of balance of tokenX
    ///     and tokenY is equal to the old product. Requires sufficient
    ///     approval for this contract to send itself tokenX.
    /// @param xIn The amount of tokenX to sell.
    /// @return yOut The amount of tokenY that has been transferred.
    /// @dev We have the invariant that
    ///         x0 * y0 <= x1 * y1
    ///     with the inequality only occuring due to rounding.
    ///
    ///     By definition
    ///         x1 = x0 + x
    ///         y1 = y0 - y
    ///     and so
    ///         x0 * y0 = (x0 + x) * (y0 - y)
    ///         y0 - y = (x0 * y0) / (x0 + x)
    ///         -y = -y0 + (x0 * y0) / (x0 + x)
    ///         y = y0 - (x0 * y0) / (x0 + x)
    ///           = (y0 * (x0 + x) - x0 * y0) / (x0 + x)
    ///           = (y0 * x0 + y0 * x - x0 * y0) / (x0 + x)
    ///           = (y0 * x) / (x0 + x)
    ///
    ///     By using integer division, `y` can never be bigger than the real
    ///     value.
    ///
    ///     We don't really need to check if the contract has been initialized.
    ///     If x0 = 0, then the value of tokenX is infinite and so the user
    ///     gets the entire supply y0 (which should be close to 0). If y0 = 0,
    ///     then the value of tokenY is infinite and so the user gets no
    ///     tokens, as they should. So, even an unitialized contract gives out
    ///     tokens at the "correct", albeit extreme price.
    function sellX(uint256 xIn) external returns (uint256 yOut) {
        uint256 xInitialBalance = xToken.balanceOf(address(this));
        uint256 yInitialBalance = yToken.balanceOf(address(this));

        yOut = (yInitialBalance * xIn) / (xInitialBalance + xIn);

        emit SoldX(msg.sender, xIn, yOut);

        xToken.safeTransferFrom(msg.sender, address(this), xIn);
        yToken.safeTransfer(msg.sender, yOut);
    }

    /// @notice Sell tokenY in exchange for tokenX. The price in the contract
    ///     will be determined such that the new product of balance of tokenX
    ///     and tokenY is equal to the old product. Requires sufficient
    ///     approval for this contract to send itself tokenY.
    /// @param yIn The amount of tokenY to sell.
    /// @return xOut The amount of tokenX that has been transferred.
    /// @dev See `sellX` for a derivation of the used equation. That function
    ///     is entirely symmetric over x <-> y.
    function sellY(uint256 yIn) external returns (uint256 xOut) {
        uint256 yInitialBalance = yToken.balanceOf(address(this));
        uint256 xInitialBalance = xToken.balanceOf(address(this));

        xOut = (xInitialBalance * yIn) / (yInitialBalance + yIn);

        emit SoldY(msg.sender, xOut, yIn);

        yToken.safeTransferFrom(msg.sender, address(this), yIn);
        xToken.safeTransfer(msg.sender, xOut);
    }
}
