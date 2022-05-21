// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/mocks/ERC20Mock.sol";

/// @notice `Coll`, the ideal token to use as collateral for vaults! At least
///     that's where the name orginates so it must be true. An added bonus is
///     that anyone can mint as much as they want, at will!
/// @dev This contract is simply an `ERC20Mock` with name and symbol set.
contract Coll is ERC20Mock {
    constructor() ERC20Mock("Coll", "COLL") {}
}
