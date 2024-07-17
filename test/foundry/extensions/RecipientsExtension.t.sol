// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockStrategyRecipientsExtension} from "../../utils/MockStrategyRecipientsExtension.sol";
import {IRecipientsExtension} from "../../../contracts/extensions/interfaces/IRecipientsExtension.sol";
import {IAllo} from "../../../contracts/core/interfaces/IAllo.sol";
import {IBaseStrategy} from "../../../contracts/strategies/CoreBaseStrategy.sol";
import {Errors} from "../../../contracts/core/libraries/Errors.sol";

abstract contract BaseRecipientsExtensionUnit is Test, IRecipientsExtension {
    MockStrategyRecipientsExtension public recipientsExtension;
    address public allo;
    uint public poolId;

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
        IRecipientsExtension.RecipientInitializeData memory _initializeData = IRecipientsExtension.RecipientInitializeData({
            useRegistryAnchor: _useRegistryAnchor,
            metadataRequired: false, // irrelevant for the test
            registrationStartTime: uint64(block.timestamp), // irrelevant for the test
            registrationEndTime: uint64(block.timestamp) // irrelevant for the test
        });

        recipientsExtension.call___RecipientsExtension_init(_initializeData);

        assertEq(recipientsExtension.useRegistryAnchor(), _useRegistryAnchor);
    }

    function test_Set_metadataRequired(bool _metadataRequired) public {
        IRecipientsExtension.RecipientInitializeData memory _initializeData = IRecipientsExtension.RecipientInitializeData({
            useRegistryAnchor: false, // irrelevant for the test
            metadataRequired: _metadataRequired,
            registrationStartTime: uint64(block.timestamp), // irrelevant for the test
            registrationEndTime: uint64(block.timestamp) // irrelevant for the test
        });

        recipientsExtension.call___RecipientsExtension_init(_initializeData);

        assertEq(recipientsExtension.metadataRequired(), _metadataRequired);
    }

    function test_Call__updatePoolTimestamps(IRecipientsExtension.RecipientInitializeData memory _initializeData) public {
        vm.assume(_initializeData.registrationStartTime < _initializeData.registrationEndTime);

        recipientsExtension.expectCall__updatePoolTimestamps(_initializeData.registrationStartTime, _initializeData.registrationEndTime);

        recipientsExtension.call___RecipientsExtension_init(_initializeData);
    }

    function test_Set_recipientsCounter() public {
        IRecipientsExtension.RecipientInitializeData memory _initializeData = IRecipientsExtension.RecipientInitializeData({
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
    function test_Revert_IfCalledByNonManager(address _caller, IRecipientsExtension.ApplicationStatus[] memory _statuses, uint256 _refRecipientsCounter) public {
        // force allo to return false
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector, poolId, _caller), abi.encode(false));
        
        vm.expectRevert(IBaseStrategy.BaseStrategy_UNAUTHORIZED.selector);
        
        vm.prank(_caller);
        recipientsExtension.reviewRecipients(_statuses, _refRecipientsCounter);
    }

    function test_Revert_IfWrongRefRecipientsCounter(IRecipientsExtension.ApplicationStatus[] memory _statuses, uint256 _refRecipientsCounter, uint _recipientsCounter) public {
        vm.assume(_recipientsCounter != _refRecipientsCounter);

        // force allo to return true
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector), abi.encode(true));

        recipientsExtension.set_recipientsCounter(_recipientsCounter);

        vm.expectRevert(Errors.INVALID.selector);

        recipientsExtension.reviewRecipients(_statuses, _refRecipientsCounter);
    }

    function test_Set_statusesBitMap(IRecipientsExtension.ApplicationStatus[] memory _statuses) public {
        // prevent duplicates on the indexes
        for (uint i = 0; i < _statuses.length; i++) {
            _statuses[i].index = i;
        }

        // force allo to return true
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector), abi.encode(true));

        recipientsExtension.reviewRecipients(_statuses, 1);

        for (uint i = 0; i < _statuses.length; i++) {
            assertEq(recipientsExtension.statusesBitMap(_statuses[i].index), _statuses[i].statusRow);
        }
    }

    function test_Emit_Event(IRecipientsExtension.ApplicationStatus[] memory _statuses, address _caller) public {
        // prevent duplicates on the indexes
        for (uint i = 0; i < _statuses.length; i++) {
            _statuses[i].index = i;
        }

        // force allo to return true
        vm.mockCall(allo, abi.encodeWithSelector(IAllo.isPoolManager.selector), abi.encode(true));

        for (uint i = 0; i < _statuses.length; i++) {
            vm.expectEmit();
            emit IRecipientsExtension.RecipientStatusUpdated(_statuses[i].index, _statuses[i].statusRow, _caller);
        }

        vm.prank(_caller);
        recipientsExtension.reviewRecipients(_statuses, 1);
    }
}

contract RecipientsExtensionUpdatePoolTimestamps is BaseRecipientsExtensionUnit {}

contract RecipientsExtension_updatePoolTimestamps is BaseRecipientsExtensionUnit {}

contract RecipientsExtension_checkOnlyActiveRegistration is BaseRecipientsExtensionUnit {}

contract RecipientsExtension_isPoolTimestampValid is BaseRecipientsExtensionUnit {}

contract RecipientsExtension_isPoolActive is BaseRecipientsExtensionUnit {}

contract RecipientsExtension_register is BaseRecipientsExtensionUnit {}

contract RecipientsExtension_getRecipient is BaseRecipientsExtensionUnit {}

contract RecipientsExtension_setRecipientStatus is BaseRecipientsExtensionUnit {}

contract RecipientsExtension_getUintRecipientStatus is BaseRecipientsExtensionUnit {}

contract RecipientsExtension_getStatusRowColumn is BaseRecipientsExtensionUnit {}
