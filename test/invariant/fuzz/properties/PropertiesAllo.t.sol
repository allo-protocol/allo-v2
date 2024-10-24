// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {HandlersParent} from "../handlers/HandlersParent.t.sol";
import {IAllo, Allo, Metadata} from "contracts/core/Allo.sol";
import {IRegistry, Registry} from "contracts/core/Registry.sol";

contract PropertiesAllo is HandlersParent {
    ///@custom:property-id 1
    ///@custom:property one should always be able to pull/push correct (based on strategy) allocation for recipient

    ///@custom:property-id 2
    ///@custom:property a token allocation never “disappears” (withdraw cannot impact an allocation)

    ///@custom:property-id 3
    ///@custom:property an address can only withdraw if has allocation

    ///@custom:property-id 4
    ///@custom:property profile owner can always create a pool

    ///@custom:property-id 5-a
    ///@custom:property profile owner is the only one who can always add profile members (name ⇒ new anchor())
    function prop_onlyProfileOwnerCanAddProfileMember(address _newMember) public {
        // Get the profile ID
        IRegistry.Profile memory _profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);

        address[] memory _members = new address[](1);
        _members[0] = _newMember;

        (bool _success,) =
            targetCallDefault(address(registry), 0, abi.encodeCall(registry.addMembers, (_profile.id, _members)));

        if (msg.sender == _profile.owner) {
            if (_success) {
                assertTrue(registry.hasRole(_profile.id, _newMember), "addMembers failed role not set");
                _ghost_roleMembers[_profile.id].push(_newMember);
            } else {
                assertTrue(_newMember == address(0), "addMembers failed");
            }
        } else {
            if (_success) {
                fail("addMembers only owner should be able to add members");
            }
        }
    }

    ///@custom:property-id 5-b
    ///@custom:property profile owner is the only one who can always remove profile members (name ⇒ new anchor())
    function prop_onlyProfileOwnerCanRemoveProfileMembers() public {
        // Get the profile ID
        IRegistry.Profile memory _profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);
        address _memberToRemove = _ghost_roleMembers[_profile.id][_ghost_roleMembers[_profile.id].length - 1];
        address[] memory _members = new address[](1);
        _members[0] = _memberToRemove;

        (bool _success,) =
            targetCallDefault(address(registry), 0, abi.encodeCall(registry.removeMembers, (_profile.id, _members)));

        if (msg.sender == _profile.owner) {
            if (_success) {
                assertTrue(!registry.hasRole(_profile.id, _memberToRemove), "removeMembers failed");
                _ghost_roleMembers[_profile.id].pop();
            } else {
                assertTrue(_memberToRemove == address(0), "removeMembers failed");
            }
        } else {
            if (_success) {
                fail("removeMembers only owner should be able to remove members");
            }
        }
    }

    ///@custom:property-id 6
    ///@custom:property profile owner is the only one who can always initiate a change of profile owner (2 steps)
    function prop_onlyProfileOwnerCanInitiateChangeOfProfileOwner(address _newOwner) public {
        // Get the profile ID
        IRegistry.Profile memory _profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);

        (bool _success,) = targetCallDefault(
            address(registry), 0, abi.encodeCall(registry.updateProfilePendingOwner, (_profile.id, _newOwner))
        );

        if (msg.sender == _profile.owner) {
            if (_success) {
                assertTrue(
                    registry.profileIdToPendingOwner(_profile.id) == _newOwner, "updateProfilePendingOwner failed"
                );
            } else {
                assertTrue(_newOwner == address(0), "updateProfilePendingOwner failed");
            }
        } else {
            if (_success) {
                fail("updateProfilePendingOwner only owner should be able to initiate change of owner");
            }
        }
    }

    ///@custom:property-id 7
    ///@custom:property profile member can always create a pool

    ///@custom:property-id 8
    ///@custom:property only profile owner or member can create a pool

    ///@custom:property-id 9
    ///@custom:property initial admin is always the creator of the pool

    ///@custom:property-id 10
    ///@custom:property pool admin can always change admin (but not to address(0))
    function prop_poolAdminCanAlwaysChangeAdminToNonZero(uint256 _idSeed, address _newAdmin) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];
        address _admin = ghost_poolAdmins[_poolId];

        bytes32 _poolAdminRole = keccak256(abi.encodePacked(_poolId, "admin"));

        (bool _success,) = targetCallDefault(address(allo), 0, abi.encodeCall(allo.changeAdmin, (_poolId, _newAdmin)));

        if (msg.sender == _admin) {
            if (_success) {
                if (_newAdmin != _admin) {
                    assertTrue(
                        !allo.hasRole(_poolAdminRole, _admin), "changeAdmin failed remove old admin role not removed"
                    );
                }
                assertTrue(allo.hasRole(_poolAdminRole, _newAdmin), "changeAdmin failed role not set");
                ghost_poolAdmins[_poolId] = _newAdmin;
            } else {
                assertTrue(_newAdmin == address(0), "changeAdmin failed");
            }
        } else {
            if (_success) {
                fail("changeAdmin only admin should be able to change admin");
            }
        }
    }

    ///@custom:property-id 11-a
    ///@custom:property pool admin can always add
    function prop_poolAdminCanAlwaysAddManagers(uint256 _idSeed, address _newManager) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];
        address _admin = ghost_poolAdmins[_poolId];

        address[] memory _managers = new address[](1);
        _managers[0] = _newManager;

        bytes32 _poolManagerRole = bytes32(_poolId);

        (bool _success,) =
            targetCallDefault(address(allo), 0, abi.encodeCall(allo.addPoolManagers, (_poolId, _managers)));

        if (msg.sender == _admin) {
            if (_success) {
                assertTrue(allo.hasRole(_poolManagerRole, _newManager), "addPoolManagers failed role not set");
                ghost_poolManagers[_poolId].push(_newManager);
            } else {
                assertTrue(_newManager == address(0), "addPoolManager failed");
            }
        } else {
            if (_success) {
                fail("addPoolManager only admin should be able to add managers");
            }
        }
    }

    ///@custom:property-id 11-b
    ///@custom:property pool admin can always remove pool managers
    function prop_poolAdminCanAlwaysRemoveManagers(uint256 _idSeed, uint256 _managerIndex) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];
        _managerIndex = bound(_managerIndex, 0, ghost_poolManagers[_poolId].length - 1);
        address _admin = ghost_poolAdmins[_poolId];
        address[] storage _managers = ghost_poolManagers[_poolId];
        address _manager = _managers[_managerIndex];
        bytes32 _poolManagerRole = bytes32(_poolId);

        address[] memory _removeManagers = new address[](1);
        _removeManagers[0] = _manager;

        (bool _success,) =
            targetCallDefault(address(allo), 0, abi.encodeCall(allo.removePoolManagers, (_poolId, _removeManagers)));

        if (msg.sender == _admin) {
            if (_success) {
                assertTrue(!allo.hasRole(_poolManagerRole, _manager), "removePoolManagers failed");
                delete _managers[_managerIndex];
            } else {
                assertTrue(_manager == address(0), "removePoolManager failed");
            }
        } else {
            if (_success) {
                fail("removePoolManager only admin should be able to remove managers");
            }
        }
    }

    ///@custom:property-id 12
    ///@custom:property pool manager can always withdraw within strategy limits/logic

    ///@custom:property-id 13
    ///@custom:property pool manager can always change metadata
    function prop_poolManagerCanAlwaysChangeMetadata(uint256 _idSeed, Metadata calldata _metadata) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];

        (bool _success,) =
            targetCallDefault(address(allo), 0, abi.encodeCall(allo.updatePoolMetadata, (_poolId, _metadata)));

        bool _isManager;
        for (uint256 _i; _i < ghost_poolManagers[_poolId].length; _i++) {
            if (msg.sender == ghost_poolManagers[_poolId][_i]) {
                _isManager = true;
                break;
            }
        }

        if (_isManager || msg.sender == ghost_poolAdmins[_poolId]) {
            if (_success) {
                Allo.Pool memory _pool = allo.getPool(_poolId);
                assertEq(_pool.metadata.protocol, _metadata.protocol, "updatePoolMetadata protocol failed");
                assertEq(_pool.metadata.pointer, _metadata.pointer, "updatePoolMetadata pointer failed");
            } else {
                fail("updatePoolMetadata failed");
            }
        } else {
            if (_success) {
                fail("updatePoolMetadata only manager should be able to update metadata");
            }
        }
    }

    ///@custom:property-id 14-a
    ///@custom:property allo owner can always change base fee to any arbitrary value
    function prop_alloOwnerCanAlwaysChangeBaseFee(uint256 _newBaseFee) public {
        (bool _success,) = targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.updateBaseFee, (_newBaseFee)));

        if (_success) {
            assertEq(allo.getBaseFee(), _newBaseFee, "updateBaseFee failed");
            baseFee = _newBaseFee;
        } else {
            fail("updateBaseFee failed");
        }
    }

    ///@custom:property-id 14-b
    ///@custom:property allo owner can always change the percent flee (./. funding amt) to any arbitrary value (max 100%)
    function prop_alloOwnerCanAlwaysPercentFee(uint256 _newPercentFee) public {
        (bool _success,) =
            targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.updatePercentFee, (_newPercentFee)));
        if (_success) {
            assertEq(allo.getPercentFee(), _newPercentFee, "updatePercentFee failed");
            percentFee = _newPercentFee;
        } else {
            assertTrue(_newPercentFee > 1e18, "updatePercentFee failed");
        }
    }

    ///@custom:property-id 15-a
    ///@custom:property allo owner can always change the treasury address
    function prop_alloOwnerCanAlwaysChangeTreasury(address _newTreasury) public {
        (bool _success,) =
            targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.updateTreasury, payable(_newTreasury)));

        if (_success) {
            assertEq(allo.getTreasury(), _newTreasury, "updateTreasury failed");
            treasury = payable(_newTreasury);
        } else {
            assertEq(_newTreasury, address(0), "updateTreasury failed");
        }
    }

    ///@custom:property-id 15-b
    ///@custom:property allo owner can always change the truster forwarder
    function prop_alloOwnerCanAlwaysChangeTrustedForwarder(address _newForwarder) public {
        (bool _success,) =
            targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.updateTrustedForwarder, (_newForwarder)));

        if (_success) {
            assertTrue(allo.isTrustedForwarder(_newForwarder), "updateTrustedForwarder failed");
            forwarder = _newForwarder;
        } else {
            assertTrue(_newForwarder == address(0), "updateTrustedForwarder failed");
        }
    }

    ///@custom:property-id 15-c
    ///@custom:property allo owner can always change the registry
    function prop_alloOwnerCanAlwaysChangeRegistry(address _newRegistry) public {
        (bool _success,) =
            targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.updateRegistry, (_newRegistry)));

        if (_success) {
            assertEq(address(allo.getRegistry()), _newRegistry, "updateRegistry failed");

            // rollback the change to use the original registry
            allo.updateRegistry(address(registry));
            assertEq(address(allo.getRegistry()), address(registry), "updateRegistry rollback failed");
        } else {
            assertTrue(_newRegistry == address(0), "updateRegistry failed");
        }
    }

    ///@custom:property-id 16
    ///@custom:property allo owner can always recover funds from allo contract ( (non-)native token )

    ///@custom:property-id 17
    ///@custom:property only funds not allocated can be withdrawn

    ///@custom:property-id 18
    ///@custom:property anyone can increase fund in a pool, if strategy (hook) logic allows so and if more than base fee

    ///@custom:property-id 19
    ///@custom:property every deposit/pool creation must take the correct fee on the amount deposited, forwarded to the treasury
}
