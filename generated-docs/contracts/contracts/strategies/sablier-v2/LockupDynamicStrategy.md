# LockupDynamicStrategy









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

### allocatedGrantAmount

```solidity
function allocatedGrantAmount() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### broker

```solidity
function broker() external view returns (address account, UD60x18 fee)
```

See https://docs.sablier.com/concepts/protocol/fees#broker-fees




#### Returns

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| fee | UD60x18 | undefined |

### cancelStream

```solidity
function cancelStream(address _recipientId, uint256 _streamId) external nonpayable
```

Cancel the stream and adjust the contract amounts.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | Id of the recipient |
| _streamId | uint256 | The id of the stream |

### changeRecipientSegments

```solidity
function changeRecipientSegments(address _recipientId, LockupDynamic.SegmentWithDelta[] _segments) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | undefined |
| _segments | LockupDynamic.SegmentWithDelta[] | undefined |

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

### getAllRecipientStreamIds

```solidity
function getAllRecipientStreamIds(address _recipientId) external view returns (uint256[])
```

Get the recipient&#39;s stream ids



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | Id of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[] | undefined |

### getAllo

```solidity
function getAllo() external view returns (contract IAllo)
```

Getter for the &#39;Allo&#39; contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IAllo | The Allo contract |

### getBroker

```solidity
function getBroker() external view returns (struct Broker)
```

Get the broker




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | Broker | undefined |

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

### getPayouts

```solidity
function getPayouts(address[] _recipientIds, bytes) external view returns (struct IStrategy.PayoutSummary[] payouts)
```

Returns the payout summary for the accepted recipient



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | undefined |
| _1 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| payouts | IStrategy.PayoutSummary[] | undefined |

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
function getRecipient(address _recipientId) external view returns (struct LockupDynamicStrategy.Recipient)
```

Get the recipient



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | LockupDynamicStrategy.Recipient | undefined |

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

### getRecipientStreamId

```solidity
function getRecipientStreamId(address _recipientId, uint256 streamIdIndex) external view returns (uint256)
```

Get the recipient&#39;s stream id at the given index



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | Id of the recipient |
| streamIdIndex | uint256 | Index of the stream id |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getStatus

```solidity
function getStatus(address _recipientId) external view returns (enum IStrategy.Status)
```

Get recipient status



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | Id of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum IStrategy.Status | undefined |

### getStrategyId

```solidity
function getStrategyId() external view returns (bytes32)
```

Getter for the &#39;strategyId&#39;.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | The ID of the strategy |

### grantAmountRequired

```solidity
function grantAmountRequired() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

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

### lockupDynamic

```solidity
function lockupDynamic() external view returns (contract ISablierV2LockupDynamic)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ISablierV2LockupDynamic | undefined |

### metadataRequired

```solidity
function metadataRequired() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

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

### registryGating

```solidity
function registryGating() external view returns (bool)
```

================================ ========== Storage ============= ================================




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### setBroker

```solidity
function setBroker(Broker _broker) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _broker | Broker | undefined |

### setRecipientStatusToInReview

```solidity
function setRecipientStatusToInReview(address[] _recipientIds) external nonpayable
```

Set the status of the recipient to InReview



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | Ids of the recipients |

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

### BrokerSet

```solidity
event BrokerSet(Broker broker)
```

=============================== ========== Events ============= ===============================



#### Parameters

| Name | Type | Description |
|---|---|---|
| broker  | Broker | undefined |

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

### PoolActive

```solidity
event PoolActive(bool active)
```

Emitted when pool is set to active status.



#### Parameters

| Name | Type | Description |
|---|---|---|
| active  | bool | The status of the pool |

### RecipientSegmentsChanged

```solidity
event RecipientSegmentsChanged(address recipientId, LockupDynamic.SegmentWithDelta[] segments)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId  | address | undefined |
| segments  | LockupDynamic.SegmentWithDelta[] | undefined |

### RecipientStatusChanged

```solidity
event RecipientStatusChanged(address recipientId, enum IStrategy.Status status)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId  | address | undefined |
| status  | enum IStrategy.Status | undefined |

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



## Errors

### ALLOCATION_ACTIVE

```solidity
error ALLOCATION_ACTIVE()
```

Thrown when the allocation is active.




### ALLOCATION_EXCEEDS_POOL_AMOUNT

```solidity
error ALLOCATION_EXCEEDS_POOL_AMOUNT()
```

=============================== ========== Errors ============= ===============================




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




### STATUS_NOT_ACCEPTED

```solidity
error STATUS_NOT_ACCEPTED()
```






### STATUS_NOT_PENDING_OR_INREVIEW

```solidity
error STATUS_NOT_PENDING_OR_INREVIEW()
```






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





