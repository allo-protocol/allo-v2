
# Strategies Extensions

This folder contains modular extensions for the core strategies. These extensions provide additional functionality to the base strategy, enabling developers to implement more advanced behaviors such as use different types of gating, recipient registration and allocation, and milestone-based allocation.

Extensions are categorized into various subfolders based on their functionality and use case. Each extension can be inherited by a strategy.

---

## Folder Structure

The `extensions` directory is divided into the following categories:

- **Gating**: Provides gating mechanisms to restrict access to certain actions or features based on various conditions, such as token holdings or NFT ownership.
- **Register**: Adds recipient registration mechanisms that can be customized according to the specific strategy.
- **Allocate**: Contains the option to add an allocation time window and manage whitelisted allocators.
- **Milestones**: Enables milestone-based distribution or allocation, where funds are released upon completion of predefined goals.

### Gating
The `gating` folder provides several extensions that restrict access to various features based on certain conditions.

- **EASGatingExtension.sol**: Uses Ethereum Attestation Service (EAS) to gate access.
- **TokenGatingExtension.sol**: Requires participants to hold a specified amount of ERC20 tokens to participate in strategy-related actions.
- **NFTGatingExtension.sol**: Gating based on NFT ownership. Participants need to own a specific NFT or belong to a specific NFT collection to proceed.

### Register
The `register` folder contains extensions that manage the registration of recipients.

- **RecipientsExtension.sol**: Implements recipient registration, enabling strategies to manage who can receive funds or rewards.
- **IRecipientsExtension.sol**: Interface for the recipient registration process, allowing strategies to implement their own customized registration logic.

### Allocate

TODO

### Milestones
The `milestones` folder contains extensions that enable milestone-based funding.

- **MilestonesExtension.sol**: Implements milestone tracking, allowing funds to be released to recipients upon completion of specific tasks or achievements.
- **IMilestonesExtension.sol**: Interface for milestone-based strategies.

---


## How to Use Extensions in Strategies

Extensions provide additional functionality that can be integrated into strategies to customize their behavior. This guide explains how to use extensions in your strategies, with a simple example.

### Example: Using an Extension in a Custom Strategy

Extensions provide additional functionality that can be integrated into strategies to customize their behavior. This example shows how to use extensions in your strategies, with a simple example.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BaseStrategy.sol";
import "./extensions/register/RecipientsExtension.sol";

contract CustomStrategy is BaseStrategy, RecipientsExtension {
    constructor(address _allo) RecipientsExtension(_allo, false) {}

    function initialize(uint256 _poolId, bytes memory _data) external {
        // Initialize the base strategy with the pool ID
        __BaseStrategy_init(_poolId);

        // Initialize the recipients extension with the provided data
        RecipientInitializeData memory initData = abi.decode(_data, (RecipientInitializeData));
        __RecipientsExtension_init(initData);
    }
}
```
