# IStrategy

*@thelostone-mc &lt;aditya@gitcoin.co&gt;, @0xKurt &lt;kurt@gitcoin.co&gt;, @codenamejason &lt;jason@gitcoin.co&gt;, @0xZakk &lt;zakk@gitcoin.co&gt;, @nfrgosselin &lt;nate@gitcoin.co&gt; @0xZakk &lt;zakk@gitcoin.co&gt;, @nfrgosselin &lt;nate@gitcoin.co&gt;*

> IStrategy Interface

BaseStrategy is the base contract that all strategies should inherit from and uses this interface.



## Methods

### allocate

```solidity
function allocate(bytes _data, address _sender) external payable
```

This will allocate to a recipient.

*The encoded &#39;_data&#39; will be determined by the strategy implementation.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _data | bytes | The data to use to allocate to the recipient |
| _sender | address | The address of the sender |

### distribute

```solidity
function distribute(address[] _recipientIds, bytes _data, address _sender) external nonpayable
```

This will distribute funds (tokens) to recipients.

*most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference this contract will need to track the amount paid already, so that it doesn&#39;t double pay.*

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

Getter for the address of the Allo contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IAllo | The &#39;Allo&#39; contract |

### getPayouts

```solidity
function getPayouts(address[] _recipientIds, bytes[] _data) external view returns (struct IStrategy.PayoutSummary[])
```

Checks the amount allocated to a recipient for distribution.

*Input the values you would send to distribute(), get the amounts each recipient in the array would receive.      The encoded &#39;_data&#39; will be determined by the strategy, and will be used to determine the payout.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _recipientIds | address[] | The IDs of the recipients |
| _data | bytes[] | The encoded data |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IStrategy.PayoutSummary[] | undefined |

### getPoolAmount

```solidity
function getPoolAmount() external view returns (uint256)
```

Checks the amount of tokens in the pool.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The balance of the pool |

### getPoolId

```solidity
function getPoolId() external view returns (uint256)
```

Getter for the &#39;poolId&#39; for this strategy.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The ID of the pool |

### getRecipientStatus

```solidity
function getRecipientStatus(address _recipientId) external view returns (enum IStrategy.Status)
```

Checks the status of a recipient probably tracked in a mapping, but will depend on the implementation      for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those      since there is no need for Pending or Rejected.



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

Getter for the &#39;id&#39; of the strategy.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | The ID of the strategy |

### increasePoolAmount

```solidity
function increasePoolAmount(uint256 _amount) external nonpayable
```

Increases the balance of the pool.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | The amount to increase the pool by |

### initialize

```solidity
function initialize(uint256 _poolId, bytes _data) external nonpayable
```

@dev The default BaseStrategy version will not use the data  if a strategy wants to use it, they will overwrite it,      use it, and then call super.initialize().



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool |
| _data | bytes | The encoded data |

### isPoolActive

```solidity
function isPoolActive() external nonpayable returns (bool)
```

whether pool is active.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | Whether the pool is active or not |

### isValidAllocator

```solidity
function isValidAllocator(address _allocator) external view returns (bool)
```

Checks whether a allocator is valid or not, will usually be true for all strategies      and will depend on the strategy implementation.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _allocator | address | The allocator to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | Whether the allocator is valid or not |

### registerRecipient

```solidity
function registerRecipient(bytes _data, address _sender) external payable returns (address)
```

This will register a recipient, set their status (and any other strategy specific values), and         return the ID of the recipient.

*Able to change status all the way up to &#39;Accepted&#39;, or to &#39;Pending&#39; and if there are more steps, additional      functions should be added to allow the owner to check this. The owner could also check attestations directly      and then accept for instance. The &#39;_data&#39; will be determined by the strategy implementation.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _data | bytes | The data to use to register the recipient |
| _sender | address | The address of the sender |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The ID of the recipient |



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

### PoolActive

```solidity
event PoolActive(bool active)
```

Emitted when pool is set to active status.



#### Parameters

| Name | Type | Description |
|---|---|---|
| active  | bool | The status of the pool |

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



