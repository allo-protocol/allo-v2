// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MockStrategyRecipientsExtension} from "../../utils/MockStrategyRecipientsExtension.sol";
import {IRecipientsExtension} from "../../../contracts/extensions/interfaces/IRecipientsExtension.sol";
import {IAllo} from "../../../contracts/core/interfaces/IAllo.sol";
import {IBaseStrategy} from "../../../contracts/strategies/CoreBaseStrategy.sol";
import {Errors} from "../../../contracts/core/libraries/Errors.sol";

abstract contract BaseRecipientsExtensionUnit is Test, IRecipientsExtension {
    MockStrategyRecipientsExtension public recipientsExtension;
    address public allo;
    uint256 public poolId;

    function setUp() public {
        allo = makeAddr("allo");
        recipientsExtension = new MockStrategyRecipientsExtension(allo);
        poolId = 1;

        vm.prank(allo);
        recipientsExtension.initialize(
            poolId,
            abi.encode(
                IRecipientsExtension.RecipientInitializeData({
                    useRegistryAnchor: false,
                    metadataRequired: false,
                    registrationStartTime: uint64(block.timestamp),
                    registrationEndTime: uint64(block.timestamp + 7 days)
                })
            )
        );
    }
}

contract RecipientsExtension__RecipientsExtension_init is BaseRecipientsExtensionUnit {
    function test_Set_useRegistryAnchor(bool _useRegistryAnchor) public {
        IRecipientsExtension.RecipientInitializeData memory _initializeData = IRecipientsExtension
            .RecipientInitializeData({
            useRegistryAnchor: _useRegistryAnchor,
            metadataRequired: false, // irrelevant for the test
            registrationStartTime: uint64(block.timestamp), // irrelevant for the test
            registrationEndTime: uint64(block.timestamp) // irrelevant for the test
        });

        recipientsExtension.call___RecipientsExtension_init(_initializeData);

        assertEq(recipientsExtension.useRegistryAnchor(), _useRegistryAnchor);
    }

    function test_Set_metadataRequired(bool _metadataRequired) public {
        IRecipientsExtension.RecipientInitializeData memory _initializeData = IRecipientsExtension
            .RecipientInitializeData({
            useRegistryAnchor: false, // irrelevant for the test
            metadataRequired: _metadataRequired,
            registrationStartTime: uint64(block.timestamp), // irrelevant for the test
            registrationEndTime: uint64(block.timestamp) // irrelevant for the test
        });

        recipientsExtension.call___RecipientsExtension_init(_initializeData);

        assertEq(recipientsExtension.metadataRequired(), _metadataRequired);
    }

    function test_Call__updatePoolTimestamps(IRecipientsExtension.RecipientInitializeData memory _initializeData)
        public
    {
        vm.assume(_initializeData.registrationStartTime < _initializeData.registrationEndTime);

        recipientsExtension.expectCall__updatePoolTimestamps(
            _initializeData.registrationStartTime, _initializeData.registrationEndTime
        );

        recipientsExtension.call___RecipientsExtension_init(_initializeData);
    }

    function test_Set_recipientsCounter() public {
        IRecipientsExtension.RecipientInitializeData memory _initializeData = IRecipientsExtension
            .RecipientInitializeData({
            useRegistryAnchor: false, // irrelevant for the test
            metadataRequired: false, // irrelevant for the test
            registrationStartTime: uint64(block.timestamp), // irrelevant for the test
            registrationEndTime: uint64(block.timestamp) // irrelevant for the test
        });

        recipientsExtension.call___RecipientsExtension_init(_initializeData);

        assertEq(recipientsExtension.recipientsCounter(), 1);
    }
}

contract RecipientsExtensionGetRecipient is BaseRecipientsExtensionUnit {
    function test_Call__getRecipient(address _recipient) public {
        recipientsExtension.expectCall__getRecipient(_recipient);

        recipientsExtension.call__getRecipient(_recipient);
    }
}

contract RecipientsExtension_getRecipientStatus is BaseRecipientsExtensionUnit {
    function test_Call__getUintRecipientStatus(address _recipient) public {
        recipientsExtension.expectCall__getUintRecipientStatus(_recipient);

        recipientsExtension.call__getUintRecipientStatus(_recipient);
    }
}

