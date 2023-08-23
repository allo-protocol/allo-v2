# BaseStrategy.sol

The `BaseStrategy` contract serves as a foundational building block within the Allo ecosystem, forming the basis for more specialized allocation strategies. By integrating essential functions and variables, this abstract contract establishes a standardized approach for implementing distribution strategies.

## Table of Contents
- [BaseStrategy.sol](#basestrategysol)
  - [Table of Contents](#table-of-contents)
  - [Smart Contract Overview](#smart-contract-overview)
    - [Storage Variables](#storage-variables)
    - [Constructor](#constructor)
    - [Modifiers](#modifiers)
    - [Views and Queries](#views-and-queries)
    - [Functions](#functions)
    - [Internal Functions](#internal-functions)

## Smart Contract Overview

* **License:** The `BaseStrategy` contract adheres to the AGPL-3.0-only License, promoting open-source usage with specific terms.
* **Solidity Version:** Developed using Solidity version 0.8.19, leveraging the latest Ethereum smart contract advancements.
* **External Libraries:** Imports `Transfer` library from the Allo core for optimized token transfers.
* **Interfaces:** Implements the `IStrategy` interface, facilitating interaction with external components.

### Storage Variables

1. `allo`: An immutable reference to the `IAllo` contract, enabling communication with the Allo ecosystem.
2. `poolId`: Identifies the pool to which this strategy is associated.
3. `strategyId`: A hash identifying the strategy instance.
4. `poolAmount`: The current amount of tokens in the pool.
5. `poolActive`: A flag indicating whether the pool is active.

### Constructor

The constructor initializes the strategy by accepting the address of the `IAllo` contract and a name.

### Modifiers

* `onlyAllo`: Validates that the caller is the Allo contract.
* `onlyPoolManager`: Ensures that the caller is a pool manager.
* `onlyActivePool`: Allows actions only when the pool is active.
* `onlyInactivePool`: Permits actions only when the pool is inactive.
* `onlyInitialized`: Requires that the strategy is initialized.

### Views and Queries

1. `getAllo`: Retrieves the `IAllo` contract reference.
2. `getPoolId`: Retrieves the pool's ID.
3. `getStrategyId`: Retrieves the strategy's ID.
4. `getPoolAmount`: Retrieves the current pool amount.
5. `isPoolActive`: Checks if the pool is active.
6. `getRecipientStatus`: Retrieves the status of a recipient.

### Functions

1. `increasePoolAmount`: Allows the Allo contract to increase the pool's amount.
2. `registerRecipient`: Registers a recipient's application and updates their status.
3. `allocate`: Allocates tokens to recipients based on provided data.
4. `distribute`: Distributes tokens to recipients based on provided data.
5. `getPayouts`: Retrieves payout summaries for recipients and data pairs.
6. `isValidAllocator`: Validates whether an address is a valid allocator.

### Internal Functions

1. `_setPoolActive`: Sets the pool's activity status.
2. `_isPoolActive`: Checks if the pool is currently active.
3. `_isValidAllocator`: Validates an address as a valid allocator.
4. `_registerRecipient`: Registers a recipient's application and updates their status.
5. `_allocate`: Allocates tokens to recipients based on provided data.
6. `_distribute`: Distributes tokens to recipients based on provided data.
7. `_getPayout`: Retrieves the payout summary for a recipient and data pair.
8. `_getRecipientStatus`: Retrieves the status of a recipient. The strategy can choose to have it's status as long it returns IStrategy.RecipientStatus

In essence, the `BaseStrategy` contract establishes a standardized blueprint for various allocation strategies within the Allo ecosystem. It integrates critical functions, modifiers, and data structures, promoting consistency and coherence across different strategies.

Every strategy implemented would be expected to override the internal functions in the base contract. It's important to note that a strategy is expected to implement its own external function when it requires a feature that cannot be met by the internal functions. This design approach allows for flexibility and customization while still adhering to the foundational structure provided by the BaseStrategy contract.

By following this pattern, developers can efficiently create specialized allocation strategies that leverage the standardized building blocks provided by the BaseStrategy contract while tailoring specific functionality as needed for their use cases. This modular approach fosters a robust ecosystem of allocation strategies within the Allo framework, enabling innovative and efficient resource distribution solutions.