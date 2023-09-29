# QVImpactStreamStrategy.sol

The `QVImpactStreamStrategy` is a Solidity smart contract that extends the `BaseStrategy` contract and provides functionality for managing allocators, allocating votes, and distributing payouts in a custom strategy.


## Sequence Diagram
```mermaid
sequenceDiagram
    participant AllocatorBob
    participant Alice
    participant ImpactStreamDapp
    participant PoolManager
    participant Allo
    participant ImpactStreamQV

    PoolManager->>Allo: createPool() with ImpactStreamQV
    Allo-->>ImpactStreamQV: poolId
    PoolManager->>ImpactStreamQV: addAllocator(AllocatorBob, Alice)
    PoolManager->>ImpactStreamQV: removeAllocator(Alice)
    Alice->>+ImpactStreamDapp: submitProposal + review proposal + create multisig (offchain)
    ImpactStreamDapp->>+PoolManager: registerRecipient()
    PoolManager->>+Allo: registerRecipient()
    Allo-->>ImpactStreamQV: registerRecipient()
    ImpactStreamQV-->>Allo: recipient1
    Allo-->>-PoolManager: recipient1
    PoolManager-->>-ImpactStreamDapp: recipient1
    ImpactStreamDapp-->-Alice: recipient1
    AllocatorBob->>+Allo: allocate()
    Allo-->>-ImpactStreamQV: allocate()
    PoolManager->>+ImpactStreamQV: setPayouts()
    PoolManager->>+Allo: distribute()
    Allo-->>-ImpactStreamQV: distribute()  
```

## Contract Overview

* **License:** The `QVSimpleStrategy` contract adheres to the AGPL-3.0-only License, promoting open-source usage with specific terms.
* **Solidity Version:** Developed using Solidity version 0.8.19, leveraging the latest Ethereum smart contract advancements.
* **Inheritance:** Inherits from the `BaseStrategy` contract, inheriting and expanding core strategy functionalities.

### InitializeParams

* `maxVoiceCreditsPerAllocator` (uint256): Maximum voice credits that can be allocated by a single allocator.
* `allocationStartTime` (uint64): Timestamp of when the allocation starts.
* `allocationEndTime` (uint64): Timestamp of when the allocation ends.

## Events

* `AllocatorAdded(address indexed allocator, address sender)`: Emitted when an allocator is added to the strategy.
* `AllocatorRemoved(address indexed allocator, address sender)`: Emitted when an allocator is removed from the strategy.
* `UpdatedRegistration(address indexed recipientId, bytes data, address sender)`: Emitted when a recipient updates their registration.
* `TimestampsUpdated(uint64 allocationStartTime, uint64 allocationEndTime, address sender)`: Emitted when the pool timestamps are updated.
* `Allocated(address indexed recipientId, uint256 votes, address allocator)`: Emitted when a recipient receives votes.
* `PayoutSet(Payout[] payouts, address sender)`: Emitted when the payouts are set.

## Storage

* `uint64 public allocationStartTime`: The start time for the allocation in milliseconds since the epoch.
* `uint64 public allocationEndTime`: The end time for the allocation in milliseconds since the epoch.
* `IRegistry private _registry`: The registry contract.
* `uint256 public maxVoiceCreditsPerAllocator`: The maximum voice credits that can be allocated by a single allocator.
* `mapping(address => bool) public allowedAllocators`: Mapping of allocator addresses to their allowed status (true/false).
* `mapping(address => Recipient) public recipients`: Details of recipients using their ID.
* `mapping(address => Allocator) public allocators`: Details of allocators using their address.
* `mapping(address => uint256) public payouts`: Payouts to distribute.
* `bool public payoutSet`: A flag indicating whether payouts have been set.

## Structs

### InitializeParams

* `uint64 allocationStartTime`: The start time for the allocation.
* `uint64 allocationEndTime`: The end time for the allocation.
* `uint256 maxVoiceCreditsPerAllocator`: Maximum voice credits per allocator.

### Recipient

* `uint256 totalVotesReceived`: Total votes received by the recipient.
* `uint256 requestedAmount`: Requested amount.
* `address recipientAddress`: Address of the recipient.
* `Metadata metadata`: Metadata of the recipient.
* `Status recipientStatus`: Status of the recipient.

### Allocator

* `uint256 voiceCredits`: Total voice credits of the allocator.
* `mapping(address => uint256) voiceCreditsCastToRecipient`: Voice credits cast to a recipient.
* `mapping(address => uint256) votesCastToRecipient`: Votes cast to a recipient.

### Payout

* `address recipientId`: ID of the recipient.
* `uint256 amount`: Amount to be paid.

## Modifiers

* `onlyActiveAllocation()`: Modifier to check if the allocation is active.
* `onlyAfterAllocation()`: Modifier to check if the allocation has ended.

## Constructor

