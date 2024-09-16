// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Internal Imports
import {Metadata} from "contracts/core/libraries/Metadata.sol";

interface IRecipientsExtension {
    /// @notice The Status enum that all recipients are based from
    enum Status {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed,
        InReview,
        Canceled
    }

    /// @notice Struct to hold details of the application status
    /// @dev Application status is stored in a bitmap. Each 4 bits represents the status of a recipient,
    /// defined as 'index' here. The first 4 bits of the 256 bits represent the status of the first recipient,
    /// the second 4 bits represent the status of the second recipient, and so on.
    ///
    /// The 'rowIndex' is the index of the row in the bitmap, and the 'statusRow' is the value of the row.
    /// The 'statusRow' is updated when the status of a recipient changes.
    ///
    /// Note: Since we need 4 bits to store a status, one row of the bitmap can hold the status information of 256/4 recipients.
    ///
    /// For example, if we have 5 recipients, the bitmap will look like this:
    /// | recipient1 | recipient2 | recipient3 | recipient4 | recipient5 | 'rowIndex'
    /// |     0000   |    0001    |    0010    |    0011    |    0100    | 'statusRow'
    /// |     none   |   pending  |  accepted  |  rejected  |  appealed  | converted status (0, 1, 2, 3, 4)
    /// @param index along a word
    /// @param statusRow is the word index
    struct ApplicationStatus {
        uint256 index;
        uint256 statusRow;
    }

    /// @notice Stores the details of the recipients.
    /// @param useRegistryAnchor If false, the recipientAddress is the anchor of the profile
    /// @param recipientAddress The address of the recipient
    /// @param statusIndex The index of the recipient in the 'statusesBitMap' bitmap.
    /// @param metadata The 'Metadata'
    struct Recipient {
        bool useRegistryAnchor;
        address recipientAddress;
        uint64 statusIndex;
        Metadata metadata;
    }

    /// @notice The data needed to initialize RecipientsExtension
    /// @param metadataRequired Whether the metadata is required.
    /// @param registrationStartTime The timestamp in seconds for the start time.
    /// @param registrationEndTime The timestamp in seconds for the end time.
    struct RecipientInitializeData {
        bool metadataRequired;
        uint64 registrationStartTime;
        uint64 registrationEndTime;
    }

    /// @notice Emitted when a recipient updates their registration
    /// @param recipientId Id of the recipient
    /// @param data The encoded data - (address recipientId, address recipientAddress, Metadata metadata)
    /// @param sender The sender of the transaction
    /// @param status The updated status of the recipient
    event UpdatedRegistration(address indexed recipientId, bytes data, address sender, uint8 status);

    /// @notice Emitted when a recipient is registered and the status is updated
    /// @param rowIndex The index of the row in the bitmap
    /// @param fullRow The value of the row
    /// @param sender The sender of the transaction
    event RecipientStatusUpdated(uint256 indexed rowIndex, uint256 fullRow, address sender);

    /// @notice Emitted when the registration timestamps are updated
    /// @param registrationStartTime The start time for the registration
    /// @param registrationEndTime The end time for the registration
    /// @param sender The sender of the transaction
    event RegistrationTimestampsUpdated(uint64 registrationStartTime, uint64 registrationEndTime, address sender);
}
