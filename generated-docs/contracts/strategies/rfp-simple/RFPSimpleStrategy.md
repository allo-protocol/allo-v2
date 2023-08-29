# RFPSimpleStrategy









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

### acceptedRecipientId

```solidity
function acceptedRecipientId() external view returns (address)
```






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

### getMilestone

```solidity
function getMilestone(uint256 _milestoneId) external view returns (struct RFPSimpleStrategy.Milestone)
```

Get the milestone



#### Parameters

| Name | Type | Description |
|---|---|---|
| _milestoneId | uint256 | Id of the milestone |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | RFPSimpleStrategy.Milestone | undefined |

### getMilestoneStatus

```solidity
function getMilestoneStatus(uint256 _milestoneId) external view returns (enum IStrategy.RecipientStatus)
```

Get the status of the milestone



#### Parameters

| Name | Type | Description |
|---|---|---|
| _milestoneId | uint256 | Id of the milestone |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum IStrategy.RecipientStatus | undefined |

### getPayouts

```solidity
function getPayouts(address[], bytes[]) external view returns (struct IStrategy.PayoutSummary[])
```

Returns the payout summary for the accepted recipient



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |
| _1 | bytes[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IStrategy.PayoutSummary[] | undefined |

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
function getRecipient(address _recipientId) external view returns (struct RFPSimpleStrategy.Recipient)
```

Get the recipient



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | Id of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | RFPSimpleStrategy.Recipient | undefined |

### getRecipientStatus

```solidity
function getRecipientStatus(address _recipientId) external view returns (enum IStrategy.RecipientStatus)
```



*Returns the status of a recipient probably tracked in a mapping, but will depend on the implementation      for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those      since there is no need for Pending or Rejected*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum IStrategy.RecipientStatus | undefined |

### getStrategyId

```solidity
function getStrategyId() external view returns (bytes32)
```



*Getter for the &#39;id&#39; of the strategy*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### increaseMaxBid

```solidity
function increaseMaxBid(uint256 _maxBid) external nonpayable
```

Update max bid for RFP pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| _maxBid | uint256 | The max bid to be set |

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

### maxBid

```solidity
function maxBid() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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
function milestones(uint256) external view returns (uint256 amountPercentage, struct Metadata metadata, enum IStrategy.RecipientStatus milestoneStatus)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountPercentage | uint256 | undefined |
| metadata | Metadata | undefined |
| milestoneStatus | enum IStrategy.RecipientStatus | undefined |

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

### rejectMilestone

```solidity
function rejectMilestone(uint256 _milestoneId) external nonpayable
```

Reject pending milestone



#### Parameters

| Name | Type | Description |
|---|---|---|
| _milestoneId | uint256 | Id of the milestone |

### setMilestones

```solidity
function setMilestones(RFPSimpleStrategy.Milestone[] _milestones) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _milestones | RFPSimpleStrategy.Milestone[] | undefined |

### setPoolActive

```solidity
function setPoolActive(bool _active) external nonpayable
```

=============================== ======= External/Custom ======= ===============================



#### Parameters

| Name | Type | Description |
|---|---|---|
| _active | bool | undefined |

### submitUpcomingMilestone

```solidity
function submitUpcomingMilestone(Metadata _metadata) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _metadata | Metadata | undefined |

### upcomingMilestone

```solidity
function upcomingMilestone() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

Withdraw funds from RFP pool



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

### MaxBidIncreased

```solidity
event MaxBidIncreased(uint256 maxBid)
```

=============================== ========== Events ============= ===============================



#### Parameters

| Name | Type | Description |
|---|---|---|
| maxBid  | uint256 | undefined |

### MilestoneRejected

```solidity
event MilestoneRejected(uint256 milestoneId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| milestoneId  | uint256 | undefined |

### MilestonesSet

```solidity
event MilestonesSet()
```






### MilstoneSubmitted

```solidity
event MilstoneSubmitted(uint256 milestoneId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| milestoneId  | uint256 | undefined |

### PoolActive

```solidity
event PoolActive(bool active)
```

Event emitted when pool is set to active status



#### Parameters

| Name | Type | Description |
|---|---|---|
| active  | bool | undefined |

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

### AMOUNT_MISMATCH

```solidity
error AMOUNT_MISMATCH()
```






### AMOUNT_TOO_LOW

```solidity
error AMOUNT_TOO_LOW()
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


### EXCEEDING_MAX_BID

```solidity
error EXCEEDING_MAX_BID()
```






### INVALID_METADATA

```solidity
error INVALID_METADATA()
```






### INVALID_MILESTONE

```solidity
error INVALID_MILESTONE()
```






### INVALID_RECIPIENT

```solidity
error INVALID_RECIPIENT()
```






### MILESTONES_ALREADY_SET

```solidity
error MILESTONES_ALREADY_SET()
```






### MILESTONE_ALREADY_ACCEPTED

```solidity
error MILESTONE_ALREADY_ACCEPTED()
```






### NOT_ENOUGH_FUNDS

```solidity
error NOT_ENOUGH_FUNDS()
```






### RECIPIENT_ALREADY_ACCEPTED

```solidity
error RECIPIENT_ALREADY_ACCEPTED()
```

=============================== ========== Errors ============= ===============================




### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```







