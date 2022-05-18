// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "src/SimpleRegistry.sol";

/// @notice Starting state: The contract exists, but there aren't any names
///     registered.
abstract contract ZeroState {
    /// @notice Clone of the event in `SimpleRegistry.sol`.
    event RegisterChanged(
        string indexed name,
        address indexed owner
    );

    SimpleRegistry simpleRegistry;

    /// @notice Deploy the contract.
    function setUp() public virtual {
        simpleRegistry = new SimpleRegistry();
    }
}

/// @notice State where some names are owned.
abstract contract ClaimedNameState is ZeroState, Test {
    string constant ownedName = "ClaimedName";
    string constant nameClaimedByOther = "AnotherName";

    address constant otherClaimer = address(0x12345);

    /// @notice Claim two names: one by the contract and another by a seperate
    ///     address.
    function setUp() public override {
        // Run the Zerostate setup
        super.setUp();

        // Claim own name
        simpleRegistry.claimName(ownedName);

        // Claim name for another user
        vm.prank(otherClaimer);
        simpleRegistry.claimName(nameClaimedByOther);
    }
}

/// @title Tests the simple name registry.
/// @author Thomas den Hollander
/// @notice Used to test the required functionality for the `SimpleRegistry` contract.
contract ZeroStateTest is Test, ZeroState {
    /// @notice Test claiming some names for this contract.
    function testClaimNames(string calldata name) public {
        assertEq(simpleRegistry.owners(name), address(0));

        // We expect an event after claiming a name.
        vm.expectEmit(true, true, true, true);
        emit RegisterChanged(name, address(this));

        // Claim the name
        simpleRegistry.claimName(name);
        assertEq(simpleRegistry.owners(name), address(this));
    }

    /// @notice Test that a name that is not owned by an address cannot be
    ///     returned by that address.
    function testCannotReleasedUnownedName(string calldata name) public {
        // Test for unowned name.
        assertEq(simpleRegistry.owners(name), address(0));
        vm.expectRevert(SimpleRegistry.NotTheOwner.selector);
        simpleRegistry.releaseName(name);
    }
}

contract ClaimedNameTest is Test, ClaimedNameState {
    /// @notice Test releasing a name for this contract.
    function testReleaseName() public {
        // We expect an event after releasing a name.
        vm.expectEmit(true, true, true, true);
        emit RegisterChanged(ownedName, address(0x0));

        simpleRegistry.releaseName(ownedName);
        assertEq(simpleRegistry.owners(ownedName), address(0));
    }

    /// @notice Tests that a name that already has an owner cannot be claimed.
    function testCannotClaimOccupiedName() public {
        // Now claiming a name should fail.
        vm.expectRevert(SimpleRegistry.NameAlreadyClaimed.selector);
        simpleRegistry.claimName(nameClaimedByOther);
    }

    /// @notice Test that a name that is owned by another address cannot be
    ///     returned.
    function testCannotReleasedNameOwnedByAnother() public {
        vm.expectRevert(SimpleRegistry.NotTheOwner.selector);
        simpleRegistry.releaseName(nameClaimedByOther);
    }
}
