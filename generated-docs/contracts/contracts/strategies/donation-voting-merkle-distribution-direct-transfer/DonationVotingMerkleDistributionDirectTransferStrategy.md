# DonationVotingMerkleDistributionDirectTransferStrategy

*@thelostone-mc &lt;aditya@gitcoin.co&gt;, @0xKurt &lt;kurt@gitcoin.co&gt;, @codenamejason &lt;jason@gitcoin.co&gt;, @0xZakk &lt;zakk@gitcoin.co&gt;, @nfrgosselin &lt;nate@gitcoin.co&gt;*

> Donation Voting Merkle Distribution Strategy

Strategy for donation voting allocation with a merkle distribution



## Methods

### NATIVE

```solidity
function NATIVE() external view returns (address)
```

Address of the native token




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### allocate

```solidity
function allocate(bytes _data, address _sender) external payable
```

Allocates to a recipient.

*The encoded &#39;_data&#39; will be determined by the strategy implementation. Only &#39;Allo&#39; contract can      call this when it is initialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _data | bytes | The data to use to allocate to the recipient |
| _sender | address | The address of the sender |

### allocationEndTime

```solidity
function allocationEndTime() external view returns (uint64)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint64 | undefined |

### allocationStartTime

```solidity
function allocationStartTime() external view returns (uint64)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint64 | undefined |

### allowedTokens

```solidity
function allowedTokens(address) external view returns (bool)
```

&#39;token&#39; address =&gt; boolean (allowed = true).



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### distribute

```solidity
function distribute(address[] _recipientIds, bytes _data, address _sender) external nonpayable
```

Distributes funds (tokens) to recipients.

*The encoded &#39;_data&#39; will be determined by the strategy implementation. Only &#39;Allo&#39; contract can      call this when it is initialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | The IDs of the recipients |
| _data | bytes | The data to use to distribute to the recipients |
| _sender | address | The address of the sender |

### distributionMetadata

```solidity
function distributionMetadata() external view returns (uint256 protocol, string pointer)
```

Metadata containing the distribution data.




#### Returns

| Name | Type | Description |
|---|---|---|
| protocol | uint256 | undefined |
| pointer | string | undefined |

### distributionStarted

```solidity
function distributionStarted() external view returns (bool)
```

Flag to indicate whether the distribution has started or not.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### getAllo

```solidity
function getAllo() external view returns (contract IAllo)
```

Getter for the &#39;Allo&#39; contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IAllo | The Allo contract |

### getPayouts

```solidity
function getPayouts(address[] _recipientIds, bytes[] _data) external view returns (struct IStrategy.PayoutSummary[])
```

Gets the payout summary for recipients.

*The encoded &#39;_data&#39; will be determined by the strategy implementation.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | The IDs of the recipients |
| _data | bytes[] | The data to use to get the payout summary for the recipients |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IStrategy.PayoutSummary[] | The payout summary for the recipients |

### getPoolAmount

```solidity
function getPoolAmount() external view returns (uint256)
```

Getter for the &#39;poolAmount&#39;.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The balance of the pool |

### getPoolId

```solidity
function getPoolId() external view returns (uint256)
```

Getter for the &#39;poolId&#39;.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The ID of the pool |

### getRecipient

```solidity
function getRecipient(address _recipientId) external view returns (struct DonationVotingMerkleDistributionBaseStrategy.Recipient recipient)
```

Get a recipient with a &#39;_recipientId&#39;



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | ID of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| recipient | DonationVotingMerkleDistributionBaseStrategy.Recipient | The recipient details |

### getRecipientStatus

```solidity
function getRecipientStatus(address _recipientId) external view returns (enum IStrategy.Status)
```

Getter for the status of a recipient.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | The ID of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum IStrategy.Status | The status of the recipient |

### getStrategyId

```solidity
function getStrategyId() external view returns (bytes32)
```

Getter for the &#39;strategyId&#39;.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | The ID of the strategy |

### hasBeenDistributed

```solidity
function hasBeenDistributed(uint256 _index) external view returns (bool)
```

