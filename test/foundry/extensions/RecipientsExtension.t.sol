// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockStrategyRecipientsExtension} from "../../utils/MockStrategyRecipientsExtension.sol";
import {IRecipientsExtension} from "../../../contracts/extensions/interfaces/IRecipientsExtension.sol";

abstract contract BaseRecipientsExtensionUnit is Test {
    MockStrategyRecipientsExtension public recipientsExtension;
    address public allo;

    function setUp() internal virtual {
        allo = makeAddr("allo");
        recipientsExtension = new MockStrategyRecipientsExtension(allo);

        recipientsExtension.initialize(
            1,
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

contract RecipientsExtension__RecipientsExtension_init is BaseRecipientsExtensionUnit {}

contract RecipientsExtensionGetRecipient is BaseRecipientsExtensionUnit {}

contract RecipientsExtension_getRecipientStatus is BaseRecipientsExtensionUnit {}

contract RecipientsExtensionReviewRecipients is BaseRecipientsExtensionUnit {}

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
