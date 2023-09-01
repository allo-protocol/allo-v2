# DonationVotingStrategy









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

token -&gt; bool



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### claim

```solidity
function claim(DonationVotingStrategy.Claim[] _claims) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _claims | DonationVotingStrategy.Claim[] | undefined |

### claims

```solidity
function claims(address, address) external view returns (uint256)
```

recipientId -&gt; token -&gt; amount



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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
function getRecipient(address _recipientId) external view returns (struct DonationVotingStrategy.Recipient)
```

Get the recipient



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | Id of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | DonationVotingStrategy.Recipient | undefined |

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

=============================== ========= Initialize ========== ===============================



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _data | bytes | undefined |

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

### metadataRequired

```solidity
function metadataRequired() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### payoutSummaries

```solidity
function payoutSummaries(address) external view returns (address recipientAddress, uint256 amount)
```

recipientId -&gt; PayoutSummary



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| recipientAddress | address | undefined |
| amount | uint256 | undefined |

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






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint64 | undefined |

### reviewRecipients

```solidity
function reviewRecipients(address[] _recipientIds, enum IStrategy.Status[] _recipientStatuses) external nonpayable
```

Review recipient application



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | Ids of the recipients |
| _recipientStatuses | enum IStrategy.Status[] | Statuses of the recipients |

### setPayout

```solidity
function setPayout(address[] _recipientIds, uint256[] _amounts) external nonpayable
```

Set payout for the recipients



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | Ids of the recipients |
| _amounts | uint256[] | Amounts to be paid out |

### totalPayoutAmount

```solidity
function totalPayoutAmount() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### updatePoolTimestamps

```solidity
function updatePoolTimestamps(uint64 _registrationStartTime, uint64 _registrationEndTime, uint64 _allocationStartTime, uint64 _allocationEndTime) external nonpayable
```

Set the start and end dates for the pool



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

================================ ========== Storage ============= ================================




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### withdraw

```solidity
function withdraw(uint256 _amount) external nonpayable
```

Withdraw funds from pool



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

### Claimed

```solidity
event Claimed(address indexed recipientId, address recipientAddress, uint256 amount, address token)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | undefined |
| recipientAddress  | address | undefined |
| amount  | uint256 | undefined |
| token  | address | undefined |

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

### PayoutSet

```solidity
event PayoutSet(bytes recipientIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientIds  | bytes | undefined |

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
event RecipientStatusUpdated(address indexed recipientId, enum IStrategy.Status recipientStatus, address sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | undefined |
| recipientStatus  | enum IStrategy.Status | undefined |
| sender  | address | undefined |

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





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrationStartTime  | uint64 | undefined |
| registrationEndTime  | uint64 | undefined |
| allocationStartTime  | uint64 | undefined |
| allocationEndTime  | uint64 | undefined |
| sender  | address | undefined |

### UpdatedRegistration

```solidity
event UpdatedRegistration(address indexed recipientId, bytes data, address sender, enum IStrategy.Status status)
```

Emitted when a recipient updates their registration



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | Id of the recipient |
| data  | bytes | The encoded data - (address recipientId, address recipientAddress, Metadata metadata) |
| sender  | address | The sender of the transaction |
| status  | enum IStrategy.Status | The updated status of the recipient |



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





