// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {IRecipientsExtension} from "contracts/strategies/extensions/register/IRecipientsExtension.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {MockMockRecipientsExtension} from "test/smock/MockMockRecipientsExtension.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {IBaseStrategy} from "contracts/strategies/IBaseStrategy.sol";

contract RecipientsExtensionUnit is Test {
    MockMockRecipientsExtension recipientsExtension;

    function setUp() public {
        recipientsExtension = new MockMockRecipientsExtension(address(0), "MockRecipientsExtension", true);
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

    function test___RecipientsExtension_initWhenParametersAreValid(
        IRecipientsExtension.RecipientInitializeData memory _initData
    ) external {
        recipientsExtension.mock_call__updatePoolTimestamps(
            _initData.registrationStartTime, _initData.registrationEndTime
        );

        // It should call _updatePoolTimestamps
        recipientsExtension.expectCall__updatePoolTimestamps(
            _initData.registrationStartTime, _initData.registrationEndTime
        );

        recipientsExtension.call___RecipientsExtension_init(_initData);

        // It should set metadataRequired
        assertEq(recipientsExtension.metadataRequired(), _initData.metadataRequired);

        // It should set recipientsCounter to 1
        assertEq(recipientsExtension.recipientsCounter(), 1);
    }

    function test_GetRecipientWhenParametersAreValid(
        address _recipientId,
        IRecipientsExtension.Recipient memory _recipient
    ) external {
        recipientsExtension.mock_call__getRecipient(_recipientId, _recipient);

        // It should call _getRecipient
        recipientsExtension.expectCall__getRecipient(_recipientId);

        // It should return the recipient
        IRecipientsExtension.Recipient memory recipient = recipientsExtension.call__getRecipient(_recipientId);
        assertEq(recipient.useRegistryAnchor, _recipient.useRegistryAnchor);
        assertEq(recipient.recipientAddress, _recipient.recipientAddress);
        assertEq(recipient.statusIndex, _recipient.statusIndex);
        assertEq(recipient.metadata.protocol, _recipient.metadata.protocol);
        assertEq(recipient.metadata.pointer, _recipient.metadata.pointer);
    }

    function test__getRecipientStatusWhenParametersAreValid(address _recipientId, uint8 _statusRawEnum) external {
        vm.assume(_statusRawEnum <= 6);
        recipientsExtension.mock_call__getUintRecipientStatus(_recipientId, _statusRawEnum);

        // It should call _getUintRecipientStatus
        recipientsExtension.expectCall__getUintRecipientStatus(_recipientId);

        // It should return the recipient status
        IRecipientsExtension.Status status = recipientsExtension.call__getRecipientStatus(_recipientId);
        assertEq(uint8(status), _statusRawEnum);
    }

    function test__isProfileMemberWhenParametersAreValid(
        address _anchor,
        address _sender,
        bool _result,
        address _registry,
        IRegistry.Profile memory _profile
    ) external {
        vm.assume(_registry != address(0));
        vm.assume(_registry != address(vm));

        vm.mockCall(address(0), abi.encodeWithSelector(IAllo.getRegistry.selector), abi.encode(_registry));
        vm.mockCall(
            _registry, abi.encodeWithSelector(IRegistry.getProfileByAnchor.selector, _anchor), abi.encode(_profile)
        );
        vm.mockCall(
            _registry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profile.id, _sender),
            abi.encode(_result)
        );

        // It should call getRegistry on allo
        vm.expectCall(address(0), abi.encodeWithSelector(IAllo.getRegistry.selector));

        // It should call getProfileByAnchor on registry
        vm.expectCall(_registry, abi.encodeWithSelector(IRegistry.getProfileByAnchor.selector, _anchor));

        // It should call isOwnerOrMemberOfProfile on registry
        vm.expectCall(
            _registry, abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profile.id, _sender)
        );

        // It should return the result
        bool isProfileMember = recipientsExtension.call__isProfileMember(_anchor, _sender);
        assertEq(isProfileMember, _result);
    }

    function test_ReviewRecipientsWhenParametersAreValid(IRecipientsExtension.ApplicationStatus[] memory _statuses)
        external
    {
        _statuses = _boundStatuses(_statuses);
        recipientsExtension.mock_call__validateReviewRecipients(address(this));
        for (uint256 i = 0; i < _statuses.length; i++) {
            recipientsExtension.mock_call__processStatusRow(
                _statuses[i].index, _statuses[i].statusRow, _statuses[i].statusRow
            );
        }

        // It should call _validateReviewRecipients
        recipientsExtension.expectCall__validateReviewRecipients(address(this));

        // It should call _processStatusRow on each status
        for (uint256 i = 0; i < _statuses.length; i++) {
            recipientsExtension.expectCall__processStatusRow(_statuses[i].index, _statuses[i].statusRow);
        }

        // It should emit the event
        for (uint256 i = 0; i < _statuses.length; i++) {
            vm.expectEmit();
            emit IRecipientsExtension.RecipientStatusUpdated(_statuses[i].index, _statuses[i].statusRow, address(this));
        }

        recipientsExtension.reviewRecipients(_statuses, recipientsExtension.recipientsCounter());

        // It should update the statusesBitMap
        for (uint256 i = 0; i < _statuses.length; i++) {
            assertEq(recipientsExtension.statusesBitMap(_statuses[i].index), _statuses[i].statusRow);
        }
    }

    function test_ReviewRecipientsRevertWhen_RefRecipientsCounterIsDifferentFromRecipientsCounter(
        uint256 _refRecipientsCounter
    ) external {
        vm.assume(_refRecipientsCounter != recipientsExtension.recipientsCounter());
        recipientsExtension.mock_call__validateReviewRecipients(address(this));

        // It should revert
        vm.expectRevert(Errors.INVALID.selector);

        recipientsExtension.reviewRecipients(new IRecipientsExtension.ApplicationStatus[](0), _refRecipientsCounter);
    }

    function test_UpdatePoolTimestampsWhenParametersAreValid(uint64 _registrationStartTime, uint64 _registrationEndTime)
        external
    {
        recipientsExtension.mock_call__checkOnlyPoolManager(address(this));
        recipientsExtension.mock_call__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);

        // It should call _checkOnlyPoolManager
        recipientsExtension.expectCall__checkOnlyPoolManager(address(this));

        // It should call _updatePoolTimestamps
        recipientsExtension.expectCall__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);

        recipientsExtension.updatePoolTimestamps(_registrationStartTime, _registrationEndTime);
    }

    function test__updatePoolTimestampsWhenParametersAreValid(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime
    ) external {
        recipientsExtension.mock_call__isPoolTimestampValid(_registrationStartTime, _registrationEndTime);

        // It should call _isPoolTimestampValid
        recipientsExtension.expectCall__isPoolTimestampValid(_registrationStartTime, _registrationEndTime);

        // It should emit event
        vm.expectEmit();
        emit IRecipientsExtension.RegistrationTimestampsUpdated(
            _registrationStartTime, _registrationEndTime, address(this)
        );

        recipientsExtension.call__updatePoolTimestamps(_registrationStartTime, _registrationEndTime);

        // It should set registrationStartTime
        assertEq(recipientsExtension.registrationStartTime(), _registrationStartTime);

        // It should set registrationEndTime
        assertEq(recipientsExtension.registrationEndTime(), _registrationEndTime);
    }

    function test__checkOnlyActiveRegistrationWhenParametersAreCorrect(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _blockTimestamp
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_registrationStartTime < _blockTimestamp);
        vm.assume(_registrationEndTime > _blockTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);
        vm.warp(_blockTimestamp);

        // It should execute successfully
        recipientsExtension.call__checkOnlyActiveRegistration();
    }

    function test__checkOnlyActiveRegistrationRevertWhen_RegistrationStartTimeIsMoreThanBlockTimestamp(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _blockTimestamp
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_registrationStartTime > _blockTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);
        vm.warp(_blockTimestamp);

        // It should revert
        vm.expectRevert(IRecipientsExtension.RecipientsExtension_RegistrationNotActive.selector);

        recipientsExtension.call__checkOnlyActiveRegistration();
    }

    function test__checkOnlyActiveRegistrationRevertWhen_RegistrationEndTimeIsLessThanBlockTimestamp(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _blockTimestamp
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_registrationEndTime < _blockTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);
        vm.warp(_blockTimestamp);

        // It should revert
        vm.expectRevert(IRecipientsExtension.RecipientsExtension_RegistrationNotActive.selector);

        recipientsExtension.call__checkOnlyActiveRegistration();
    }

    function test__isPoolTimestampValidWhenParametersAreRight(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);

        // It should execute successfully
        recipientsExtension.call__isPoolTimestampValid(_registrationStartTime, _registrationEndTime);
    }

    function test__isPoolTimestampValidRevertWhen_RegistrationStartTimeIsMoreThanRegistrationEndTime(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime
    ) external {
        vm.assume(_registrationStartTime > _registrationEndTime);

        // It should revert
        vm.expectRevert(Errors.INVALID.selector);

        recipientsExtension.call__isPoolTimestampValid(_registrationStartTime, _registrationEndTime);
    }

    function test__isPoolActiveWhenCurrentTimestampIsBetweenRegistrationStartTimeAndRegistrationEndTime(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _blockTimestamp
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_registrationStartTime < _blockTimestamp);
        vm.assume(_registrationEndTime > _blockTimestamp);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);
        vm.warp(_blockTimestamp);

        // It should return true
        assertTrue(recipientsExtension.call__isPoolActive());
    }

    function test__isPoolActiveWhenCurrentTimestampIsLessThanRegistrationStartTimeOrMoreThanRegistrationEndTime(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _blockTimestamp
    ) external {
        vm.assume(_registrationStartTime < _registrationEndTime);
        vm.assume(_blockTimestamp < _registrationStartTime || _blockTimestamp > _registrationEndTime);
        recipientsExtension.set_registrationStartTime(_registrationStartTime);
        recipientsExtension.set_registrationEndTime(_registrationEndTime);
        vm.warp(_blockTimestamp);

        // It should return false
        assertFalse(recipientsExtension.call__isPoolActive());
    }

    function test__registerWhenParametersAreValid() external {
        recipientsExtension.mock_call__checkOnlyActiveRegistration();

        // It should call _checkOnlyActiveRegistration
        recipientsExtension.expectCall__checkOnlyActiveRegistration();

        recipientsExtension.call__register(new address[](0), abi.encode(new bytes[](0)), address(0));
    }

    modifier whenIteratingEachRecipient() {
        recipientsExtension.mock_call__checkOnlyActiveRegistration();
        _;
    }

    function test__registerWhenIteratingEachRecipient(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        Metadata[10] memory _metadatas,
        address _sender
    ) external whenIteratingEachRecipient {
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], _metadatas[i]);
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], _metadatas[i], bytes("")
            );
            recipientsExtension.mock_call__processRecipient(_recipientIds[i], _booleans[i], _metadatas[i], bytes(""));
            recipientsExtension.mock_call__setRecipientStatus(
                _recipientIds[0], uint8(IRecipientsExtension.Status.Pending)
            );

            // It should call _extractRecipientAndMetadata
            recipientsExtension.expectCall__extractRecipientAndMetadata(_dataArray[i], _sender);

            // It should call _processRecipient
            recipientsExtension.expectCall__processRecipient(_recipientIds[i], _booleans[i], _metadatas[i], bytes(""));
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);

        // It should set recipient struct
        for (uint256 i = 0; i < _recipients.length; i++) {
            IRecipientsExtension.Recipient memory recipient = recipientsExtension.getRecipient(_recipientIds[i]);
            assertEq(recipient.useRegistryAnchor, _booleans[i]);
            assertEq(recipient.recipientAddress, _recipients[i]);
            assertEq(recipient.metadata.protocol, _metadatas[i].protocol);
            assertEq(recipient.metadata.pointer, _metadatas[i].pointer);
        }

        // It should save recipientId in the array
        for (uint256 i = 0; i < _recipients.length; i++) {
            assertEq(recipientsExtension.recipientIndexToRecipientId(i), _recipientIds[i]);
        }
    }

    function test__registerRevertWhen_RecipientAddressIsAddressZero(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        Metadata[10] memory _metadatas,
        address _sender
    ) external whenIteratingEachRecipient {
        _recipients[0] = address(0);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], _metadatas[i]);
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], _metadatas[i], bytes("")
            );
            recipientsExtension.mock_call__processRecipient(_recipientIds[i], _booleans[i], _metadatas[i], bytes(""));
        }

        // It should revert
        vm.expectRevert(
            abi.encodeWithSelector(IRecipientsExtension.RecipientsExtension_RecipientError.selector, _recipientIds[0])
        );

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test__registerRevertWhen_MetadataRequiredIsTrueAndTheMetadataIsInvalid(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) external whenIteratingEachRecipient {
        recipientsExtension.set_metadataRequired(true);
        _assumeNotZeroAddressInArray(_recipients);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
        }

        // It should revert
        vm.expectRevert(IRecipientsExtension.RecipientsExtension_InvalidMetada.selector);

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test__registerWhenStatusIndexIsZero(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) external whenIteratingEachRecipient {
        recipientsExtension.set_metadataRequired(false);
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        recipientsExtension.set_recipientsCounter(1); // Initialize recipientsCounter

        bytes[] memory _eventDataArray = new bytes[](_recipients.length);
        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            recipientsExtension.mock_call__setRecipientStatus(
                _recipientIds[0], uint8(IRecipientsExtension.Status.Pending)
            );

            _eventDataArray[i] = abi.encode(_dataArray[i], i + 1);

            // It should call _setRecipientStatus
            recipientsExtension.expectCall__setRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Pending)
            );
        }

        for (uint256 i = 0; i < _recipients.length; i++) {
            // It should emit event
            vm.expectEmit();
            emit IBaseStrategy.Registered(_recipientIds[i], _eventDataArray[i]);
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);

        for (uint256 i = 0; i < _recipients.length; i++) {
            // It should set statusIndex
            IRecipientsExtension.Recipient memory recipient = recipientsExtension.getRecipient(_recipientIds[i]);
            assertEq(recipient.statusIndex, i + 1);

            // It should set recipientIndexToRecipientId mapping
            assertEq(recipientsExtension.recipientIndexToRecipientId(i + 1), _recipientIds[i]);
        }

        // It should increment recipientsCounter
        assertEq(recipientsExtension.recipientsCounter(), _recipients.length + 1);
    }

    modifier whenStatusIndexIsDifferentThanZero() {
        // This modifier was auto-generated by bulloak
        _;
    }

    function test__registerWhenStatusIndexIsDifferentThanZero(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) external whenIteratingEachRecipient whenStatusIndexIsDifferentThanZero {
        recipientsExtension.set_metadataRequired(false);
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            recipientsExtension.mock_call__setRecipientStatus(
                _recipientIds[0], uint8(IRecipientsExtension.Status.Pending)
            );
            recipientsExtension.mock_call__getUintRecipientStatus(_recipientIds[i], 2);
            recipientsExtension.set__recipients(
                _recipientIds[i],
                IRecipientsExtension.Recipient({
                    useRegistryAnchor: false,
                    recipientAddress: address(0),
                    statusIndex: uint64(i + 1),
                    metadata: Metadata({protocol: 0, pointer: ""})
                })
            );

            // It should call _getUintRecipientStatus
            recipientsExtension.expectCall__getUintRecipientStatus(_recipientIds[i]);

            // It should call _getUintRecipientStatus
            recipientsExtension.expectCall__getUintRecipientStatus(_recipientIds[i]);
        }

        for (uint256 i = 0; i < _recipients.length; i++) {
            // It should emit event
            vm.expectEmit();
            emit IRecipientsExtension.UpdatedRegistration(_recipientIds[i], _dataArray[i], _sender, 2);
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test__registerWhenCurrentStatusIsAcceptedOrInReview(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) external whenIteratingEachRecipient whenStatusIndexIsDifferentThanZero {
        recipientsExtension.set_metadataRequired(false);
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            recipientsExtension.set__recipients(
                _recipientIds[i],
                IRecipientsExtension.Recipient({
                    useRegistryAnchor: false,
                    recipientAddress: address(0),
                    statusIndex: uint64(i + 1),
                    metadata: Metadata({protocol: 0, pointer: ""})
                })
            );
            // Half of the recipients will have status Accepted and the other half InReview
            uint8 currentStatus =
                i % 2 == 0 ? uint8(IRecipientsExtension.Status.Accepted) : uint8(IRecipientsExtension.Status.InReview);
            recipientsExtension.mock_call__getUintRecipientStatus(_recipientIds[i], currentStatus);
            recipientsExtension.mock_call__setRecipientStatus(
                _recipientIds[0], uint8(IRecipientsExtension.Status.Pending)
            );

            // It should call _setRecipientStatus with correct parameters
            recipientsExtension.expectCall__setRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Pending)
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test__registerWhenCurrentStatusIsRejected(
        address[10] memory _recipients,
        address[10] memory _recipientIds,
        bool[10] memory _booleans,
        address _sender
    ) external whenIteratingEachRecipient whenStatusIndexIsDifferentThanZero {
        recipientsExtension.set_metadataRequired(false);
        _assumeNotZeroAddressInArray(_recipients);
        _assumeNoDuplicates(_recipientIds);

        bytes[] memory _dataArray = new bytes[](_recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            _dataArray[i] = abi.encode(_recipientIds[i], Metadata({protocol: 0, pointer: ""}));
            // mock the calls
            recipientsExtension.mock_call__extractRecipientAndMetadata(
                _dataArray[i], _sender, _recipientIds[i], _booleans[i], Metadata({protocol: 0, pointer: ""}), bytes("")
            );
            recipientsExtension.set__recipients(
                _recipientIds[i],
                IRecipientsExtension.Recipient({
                    useRegistryAnchor: false,
                    recipientAddress: address(0),
                    statusIndex: uint64(i + 1),
                    metadata: Metadata({protocol: 0, pointer: ""})
                })
            );
            recipientsExtension.mock_call__getUintRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Rejected)
            );
            recipientsExtension.mock_call__setRecipientStatus(
                _recipientIds[0], uint8(IRecipientsExtension.Status.Appealed)
            );

            // It should call _setRecipientStatus with correct parameters
            recipientsExtension.expectCall__setRecipientStatus(
                _recipientIds[i], uint8(IRecipientsExtension.Status.Appealed)
            );
        }

        bytes memory _datas = abi.encode(_dataArray);
        recipientsExtension.call__register(_fixedArrayToMemory(_recipients), _datas, _sender);
    }

    function test__extractRecipientAndMetadataWhenParametersAreValid(
        address _recipientIdOrRegistryAnchor,
        address _sender,
        Metadata memory _metadata
    ) external {
        bytes memory _data = abi.encode(_recipientIdOrRegistryAnchor, _metadata, bytes(""));
        recipientsExtension.mock_call__isProfileMember(_recipientIdOrRegistryAnchor, _sender, true);

        (,, Metadata memory __metadata, bytes memory _extraData) =
            recipientsExtension.call__extractRecipientAndMetadata(_data, _sender);

        // It should return metadata
        assertEq(__metadata.pointer, _metadata.pointer);
        assertEq(__metadata.protocol, _metadata.protocol);

        // It should return extraData
        assertEq(_extraData.length, 0);
    }

    struct _extractRecipientAndMetadataParam {
        address recipientIdOrRegistryAnchor;
    }

    modifier whenDecoded_recipientIdOrRegistryAnchorIsNotZero(_extractRecipientAndMetadataParam memory _param) {
        vm.assume(_param.recipientIdOrRegistryAnchor != address(0));
        _;
    }

    function test__extractRecipientAndMetadataWhenDecoded_recipientIdOrRegistryAnchorIsNotZero(
        address _sender,
        Metadata memory _metadata,
        _extractRecipientAndMetadataParam memory _param
    ) external whenDecoded_recipientIdOrRegistryAnchorIsNotZero(_param) {
        bytes memory _data = abi.encode(_param.recipientIdOrRegistryAnchor, _metadata, bytes(""));
        recipientsExtension.mock_call__isProfileMember(_param.recipientIdOrRegistryAnchor, _sender, true);

        // It should call _isProfileMember
        recipientsExtension.expectCall__isProfileMember(_param.recipientIdOrRegistryAnchor, _sender);

        (address recipientId, bool isUsingRegistryAnchor,,) =
            recipientsExtension.call__extractRecipientAndMetadata(_data, _sender);

        // It should set isUsingRegistryAnchor as true
        assertTrue(isUsingRegistryAnchor);

        // It should set recipientId as _recipientIdOrRegistryAnchor
        assertEq(recipientId, _param.recipientIdOrRegistryAnchor);
    }

    function test__extractRecipientAndMetadataRevertWhen_IsNotAProfileMember(
        address _recipientIdOrRegistryAnchor,
        address _sender,
        Metadata memory _metadata,
        _extractRecipientAndMetadataParam memory _param
    ) external whenDecoded_recipientIdOrRegistryAnchorIsNotZero(_param) {
        bytes memory _data = abi.encode(_param.recipientIdOrRegistryAnchor, _metadata, bytes(""));
        recipientsExtension.mock_call__isProfileMember(_param.recipientIdOrRegistryAnchor, _sender, false);

        // It should revert
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        recipientsExtension.call__extractRecipientAndMetadata(_data, _sender);
    }

    function test__extractRecipientAndMetadataWhenDecoded_recipientIdOrRegistryAnchorIsEqualZero(
        address _sender,
        Metadata memory _metadata
    ) external {
        bytes memory _data = abi.encode(address(0), _metadata, bytes(""));
        (address recipientId,,,) = recipientsExtension.call__extractRecipientAndMetadata(_data, _sender);

        // It should set recipientId as sender
        assertEq(recipientId, _sender);
    }

    function test__getRecipientShouldReturnTheRecipient(
        address _recipientId,
        IRecipientsExtension.Recipient memory _recipient
    ) external {
        recipientsExtension.set__recipients(_recipientId, _recipient);

        // It should return the recipient
        IRecipientsExtension.Recipient memory recipient = recipientsExtension.call__getRecipient(_recipientId);
        assertEq(recipient.useRegistryAnchor, _recipient.useRegistryAnchor);
        assertEq(recipient.recipientAddress, _recipient.recipientAddress);
        assertEq(recipient.statusIndex, _recipient.statusIndex);
        assertEq(recipient.metadata.protocol, _recipient.metadata.protocol);
        assertEq(recipient.metadata.pointer, _recipient.metadata.pointer);
    }

    function test__setRecipientStatusWhenParametersAreValid(
        address _recipientId,
        uint256 _status,
        uint256 _rowIndex,
        uint256 _colIndex,
        uint256 _currentRow
    ) external {
        recipientsExtension.mock_call__getStatusRowColumn(_recipientId, _rowIndex, _colIndex, _currentRow);

        // It should call _getStatusRowColumn
        recipientsExtension.expectCall__getStatusRowColumn(_recipientId);

        recipientsExtension.call__setRecipientStatus(_recipientId, _status);

        uint256 newRow = _currentRow & ~(15 << _colIndex);

        // It should set statusesBitMap
        assertEq(recipientsExtension.statusesBitMap(_rowIndex), newRow | (_status << _colIndex));
    }

    function test__getUintRecipientStatusWhenParametersAreValid(
        address _recipient,
        uint256 _colIndex,
        uint256 _currentRow
    ) external {
        recipientsExtension.set_recipientToStatusIndexes(_recipient, 1); // force to return more than zero
        recipientsExtension.mock_call__getStatusRowColumn(_recipient, 0, _colIndex, _currentRow);

        // It should call _getStatusRowColumn
        recipientsExtension.expectCall__getStatusRowColumn(_recipient);

        // It should return the status
        uint8 _status = recipientsExtension.call__getUintRecipientStatus(_recipient);
        assertEq(_status, uint8((_currentRow >> _colIndex) & 15));
    }

    function test__getUintRecipientStatusWhenStatusIndexIsZero(address _recipient) external {
        // It should return zero
        recipientsExtension.set_recipientToStatusIndexes(_recipient, 0);
        assertEq(recipientsExtension.call__getUintRecipientStatus(_recipient), 0);
    }

    function test__getStatusRowColumnShouldReturnRowIndexColIndexAndTheValueFromTheBitmap(
        address _recipientId,
        uint256 _recipientIndex,
        uint256 _currentRow
    ) external {
        _recipientIndex = bound(_recipientIndex, 1, type(uint64).max);
        uint256 _recipientIndexMinusOne = _recipientIndex - 1;
        vm.assume(_recipientIndexMinusOne > 64);

        uint256 _rowIndex = _recipientIndexMinusOne / 64;
        recipientsExtension.set_recipientToStatusIndexes(_recipientId, uint64(_recipientIndex));
        recipientsExtension.set_statusesBitMap(_rowIndex, _currentRow);

        // It should return rowIndex, colIndex and the value from the bitmap
        (uint256 __rowIndex, uint256 _colIndex, uint256 __currentRow) =
            recipientsExtension.call__getStatusRowColumn(_recipientId);
        assertEq(_rowIndex, __rowIndex);
        assertEq(_colIndex, (_recipientIndexMinusOne % 64) * 4);
        assertEq(_currentRow, __currentRow);
    }

    modifier whenTheNewStatusIsDifferentThanTheCurrentStatus() {
        // This modifier was auto-generated by bulloak
        _;
    }

    function test__processStatusRowWhenTheNewStatusIsDifferentThanTheCurrentStatus(uint256 _fullRow)
        external
        whenTheNewStatusIsDifferentThanTheCurrentStatus
    {
        uint8[] memory _statusValues;
        (_fullRow, _statusValues) = _boundStatuses(_fullRow);

        uint256 _rowIndex = 0;
        uint256 currentRow = recipientsExtension.statusesBitMap(_rowIndex);
        for (uint256 col = 0; col < 64; ++col) {
            // Extract the status at the column index
            uint256 colIndex = col << 2; // col * 4
            uint8 newStatus = uint8((_fullRow >> colIndex) & 0xF);
            uint8 currentStatus = uint8((currentRow >> colIndex) & 0xF);

            // Only test if the status is being modified
            if (newStatus == currentStatus) {
                vm.assume(false);
            }

            uint256 recipientIndex = (_rowIndex << 6) + col + 1; // _rowIndex * 64 + col + 1

            // It should call _reviewRecipientStatus
            recipientsExtension.expectCall__reviewRecipientStatus(
                IRecipientsExtension.Status(newStatus), IRecipientsExtension.Status(currentStatus), recipientIndex
            );
        }

        recipientsExtension.call__processStatusRow(0, _fullRow);
    }

    function test__processStatusRowWhenTheReviewedStatusIsDifferentThanNewStatus(
        uint256 _fullRow,
        uint8 _reviewedStatus
    ) external whenTheNewStatusIsDifferentThanTheCurrentStatus {
        vm.assume(_reviewedStatus <= 6);
        uint8[] memory _statusValues;
        (_fullRow, _statusValues) = _boundStatuses(_fullRow);

        uint256 _rowIndex = 0;

        uint256 currentRow = recipientsExtension.statusesBitMap(_rowIndex);
        for (uint256 col = 0; col < 64; ++col) {
            // Extract the status at the column index
            uint256 colIndex = col << 2; // col * 4
            uint8 newStatus = uint8((_fullRow >> colIndex) & 0xF);
            uint8 currentStatus = uint8((currentRow >> colIndex) & 0xF);

            // Only test if the status is being modified
            if (newStatus == currentStatus) {
                vm.assume(false);
            }

            uint256 recipientIndex = (_rowIndex << 6) + col + 1; // _rowIndex * 64 + col + 1
            recipientsExtension.mock_call__reviewRecipientStatus(
                IRecipientsExtension.Status(newStatus),
                IRecipientsExtension.Status(currentStatus),
                recipientIndex,
                IRecipientsExtension.Status(_reviewedStatus)
            );
        }

        uint256 reviewedFullRow = recipientsExtension.call__processStatusRow(_rowIndex, _fullRow);

        // It should update _fullRow
        for (uint256 col = 0; col < 64; col++) {
            uint256 colIndex = col << 2; // col * 4
            uint8 newStatus = uint8((reviewedFullRow >> colIndex) & 0xF);
            uint8 proposedStatus = uint8((_fullRow >> colIndex) & 0xF);
            assertEq(newStatus, _reviewedStatus);
        }
    }

    function test__validateReviewRecipientsWhenParametersAreValid(address _sender) external {
        recipientsExtension.mock_call__checkOnlyPoolManager(_sender);
        recipientsExtension.mock_call__checkOnlyActiveRegistration();

        // It should call _checkOnlyActiveRegistration
        recipientsExtension.expectCall__checkOnlyActiveRegistration();

        // It should call _checkOnlyPoolManager
        recipientsExtension.expectCall__checkOnlyPoolManager(_sender);

        recipientsExtension.call__validateReviewRecipients(_sender);
    }

    function test__reviewRecipientStatusShouldReturnTheNewStatusAs_reviewedStatus(
        uint8 _newStatus,
        uint8 _oldStatus,
        uint256 _recipientIndex
    ) external {
        vm.assume(_newStatus <= 6);
        vm.assume(_oldStatus <= 6);

        // It should return the newStatus as _reviewedStatus
        IRecipientsExtension.Status status = recipientsExtension.call__reviewRecipientStatus(
            IRecipientsExtension.Status(_newStatus), IRecipientsExtension.Status(_oldStatus), _recipientIndex
        );
        assertEq(uint8(status), _newStatus);
    }
}