contract RecipientsExtensionReviewRecipients is BaseRecipientsExtensionUnit {
    function test_Revert_IfCalledByNonManager(
        address _caller,
        IRecipientsExtension.ApplicationStatus[] memory _statuses,
        uint256 _refRecipientsCounter
    ) public {
        // force allo to return false
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector, poolId, _caller), abi.encode(false));

        vm.expectRevert(IBaseStrategy.BaseStrategy_UNAUTHORIZED.selector);

        vm.prank(_caller);
        recipientsExtension.reviewRecipients(_statuses, _refRecipientsCounter);
    }

    function test_Revert_IfWrongRefRecipientsCounter(
        IRecipientsExtension.ApplicationStatus[] memory _statuses,
        uint256 _refRecipientsCounter,
        uint256 _recipientsCounter
    ) public {
        vm.assume(_recipientsCounter != _refRecipientsCounter);

        // force allo to return true
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector), abi.encode(true));

        recipientsExtension.set_recipientsCounter(_recipientsCounter);

        vm.expectRevert(Errors.INVALID.selector);

        recipientsExtension.reviewRecipients(_statuses, _refRecipientsCounter);
    }

    function test_Set_statusesBitMap(IRecipientsExtension.ApplicationStatus[] memory _statuses) public {
        // prevent duplicates on the indexes
        for (uint256 i = 0; i < _statuses.length; i++) {
            _statuses[i].index = i;
        }

        // force allo to return true
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector), abi.encode(true));

        recipientsExtension.reviewRecipients(_statuses, 1);

        for (uint256 i = 0; i < _statuses.length; i++) {
            assertEq(recipientsExtension.statusesBitMap(_statuses[i].index), _statuses[i].statusRow);
        }
    }

    function test_Emit_Event(IRecipientsExtension.ApplicationStatus[] memory _statuses, address _caller) public {
        // prevent duplicates on the indexes
        for (uint256 i = 0; i < _statuses.length; i++) {
            _statuses[i].index = i;
        }

        // force allo to return true
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector), abi.encode(true));

        for (uint256 i = 0; i < _statuses.length; i++) {
            vm.expectEmit();
            emit IRecipientsExtension.RecipientStatusUpdated(_statuses[i].index, _statuses[i].statusRow, _caller);
        }

        vm.prank(_caller);
        recipientsExtension.reviewRecipients(_statuses, 1);
    }
}

contract RecipientsExtensionUpdatePoolTimestamps is BaseRecipientsExtensionUnit {
    function test_Revert_IfCalledByNonManager(address _caller) public {
        // force allo to return false
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector, poolId, _caller), abi.encode(false));

        vm.expectRevert(IBaseStrategy.BaseStrategy_UNAUTHORIZED.selector);

        vm.prank(_caller);
        recipientsExtension.updatePoolTimestamps(0, 0);
    }

    function test_Call__updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        // force allo to return true
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector), abi.encode(true));

        vm.assume(_registrationStartTime < _registrationEndTime);

        recipientsExtension.expectCall__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);

        recipientsExtension.updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
    }
}

contract RecipientsExtension_updatePoolTimestamps is BaseRecipientsExtensionUnit {
    function test_Call__isPoolTimestampValid(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        vm.assume(_registrationStartTime < _registrationEndTime);

        recipientsExtension.expectCall__isPoolTimestampValid(_registrationStartTime, _registrationEndTime);

        recipientsExtension.call__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
    }

    function test_Set_registrationStartTime(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        vm.assume(_registrationStartTime < _registrationEndTime);

        recipientsExtension.call__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);

        assertEq(recipientsExtension.registrationStartTime(), _registrationStartTime);
    }

    function test_Set_registrationEndTime(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        vm.assume(_registrationStartTime < _registrationEndTime);

        recipientsExtension.call__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);

        assertEq(recipientsExtension.registrationEndTime(), _registrationEndTime);
    }

    function test_Emit_Event(uint64 _registrationStartTime, uint64 _registrationEndTime, address _caller) public {
        vm.assume(_registrationStartTime < _registrationEndTime);

        vm.expectEmit();
        emit IRecipientsExtension.TimestampsUpdated(_registrationStartTime, _registrationEndTime, _caller);

        vm.prank(_caller);
        recipientsExtension.call__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
    }
}

