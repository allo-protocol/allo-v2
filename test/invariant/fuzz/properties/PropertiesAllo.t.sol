// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Transfer} from "contracts/core/libraries/Transfer.sol";

import {HandlersParent} from "../handlers/HandlersParent.t.sol";
import {IAllo, Allo, Metadata} from "contracts/core/Allo.sol";
import {IRegistry, Registry} from "contracts/core/Registry.sol";
import {IBaseStrategy} from "contracts/strategies/BaseStrategy.sol";
import {IAllocationExtension} from "contracts/strategies/extensions/allocate/IAllocationExtension.sol";

import {FuzzERC20, ERC20} from "../helpers/FuzzERC20.sol";

contract PropertiesAllo is HandlersParent {
    ///@custom:property-id 1-a
    ///@custom:property one should always be able to allocate for recipient
    function prop_userShouldBeAbleToAllocateForRecipient(uint256 _actorSeed, uint256 _idSeed, uint256 _amount) public {
        address _recipient = _pickActor(_actorSeed);

        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];

        bytes32 _strategyId = allo.getPool(_poolId).strategy.getStrategyId();

        address[] memory _recipients = new address[](1);
        _recipients[0] = _recipient;

        address _token = allo.getPool(_poolId).token;

        address[] memory _tokens = new address[](1);
        _tokens[0] = address(_token);

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = _amount;

        bytes memory _data = abi.encode(_tokens);

        // For now, only DirectAllocation strategy is supported
        if (_strategyId != keccak256(abi.encode("DirectAllocation"))) {
            return;
        }

        address _allocator = _usingAnchor ? _ghost_anchorOf[msg.sender] : msg.sender;
        address _strategy = address(allo.getPool(_poolId).strategy);

        uint256 _recipientPreviousBalance;

        if (_token == Transfer.NATIVE) {
            vm.deal(_allocator, _amount);
            _recipientPreviousBalance = _recipient.balance;
        } else {
            FuzzERC20(_token).mint(_allocator, _amount);
            vm.prank(_allocator);
            FuzzERC20(_token).approve(_strategy, _amount);
            _recipientPreviousBalance = FuzzERC20(_token).balanceOf(_recipient);
        }

        (bool _success,) =
            targetCall(address(allo), 0, abi.encodeCall(allo.allocate, (_poolId, _recipients, _amounts, _data)));

        if (_success) {
            if (_token == Transfer.NATIVE) {
                assertEq(_recipient.balance, _recipientPreviousBalance + _amount, "property-id 1-a: allocate failed");
            } else {
                assertEq(
                    FuzzERC20(_token).balanceOf(_recipient),
                    _allocator == _recipient ? _recipientPreviousBalance : _recipientPreviousBalance + _amount,
                    "property-id 1-a: allocate failed"
                );
            }
        } else {
            fail("property-id 1-a: allocate failed");
        }
    }

    ///@custom:property-id 1-b
    ///@custom:property one should always be able to pull correct (based on strategy) allocation for recipient
    function prop_poolManagerShouldBeAbleToWithdrawForRecipient(
        uint256 _idSeed,
        uint256 _managerSeed,
        uint256 _actorSeed,
        uint256 _amount
    ) public {
        address _recipient = _pickActor(_actorSeed);

        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];

        address _manager = ghost_poolManagers[_poolId][_managerSeed % ghost_poolManagers[_poolId].length - 1];

        IBaseStrategy _strategy = allo.getPool(_poolId).strategy;

        // For now, only DirectAllocation strategy is supported
        if (_strategy.getStrategyId() != keccak256(abi.encode("DirectAllocation"))) {
            return;
        }

        uint256 _recipientPreviousBalance = token.balanceOf(_recipient);

        FuzzERC20(address(token)).mint(address(_strategy), _amount);
        _recipientPreviousBalance = token.balanceOf(_recipient);
        uint256 _poolAmount = _strategy.getPoolAmount();

        (bool _success,) = targetCall(
            address(_strategy), _manager, 0, abi.encodeCall(_strategy.withdraw, (address(token), _amount, _recipient))
        );

        if (_success) {
            assertEq(
                token.balanceOf(_recipient), _recipientPreviousBalance + _amount, "property-id 1-b: withdraw failed"
            );
        } else {
            assertTrue(_amount > _poolAmount, "property-id 1-b: withdraw failed");
        }
    }

    ///@custom:property-id 2
    ///@custom:property a token allocation never “disappears” (withdraw cannot impact an allocation)

    ///@custom:property-id 3
    ///@custom:property an address can only withdraw if has allocation

    ///@custom:property-id 4
    ///@custom:property profile owner can always create a pool
    function prop_profileOwnerCanAlwaysCreateAPool(uint256 _msgValue, uint256 _seedPoolStrategy) public {
        _seedPoolStrategy = bound(
            _seedPoolStrategy,
            uint256(type(PoolStrategies).min) + 1, // Avoid None elt
            uint256(type(PoolStrategies).max)
        );

        IRegistry.Profile memory _profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);

        bool _isOwnerOrMember = registry.isOwnerOrMemberOfProfile(_profile.id, msg.sender);

        // Create a pool
        (bool succ, bytes memory ret) = targetCall(
            address(allo),
            _msgValue,
            abi.encodeCall(
                allo.createPool,
                (
                    _profile.id,
                    _strategyImplementations[PoolStrategies(_seedPoolStrategy)],
                    bytes(""),
                    address(token),
                    0,
                    _profile.metadata,
                    new address[](0)
                )
            )
        );

        if (succ) {
            uint256 _poolId = abi.decode(ret, (uint256));
            assertTrue(
                allo.hasRole(keccak256(abi.encodePacked(_poolId, "admin")), msg.sender),
                "property-id 9: initial admin should be pool creator"
            );
            ghost_poolIds.push(_poolId);
            ghost_poolAdmins[_poolId] = msg.sender;
        } else {
            assertTrue(
                _profile.anchor == address(0) || _usingAnchor || !_isOwnerOrMember || _msgValue != baseFee,
                "property-id 4: createPool failed"
            );
        }
    }

    ///@custom:property-id 5-a
    ///@custom:property profile owner is the only one who can always add profile members (name ⇒ new anchor())
    function prop_onlyProfileOwnerCanAddProfileMember(uint256 _actorSeed) public {
        // Get the profile ID
        IRegistry.Profile memory _profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);

        address[] memory _members = new address[](1);
        address _newMember = _pickActor(_actorSeed);
        _members[0] = _newMember;

        (bool _success,) =
            targetCall(address(registry), 0, abi.encodeCall(registry.addMembers, (_profile.id, _members)));

        if (msg.sender == _profile.owner) {
            if (_success) {
                assertTrue(registry.hasRole(_profile.id, _newMember), "property-id 5-a: addMembers failed role not set");
                _ghost_roleMembers[_profile.id].push(_newMember);
            } else {
                assertTrue(_newMember == address(0) || _usingAnchor, "property-id 5-a: addMembers failed");
            }
        } else {
            if (_success) {
                fail("property-id 5-a: addMembers only owner should be able to add members");
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
            targetCall(address(registry), 0, abi.encodeCall(registry.removeMembers, (_profile.id, _members)));

        if (msg.sender == _profile.owner) {
            if (_success) {
                assertTrue(!registry.hasRole(_profile.id, _memberToRemove), "property-id 5-b: removeMembers failed");
                _ghost_roleMembers[_profile.id].pop();
            } else {
                assertTrue(_memberToRemove == address(0) || _usingAnchor, "property-id 5-b: removeMembers failed");
            }
        } else {
            if (_success) {
                fail("property-id 5-b: removeMembers only owner should be able to remove members");
            }
        }
    }

    ///@custom:property-id 6
    ///@custom:property profile owner is the only one who can always initiate a change of profile owner (2 steps)
    function prop_onlyProfileOwnerCanInitiateChangeOfProfileOwner(address _newOwner) public {
        // Get the profile ID
        IRegistry.Profile memory _profile = registry.getProfileByAnchor(_ghost_anchorOf[msg.sender]);

        (bool _success,) = targetCall(
            address(registry), 0, abi.encodeCall(registry.updateProfilePendingOwner, (_profile.id, _newOwner))
        );

        if (msg.sender == _profile.owner) {
            if (_success) {
                assertTrue(
                    registry.profileIdToPendingOwner(_profile.id) == _newOwner,
                    "property-id 6: updateProfilePendingOwner failed"
                );
            } else {
                assertTrue(_newOwner == address(0) || _usingAnchor, "property-id 6: updateProfilePendingOwner failed");
            }
        } else {
            if (_success) {
                fail("property-id 6: updateProfilePendingOwner only owner should be able to initiate change of owner");
            }
        }
    }

    ///@custom:property-id 7
    ///@custom:property profile member can always create a pool
    /// covered with property-id 4

    ///@custom:property-id 8
    ///@custom:property only profile owner or member can create a pool
    /// covered with property-id 4

    ///@custom:property-id 9
    ///@custom:property initial admin is always the creator of the pool
    /// covered with property-id 4

    ///@custom:property-id 10
    ///@custom:property pool admin can always change admin (but not to address(0))
    function prop_poolAdminCanAlwaysChangeAdminToNonZero(uint256 _idSeed, uint256 _actorSeed) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];
        address _admin = ghost_poolAdmins[_poolId];

        bytes32 _poolAdminRole = keccak256(abi.encodePacked(_poolId, "admin"));

        address _newAdmin = _pickActor(_actorSeed);

        (bool _success,) = targetCall(address(allo), 0, abi.encodeCall(allo.changeAdmin, (_poolId, _newAdmin)));

        if (_success) {
            assertEq(msg.sender, _admin, "property-id 10: changeAdmin only admin should be able to change admin");
            if (_newAdmin != _admin) {
                assertTrue(
                    !allo.hasRole(_poolAdminRole, _admin),
                    "property-id 10: changeAdmin failed remove old admin role not removed"
                );
            }
            assertTrue(allo.hasRole(_poolAdminRole, _newAdmin), "property-id 10: changeAdmin failed role not set");
            assertTrue(allo.isPoolAdmin(_poolId, _newAdmin), "property-id 10: admin not set");
            ghost_poolAdmins[_poolId] = _newAdmin;
        } else {
            assertTrue(
                _newAdmin == address(0) || msg.sender != _admin || _usingAnchor, "property-id 10: changeAdmin failed"
            );
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

        (bool _success,) = targetCall(address(allo), 0, abi.encodeCall(allo.addPoolManagers, (_poolId, _managers)));

        if (_success) {
            assertEq(msg.sender, _admin, "property-id 11-a: addPoolManagers only admin should be able to add managers");
            assertTrue(
                allo.hasRole(_poolManagerRole, _newManager), "property-id 11-a: addPoolManagers failed role not set"
            );
            ghost_poolManagers[_poolId].push(_newManager);
        } else {
            assertTrue(
                _newManager == address(0) || _usingAnchor || msg.sender != _admin,
                "property-id 11-a: addPoolManager failed"
            );
        }
    }

    ///@custom:property-id 11-b
    ///@custom:property pool admin can always remove pool managers
    function prop_poolAdminCanAlwaysRemoveManagers(uint256 _idSeed, uint256 _managerIndex) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];
        _managerIndex = bound(_managerIndex, 0, ghost_poolManagers[_poolId].length - 1);
        address _admin = ghost_poolAdmins[_poolId];
        address[] memory _managers = ghost_poolManagers[_poolId];
        address _manager = _managers[_managerIndex];
        bytes32 _poolManagerRole = bytes32(_poolId);

        address[] memory _removeManagers = new address[](1);
        _removeManagers[0] = _manager;

        (bool _success,) =
            targetCall(address(allo), 0, abi.encodeCall(allo.removePoolManagers, (_poolId, _removeManagers)));

        if (_success) {
            assertEq(
                msg.sender, _admin, "property-id 11-b: removePoolManagers only admin should be able to remove managers"
            );
            assertTrue(!allo.hasRole(_poolManagerRole, _manager), "property-id 11-b: removePoolManagers failed");
            delete ghost_poolManagers[_poolId];
            // regenerate the list of managers for the pool
            for (uint256 _i; _i < _managers.length; _i++) {
                if (_i != _managerIndex) {
                    ghost_poolManagers[_poolId].push(_managers[_i]);
                }
            }
        } else {
            assertTrue(
                _manager == address(0) || _usingAnchor || msg.sender != _admin,
                "property-id 11-b: removePoolManager failed"
            );
        }
    }

    ///@custom:property-id 12
    ///@custom:property pool manager can always withdraw within strategy limits/logic

    ///@custom:property-id 13
    ///@custom:property pool manager can always change metadata
    function prop_poolManagerCanAlwaysChangeMetadata(uint256 _idSeed, Metadata calldata _metadata) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];
        address _admin = ghost_poolAdmins[_poolId];

        (bool _success,) = targetCall(address(allo), 0, abi.encodeCall(allo.updatePoolMetadata, (_poolId, _metadata)));

        if (_success) {
            assertTrue(
                _isManager(msg.sender, _poolId) || msg.sender == _admin,
                "property-id 13: updatePoolMetadata only manager or admin should be able to update metadata"
            );
            Allo.Pool memory _pool = allo.getPool(_poolId);
            assertEq(_pool.metadata.protocol, _metadata.protocol, "property-id 13: updatePoolMetadata protocol failed");
            assertEq(_pool.metadata.pointer, _metadata.pointer, "property-id 13: updatePoolMetadata pointer failed");
        } else {
            assertTrue(
                (!_isManager(msg.sender, _poolId) && msg.sender != _admin) || _usingAnchor,
                "property-id 13: updatePoolMetadata failed"
            );
        }
    }

    ///@custom:property-id 14-a
    ///@custom:property allo owner can always change base fee to any arbitrary value
    function prop_alloOwnerCanAlwaysChangeBaseFee(uint256 _newBaseFee) public {
        (bool _success,) = targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.updateBaseFee, (_newBaseFee)));

        if (_success) {
            assertEq(allo.getBaseFee(), _newBaseFee, "property-id 14-a: updateBaseFee failed");
            baseFee = _newBaseFee;
        } else {
            fail("property-id 14-a: updateBaseFee failed");
        }
    }

    ///@custom:property-id 14-b
    ///@custom:property allo owner can always change the percent flee (./. funding amt) to any arbitrary value (max 100%)
    function prop_alloOwnerCanAlwaysChangePercentFee(uint256 _newPercentFee) public {
        (bool _success,) =
            targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.updatePercentFee, (_newPercentFee)));
        if (_success) {
            assertEq(allo.getPercentFee(), _newPercentFee, "property-id 14-b: updatePercentFee failed");
            percentFee = _newPercentFee;
        } else {
            assertTrue(_newPercentFee > 1e18, "property-id 14-b: updatePercentFee failed");
        }
    }

    ///@custom:property-id 15-a
    ///@custom:property allo owner can always change the treasury address
    function prop_alloOwnerCanAlwaysChangeTreasury(address _newTreasury) public {
        (bool _success,) =
            targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.updateTreasury, payable(_newTreasury)));

        if (_success) {
            assertEq(allo.getTreasury(), _newTreasury, "property-id 15-a: updateTreasury failed");
            treasury = payable(_newTreasury);
        } else {
            assertTrue(_newTreasury == address(0) || _usingAnchor, "property-id 15-a: updateTreasury failed");
        }
    }

    ///@custom:property-id 15-b
    ///@custom:property allo owner can always change the truster forwarder
    function prop_alloOwnerCanAlwaysChangeTrustedForwarder(address _newForwarder) public {
        (bool _success,) =
            targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.updateTrustedForwarder, (_newForwarder)));

        if (_success) {
            assertTrue(allo.isTrustedForwarder(_newForwarder), "property-id 15-b: updateTrustedForwarder failed");
            forwarder = _newForwarder;
        } else {
            assertTrue(_newForwarder == address(0) || _usingAnchor, "property-id 15-b: updateTrustedForwarder failed");
        }
    }

    ///@custom:property-id 15-c
    ///@custom:property allo owner can always change the registry
    function prop_alloOwnerCanAlwaysChangeRegistry(address _newRegistry) public {
        (bool _success,) =
            targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.updateRegistry, (_newRegistry)));

        if (_success) {
            assertEq(address(allo.getRegistry()), _newRegistry, "property-id 15-c: updateRegistry failed");

            // rollback the change to use the original registry
            allo.updateRegistry(address(registry));
            assertEq(address(allo.getRegistry()), address(registry), "property-id 15-c: updateRegistry rollback failed");
        } else {
            assertTrue(_newRegistry == address(0) || _usingAnchor, "property-id 15-c: updateRegistry failed");
        }
    }

    ///@custom:property-id 16
    ///@custom:property allo owner can always recover funds from allo contract ( (non-)native token )
    function prop_alloOwnerCanAlwaysRecoverFundsFromAlloContract(uint256 _idSeed) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];

        address _token = allo.getPool(_poolId).token;
        address _recipient = _ghost_actors[_idSeed % (_ghost_actors.length - 1)];

        uint256 _previousBalanceRecipient;
        uint256 _previousBalanceAllo;

        if (_token == Transfer.NATIVE) {
            _previousBalanceRecipient = _recipient.balance;
            _previousBalanceAllo = address(allo).balance;
        } else {
            _previousBalanceRecipient = token.balanceOf(_recipient);
            _previousBalanceAllo = token.balanceOf(address(allo));
        }

        (bool _success,) =
            targetCall(address(allo), allo.owner(), 0, abi.encodeCall(allo.recoverFunds, (address(_token), _recipient)));

        if (_success) {
            if (_token == Transfer.NATIVE) {
                assertEq(
                    _recipient.balance,
                    _previousBalanceRecipient + _previousBalanceAllo,
                    "property-id 16: recoverFunds failed invalid recipient balance"
                );
                assertEq(address(allo).balance, 0, "property-id 16: recoverFunds failed allo balance should  be zero");
            } else {
                assertEq(
                    token.balanceOf(_recipient),
                    _previousBalanceRecipient + _previousBalanceAllo,
                    "property-id 16: recoverFunds failed invalid recipient balance"
                );
                assertEq(
                    token.balanceOf(address(allo)), 0, "property-id 16: recoverFunds failed allo balance should be zero"
                );
            }
        } else {
            assertTrue(_previousBalanceAllo == 0, "property-id 16: recoverFunds failed");
        }
    }

    ///@custom:property-id 17
    ///@custom:property only funds not allocated can be withdrawn

    ///@custom:property-id 18
    ///@custom:property anyone can increase fund in a pool, if strategy (hook) logic allows so and if more than base fee
    function prop_anyoneCanIncreaseFundInAPool(uint256 _idSeed, uint256 _amount) public {
        _idSeed = bound(_idSeed, 0, ghost_poolIds.length - 1);
        uint256 _poolId = ghost_poolIds[_idSeed];

        address _token = allo.getPool(_poolId).token;
        address _strategy = allo.getStrategy(_poolId);

        uint256 _feeAmount = (_amount * percentFee) / allo.getFeeDenominator();
        uint256 _amountAfterFee = _amount - _feeAmount;

        address anchor = _ghost_anchorOf[msg.sender];
        uint256 _previousBalanceStrategy;
        uint256 _previousBalanceTreasury;

        address _funder = _usingAnchor ? _ghost_anchorOf[msg.sender] : msg.sender;

        if (_token == Transfer.NATIVE) {
            vm.deal(_funder, _amount);
            _previousBalanceStrategy = _strategy.balance;
            _previousBalanceTreasury = treasury.balance;
        } else {
            FuzzERC20(_token).mint(_funder, _amount);
            vm.prank(_funder);
            token.approve(address(allo), type(uint256).max);
            _previousBalanceStrategy = token.balanceOf(_strategy);
            _previousBalanceTreasury = token.balanceOf(treasury);
        }

        (bool _success,) = targetCall(address(allo), _amount, abi.encodeCall(allo.fundPool, (_poolId, _amountAfterFee)));

        if (_success) {
            uint256 _afterBalanceStrategy;
            uint256 _afterBalanceTreasury;
            if (_token == Transfer.NATIVE) {
                _afterBalanceStrategy = _strategy.balance;
                _afterBalanceTreasury = treasury.balance;
            } else {
                _afterBalanceStrategy = token.balanceOf(_strategy);
                _afterBalanceTreasury = token.balanceOf(treasury);
            }
            assertEq(
                _afterBalanceStrategy,
                _previousBalanceStrategy + _amountAfterFee,
                "property-id 18: increasePoolFunds invalid strategy balance"
            );
            assertEq(
                _afterBalanceTreasury,
                _previousBalanceTreasury + _feeAmount,
                "property-id 19: increasePoolFunds invalid treasury balance"
            );
        } else {
            (bool _successAllocationEndtime, bytes memory _allocationEndTimedata) =
                address(_strategy).call(abi.encodeWithSignature("allocationEndTime()"));
            uint256 _allocationEndTime;
            if (_successAllocationEndtime) {
                _allocationEndTime = abi.decode(_allocationEndTimedata, (uint256));
            }
            assertTrue(
                _amount == 0 || (_successAllocationEndtime && _allocationEndTime > block.timestamp),
                "property-id 18: increasePoolFunds failed"
            );
        }
    }

    ///@custom:property-id 19
    ///@custom:property every deposit/pool creation must take the correct fee on the amount deposited, forwarded to the treasury
    /// covered with property-id 18
}
