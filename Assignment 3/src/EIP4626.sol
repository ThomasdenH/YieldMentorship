// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/token/IERC20Metadata.sol";

abstract contract EIP4626 is IERC20Metadata {
    function asset() external virtual view returns (address assetTokenAddress);
    function totalAssets() external virtual view returns (uint256 totalManagedAssets);

    function convertToShares(uint256 assets) external virtual view returns (uint256 shares);
    function convertToAssets(uint256 shares) external virtual view returns (uint256 assets);

    function maxDeposit(address receiver) external virtual view returns (uint256 maxAssets);
    function previewDeposit(uint256 assets) external virtual view returns (uint256 shares);
    function deposit(uint256 assets, address receiver) external virtual returns (uint256 shares);

    function maxMint(address receiver) external virtual view returns (uint256 maxShares);
    function previewMint(uint256 shares) external virtual view returns (uint256 assets);
    function mint(uint256 shares, address receiver) external virtual returns (uint256 assets);

    function maxWithdraw(address owner) external virtual view returns (uint256 maxAssets);
    function previewWithdraw(uint256 assets) external virtual view returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external virtual returns (uint256 shares);

    function maxRedeem(address owner) external virtual view returns (uint256 maxShares);
    function previewRedeem(uint256 shares) external virtual view returns (uint256 assets);
    function redeem(uint256 shares, address receiver, address owner) external virtual returns (uint256 assets);
}
