// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/SimpleRegistry.sol";

/// @title Tests the simple name registry.
/// @author Thomas den Hollander
/// @notice Used to test the required functionality for the `SimpleRegistry` contract.
contract SimpleRegistryTest is Test {
    SimpleRegistry simpleRegistry;

    constructor() {
        simpleRegistry = new SimpleRegistry();
    }

    /// @notice Test claiming some names for this contract.
    function testClaimNames() public {
        assertEq(simpleRegistry.owners("TestName"), address(0));
        simpleRegistry.claimName("TestName");
        assertEq(simpleRegistry.owners("TestName"), address(this));
        
        assertEq(simpleRegistry.owners("A-Somewhat_longer_test!Name"), address(0));
        simpleRegistry.claimName("A-Somewhat_longer_test!Name");
        assertEq(simpleRegistry.owners("A-Somewhat_longer_test!Name"), address(this));
    }

    /// @notice Test releasing a name for this contract.
    /// @param name The name to claim and release.
    function testClaimAndRelease(string calldata name) public {
        assertEq(simpleRegistry.owners(name), address(0));

        // Claim...
        simpleRegistry.claimName(name);
        assertEq(simpleRegistry.owners(name), address(this));

        // ...and release!
        simpleRegistry.releaseName(name);
        assertEq(simpleRegistry.owners(name), address(0));
    }

    /// @notice Tests that a name that already has an owner cannot be claimed.
    function testCannotClaimOccupiedName() public {
        // Claim a name with another address.
        address anotherAddress = address(0x01);
        vm.prank(anotherAddress);
        simpleRegistry.claimName("ClaimedName");

        // Now claiming a name should fail.
        vm.expectRevert(SimpleRegistry.NameAlreadyClaimed.selector);
        simpleRegistry.claimName("ClaimedName");
    }

    /// @notice Test that a name that is not owned by an address cannot be
    ///     returned by that address.
    function testCannotReleasedUnownedName() public {
        // Test for unowned name.
        assertEq(simpleRegistry.owners("UnownedName"), address(0));
        vm.expectRevert(SimpleRegistry.NotTheOwner.selector);
        simpleRegistry.releaseName("UnownedName");
    }

    /// @notice Test that a name that is owned by another address cannot be
    ///     returned.
    function testCannotReleasedNameOwnedByAnother() public {
        // Test for name owned by another address.
        vm.prank(address(0x12345));
        simpleRegistry.claimName("UnownedName");

        vm.expectRevert(SimpleRegistry.NotTheOwner.selector);
        simpleRegistry.releaseName("UnownedName");
    }
}
