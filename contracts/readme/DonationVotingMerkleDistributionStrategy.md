# DonationVotingMerkleDistributionStrategy.sol

The `DonationVotingMerkleDistributionStrategy` contract presents an advanced fund distribution approach within the Allo ecosystem, combining Merkle trees, recipient statuses, and precise timestamps for secure and equitable allocation. This contract builds upon the `BaseStrategy` while integrating OpenZeppelin's `ReentrancyGuard` and `Multicall` libraries, ensuring heightened security, prevention of reentrancy attacks, and optimized batch operations.

**Smart Contract Overview:**

* **License:** The `DonationVotingMerkleDistributionStrategy` contract adheres to the AGPL-3.0-only License, promoting open-source usage with specific terms.
* **Solidity Version:** Developed using Solidity version 0.8.19, leveraging the latest Ethereum smart contract advancements.
* **External Libraries:** Utilizes the `MerkleProof`, `ReentrancyGuard`, and `Multicall` libraries from OpenZeppelin for enhanced security, efficiency, and reentrancy protection.
* **Interfaces:** Interfaces with the `IAllo` and `IRegistry` components for external communication.
* **Inheritance:** Inherits from the `BaseStrategy` contract, inheriting and expanding core strategy functionalities.

**Structs and Enums:**

1. `InternalRecipientStatus`: Enumerates the internal status of recipients, indicating pending, accepted, rejected, appealed, or no status.
2. `ApplicationStatus`: Contains the recipient application's index and status row.
3. `Recipient`: Captures recipient-specific attributes, such as using a registry anchor, recipient address, and metadata.
4. `Claim`: Describes a claim for allocated tokens.
5. `Distribution`: Represents fund distribution, encompassing an index, recipient ID, allocation amount, and Merkle proof.

**Modifiers:**

* `onlyActiveRegistration`: Restricts actions to the active registration period.
* `onlyActiveAllocation`: Permits actions only during the active allocation phase.
* `onlyAfterAllocation`: Allows actions after the allocation period concludes.

**Constructor:**

The constructor initializes the strategy with essential parameters and configurations.

**Views and Queries:**

1. `getRecipient`: Retrieves recipient details using their ID.
2. `getInternalRecipientStatus`: Fetches the internal status of a recipient.
3. `isDistributionSet`: Checks if the distribution is configured.
4. `hasBeenDistributed`: Verifies if a distribution has occurred.

**External/Custom Functions:**

1. `reviewRecipients`: Enables pool managers to update recipient application statuses.
2. `updatePoolTimestamps`: Allows pool managers to adjust pool phase timestamps.
3. `withdraw`: Permits pool managers to withdraw funds post-allocation.
4. `claim`: Enables recipients to claim their allocated tokens after allocation.
5. `updateDistribution`: Enables pool managers to update distribution metadata and Merkle root.
6. `isDistributionSet`: Checks if the distribution is configured.
7. `getRecipient`: Retrieves recipient details using their ID.
8. `getInternalRecipientStatus`: Fetches the internal status of a recipient.

**Internal Functions:**

1. `_isValidAllocator`: Validates an address as an eligible allocator.
2. `_isPoolTimestampValid`: Validates the pool's timestamp configuration.
3. `_isPoolActive`: Checks if the pool is active.
4. `_registerRecipient`: Registers a recipient with validation and status updates.
5. `_allocate`: Allocates tokens to recipients using provided data.
6. `_distribute`: Distributes funds to recipients based on data.
7. `_isProfileMember`: Checks if the sender is a profile member (when using registry anchors).
8. `_getRecipient`: Retrieves recipient details using their ID.
9. `_getRecipientStatus`: Retrieves a recipient's status (pending, accepted, rejected, appealed).
10. `_getUintRecipientStatus`: Retrieves recipient status as a uint8 value.
11. `_getStatusRowColumn`: Retrieves a recipient's status row index, column index, and current row.
12. `_setRecipientStatus`: Sets a recipient's status.
13. `_setDistributed`: Marks a distribution as complete.
14. `_validateDistribution`: Validates a distribution with a provided Merkle proof.
15. `_hasBeenDistributed`: Checks if a distribution has occurred.

**Recipient Status Bitmap:**

The contract employs a bitmap to efficiently store recipient statuses. Each bit in the bitmap represents a specific recipient's status (pending, accepted, rejected, appealed). By using 4 bits per recipient, the bitmap optimally accommodates five status levels.