Utility function to check if distribution is done.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _index | uint256 | index of the distribution |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if distribution is completed, otherwise &#39;false&#39; |

### increasePoolAmount

```solidity
function increasePoolAmount(uint256 _amount) external nonpayable
```

Increases the pool amount.

*Increases the &#39;poolAmount&#39; by &#39;_amount&#39;. Only &#39;Allo&#39; contract can call this.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | The amount to increase the pool by |

### initialize

```solidity
function initialize(uint256 _poolId, bytes _data) external nonpayable
```

Initializes the strategy

*This will revert if the strategy is already initialized and &#39;msg.sender&#39; is not the &#39;Allo&#39; contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The &#39;poolId&#39; to initialize |
| _data | bytes | The data to be decoded to initialize the strategy |

### isDistributionSet

```solidity
function isDistributionSet() external view returns (bool)
```

Checks if distribution is set.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if distribution is set, otherwise &#39;false&#39; |

### isPoolActive

```solidity
function isPoolActive() external view returns (bool)
```

Getter for whether or not the pool is active.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the pool is active, otherwise &#39;false&#39; |

### isValidAllocator

```solidity
function isValidAllocator(address _allocator) external view returns (bool)
```

Checks if the &#39;_allocator&#39; is a valid allocator.

*How the allocator is determined is up to the strategy implementation.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _allocator | address | The address to check if it is a valid allocator for the strategy. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the address is a valid allocator, &#39;false&#39; otherwise |

### merkleRoot

```solidity
function merkleRoot() external view returns (bytes32)
```

The merkle root of the distribution will be set by the pool manager.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### metadataRequired

```solidity
function metadataRequired() external view returns (bool)
```

Flag to indicate whether metadata is required or not.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```



*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | undefined |

### recipientToStatusIndexes

```solidity
function recipientToStatusIndexes(address) external view returns (uint256)
```

&#39;recipientId&#39; =&gt; &#39;statusIndex&#39;



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### recipientsCounter

```solidity
function recipientsCounter() external view returns (uint256)
```

The total number of recipients.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### registerRecipient

```solidity
function registerRecipient(bytes _data, address _sender) external payable returns (address recipientId)
```

Registers a recipient.

*Registers a recipient and returns the ID of the recipient. The encoded &#39;_data&#39; will be determined by the      strategy implementation. Only &#39;Allo&#39; contract can call this when it is initialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _data | bytes | The data to use to register the recipient |
| _sender | address | The address of the sender |

#### Returns

| Name | Type | Description |
|---|---|---|
| recipientId | address | The recipientId |

### registrationEndTime

```solidity
function registrationEndTime() external view returns (uint64)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint64 | undefined |

### registrationStartTime

```solidity
function registrationStartTime() external view returns (uint64)
```

The timestamps in milliseconds for the start and end times.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint64 | undefined |

### reviewRecipients

```solidity
function reviewRecipients(DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] statuses) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| statuses | DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] | undefined |

### statusesBitMap

```solidity
function statusesBitMap(uint256) external view returns (uint256)
```

This is a packed array of booleans, &#39;statuses[0]&#39; is the first row of the bitmap and allows to store 256 bits to describe the status of 256 projects. &#39;statuses[1]&#39; is the second row, and so on Instead of using 1 bit for each recipient status, we will use 4 bits for each status to allow 5 statuses: 0: none 1: pending 2: accepted 3: rejected 4: appealed Since it&#39;s a mapping the storage it&#39;s pre-allocated with zero values, so if we check the status of an existing recipient, the value is by default 0 (none). If we want to check the status of an recipient, we take its index from the `recipients` array and convert it to the 2-bits position in the bitmap.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### totalPayoutAmount

```solidity
function totalPayoutAmount() external view returns (uint256)
```

The total amount of tokens allocated to the payout.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### updateDistribution

```solidity
function updateDistribution(bytes32 _merkleRoot, Metadata _distributionMetadata) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _merkleRoot | bytes32 | undefined |
| _distributionMetadata | Metadata | undefined |

### updatePoolTimestamps

```solidity
function updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime, uint64 _allocationStartTime, uint64 _allocationEndTime) external nonpayable
```

