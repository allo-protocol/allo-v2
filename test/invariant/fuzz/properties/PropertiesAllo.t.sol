// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {HandlersParent} from '../handlers/HandlersParent.t.sol';
import {IAllo, Allo, Metadata} from 'contracts/core/Allo.sol';
import {Registry} from 'contracts/core/Registry.sol';

contract PropertiesAllo is HandlersParent {
    ///@custom:property-id 1
    ///@custom:property one should always be able to pull/push correct (based on strategy) allocation for recipient

    ///@custom:property-id 2
    ///@custom:property a token allocation never “disappears” (withdraw cannot impact an allocation)

    ///@custom:property-id 3
    ///@custom:property an address can only withdraw if has allocation

    ///@custom:property-id 4
    ///@custom:property profile owner can always create a pool

    ///@custom:property-id 5
    ///@custom:property profile owner is the only one who can always add/remove/modify profile members (name ⇒ new anchor())

    ///@custom:property-id 6
    ///@custom:property profile owner is the only one who can always initiate a change of profile owner (2 steps)

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

        bytes32 _poolAdminRole = keccak256(abi.encodePacked(_poolId, 'admin'));

        vm.prank(_admin);
        try allo.changeAdmin(_poolId, _newAdmin) {
            if (_newAdmin != _admin) {
                assertTrue(!allo.hasRole(_poolAdminRole, _admin), 'changeAdmin failed remove old admin');
            }
            assertTrue(allo.hasRole(_poolAdminRole, _newAdmin), 'changeAdmin failed set new admin');
            ghost_poolAdmins[_poolId] = _newAdmin;
        } catch Error(string memory) {
            // should only fail if _newAdmin is address(0)
            assertEq(_newAdmin, address(0), 'changeAdmin unexpected error');
        } catch {
            // should only fail if _newAdmin is address(0)
            assertEq(_newAdmin, address(0), 'changeAdmin unexpected failure');
        }
    }

    ///@custom:property-id 11-a
    ///@custom:property pool admin can always add/remove pool managers
    function prop_poolAdminCanAlwaysAddManagers(uint256 _idSeed, address _newManager) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];
        address _admin = ghost_poolAdmins[_poolId];

        if (_admin == address(0) || _newManager == address(0)) {
            return;
        }

        bytes32 _poolManagerRole = bytes32(_poolId);

        if (allo.hasRole(_poolManagerRole, _newManager)) {
            return;
        }

        address[] memory _managers = new address[](1);
        _managers[0] = _newManager;

        vm.prank(_admin);
        try allo.addPoolManagers(_poolId, _managers) {
            assertTrue(allo.hasRole(_poolManagerRole, _newManager), 'addPoolManagers failed');
            ghost_poolManagers[_poolId].push(_newManager);
        } catch Error(string memory) {
            fail('addPoolManager unexpected error');
        } catch {
            fail('addPoolManager unexpected failure');
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

        if (_admin == address(0) || _managers.length == 0) {
            return;
        }

        address _manager = _managers[_managerIndex];

        if (_manager == address(0)) {
            return;
        }

        bytes32 _poolManagerRole = bytes32(_poolId);

        address[] memory _removeManagers = new address[](1);
        _removeManagers[0] = _manager;

        vm.prank(_admin);
        try allo.removePoolManagers(_poolId, _removeManagers) {
            assertTrue(!allo.hasRole(_poolManagerRole, _manager), 'removePoolManagers failed');
            delete _managers[_managerIndex];
        } catch Error(string memory) {
            fail('addPoolManager unexpected error');
        } catch {
            fail('addPoolManager unexpected failure');
        }
    }

    ///@custom:property-id 12
    ///@custom:property pool manager can always withdraw within strategy limits/logic

    ///@custom:property-id 13
    ///@custom:property pool manager can always change metadata
    function prop_poolManagerCanAlwaysChangeMetadata(uint256 _idSeed, uint256 _seedManager, Metadata calldata _metadata)
        public
    {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];
        uint256 _managerIndex = _seedManager % (ghost_poolManagers[_poolId].length - 1);
        address _manager = ghost_poolManagers[_poolId][_managerIndex];

        if (_manager == address(0)) {
            return;
        }

        vm.prank(_manager);
        try allo.updatePoolMetadata(_poolId, _metadata) {
            Allo.Pool memory _pool = allo.getPool(_poolId);
            assertEq(_pool.metadata.protocol, _metadata.protocol, 'updatePoolMetadata protocol failed');
            assertEq(_pool.metadata.pointer, _metadata.pointer, 'updatePoolMetadata pointer failed');
        } catch Error(string memory) {
            fail('updatePoolMetadata unexpected error');
        } catch {
            fail('updatePoolMetadata unexpected failure');
        }
    }

    ///@custom:property-id 14-a
    ///@custom:property allo owner can always change base fee to any arbitrary value
    function prop_alloOwnerCanAlwaysChangeBaseFee(uint256 _newBaseFee) public {
        vm.prank(allo.owner());
        try allo.updateBaseFee(_newBaseFee) {
            assertEq(allo.getBaseFee(), _newBaseFee, 'updateBaseFee failed');
            baseFee = _newBaseFee;
        } catch Error(string memory) {
            fail('updateBaseFee unexpected error');
        } catch {
            fail('updateBaseFee unexpected failure');
        }
    }

    ///@custom:property-id 14-b
    ///@custom:property allo owner can always change the percent flee (./. funding amt) to any arbitrary value (max 100%)
    function prop_alloOwnerCanAlwaysPercentFee(uint256 _newPercentFee) public {
        _newPercentFee = bound(_newPercentFee, 0, 1e18);

        vm.prank(allo.owner());
        try allo.updatePercentFee(_newPercentFee) {
            assertEq(allo.getPercentFee(), _newPercentFee, 'updatePercentFee failed');
            percentFee = _newPercentFee;
        } catch Error(string memory) {
            fail('updatePercentFee unexpected error');
        } catch {
            fail('updatePercentFee unexpected failure');
        }
    }

    ///@custom:property-id 15-a
    ///@custom:property allo owner can always change the treasury address
    function prop_alloOwnerCanAlwaysChangeTreasury(address _newTreasury) public {
        vm.prank(allo.owner());
        try allo.updateTreasury(payable(_newTreasury)) {
            assertEq(allo.getTreasury(), _newTreasury, 'updateTreasury failed');
            treasury = payable(_newTreasury);
        } catch Error(string memory) {
            assertEq(_newTreasury, address(0), 'updateTreasury unexpected error');
        } catch {
            assertEq(_newTreasury, address(0), 'updateTreasury unexpected failure');
        }
    }

    ///@custom:property-id 15-b
    ///@custom:property allo owner can always change the truster forwarder
    function prop_alloOwnerCanAlwaysChangeTrustedForwarder(address _newForwarder) public {
        vm.prank(allo.owner());
        try allo.updateTrustedForwarder(_newForwarder) {
            assertTrue(allo.isTrustedForwarder(_newForwarder), 'updateTrustedForwarder failed');
            forwarder = _newForwarder;
        } catch Error(string memory) {
            assertEq(_newForwarder, address(0), 'updateTrustedForwarder unexpected error');
        } catch {
            assertEq(_newForwarder, address(0), 'updateTrustedForwarder unexpected failure');
        }
    }

    ///@custom:property-id 15-c
    ///@custom:property allo owner can always change the registry
    function prop_alloOwnerCanAlwaysChangeRegistry(address _newRegistry) public {
        vm.prank(allo.owner());
        try allo.updateRegistry(_newRegistry) {
            assertEq(address(allo.getRegistry()), _newRegistry, 'updateRegistry failed');
            registry = Registry(_newRegistry);
        } catch Error(string memory) {
            assertEq(_newRegistry, address(0), 'updateRegistry unexpected error');
        } catch {
            assertEq(_newRegistry, address(0), 'updateRegistry unexpected failure');
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