* `constructor(address _allo, string memory _name)`: Constructor for initializing the contract.

## Initialize

* `initialize(uint256 _poolId, bytes memory _data) external virtual override`: Initialize the strategy with provided parameters, including:

* `uint64 allocationStartTime`: The start time for the allocation.
* `uint64 allocationEndTime`: The end time for the allocation.
* `uint256 maxVoiceCreditsPerAllocator`: Maximum voice credits per allocator.


## External/Public Functions

* `updatePoolTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime) external onlyPoolManager(msg.sender)`: Set the start and end dates for the pool.
* `batchAddAllocator(address[] memory _allocators) external onlyPoolManager(msg.sender)`: Add allocator array.
* `addAllocator(address _allocator) external onlyPoolManager(msg.sender)`: Add allocator.
* `batchRemoveAllocator(address[] memory _allocators) external onlyPoolManager(msg.sender)`: Remove allocator array.
* `removeAllocator(address _allocator) external onlyPoolManager(msg.sender)`: Remove allocator.
* `setPayouts(Payout[] memory _payouts) external onlyPoolManager(msg.sender) onlyAfterAllocation`: Set the payouts to distribute.
* `recoverFunds(address _token, address _recipient) external onlyPoolManager(msg.sender)`: Transfer the funds recovered to the recipient.

## Internal Functions

* `_checkOnlyActiveAllocation()`: Check if the allocation is active.
* `_checkOnlyAfterAllocation()`: Check if the allocation has ended.
* `_distribute(address[] memory _recipientIds, bytes memory, address _sender) internal virtual override onlyAfterAllocation`: Distribute funds to recipients.
* `_addAllocator(address _allocator) internal`: Add allocator.
* `_removeAllocator(address _allocator) internal`: Remove allocator.
* `_updatePoolTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime) internal`: Set the start and end dates for the pool.
* `_allocate(bytes memory _data, address _sender) internal virtual override onlyActiveAllocation`: Allocate votes to a recipient.
* `_registerRecipient(bytes memory _data, address _sender) internal virtual override onlyPoolManager(_sender) returns (address recipientId)`: Register a recipient.
* `_isAcceptedRecipient(address _recipientId) internal view returns (bool)`: Check if a recipient is accepted.
* `_isValidAllocator(address _allocator) internal view override returns (bool)`: Check if an allocator is valid.
* `_hasVoiceCreditsLeft(uint256 _voiceCreditsToAllocate, uint256 _allocatedVoiceCredits) internal view returns (bool)`: Check if an allocator has voice credits left.
* `_getRecipient(address _recipientId) internal view returns (Recipient memory)`: Get recipient details.
* `_getRecipientStatus(address _recipientId) internal view virtual override returns (Status)`: Get recipient status.
* `_isPoolActive() internal view virtual override returns (bool)`: Check if a pool is active.
* `_sqrt(uint256 x) internal pure returns (uint256 y)`: Calculate the square root of a number.
* `_getPayout(address _recipientId, bytes memory) internal view virtual override returns (PayoutSummary memory)`: Get the payout for a single recipient.

## View Functions

* `getRecipient(address _recipientId) external view returns (Recipient memory)`: Get recipient details.
* `getAllocatorVoiceCredits(address _allocator) external view returns (uint256)`: Get allocator's voice credits.
* `getAllocatorVoiceCreditsCastToRecipient(address _allocator, address _recipientId) external view returns (uint256)`: Get voice credits cast by an allocator to a recipient.
* `getAllocatorVotesCastToRecipient(address _allocator, address _recipientId) external view returns (uint256)`: Get votes cast by an allocator to a recipient.


## User Flows 

### Setting Pool Timestamps

1. **User (Pool Manager)**: Call the `updatePoolTimestamps` function to set the start and end times for the allocation.


### Adding Allocators

1. **User (Pool Manager)**: Call the `addAllocator` function to add a single allocator to the strategy.
2. **User (Pool Manager)**: Alternatively, call the `batchAddAllocator` function to add multiple allocators at once.

### Removing Allocators

1. **User (Pool Manager)**: Call the `removeAllocator` function to remove a single allocator from the strategy.
2. **User (Pool Manager)**: Alternatively, call the `batchRemoveAllocator` function to remove multiple allocators at once.

## User Flow 4: Allocating Votes

1. **User (Allocator)**: Allocate votes to a specific recipient by calling the `allocate` function. The allocator must have voice credits left, and the allocation must be active.

### Updating Recipient Registration

1. **User (Pool Manager)**: Update a recipient's registration information by calling the `registerRecipient` function.

## User Flow 6: Distributing Payouts

1. **User (Pool Manager)**: After the allocation period ends, call the `setPayouts` function to set the payouts for distribution.
2. **User (Pool Manager)**: The pool manager can also recover funds by calling the `recoverFunds` function, which transfers recovered funds to a specified recipient.