Sets the start and end dates.

*The timestamps are in milliseconds for the start and end times. The &#39;msg.sender&#39; must be a pool manager.      Emits a &#39;TimestampsUpdated()&#39; event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _registrationStartTime | uint64 | The start time for the registration |
| _registrationEndTime | uint64 | The end time for the registration |
| _allocationStartTime | uint64 | The start time for the allocation |
| _allocationEndTime | uint64 | The end time for the allocation |

### useRegistryAnchor

```solidity
function useRegistryAnchor() external view returns (bool)
```

Flag to indicate whether to use the registry anchor or not.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### withdraw

```solidity
function withdraw(uint256 _amount) external nonpayable
```

Withdraw funds from pool

*This can only be called after the allocation has ended and 30 days have passed. If the      &#39;_amount&#39; is greater than the pool amount or if &#39;msg.sender&#39; is not a pool manager.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | The amount to be withdrawn |



## Events

### Allocated

```solidity
event Allocated(address indexed recipientId, uint256 amount, address token, address sender)
```

Emitted when a recipient is allocated to.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | The ID of the recipient |
| amount  | uint256 | The amount allocated |
| token  | address | The token allocated |
| sender  | address | undefined |

### BatchPayoutSuccessful

```solidity
event BatchPayoutSuccessful(address indexed sender)
```

Emitted when a batch payout is successful



#### Parameters

| Name | Type | Description |
|---|---|---|
| sender `indexed` | address | The sender of the transaction |

### Distributed

```solidity
event Distributed(address indexed recipientId, address recipientAddress, uint256 amount, address sender)
```

Emitted when tokens are distributed.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | The ID of the recipient |
| recipientAddress  | address | The recipient |
| amount  | uint256 | The amount distributed |
| sender  | address | The sender |

### DistributionUpdated

```solidity
event DistributionUpdated(bytes32 merkleRoot, Metadata metadata)
```

Emitted when the distribution has been updated with a new merkle root or metadata



#### Parameters

| Name | Type | Description |
|---|---|---|
| merkleRoot  | bytes32 | The merkle root of the distribution |
| metadata  | Metadata | The metadata of the distribution |

### FundsDistributed

```solidity
event FundsDistributed(uint256 amount, address grantee, address indexed token, address indexed recipientId)
```

Emitted when funds are distributed to a recipient



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount  | uint256 | The amount of tokens distributed |
| grantee  | address | The address of the recipient |
| token `indexed` | address | The address of the token |
| recipientId `indexed` | address | The id of the recipient |

### Initialized

```solidity
event Initialized(address allo, bytes32 profileId, uint256 poolId, bytes data)
```

Emitted when strategy is initialized.



#### Parameters

| Name | Type | Description |
|---|---|---|
| allo  | address | The Allo contract |
| profileId  | bytes32 | The ID of the profile |
| poolId  | uint256 | The ID of the pool |
| data  | bytes | undefined |

### PoolActive

```solidity
event PoolActive(bool active)
```

Emitted when pool is set to active status.



#### Parameters

| Name | Type | Description |
|---|---|---|
| active  | bool | The status of the pool |

### RecipientStatusUpdated

```solidity
event RecipientStatusUpdated(uint256 indexed rowIndex, uint256 fullRow, address sender)
```

Emitted when a recipient is registered and the status is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| rowIndex `indexed` | uint256 | The index of the row in the bitmap |
| fullRow  | uint256 | The value of the row |
| sender  | address | The sender of the transaction |

### Registered

```solidity
event Registered(address indexed recipientId, bytes data, address sender)
```

Emitted when a recipient is registered.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | The ID of the recipient |
| data  | bytes | The data passed to the &#39;registerRecipient&#39; function |
| sender  | address | The sender |

### TimestampsUpdated

```solidity
event TimestampsUpdated(uint64 registrationStartTime, uint64 registrationEndTime, uint64 allocationStartTime, uint64 allocationEndTime, address sender)
```

Emitted when the timestamps are updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| registrationStartTime  | uint64 | The start time for the registration |
| registrationEndTime  | uint64 | The end time for the registration |
| allocationStartTime  | uint64 | The start time for the allocation |
| allocationEndTime  | uint64 | The end time for the allocation |
| sender  | address | The sender of the transaction |

