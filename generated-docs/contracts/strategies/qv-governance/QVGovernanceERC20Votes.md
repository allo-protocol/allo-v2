# QVGovernanceERC20Votes









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

### allocationEndTime

```solidity
function allocationEndTime() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### allocationStartTime

```solidity
function allocationStartTime() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### allocators

```solidity
function allocators(address) external view returns (uint256 voiceCredits)
```

allocator address =&gt; Allocator



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| voiceCredits | uint256 | undefined |

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

### getInternalRecipientStatus

```solidity
function getInternalRecipientStatus(address _recipientId) external view returns (enum QVBaseStrategy.InternalRecipientStatus)
```

Get Internal recipient status



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | Id of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum QVBaseStrategy.InternalRecipientStatus | undefined |

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
function getRecipient(address _recipientId) external view returns (struct QVBaseStrategy.Recipient)
```

Get the recipient



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientId | address | Id of the recipient |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | QVBaseStrategy.Recipient | undefined |

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

### govToken

```solidity
function govToken() external view returns (contract IVotes)
```

====================== ======= Storage ====== ======================




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IVotes | undefined |

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
| _poolId | uint256 | The pool id |
| _data | bytes | The data |

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

### paidOut

```solidity
function paidOut(address) external view returns (bool)
```

recipientId =&gt; paid out



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### recipients

```solidity
function recipients(address) external view returns (bool useRegistryAnchor, address recipientAddress, struct Metadata metadata, enum QVBaseStrategy.InternalRecipientStatus recipientStatus, uint256 totalVotesReceived)
```

recipientId =&gt; Recipient



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| useRegistryAnchor | bool | undefined |
| recipientAddress | address | undefined |
| metadata | Metadata | undefined |
| recipientStatus | enum QVBaseStrategy.InternalRecipientStatus | undefined |
| totalVotesReceived | uint256 | undefined |

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

### registrationEndTime

```solidity
function registrationEndTime() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### registrationStartTime

```solidity
function registrationStartTime() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### registryGating

```solidity
function registryGating() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### reviewRecipients

```solidity
function reviewRecipients(address[] _recipientIds, enum QVBaseStrategy.InternalRecipientStatus[] _recipientStatuses) external nonpayable
```

Review recipient application



#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | Ids of the recipients |
| _recipientStatuses | enum QVBaseStrategy.InternalRecipientStatus[] | Statuses of the recipients |

### reviewThreshold

```solidity
function reviewThreshold() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### reviewsByStatus

```solidity
function reviewsByStatus(address, enum QVBaseStrategy.InternalRecipientStatus) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | enum QVBaseStrategy.InternalRecipientStatus | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### timestamp

```solidity
function timestamp() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### totalRecipientVotes

```solidity
function totalRecipientVotes() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### updatePoolTimestamps

```solidity
function updatePoolTimestamps(uint256 _registrationStartTime, uint256 _registrationEndTime, uint256 _allocationStartTime, uint256 _allocationEndTime) external nonpayable
```

Set the start and end dates for the pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| _registrationStartTime | uint256 | The start time for the registration |
| _registrationEndTime | uint256 | The end time for the registration |
| _allocationStartTime | uint256 | The start time for the allocation |
| _allocationEndTime | uint256 | The end time for the allocation |



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

### Appealed

```solidity
event Appealed(address indexed recipientId, bytes data, address sender)
```

====================== ======= Events ======= ======================



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | undefined |
| data  | bytes | undefined |
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

### PoolActive

```solidity
event PoolActive(bool active)
```

Event emitted when pool is set to active status



#### Parameters

| Name | Type | Description |
|---|---|---|
| active  | bool | undefined |

### RecipientStatusUpdated

```solidity
event RecipientStatusUpdated(address indexed recipientId, enum QVBaseStrategy.InternalRecipientStatus status, address sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | undefined |
| status  | enum QVBaseStrategy.InternalRecipientStatus | undefined |
| sender  | address | undefined |

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

### Reviewed

```solidity
event Reviewed(address indexed recipientId, enum QVBaseStrategy.InternalRecipientStatus status, address sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId `indexed` | address | undefined |
| status  | enum QVBaseStrategy.InternalRecipientStatus | undefined |
| sender  | address | undefined |

### TimestampsUpdated

```solidity
event TimestampsUpdated(uint256 registrationStartTime, uint256 registrationEndTime, uint256 allocationStartTime, uint256 allocationEndTime, address sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrationStartTime  | uint256 | undefined |
| registrationEndTime  | uint256 | undefined |
| allocationStartTime  | uint256 | undefined |
| allocationEndTime  | uint256 | undefined |
| sender  | address | undefined |



## Errors

### ALLOCATION_NOT_ACTIVE

```solidity
error ALLOCATION_NOT_ACTIVE()
```

====================== ======= Errors ====== ======================




### ALLOCATION_NOT_ENDED

```solidity
error ALLOCATION_NOT_ENDED()
```






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


### INVALID

```solidity
error INVALID()
```






### INVALID_METADATA

```solidity
error INVALID_METADATA()
```






### RECIPIENT_ERROR

```solidity
error RECIPIENT_ERROR(address recipientId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId | address | undefined |

### REGISTRATION_NOT_ACTIVE

```solidity
error REGISTRATION_NOT_ACTIVE()
```






### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```







