// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../../contracts/core/Registry.sol";
import {Metadata} from "../../contracts/core/libraries/Metadata.sol";

contract ExpectEmit {
    event IdentityCreated(
        address identityId,
        Registry.IdentityDetails metadata
    );
    event MetadataUpdated(
        address identityId,
        Registry.IdentityDetails metadata
    );
    event OwnerAdded(address identityId, address owner);
    event OwnerRemoved(address identityId, address owner);

    // function identity() public {
    // address identityId = address(0x123);
    // emit IdentityCreated(
    //     identityId,
    //     MetaPtr(
    //         1,
    //         "bafybeif43xtcb7zfd6lx7q3knx7m6yecywtzxlh2d2jxqcgktvj4z2o3am"
    //     )
    // );
    // emit MetadataUpdated(
    //     identityId,
    //     MetaPtr(
    //         1,
    //         "bafybeif43xtcb7zfd6lx7q3knx7m6yecywtzxlh2d2jxqcgktvj4z2o3am"
    //     )
    // );
    // }

    function owner() public {
        address identityId = address(0x123);
        emit OwnerAdded(identityId, address(0x123));
        emit OwnerRemoved(identityId, address(0x123));
    }
}

contract RegistryTest is Test, ExpectEmit {
    Registry private _registry;

    function setUp() public {
        _registry = new Registry();
        _registry.initialize();
    }

    function createIdentity() public {
        // MetaPtr memory metadata = MetaPtr(1, "bafybeif43xtcb7zfd6lx7q3knx7m6yecywtzxlh2d2jxqcgktvj4z2o3am");
        // _registry.createIdentity(metadata);
        // uint256 identityId = 0;
        // registry.Identity memory identity = _registry.identities(identityId);
        // assertTrue(identity.id == identityId, "Identity id does not match");
        // assertTrue(identity.metadata.protocol == 1, "Metadata protocol does not match");
        // assertTrue(keccak256(bytes(identity.metadata.pointer)) ==
        //   keccak256(bytes("bafybeif43xtcb7zfd6lx7q3knx7m6yecywtzxlh2d2jxqcgktvj4z2o3am")), "Metadata pointer does not match");
    }

    function testCreateIdentity() public {
        createIdentity();
    }

    function testExpectEmitIdentityCreated() public {
        // MetaPtr memory metadata = MetaPtr(
        //     1,
        //     "bafybeif43xtcb7zfd6lx7q3knx7m6yecywtzxlh2d2jxqcgktvj4z2o3am"
        // );
        // address identityId = address(0x123);
        // _registry.createIdentity(metadata);
        // ExpectEmit emitter = new ExpectEmit();
        // vm.expectEmit(true, true, false, true);
        // emit IdentityCreated(identityId, metadata);
        // emitter.identity();
    }

    function testExpectEmitMetadataUpdated() public {
        // MetaPtr memory metadata = MetaPtr(
        //     1,
        //     "bafybeif43xtcb7zfd6lx7q3knx7m6yecywtzxlh2d2jxqcgktvj4z2o3am"
        // );
        // address identityId = address(0x123);
        // ExpectEmit emitter = new ExpectEmit();
        // vm.expectEmit(true, true, false, true);
        // emit MetadataUpdated(identityId, metadata);
        // emitter.identity();
    }

    // todo: revert if not the owner
    function testUpdateIdentityMetadataRevert() public {
        // vm.prank(address(0));
        // MetaPtr memory newMetadata = MetaPtr(1, "bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetoqaaa2fxqryzysaia");
        // _registry.updateIdentityMetadata(0, newMetadata);
        // vm.expectRevert("Registry: Only owner can update identity metadata");
    }

    function testUpdateIdentityMetadataOnlyOwner() public {
        // MetaPtr memory metadata = MetaPtr(1, "bafybeif43xtcb7zfd6lx7q3knx7m6yecywtzxlh2d2jxqcgktvj4z2o3am");
        // _registry.createIdentity(metadata);
        // MetaPtr memory newMetadata = MetaPtr(1, "bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetoqaaa2fxqryzysaia");
        // _registry.updateIdentityMetadata(0, newMetadata);
        // address identityId = address(0x123);
        // Registry.Identity memory identity = _registry.identities(identityId);
        // assertTrue(identity.metadata.protocol == 1, "Updated metadata protocol does not match");
        // assertTrue(keccak256(bytes(identity.metadata.pointer)) ==
        //   keccak256(bytes("bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetoqaaa2fxqryzysaia")), "Updated metadata pointer does not match");
    }

    function testAddIdentityOwner() public {
        // todo: test addIdentityOwner
        // uint256 identityId = 0;
        // address newOwner = address(0x123);
        // _registry.addIdentityOwner(identityId, newOwner);
    }

    function testExpectEmitAddOwner() public {
        address newOwner = address(0x123);
        address identityId = newOwner;
        ExpectEmit emitter = new ExpectEmit();

        vm.expectEmit(true, true, false, true);
        emit OwnerAdded(identityId, newOwner);
        emitter.owner();
    }

    function testRemoveIdentityOwner() public {
        // todo: test removeIdentityOwner
    }

    function testExpectEmitRemoveOwner() public {
        address removedOwner = address(0x123);
        address identityId = removedOwner;
        ExpectEmit emitter = new ExpectEmit();

        vm.expectEmit(true, true, false, true);
        emit OwnerRemoved(identityId, removedOwner);
        emitter.owner();
    }

    function testIdentityOwnersCount() public {
        // todo: test IdentityOwnersCount
    }

    function testGetIdentityOwner() public {
        // todo: test getIdentityOwner
    }

    function testInitIdentityOwners() public {
        // todo: test initIdentityOwners
    }
}