contract RecipientsExtension_checkOnlyActiveRegistration is BaseRecipientsExtensionUnit {
    function test_Revert_IfTimestampSmallerThanRegistrationStartTime(
        uint64 _currentTimestamp,
        uint64 _registrationStartTime,
        uint64 _registrationEndTime
    ) public {
        vm.assume(_registrationStartTime < _currentTimestamp);
        vm.assume(_registrationEndTime < _currentTimestamp);

        vm.warp(_currentTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);

        vm.expectRevert(Errors.REGISTRATION_NOT_ACTIVE.selector);

        recipientsExtension.call__checkOnlyActiveRegistration();
    }

    function test_Revert_IfTimestampGreaterThanRegistrationEndTime(
        uint64 _currentTimestamp,
        uint64 _registrationStartTime,
        uint64 _registrationEndTime
    ) public {
        vm.assume(_registrationStartTime > _currentTimestamp);
        vm.assume(_registrationEndTime > _currentTimestamp);

        vm.warp(_currentTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);

        vm.expectRevert(Errors.REGISTRATION_NOT_ACTIVE.selector);

        recipientsExtension.call__checkOnlyActiveRegistration();
    }
}

contract RecipientsExtension_isPoolTimestampValid is BaseRecipientsExtensionUnit {
    function test_Revert_IfInvalidTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime) public {
        vm.assume(_registrationStartTime > _registrationEndTime);

        vm.expectRevert(Errors.INVALID.selector);

        recipientsExtension.call__isPoolTimestampValid(_registrationStartTime, _registrationEndTime);
    }
}

contract RecipientsExtension_isPoolActive is BaseRecipientsExtensionUnit {
    function test_Return_TrueIfPoolActive(
        uint64 _currentTimestamp,
        uint64 _registrationStartTime,
        uint64 _registrationEndTime
    ) public {
        vm.assume(_registrationStartTime <= _currentTimestamp);
        vm.assume(_registrationEndTime >= _currentTimestamp);

        vm.warp(_currentTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);

        assertTrue(recipientsExtension.call__isPoolActive());
    }

    function test_Return_FalseIfPoolInactive(
        uint64 _currentTimestamp,
        uint64 _registrationStartTime,
        uint64 _registrationEndTime
    ) public {
        vm.assume(_registrationStartTime > _currentTimestamp || _registrationEndTime < _currentTimestamp);

        vm.warp(_currentTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);

        assertFalse(recipientsExtension.call__isPoolActive());
    }
}

contract RecipientsExtension_register is BaseRecipientsExtensionUnit {
    function test_Revert_IfNotActiveRegistration() public {}

    function test_Revert_IfValueNotZero() public {}

    function test_Revert_RecipientZeroAddress() public {}

    function test_Revert_IfUsingRegistryAnchorSenderAndSenderIsNotProfileMember() public {}

    function test_Set_RecipientIdIfNotUsingRegistryAnchorAndProvidedRegistryAnchorIsZero() public {}

    function test_Set_RecipientIdIfNotUsingRegistryAnchorAndProvidedRegistryAnchorIsNotZero() public {}

    function test_Revert_IfNotUsingRegistryAnchorAndProvidedRegistryAnchorIsNotZeroAndSenderIsNotProfileMember()
        public
    {}

    function test_Revert_IfMetadataRequiredAndMetadataPointerIsEmpty() public {}

    function test_Revert_IfMetadataRequiredAndMetadataProtocolIsEmpty() public {}

    function test_Set_recipientAddress() public {}

    function test_Set_metadata() public {}

    function test_Set_IfUseRegistryAnchor() public {}

    function test_Set_IfNotUseRegistryAnchor() public {}

    function test_Set_recipientsCounterIfRegisteringNewApplication() public {}

    function test_Call__setRecipientStatusIfRegisteringNewApplication() public {}

    function test_Emit_eventIfRegisteringNewApplication() public {}

    function test_Increase_recipientsCounterIfRegisteringNewApplication() public {}

    function test_Call__getUintRecipientStatusIfRegisteringNewApplication() public {}

    function test_Call__setRecipientStatusIfAcceptedApplication() public {}

    function test_Call__setRecipientStatusIfInReviewApplication() public {}

    function test_Call__setRecipientStatusIfRejectedApplication() public {}

    function test_Emit_UpdatedRegistration() public {}

    function test_Return_recipientIds() public {}
}

