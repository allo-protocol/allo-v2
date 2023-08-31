# DirectGrantsSimpleStrategy

*allo-team*

> Direct Grants Simple Strategy

A strategy is used to allocate &amp; distribute funds to recipients with milestone payouts

*This strategy is used to allocate &amp; distribute funds to recipients with milestone payouts*

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



*Only called via Allo.sol by users to allocate to a recipient      this will update some data in this contract to store votes, etc Requirements: This will be determined by the strategy*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _data | bytes | undefined |
| _sender | address | undefined |

### allocatedGrantAmount

```solidity
function allocatedGrantAmount() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### distribute

```solidity
function distribute(address[] _recipientIds, bytes _data, address _sender) external nonpayable
```



*This will distribute tokens to recipients NOTE: Most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference.       This contract will need to track the amount paid already, so that it doesn&#39;t double pay Requirements: This will be determined by the strategy*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | undefined |
| _data | bytes | undefined |
| _sender | address | undefined |

### getAllo

```solidity
function getAllo() external view returns (contract IAllo)
```

================================ =========== Views ============== ================================




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IAllo | undefined |

### getRecipientStatus

```solidity
function getRecipientStatus(address _recipientId) external view returns (enum IStrategy.Status)
```

Get recipient status

*This status is specific to this strategy and is used to track the status of the recipient*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | ID of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum IStrategy.Status | Returns the recipient status specific to this strategy |

### getMilestoneStatus

```solidity
function getMilestoneStatus(address _recipientId, uint256 _milestoneId) external view returns (enum IStrategy.Status)
```

Get the status of the milestone of an recipient

*This is used to check the status of the milestone of an recipient and is strategy specific*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | ID of the recipient |
| _milestoneId | uint256 | ID of the milestone |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum IStrategy.Status | Returns the status of the milestone using the &#39;Status&#39; enum |

### getMilestones

```solidity
function getMilestones(address _recipientId) external view returns (struct DirectGrantsSimpleStrategy.Milestone[])
```

Get the milestones



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





#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | undefined |
| _data | bytes[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IStrategy.PayoutSummary[] | Input the values you would send to distribute(), get the amounts each recipient in the array would receive |

### getPoolAmount

```solidity
function getPoolAmount() external view returns (uint256)
```



*returns the amount of tokens in the pool*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getPoolId

```solidity
function getPoolId() external view returns (uint256)
```



*Getter for the &#39;poolId&#39; for this strategy*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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



*Returns the status of a recipient probably tracked in a mapping, but will depend on the implementation. For example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those since there is no need for Pending or Rejected.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum IStrategy.Status | undefined |

### getStrategyId

```solidity
function getStrategyId() external view returns (bytes32)
```



*Getter for the &#39;id&#39; of the strategy*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

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

incrases the poolAmount which is set on invoking Allo.fundPool



#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | undefined |

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



*whether pool is active*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isValidAllocator

```solidity
function isValidAllocator(address _allocator) external view returns (bool)
```



*Returns whether a allocator is valid or not, will usually be true for all      and will depend on the strategy implementation*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _allocator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### metadataRequired

```solidity
function metadataRequired() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### milestones

```solidity
function milestones(address, uint256) external view returns (uint256 amountPercentage, struct Metadata metadata, enum IStrategy.Status milestoneStatus)
```

This maps accepted recipients to their milestones

*Mapping of the &#39;recipientId&#39; to the &#39;Milestone&#39; struct*

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
function registerRecipient(bytes _data, address _sender) external payable returns (address)
```



*This is called via Allo.sol to register recipients      it can change their status all the way to Accepted, or to Pending if there are more steps      if there are more steps, additional functions should be added to allow the owner to check      this could also check attestations directly and then Accept Requirements: This will be determined by the strategy*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _data | bytes | undefined |
| _sender | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### registryGating

```solidity
function registryGating() external view returns (bool)
```

================================ ========== Storage ============= ================================




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### rejectMilestone

```solidity
function rejectMilestone(address _recipientId, uint256 _milestoneId) external nonpayable
```

Reject pending milestone of the recipient Requirements: Only the pool manager can reject the milestone



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | ID of the recipient |
| _milestoneId | uint256 | ID of the milestone |

### setRecipientStatusToInReview

```solidity
function setRecipientStatusToInReview(address[] _recipientIds) external nonpayable
```

Set the status of the recipient to InReview Requirements: Only the pool manager can set the status



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | Ids of the recipients |

### setMilestones

```solidity
function setMilestones(address _recipientId, DirectGrantsSimpleStrategy.Milestone[] _milestones) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | undefined |
| _milestones | DirectGrantsSimpleStrategy.Milestone[] | undefined |

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