### UpdatedRegistration

```solidity
event UpdatedRegistration(address indexed recipientId, bytes data, address sender, uint8 status)
```

Emitted when a recipient updates their registration



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | Id of the recipient |
| data  | bytes | The encoded data - (address recipientId, address recipientAddress, Metadata metadata) |
| sender  | address | The sender of the transaction |
| status  | uint8 | The updated status of the recipient |



## Errors

### ALLOCATION_ACTIVE

```solidity
error ALLOCATION_ACTIVE()
```

Thrown when the allocation is active.




### ALLOCATION_NOT_ACTIVE

```solidity
error ALLOCATION_NOT_ACTIVE()
```

Thrown when the allocation is not active.




### ALLOCATION_NOT_ENDED

```solidity
error ALLOCATION_NOT_ENDED()
```

Thrown when the allocation is not ended.




### ALREADY_INITIALIZED

```solidity
error ALREADY_INITIALIZED()
```

Thrown when data is already intialized




### AMOUNT_MISMATCH

```solidity
error AMOUNT_MISMATCH()
```






### ANCHOR_ERROR

```solidity
error ANCHOR_ERROR()
```



*Thrown if the anchor creation fails*


### ARRAY_MISMATCH

```solidity
error ARRAY_MISMATCH()
```

Thrown when two arrays length are not equal




### INVALID

```solidity
error INVALID()
```

Thrown as a general error when input / data is invalid




### INVALID_ADDRESS

```solidity
error INVALID_ADDRESS()
```

Thrown when an invalid address is used




### INVALID_FEE

```solidity
error INVALID_FEE()
```

Thrown when the fee is below 1e18 which is the fee percentage denominator




### INVALID_METADATA

```solidity
error INVALID_METADATA()
```

Thrown when the metadata is invalid.




### INVALID_REGISTRATION

```solidity
error INVALID_REGISTRATION()
```

Thrown when the registration is invalid.




### IS_APPROVED_STRATEGY

```solidity
error IS_APPROVED_STRATEGY()
```

Thrown when the strategy is approved and should be cloned




### MISMATCH

```solidity
error MISMATCH()
```

Thrown when mismatch in decoding data




### NONCE_NOT_AVAILABLE

```solidity
error NONCE_NOT_AVAILABLE()
```



*Thrown when the nonce passed has been used or not available*


### NOT_APPROVED_STRATEGY

```solidity
error NOT_APPROVED_STRATEGY()
```

Thrown when the strategy is not approved




### NOT_ENOUGH_FUNDS

```solidity
error NOT_ENOUGH_FUNDS()
```

Thrown when not enough funds are available




### NOT_INITIALIZED

```solidity
error NOT_INITIALIZED()
```

Thrown when data is yet to be initialized




### NOT_PENDING_OWNER

```solidity
error NOT_PENDING_OWNER()
```



*Thrown when the &#39;msg.sender&#39; is not the pending owner on ownership transfer*


### POOL_ACTIVE

```solidity
error POOL_ACTIVE()
```

Thrown when a pool is already active




### POOL_INACTIVE

```solidity
error POOL_INACTIVE()
```

Thrown when a pool is inactive




### RECIPIENT_ALREADY_ACCEPTED

```solidity
error RECIPIENT_ALREADY_ACCEPTED()
```

Thrown when recipient is already accepted.




### RECIPIENT_ERROR

```solidity
error RECIPIENT_ERROR(address recipientId)
```

Thrown when there is an error in recipient.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId | address | undefined |

### RECIPIENT_NOT_ACCEPTED

```solidity
error RECIPIENT_NOT_ACCEPTED()
```

Thrown when the recipient is not accepted.




### REGISTRATION_NOT_ACTIVE

```solidity
error REGISTRATION_NOT_ACTIVE()
```

Thrown when registration is not active.




### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```

Thrown when user is not authorized




### ZERO_ADDRESS

```solidity
error ZERO_ADDRESS()
```

Thrown when address is the zero address





