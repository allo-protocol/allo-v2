# QVSimpleStrategy.sol

The `QVSimpleStrategy` is a Solidity smart contract that extends the `QVBaseStrategy` contract and provides a simplified version of a quadratic voting strategy. This contract includes features to manage allocators, allocate votes using a quadratic voting algorithm, and customize voice credit allocations.

## Table of Contents

- [QVSimpleStrategy.sol](#qvsimplestrategysol)
  - [Table of Contents](#table-of-contents)
  - [Sequence Diagram](#sequence-diagram)
  - [Contract Overview](#contract-overview)
  - [Structs and Enums](#structs-and-enums)
    - [InitializeParamsSimple](#initializeparamssimple)
  - [Events](#events)
  - [State Variables](#state-variables)
  - [Constructor](#constructor)
  - [Initialize](#initialize)
  - [External/Custom Functions](#externalcustom-functions)
  - [Internal Functions](#internal-functions)
  - [User Flows](#user-flows)
    - [Allocator Management](#allocator-management)
    - [Voting Allocation](#voting-allocation)
    - [Recipient Acceptance](#recipient-acceptance)


## Sequence Diagram

## Contract Overview

* **License:** The `QVSimpleStrategy` contract adheres to the AGPL-3.0-only License, promoting open-source usage with specific terms.
* **Solidity Version:** Developed using Solidity version 0.8.19, leveraging the latest Ethereum smart contract advancements.
* **Inheritance:** Inherits from the `QVBaseStrategy` contract, inheriting and expanding core strategy functionalities.

## Structs and Enums

### InitializeParamsSimple

* `maxVoiceCreditsPerAllocator` (uint256): Maximum voice credits that can be allocated by a single allocator.
* `params` (InitializeParams): Parameters for initializing the strategy (inherited from `QVBaseStrategy`).

## Events

* `AllocatorAdded(address indexed allocator, address sender)`: Emitted when an allocator is added to the strategy.
* `AllocatorRemoved(address indexed allocator, address sender)`: Emitted when an allocator is removed from the strategy.

## State Variables

* `maxVoiceCreditsPerAllocator` (uint256): Maximum voice credits that can be allocated by a single allocator.
* `allowedAllocators` (mapping(address => bool)): Mapping of allocator addresses to their allowed status.

## Constructor

* `constructor(address _allo, string memory _name)`: Sets the Allo contract address and the strategy name. Calls the parent constructor from `QVBaseStrategy`.

## Initialize

* `initialize(uint256 _poolId, bytes memory _data) external override`: Initializes the strategy with provided parameters, including maximum voice credits per allocator.

## External/Custom Functions

* `addAllocator(address _allocator) external onlyPoolManager(msg.sender)`: Allows a pool manager to add an allocator to the strategy, enabling them to allocate voice credits.
* `removeAllocator(address _allocator) external onlyPoolManager(msg.sender)`: Allows a pool manager to remove an allocator from the strategy, revoking their allocation privileges.

## Internal Functions

* `_allocate(bytes memory _data, address _sender) internal override`: Allocates votes to a recipient based on allocator's voice credits. Checks allocator validity and recipient acceptance.
* `_isAcceptedRecipient(address _recipientId) internal view override returns (bool)`: Checks if a recipient is accepted based on internal recipient status.
* `_isValidAllocator(address _allocator) internal view override returns (bool)`: Checks if an allocator is valid based on allowedAllocators mapping.
* `_hasVoiceCreditsLeft(uint256 _voiceCreditsToAllocate, uint256 _allocatedVoiceCredits) internal view override returns (bool)`: Checks if an allocator has enough voice credits left to allocate.

## User Flows

### Allocator Management

* Pool managers can add or remove allocators, enabling them to allocate voice credits to recipients.
* Adding an allocator allows them to participate in the allocation process.
* Removing an allocator revokes their ability to allocate voice credits.

### Voting Allocation

* Allocators can allocate voice credits to specific recipients based on a quadratic voting algorithm.
* The `maxVoiceCreditsPerAllocator` limits the total voice credits an allocator can allocate.
* Voice credits are used to influence recipients' accumulated votes.

### Recipient Acceptance

* Recipients must be accepted based on internal status to be eligible for vote allocation.
* The contract checks if a recipient's status is accepted before allowing allocation.