*Mapping of the &#39;recipientId&#39; to the &#39;nextMilestone&#39; index*

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

Withdraw funds from pool Requirements: Only the pool manager can withdraw



#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | The amount to be withdrawn |



## Events

### Allocated

```solidity
event Allocated(address indexed recipientId, uint256 amount, address token, address sender)
```

Event emitted when a recipient is allocated to



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | undefined |
| amount  | uint256 | undefined |
| token  | address | undefined |
| sender  | address | undefined |

### Distributed

```solidity
event Distributed(address indexed recipientId, address recipientAddress, uint256 amount, address sender)
```

Event emitted when tokens are distributed



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | undefined |
| recipientAddress  | address | undefined |
| amount  | uint256 | undefined |
| sender  | address | undefined |

### Initialized

```solidity
event Initialized(address allo, bytes32 profileId, uint256 poolId, bytes data)
```

Event emitted when strategy is initialized



#### Parameters

| Name | Type | Description |
|---|---|---|
| allo  | address | undefined |
| profileId  | bytes32 | undefined |
| poolId  | uint256 | undefined |
| data  | bytes | undefined |

### MilestoneStatusChanged

```solidity
event MilestoneStatusChanged(address recipientId, uint256 milestoneId, enum IStrategy.Status status)
```

Event for the status change of a milestone



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

Event for the submission of a milestone



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId  | address | undefined |
| milestoneId  | uint256 | undefined |
| metadata  | Metadata | undefined |

### MilestonesSet

```solidity
event MilestonesSet(address recipientId)
```

Event for the milestones set



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId  | address | undefined |

### PoolActive

```solidity
event PoolActive(bool active)
```

Event emitted when pool is set to active status



#### Parameters

| Name | Type | Description |
|---|---|---|
| active  | bool | undefined |

### RecipientStatusChanged

```solidity
event RecipientStatusChanged(address recipientId, enum IStrategy.Status status)
```

Event for the registration of a recipient and the status is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId  | address | undefined |
| status  | enum IStrategy.Status | undefined |

### Registered

```solidity
event Registered(address indexed recipientId, bytes data, address sender)
```

Event emitted when a recipient is registered



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | undefined |
| data  | bytes | undefined |
| sender  | address | undefined |



## Errors

### ALLOCATION_EXCEEDS_POOL_AMOUNT

```solidity
error ALLOCATION_EXCEEDS_POOL_AMOUNT()
```

Error when the allocation exceeds the pool amount




### AMOUNT_MISMATCH

```solidity
error AMOUNT_MISMATCH()
```






### ALREADY_INITIALIZED

```solidity
error ALREADY_INITIALIZED()
```



*Returns when Base Strategy is already initialized*


### ARRAY_MISMATCH

```solidity
error ARRAY_MISMATCH()
```



*Returns when two arrays length are not equal*


### INVALID

```solidity
error INVALID()
```



*Returns as a general error when either a recipient address or an amount is invalid*


### INVALID_ADDRESS

```solidity
error INVALID_ADDRESS()
```



*Returns when an invalid address is used*


### NOT_INITIALIZED

```solidity
error NOT_INITIALIZED()
```



*Returns when Base Strategy is not initialized*


### POOL_ACTIVE

```solidity
error POOL_ACTIVE()
```



*Returns when a pool is already active*


### POOL_INACTIVE

```solidity
error POOL_INACTIVE()
```



*Returns when a pool is inactive*


### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```



*Returns when calls to Base Strategy are unauthorized*


### INVALID_METADATA

```solidity
error INVALID_METADATA()
```

Error when the metadata is invalid




### INVALID_MILESTONE

```solidity
error INVALID_MILESTONE()
```

Error when the milestone is invalid




### INVALID_REGISTRATION

```solidity
error INVALID_REGISTRATION()
```

Error when the registration is invalid




### MILESTONES_ALREADY_SET

```solidity
error MILESTONES_ALREADY_SET()
```

Error when the milestones are already set




### MILESTONE_ALREADY_ACCEPTED

```solidity
error MILESTONE_ALREADY_ACCEPTED()
```

Error when the milestone is already accepted




### RECIPIENT_ALREADY_ACCEPTED

```solidity
error RECIPIENT_ALREADY_ACCEPTED()
```

Error when recipient is already accepted




### RECIPIENT_NOT_ACCEPTED

```solidity
error RECIPIENT_NOT_ACCEPTED()
```

Error when the recipient is not accepted




### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```

Error when the user address is not authorized





