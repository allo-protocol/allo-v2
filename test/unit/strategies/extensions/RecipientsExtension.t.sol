// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockRecipientsExtension} from "test/smock/MockMockRecipientsExtension.sol";
import {IRecipientsExtension} from "strategies/extensions/register/IRecipientsExtension.sol";
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";
import {IBaseStrategy} from "strategies/BaseStrategy.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";

abstract contract BaseRecipientsExtensionUnit is Test, IRecipientsExtension {
    MockMockRecipientsExtension public recipientsExtension;
    address public allo;
    address public registry;
    uint256 public poolId;

    event Registered(address indexed _recipient, bytes _data);

    function setUp() public {
        allo = makeAddr("allo");
        registry = makeAddr("registry");
        recipientsExtension = new MockMockRecipientsExtension(allo, true);
        poolId = 1;

        vm.prank(allo);
        recipientsExtension.initialize(
            poolId,
            abi.encode(
                IRecipientsExtension.RecipientInitializeData({
                    metadataRequired: false,
                    registrationStartTime: uint64(block.timestamp),
                    registrationEndTime: uint64(block.timestamp + 7 days)
                })
            )
        );

        vm.mockCall(allo, abi.encodeWithSelector(IAllo.getRegistry.selector), abi.encode(registry));
        vm.mockCall(
            registry,
            abi.encodeWithSelector(IRegistry.getProfileByAnchor.selector),
            abi.encode(
                IRegistry.Profile({
                    id: bytes32(0),
                    nonce: 0,
                    name: "",
                    metadata: Metadata({protocol: 0, pointer: ""}),
                    owner: address(0),
                    anchor: address(0)
                })
            )
        );
        vm.mockCall(registry, abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector), abi.encode(true));
    }

    function _fixedArrayToMemory(address[10] memory _array) internal pure returns (address[] memory) {
        address[] memory _memoryArray = new address[](_array.length);
        for (uint256 i = 0; i < _array.length; i++) {
            _memoryArray[i] = _array[i];
        }
        return _memoryArray;
    }

    function _assumeNotZeroAddressInArray(address[10] memory _array) internal pure {
        for (uint256 i = 0; i < _array.length; i++) {
            vm.assume(_array[i] != address(0));
        }
    }

    function _assumeNoDuplicates(address[10] memory _array) internal pure {
        for (uint256 i = 0; i < _array.length; i++) {
            for (uint256 j = 0; j < _array.length; j++) {
                if (i != j) {
                    vm.assume(_array[i] != _array[j]);
                }
            }
        }
    }
}

contract RecipientsExtension__RecipientsExtension_init is BaseRecipientsExtensionUnit {
    function test_Set_metadataRequired(bool _metadataRequired) public {
        IRecipientsExtension.RecipientInitializeData memory _initializeData = IRecipientsExtension
            .RecipientInitializeData({
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

contract RecipientsExtension_isProfileMember is BaseRecipientsExtensionUnit {
    function test_Call_getRegistry(address _anchor, address _sender) public {
        vm.expectCall(allo, abi.encodeWithSelector(IAllo.getRegistry.selector));

        recipientsExtension.call__isProfileMember(_anchor, _sender);
    }

    function test_Call_getProfileByAnchor(address _anchor, address _sender) public {
        vm.expectCall(registry, abi.encodeWithSelector(IRegistry.getProfileByAnchor.selector));

        recipientsExtension.call__isProfileMember(_anchor, _sender);
    }

    function test_Call_isOwnerOrMemberOfProfile(address _anchor, address _sender) public {
        vm.expectCall(registry, abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector));

        recipientsExtension.call__isProfileMember(_anchor, _sender);
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
        _statuses = _boundStatuses(_statuses);

        // force allo to return true
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector), abi.encode(true));

        recipientsExtension.reviewRecipients(_statuses, 1);

        for (uint256 i = 0; i < _statuses.length; i++) {
            assertEq(recipientsExtension.statusesBitMap(_statuses[i].index), _statuses[i].statusRow);
        }
    }

    function test_Emit_Event(IRecipientsExtension.ApplicationStatus[] memory _statuses, address _caller) public {
        _statuses = _boundStatuses(_statuses);

        // force allo to return true
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector), abi.encode(true));

        for (uint256 i = 0; i < _statuses.length; i++) {
            vm.expectEmit();
            emit IRecipientsExtension.RecipientStatusUpdated(_statuses[i].index, _statuses[i].statusRow, _caller);
        }

        vm.prank(_caller);
        recipientsExtension.reviewRecipients(_statuses, 1);
    }

    function _boundStatuses(IRecipientsExtension.ApplicationStatus[] memory _statuses)
        internal
        view
        returns (IRecipientsExtension.ApplicationStatus[] memory)
    {
        // prevent duplicates on the indexes and bound Status to 6
        for (uint256 i = 0; i < _statuses.length; i++) {
            _statuses[i].index = i;
            uint256 fullRow = _statuses[i].statusRow;

            for (uint256 col = 0; col < 64; col++) {
                uint256 colIndex = col << 2; // col * 4
                uint8 newStatus = uint8((fullRow >> colIndex) & 0xF);
                newStatus = uint8(bound(newStatus, 0, 6)); // max enum value = 6

                uint256 reviewedRow = fullRow & ~(0xF << colIndex);
                fullRow = reviewedRow | (uint256(newStatus) << colIndex);
            }
            _statuses[i].statusRow = fullRow;
        }
        return _statuses;
    }
}

