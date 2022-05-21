// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "yield-utils-v2/mocks/ERC20Mock.sol";
import "src/FractionalWrapper.sol";

abstract contract ZeroState {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    ERC20Mock token;
    FractionalWrapper wrapper;

    uint256 constant fraction = 7 * (10**26);

    uint256 constant tokensMinted = 1_000_000_000_000_000_000;

    function setUp() public {
        token = new ERC20Mock("Token", "TOK");
        wrapper = new FractionalWrapper(token, fraction);

        token.mint(address(this), tokensMinted);
    }
}

contract ZeroStateTest is ZeroState, Test {
    function testToken() public {
        assertEq(address(wrapper.token()), address(token));
    }

    function testAsset() public {
        assertEq(wrapper.asset(), address(token));
    }

    function testFraction() public {
        assertEq(wrapper.fraction(), fraction);
    }

    function testTotalSupplyAndAssets() public {
        assertEq(wrapper.totalSupply(), 0);
        assertEq(wrapper.totalAssets(), 0);
    }

    function testAllowance(address owner, address spender) public {
        assertEq(wrapper.allowance(owner, spender), 0);
    }

    function testBalance(address account) public {
        assertEq(wrapper.balanceOf(account), 0);
    }

    function testConvertToShares() public {
        assertEq(wrapper.convertToShares(100), 70);
        assertEq(wrapper.convertToShares(19), 13);
        assertEq(wrapper.convertToShares(8), 5);
        assertEq(wrapper.convertToShares(7), 4);
        assertEq(wrapper.convertToShares(2), 1);

        assertEq(wrapper.convertToShares(9), 6);
        assertEq(wrapper.convertToShares(9*9), 56);
        assertEq(wrapper.convertToShares(9*9*9), 510);
    }

    function testConvertToAssets() public {
        assertEq(wrapper.convertToAssets(7), 10);
        assertEq(wrapper.convertToAssets(700), 1000);

        assertEq(wrapper.convertToAssets(100_000), 142857);
        assertEq(wrapper.convertToAssets(10_000), 14285);
        assertEq(wrapper.convertToAssets(1_000), 1428);
        assertEq(wrapper.convertToAssets(100), 142);
        assertEq(wrapper.convertToAssets(10), 14);
        assertEq(wrapper.convertToAssets(1), 1);
    }

    function testDeposit(address receiver) public {
        token.approve(address(wrapper), tokensMinted);
        wrapper.deposit(tokensMinted, receiver);

        assertEq(wrapper.balanceOf(receiver), wrapper.convertToShares(tokensMinted));
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testMint(address receiver) public {
        token.approve(address(wrapper), tokensMinted);
        uint256 shares = wrapper.convertToShares(tokensMinted);
        wrapper.mint(shares, receiver);

        assertEq(wrapper.balanceOf(receiver), shares);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testApproveAndSpendLess(uint256 value, uint256 spend) public {
        vm.assume(value <= tokensMinted);
        vm.assume(spend <= value);

        address receiver = address(1);
        address caller = address(2);

        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), caller, value);

        wrapper.approve(caller, value);
        assertEq(wrapper.allowance(caller, address(this)), value);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), receiver, spend);
        vm.prank(caller);
        wrapper.transferFrom(address(this), receiver, spend);

        assertEq(wrapper.allowance(caller, address(this)), value - spend);
        assertEq(wrapper.balanceOf(receiver), spend);
        assertEq(wrapper.balanceOf(address(this)), value - spend);
    }

    
    function testApproveAndSpendMore(uint256 value, uint256 spend) public {
        vm.assume(value <= tokensMinted);
        vm.assume(spend > value);

        address receiver = address(1);
        address caller = address(2);

        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), caller, value);

        wrapper.approve(caller, value);
        assertEq(wrapper.allowance(caller, address(this)), value);

        vm.prank(caller);
        vm.expectRevert(FractionalWrapper.TransferFailed.selector);
        wrapper.transferFrom(address(this), receiver, spend);
    }
}