contract RecipientsExtension_getRecipient is BaseRecipientsExtensionUnit {
    function test_Return_recipient(address _recipientId, Recipient memory _recipient) public {
        recipientsExtension.set__recipients(_recipientId, _recipient);

        assertEq(recipientsExtension.call__getRecipient(_recipientId).useRegistryAnchor, _recipient.useRegistryAnchor);
        assertEq(recipientsExtension.call__getRecipient(_recipientId).recipientAddress, _recipient.recipientAddress);
        assertEq(recipientsExtension.call__getRecipient(_recipientId).metadata.pointer, _recipient.metadata.pointer);
        assertEq(recipientsExtension.call__getRecipient(_recipientId).metadata.protocol, _recipient.metadata.protocol);
    }
}

contract RecipientsExtension_setRecipientStatus is BaseRecipientsExtensionUnit {
    function test_Call__getStatusRowColumn(address _recipientId, uint256 _status) public {
        recipientsExtension.mock_call__getStatusRowColumn(_recipientId, 0, 0, 0);

        recipientsExtension.expectCall__getStatusRowColumn(_recipientId);

        recipientsExtension.call__setRecipientStatus(_recipientId, _status);
    }

    function test_Set_statusesBitMap(
        address _recipientId,
        uint256 _status,
        uint256 _rowIndex,
        uint256 _colIndex,
        uint256 _currentRow
    ) public {
        recipientsExtension.mock_call__getStatusRowColumn(_recipientId, _rowIndex, _colIndex, _currentRow);

        recipientsExtension.call__setRecipientStatus(_recipientId, _status);

        uint256 newRow = _currentRow & ~(15 << _colIndex);

        assertEq(recipientsExtension.statusesBitMap(_rowIndex), newRow | (_status << _colIndex));
    }
}

contract RecipientsExtension_getUintRecipientStatus is BaseRecipientsExtensionUnit {
    function test_Return_zeroIfRecipientNotFound(address _recipient) public {
        recipientsExtension.set_recipientToStatusIndexes(_recipient, 0);

        assertEq(recipientsExtension.call__getUintRecipientStatus(_recipient), 0);
    }

    function test_Call__getStatusRowColumn(address _recipient) public {
        recipientsExtension.set_recipientToStatusIndexes(_recipient, 1); // force to return more than zero
        recipientsExtension.mock_call__getStatusRowColumn(_recipient, 0, 0, 0);

        recipientsExtension.expectCall__getStatusRowColumn(_recipient);

        recipientsExtension.call__getUintRecipientStatus(_recipient);
    }

    function test_Return_status(address _recipient, uint256 _colIndex, uint256 _currentRow) public {
        recipientsExtension.set_recipientToStatusIndexes(_recipient, 1); // force to return more than zero
        recipientsExtension.mock_call__getStatusRowColumn(_recipient, 0, _colIndex, _currentRow);

        uint8 _status = recipientsExtension.call__getUintRecipientStatus(_recipient);
        assertEq(_status, uint8((_currentRow >> _colIndex) & 15));
    }
}

contract RecipientsExtension_getStatusRowColumn is BaseRecipientsExtensionUnit {
    function test_Return_statusRowColumn(address _recipientId, uint256 _recipientIndex, uint256 _currentRow) public {
        vm.assume(_recipientIndex > 0);
        uint256 _recipientIndexMinusOne = _recipientIndex - 1;
        vm.assume(_recipientIndexMinusOne > 64);

        uint256 _rowIndex = _recipientIndexMinusOne / 64;
        recipientsExtension.set_recipientToStatusIndexes(_recipientId, _recipientIndex);
        recipientsExtension.set_statusesBitMap(_rowIndex, _currentRow);

        (uint256 __rowIndex, uint256 _colIndex, uint256 __currentRow) =
            recipientsExtension.call__getStatusRowColumn(_recipientId);
        assertEq(_rowIndex, __rowIndex);
        assertEq(_colIndex, (_recipientIndexMinusOne % 64) * 4);
        assertEq(_currentRow, __currentRow);
    }
}