contract RecipientsExtensionReviewRecipientStatus is BaseRecipientsExtensionUnit {
    function test_Set_statusesBitMap(uint256 _fullRow) public {
        uint8[] memory _statusValues;
        (_fullRow, _statusValues) = _boundStatuses(_fullRow);

        uint256 _rowIndex = 0;

        // force allo to return true
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector), abi.encode(true));

        uint256 currentRow = recipientsExtension.statusesBitMap(_rowIndex);
        for (uint256 col = 0; col < 64; ++col) {
            // Extract the status at the column index
            uint256 colIndex = col << 2; // col * 4
            uint8 newStatus = uint8((_fullRow >> colIndex) & 0xF);
            uint8 currentStatus = uint8((currentRow >> colIndex) & 0xF);

            // Only do something if the status is being modified
            if (newStatus != currentStatus) {
                uint256 recipientIndex = (_rowIndex << 6) + col + 1; // _rowIndex * 64 + col + 1
                recipientsExtension.mock_call__reviewRecipientStatus(
                    Status(newStatus), Status(currentStatus), recipientIndex, Status.Accepted
                );
            }
        }

        uint256 reviewedFullRow = recipientsExtension.call__processStatusRow(_rowIndex, _fullRow);

        for (uint256 col = 0; col < 64; col++) {
            uint256 colIndex = col << 2; // col * 4
            uint8 newStatus = uint8((reviewedFullRow >> colIndex) & 0xF);
            uint8 proposedStatus = uint8((_fullRow >> colIndex) & 0xF);
            if (proposedStatus == 0) {
                assertEq(newStatus, uint8(Status.None));
            } else {
                assertEq(newStatus, uint8(Status.Accepted));
            }
        }
    }

    function test_Call__reviewRecipientStatus(uint256 _fullRow) public {
        uint8[] memory _statusValues;
        (_fullRow, _statusValues) = _boundStatuses(_fullRow);

        uint256 _rowIndex = 0;
        uint256 currentRow = recipientsExtension.statusesBitMap(_rowIndex);
        for (uint256 col = 0; col < 64; ++col) {
            // Extract the status at the column index
            uint256 colIndex = col << 2; // col * 4
            uint8 newStatus = uint8((_fullRow >> colIndex) & 0xF);
            uint8 currentStatus = uint8((currentRow >> colIndex) & 0xF);

            // Only do something if the status is being modified
            if (newStatus != currentStatus) {
                uint256 recipientIndex = (_rowIndex << 6) + col + 1; // _rowIndex * 64 + col + 1
                recipientsExtension.expectCall__reviewRecipientStatus(
                    Status(newStatus), Status(currentStatus), recipientIndex
                );
            }
        }

        recipientsExtension.call__processStatusRow(0, _fullRow);
    }

    function _boundStatuses(uint256 _fullRow) internal view returns (uint256, uint8[] memory) {
        uint8[] memory _statusValues = new uint8[](64);
        for (uint256 col = 0; col < 64; col++) {
            uint256 colIndex = col << 2; // col * 4
            uint8 newStatus = uint8((_fullRow >> colIndex) & 0xF);
            newStatus = uint8(bound(newStatus, 0, 6)); // max enum value = 6
            _statusValues[col] = newStatus;

            uint256 reviewedRow = _fullRow & ~(0xF << colIndex);
            _fullRow = reviewedRow | (uint256(newStatus) << colIndex);
        }
        return (_fullRow, _statusValues);
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
        emit IRecipientsExtension.RegistrationTimestampsUpdated(_registrationStartTime, _registrationEndTime, _caller);

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
    function test_Revert_IfNotActiveRegistration(address[] memory _recipients, bytes memory _data, address _sender)
        public
    {
        recipientsExtension.set_registrationStartTime(uint64(block.timestamp + 1));

        vm.expectRevert(Errors.REGISTRATION_NOT_ACTIVE.selector);

        recipientsExtension.call__register(_recipients, _data, _sender);
    }

    function test_Call__extractRecipientAndMetadata(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        Metadata[10] memory _metadatas,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], _metadatas[i]);
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], _metadatas[i], bytes("")
            );
            // expect the calls
            recipientsExtension.expectCall__extractRecipientAndMetadata(_dataArray[i], _sender);
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Revert_RecipientZeroAddress(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        Metadata[10] memory _metadatas,
        address _sender
    ) public {
        _recipients[0] = address(0);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], _metadatas[i]);
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], _metadatas[i], bytes("")
            );
        }

        vm.expectRevert(abi.encodeWithSelector(Errors.RECIPIENT_ERROR.selector, _recipientIds[0]));

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Revert_IfMetadataRequiredAndMetadataPointerIsEmpty(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        recipientsExtension.set_metadataRequired(true);
        _assumeNotZeroAddressInArray(_recipients);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 1, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 1, pointer: ""}), bytes("")
            );
        }

        vm.expectRevert(Errors.INVALID_METADATA.selector);

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Revert_IfMetadataRequiredAndMetadataProtocolIsEmpty(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        recipientsExtension.set_metadataRequired(true);
        _assumeNotZeroAddressInArray(_recipients);

        bytes[] memory _dataArray = new bytes[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: "0x"}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i],
                _sender,
                _recipientIds[i],
                _booleans[i],
                Metadata({protocol: 0, pointer: "0x"}),
                bytes("")
            );
        }

        vm.expectRevert(Errors.INVALID_METADATA.selector);

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Set_recipientAddress(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);

        for (uint256 i = 0; i < _recipients.length; i++) {
            assertEq(recipientsExtension.getRecipient(_recipientIds[i]).recipientAddress, _recipients[i]);
        }
    }

    function test_Set_metadata(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        Metadata[10] memory _metadatas,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], _metadatas[i]);
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], _metadatas[i], bytes("")
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);

        for (uint256 i = 0; i < _recipients.length; i++) {
            assertEq(recipientsExtension.getRecipient(_recipientIds[i]).metadata.pointer, _metadatas[i].pointer);
            assertEq(recipientsExtension.getRecipient(_recipientIds[i]).metadata.protocol, _metadatas[i].protocol);
        }
    }

    function test_Set_useRegistryAnchor(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);

        for (uint256 i = 0; i < _recipients.length; i++) {
            assertEq(recipientsExtension.getRecipient(_recipientIds[i]).useRegistryAnchor, _booleans[i]);
        }
    }

    function test_Set_recipientsCounterIfRegisteringNewApplication(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
        }
        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);

        for (uint256 i = 0; i < _recipients.length; i++) {
            Recipient memory recipient = recipientsExtension.getRecipient(_recipientIds[i]);
            assertEq(recipient.statusIndex, uint64(i + 1));
        }
    }

    function test_Call__setRecipientStatusIfRegisteringNewApplication(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            // expect the calls
            recipientsExtension.expectCall__setRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Pending)
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Emit_eventIfRegisteringNewApplication(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _eventDataArray = new bytes[](_recipients.length);
        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            _eventDataArray[i] = abi.encode(_dataArray[i], i + 1);
        }

        // expect the events
        for (uint256 i = 0; i < _recipients.length; i++) {
            vm.expectEmit();
            emit Registered(_recipientIds[i], _eventDataArray[i]);
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Increase_recipientsCounterIfRegisteringNewApplication(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
        }

        uint256 _recipientsCounterBefore = recipientsExtension.recipientsCounter();

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);

        assertEq(recipientsExtension.recipientsCounter(), _recipientsCounterBefore + _recipientIds.length);
    }

    function test_Call__getUintRecipientStatusIfUpdatingApplication(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            // set the index to simulate updating
            recipientsExtension.set_recipientToStatusIndexes(_recipientIds[i], uint64(i + 1));
        }

        recipientsExtension.expectCall__getUintRecipientStatus(_recipientIds[0]);

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Call__setRecipientStatusIfAcceptedApplication(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            // set the index to simulate updating
            recipientsExtension.set_recipientToStatusIndexes(_recipientIds[i], uint64(i + 1));

            // mock status
            recipientsExtension.mock_call__getUintRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Accepted)
            );

            // expect call
            recipientsExtension.mock_call__setRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Pending)
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Call__setRecipientStatusIfInReviewApplication(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            // set the index to simulate updating
            recipientsExtension.set_recipientToStatusIndexes(_recipientIds[i], uint64(i + 1));

            // mock status
            recipientsExtension.mock_call__getUintRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.InReview)
            );

            // expect call
            recipientsExtension.mock_call__setRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Pending)
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Call__setRecipientStatusIfRejectedApplication(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            // set the index to simulate updating
            recipientsExtension.set_recipientToStatusIndexes(_recipientIds[i], uint64(i + 1));
            // mock status
            recipientsExtension.mock_call__getUintRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Rejected)
            );
            // expect call
            recipientsExtension.mock_call__setRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Appealed)
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Emit_UpdatedRegistration(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            // set the index to simulate updating
            recipientsExtension.set_recipientToStatusIndexes(_recipientIds[i], uint64(i + 1));

            // mock status
            recipientsExtension.mock_call__getUintRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Pending)
            );
        }

        // expect the events
        for (uint256 i = 0; i < _recipients.length; i++) {
            vm.expectEmit();
            emit IRecipientsExtension.UpdatedRegistration(
                _recipientIds[i], _dataArray[i], _sender, uint8(IRecipientsExtension.Status.Pending)
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test_Return_recipientIds(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) public {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        address[] memory _receivedRecipients =
            recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);

        for (uint256 i = 0; i < _recipients.length; i++) {
            assertEq(_receivedRecipients[i], _recipientIds[i]);
        }
    }
}