**Merkle Tree Distribution:**

The contract implements a Merkle tree structure for fund distribution. Recipients receive a Merkle proof along with their allocation data. To claim funds, recipients submit their proof, and the contract verifies it against the Merkle root, ensuring the validity of distributions.

In summary, the `DonationVotingMerkleDistributionStrategy` contract introduces a sophisticated fund distribution mechanism within the Allo ecosystem. By integrating Merkle trees, precise timestamps, and recipient status management, the contract guarantees secure and fair fund allocation. With the integration of external libraries and meticulous contract design, the strategy fosters efficient and secure fund distribution.

## User Flows

**User Flow: Registering a Recipient**

1. Recipient initiates a registration request.
2. If `useRegistryAnchor` is enabled: a. Decodes recipient ID, recipient address, and metadata from provided data. b. Verifies sender's authorization as a profile member. c. Validates the provided data. d. If recipient ID is not a profile member, reverts. e. Registers recipient as "Pending" with provided details. f. Emits `Registered` event.
3. If `useRegistryAnchor` is disabled: a. Decodes recipient address, registry anchor (optional), and metadata from provided data. b. Determines if registry anchor is being used. c. Verifies sender's authorization as a profile member if using registry anchor. d. Validates the provided data. e. If registry anchor is used and recipient ID is not a profile member, reverts. f. Registers recipient as "Pending" with provided details. g. Emits `Registered` event.

* * *

**User Flow: Reviewing Recipients**

1. Pool Manager initiates a recipient status review request.
2. Verifies if sender is a pool manager.
3. Loops through provided application statuses: a. Updates recipient's internal status based on the application status. b. Emits `RecipientStatusUpdated` event.

* * *

**User Flow: Updating Pool Timestamps**

1. Pool Manager initiates a pool timestamp update request.
2. Verifies if sender is a pool manager.
3. Updates registration and allocation timestamps.
4. Emits `TimestampsUpdated` event.

* * *

**User Flow: Withdrawing Funds from Pool**

1. Pool Manager initiates a withdrawal request.
2. Verifies if sender is a pool manager.
3. Deducts the specified amount from the pool amount.
4. Transfers the specified amount to the sender's address.

* * *

**User Flow: Claiming Allocated Tokens**

1. Recipient initiates a claim request.
2. Verifies if claim amount is greater than zero.
3. Transfers the claim amount of tokens from the contract to the recipient's address.
4. Emits `Claimed` event.

* * *

**User Flow: Updating Distribution**

1. Pool Manager initiates a distribution update request.
2. Verifies if sender is a pool manager.
3. Checks if distribution has started, reverts if it has.
4. Updates merkle root and distribution metadata.
5. Emits `DistributionUpdated` event.

* * *

**User Flow: Distributing Funds**

1. Pool Manager initiates a batch payout request.
2. Verifies if sender is a pool manager.
3. Checks if distribution has started.
4. Decodes distribution data and loops through distributions: a. Validates the distribution using merkle proof. b. Deducts the distributed amount from the pool amount. c. Transfers the distributed amount to the recipient's address. d. Marks the distribution as done. e. Emits `FundsDistributed` event.

* * *

**User Flow: Checking Distribution Status**

1. User initiates a distribution status check request.
2. Checks if the specified distribution index has been marked as distributed.

* * *

**User Flow: Checking Distribution Set Status**

1. User initiates a distribution set status check request.
2. Checks if the merkle root for distribution has been set.

* * *

**User Flow: Marking Recipient as Appealed**

1. Recipient initiates an appeal request.
2. Checks if the recipient's internal status is "Rejected."
3. Updates recipient's internal status to "Appealed."
4. Emits `Appealed` event.

* * *

**User Flow: Checking Recipient Status**

1. User initiates a recipient status check request.
2. Retrieves and returns the internal recipient status.

* * *

**User Flow: Getting Recipient Details**

1. User initiates a recipient details request.
2. Retrieves and returns recipient details, including recipient address and metadata.

* * *

**User Flow: Getting Payout Summary**

1. Pool Manager initiates a payout summary request.
2. Decodes distribution data and retrieves recipient address and payout amount for a distribution.

* * *

**User Flow: Receiving Ether (Fallback Function)**

1. The contract receives Ether from external transactions.
2. Ether is added to the contract's balance.
