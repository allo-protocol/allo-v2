# DirectGrantsSimpleStrategy

*@thelostone-mc &lt;aditya@gitcoin.co&gt;, @0xKurt &lt;kurt@gitcoin.co&gt;, @codenamejason &lt;jason@gitcoin.co&gt;, @0xZakk &lt;zakk@gitcoin.co&gt;, @nfrgosselin &lt;nate@gitcoin.co&gt;*

> Direct Grants Simple Strategy.

Strategy used to allocate &amp; distribute funds to recipients with milestone payouts. The milestones         are set by the recipient and the pool manager can accept or reject the milestone. The pool manager         can also reject the recipient.



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

The total amount allocated to grant/recipient.




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

### getMilestoneStatus

```solidity
function getMilestoneStatus(address _recipientId, uint256 _milestoneId) external view returns (enum IStrategy.Status)
```

Get the status of the milestone of an recipient.

*This is used to check the status of the milestone of an recipient and is strategy specific*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | ID of the recipient |
| _milestoneId | uint256 | ID of the milestone |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum IStrategy.Status | Status Returns the status of the milestone using the &#39;Status&#39; enum |

### getMilestones

```solidity
function getMilestones(address _recipientId) external view returns (struct DirectGrantsSimpleStrategy.Milestone[])
```

Get the milestones.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | ID of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | DirectGrantsSimpleStrategy.Milestone[] | Milestone[] Returns the milestones for a &#39;recipientId&#39; |

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
function getRecipient(address _recipientId) external view returns (struct DirectGrantsSimpleStrategy.Recipient)
```

Get the recipient



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | ID of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | DirectGrantsSimpleStrategy.Recipient | Recipient Returns the recipient |

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

### grantAmountRequired

```solidity
function grantAmountRequired() external view returns (bool)
```

Flag to check if grant amount is required.




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

Initialize the strategy



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | ID of the pool |
| _data | bytes | The data to be decoded |

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

Flag to check if metadata is required.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### milestones

```solidity
function milestones(address, uint256) external view returns (uint256 amountPercentage, struct Metadata metadata, enum IStrategy.Status milestoneStatus)
```

This maps accepted recipients to their milestones

*&#39;recipientId&#39; to &#39;Milestone&#39;*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountPercentage | uint256 | undefined |
| metadata | Metadata | undefined |
| milestoneStatus | enum IStrategy.Status | undefined |

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

Flag to check if registry gating is enabled.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### rejectMilestone

```solidity
function rejectMilestone(address _recipientId, uint256 _milestoneId) external nonpayable
```

Reject pending milestone of the recipient.

*&#39;msg.sender&#39; must be a pool manager to reject a milestone. Emits a &#39;MilestonesStatusChanged()&#39; event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | ID of the recipient |
| _milestoneId | uint256 | ID of the milestone |

### reviewSetMilestones

```solidity
function reviewSetMilestones(address _recipientId, enum IStrategy.Status _status) external nonpayable
```

Set milestones of the recipient

*Emits a &#39;MilestonesReviewed()&#39; event*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | ID of the recipient |
| _status | enum IStrategy.Status | The status of the milestone review |

### setMilestones

```solidity
function setMilestones(address _recipientId, DirectGrantsSimpleStrategy.Milestone[] _milestones) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | undefined |
| _milestones | DirectGrantsSimpleStrategy.Milestone[] | undefined |

### setPoolActive

```solidity
function setPoolActive(bool _flag) external nonpayable
```

Toggle the status between active and inactive.

*&#39;msg.sender&#39; must be a pool manager to close the pool. Emits a &#39;PoolActive()&#39; event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _flag | bool | The flag to set the pool to active or inactive |

### setRecipientStatusToInReview

```solidity
function setRecipientStatusToInReview(address[] _recipientIds) external nonpayable
```

Set the status of the recipient to &#39;InReview&#39;

*Emits a &#39;RecipientStatusChanged()&#39; event*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | IDs of the recipients |

### submitMilestone

```solidity
function submitMilestone(address _recipientId, uint256 _milestoneId, Metadata _metadata) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | undefined |
| _milestoneId | uint256 | undefined |
| _metadata | Metadata | undefined |

### upcomingMilestone

```solidity
function upcomingMilestone(address) external view returns (uint256)
```

This maps accepted recipients to their upcoming milestone

*&#39;recipientId&#39; to &#39;nextMilestone&#39;*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### withdraw

```solidity
function withdraw(uint256 _amount) external nonpayable
```

Withdraw funds from pool.

*&#39;msg.sender&#39; must be a pool manager to withdraw funds.*

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

### MilestoneStatusChanged

```solidity
event MilestoneStatusChanged(address recipientId, uint256 milestoneId, enum IStrategy.Status status)
```

Emitted for the status change of a milestone.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId  | address | undefined |
| milestoneId  | uint256 | undefined |
| status  | enum IStrategy.Status | undefined |

### MilestoneSubmitted

```solidity
event MilestoneSubmitted(address recipientId, uint256 milestoneId, Metadata metadata)
```

Emitted for the submission of a milestone.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId  | address | undefined |
| milestoneId  | uint256 | undefined |
| metadata  | Metadata | undefined |

### MilestonesReviewed

```solidity
event MilestonesReviewed(address recipientId, enum IStrategy.Status status)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId  | address | undefined |
| status  | enum IStrategy.Status | undefined |

### MilestonesSet

```solidity
event MilestonesSet(address recipientId)
```

Emitted for the milestones set.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId  | address | undefined |

### PoolActive

```solidity
event PoolActive(bool active)
```

Emitted when pool is set to active status.



#### Parameters

| Name | Type | Description |
|---|---|---|
| active  | bool | The status of the pool |

### RecipientStatusChanged

```solidity
event RecipientStatusChanged(address recipientId, enum IStrategy.Status status)
```

Emitted for the registration of a recipient and the status is updated.



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

Throws when the allocation exceeds the pool amount.




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




### INVALID_MILESTONE

```solidity
error INVALID_MILESTONE()
```

Throws when the milestone is invalid.




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




### MILESTONES_ALREADY_SET

```solidity
error MILESTONES_ALREADY_SET()
```

Throws when the milestones are already set.




### MILESTONE_ALREADY_ACCEPTED

```solidity
error MILESTONE_ALREADY_ACCEPTED()
```

Throws when the milestone is already accepted.




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