contract RecipientsExtension_extractRecipientAndMetadata is BaseRecipientsExtensionUnit {
    function test_Revert_IfRecipientIdOrRegistryAnchorIsNotMember(
        address _recipientIdOrRegistryAnchor,
        address _sender,
        Metadata memory _metadata
    ) public {
        vm.assume(_recipientIdOrRegistryAnchor != address(0));

        bytes memory _data = abi.encode(_recipientIdOrRegistryAnchor, _metadata, bytes(""));
        recipientsExtension.mock_call__isProfileMember(_recipientIdOrRegistryAnchor, _sender, false);

        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        recipientsExtension.call__extractRecipientAndMetadata(_data, _sender);
    }

    function test_Return_ValuesWhenRecipientIdOrRegistryAnchorNotZero(
        address _recipientIdOrRegistryAnchor,
        address _sender,
        Metadata memory _metadata
    ) public {
        vm.assume(_recipientIdOrRegistryAnchor != address(0));
        bytes memory _data = abi.encode(_recipientIdOrRegistryAnchor, _metadata, bytes(""));
        recipientsExtension.mock_call__isProfileMember(_recipientIdOrRegistryAnchor, _sender, true);

        (address __registryOrAnchor, bool _isUsingRegistryAnchor, Metadata memory __metadata, bytes memory _extraData) =
            recipientsExtension.call__extractRecipientAndMetadata(_data, _sender);

        assertEq(__registryOrAnchor, _recipientIdOrRegistryAnchor);
        assertEq(__metadata.pointer, _metadata.pointer);
        assertEq(__metadata.protocol, _metadata.protocol);
        assertEq(_isUsingRegistryAnchor, true);
        assertEq(_extraData.length, 0);
    }

    function test_Return_ValuesWhenRecipientIdOrRegistryAnchorIsZero(address _sender, Metadata memory _metadata)
        public
    {
        bytes memory _data = abi.encode(address(0), _metadata, bytes(""));

        (address __registryOrAnchor, bool _isUsingRegistryAnchor, Metadata memory __metadata, bytes memory _extraData) =
            recipientsExtension.call__extractRecipientAndMetadata(_data, _sender);

        assertEq(__registryOrAnchor, _sender);
        assertEq(__metadata.pointer, _metadata.pointer);
        assertEq(__metadata.protocol, _metadata.protocol);
        assertEq(_isUsingRegistryAnchor, false);
        assertEq(_extraData.length, 0);
    }
}

contract RecipientsExtension_getRecipient is BaseRecipientsExtensionUnit {
    function test_Return_recipient(address _recipientId, Recipient memory _recipient) public {
        recipientsExtension.set__recipients(_recipientId, _recipient);

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
        _recipientIndex = bound(_recipientIndex, 1, type(uint64).max);
        uint256 _recipientIndexMinusOne = _recipientIndex - 1;
        vm.assume(_recipientIndexMinusOne > 64);

        uint256 _rowIndex = _recipientIndexMinusOne / 64;
        recipientsExtension.set_recipientToStatusIndexes(_recipientId, uint64(_recipientIndex));
        recipientsExtension.set_statusesBitMap(_rowIndex, _currentRow);

        (uint256 __rowIndex, uint256 _colIndex, uint256 __currentRow) =
            recipientsExtension.call__getStatusRowColumn(_recipientId);
        assertEq(_rowIndex, __rowIndex);
        assertEq(_colIndex, (_recipientIndexMinusOne % 64) * 4);
        assertEq(_currentRow, __currentRow);
    }
}
