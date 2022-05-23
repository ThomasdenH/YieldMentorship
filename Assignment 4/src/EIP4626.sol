// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/token/IERC20Metadata.sol";

abstract contract EIP4626 is IERC20Metadata {
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function asset() external view virtual returns (address assetTokenAddress);

    function totalAssets()
        external
        view
        virtual
        returns (uint256 totalManagedAssets);

    function convertToShares(uint256 assets)
        external
        view
        virtual
        returns (uint256 shares);

    function convertToAssets(uint256 shares)
        external
        view
        virtual
        returns (uint256 assets);

    function maxDeposit(address receiver)
        external
        view
        virtual
        returns (uint256 maxAssets);

    function previewDeposit(uint256 assets)
        external
        view
        virtual
        returns (uint256 shares);

    function deposit(uint256 assets, address receiver)
        external
        virtual
        returns (uint256 shares);

    function maxMint(address receiver)
        external
        view
        virtual
        returns (uint256 maxShares);

    function previewMint(uint256 shares)
        external
        view
        virtual
        returns (uint256 assets);

    function mint(uint256 shares, address receiver)
        external
        virtual
        returns (uint256 assets);

    function maxWithdraw(address owner)
        external
        view
        virtual
        returns (uint256 maxAssets);

    function previewWithdraw(uint256 assets)
        external
        view
        virtual
        returns (uint256 shares);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual returns (uint256 shares);

    function maxRedeem(address owner)
        external
        view
        virtual
        returns (uint256 maxShares);

    function previewRedeem(uint256 shares)
        external
        view
        virtual
        returns (uint256 assets);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual returns (uint256 assets);
}
