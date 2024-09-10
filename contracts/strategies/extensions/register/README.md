# Register Extensions

The `register` extensions are designed to handle recipient registration within funding strategies. They manage recipient data, registration status, and timestamps, ensuring efficient tracking and updating of recipients.

## Overview

The main contract in this category is `RecipientsExtension`. It extends `BaseStrategy` and implements `IRecipientsExtension`, providing functionalities to manage and update recipient information. This extension allows for flexible recipient registration and status management.

## Key Components

### `RecipientsExtension`

- **Functionality**: 
  - Handles the registration and status management of recipients.
  - Allows setting and reviewing recipient statuses.
  - Manages metadata requirements and registration timeframes.

- **Features**:
  - **Registration Management**: Register new recipients and update existing ones.
  - **Status Tracking**: Uses a bitmap to track and manage recipient statuses, including pending, accepted, rejected, and more.
  - **Timestamp Management**: Set and check the registration start and end times.
  - **Metadata Handling**: Optionally enforce metadata requirements for recipients.
  - **Recipient Review**: Optionally review each status update if `REVIEW_EACH_STATUS` is enabled.

- **Key Functions**:
  - `getRecipient(address _recipientId)`: Retrieve recipient details.
  - `reviewRecipients(ApplicationStatus[] calldata statuses, uint256 refRecipientsCounter)`: Update recipient statuses in bulk.
  - `updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime)`: Update registration timeframe.
  - `_register(address[] memory __recipients, bytes memory _data, address _sender)`: Register recipients and handle metadata.

## Usage

1. **Initialization**: Ensure the strategy is initialized with the appropriate metadata and registration timeframes.
2. **Registration**: Use the `_register` function to add new recipients or update existing ones.
3. **Status Management**: Call `reviewRecipients` to update the status of multiple recipients based on provided data.
4. **Timestamp Updates**: Update registration periods as needed using `updatePoolTimestamps`.

## Events

- `Registered(address recipientId, bytes extendedData)`: Emitted when a recipient is registered.
- `UpdatedRegistration(address recipientId, bytes data, address sender, uint8 status)`: Emitted when a recipient's registration is updated.
- `RecipientStatusUpdated(uint256 rowIndex, uint256 fullRow, address sender)`: Emitted when recipient statuses are reviewed and updated.
- `RegistrationTimestampsUpdated(uint64 registrationStartTime, uint64 registrationEndTime, address sender)`: Emitted when registration timestamps are updated.

For more details on the `RecipientsExtension` contract, refer to the code comments and documentation in the Solidity source file.
