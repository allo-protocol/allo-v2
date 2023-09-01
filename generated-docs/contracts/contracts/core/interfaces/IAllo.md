# IAllo

*@thelostone-mc &lt;aditya@gitcoin.co&gt;, @0xKurt &lt;kurt@gitcoin.co&gt;, @codenamejason &lt;jason@gitcoin.co&gt;, @0xZakk &lt;zakk@gitcoin.co&gt;, @nfrgosselin &lt;nate@gitcoin.co&gt;*

> Allo Interface

Interface for the Allo contract. It exposes all functions needed to use the Allo protocol.



## Methods

### addPoolManager

```solidity
function addPoolManager(uint256 _poolId, address _manager) external nonpayable
```

Adds a pool manager to the pool.

*&#39;msg.sender&#39; must be a pool admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool to add the manager to |
| _manager | address | The address of the manager to add |

### addToCloneableStrategies

```solidity
function addToCloneableStrategies(address _strategy) external nonpayable
```

Adds a strategy to the cloneable strategies.

*&#39;msg.sender&#39; must be the Allo contract owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | The address of the strategy to add |

### allocate

```solidity
function allocate(uint256 _poolId, bytes _data) external payable
```

Allocates funds to a recipient.

*Each strategy will handle the allocation of funds differently.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool to allocate funds from |
| _data | bytes | The data to pass to the strategy and may be handled differently by each strategy. |

### batchAllocate

```solidity
function batchAllocate(uint256[] _poolIds, bytes[] _datas) external nonpayable
```

Allocates funds to multiple recipients.

*Each strategy will handle the allocation of funds differently*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolIds | uint256[] | undefined |
| _datas | bytes[] | undefined |

### batchRegisterRecipient

```solidity
function batchRegisterRecipient(uint256[] _poolIds, bytes[] _data) external nonpayable returns (address[])
```

Registers a batch of recipients.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolIds | uint256[] | The pool ID&#39;s to register the recipients for |
| _data | bytes[] | The data to pass to the strategy and may be handled differently by each strategy |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### distribute

```solidity
function distribute(uint256 _poolId, address[] _recipientIds, bytes _data) external nonpayable
```

Distributes funds to recipients and emits {Distributed} event if successful

*Each strategy will handle the distribution of funds differently*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool to distribute from |
| _recipientIds | address[] | The recipient ids to distribute to |
| _data | bytes | The data to pass to the strategy and may be handled differently by each strategy |

### fundPool

```solidity
function fundPool(uint256 _poolId, uint256 _amount) external payable
```

Funds a pool.

*&#39;msg.value&#39; must be greater than 0 if the token is the native token       or &#39;_amount&#39; must be greater than 0 if the token is not the native token.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool to fund |
| _amount | uint256 | The amount to fund the pool with |

### getBaseFee

```solidity
function getBaseFee() external view returns (uint256)
```

Returns the current base fee




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | baseFee The current base fee |

### getFeeDenominator

```solidity
function getFeeDenominator() external view returns (uint256)
```

Returns the current fee denominator

*1e18 represents 100%*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | feeDenominator The current fee denominator |

### getPercentFee

```solidity
function getPercentFee() external view returns (uint256)
```

Returns the current percent fee




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | percentFee The current percentage for the fee |

### getPool

```solidity
function getPool(uint256 _poolId) external view returns (struct IAllo.Pool)
```

Returns the &#39;Pool&#39; struct for a given &#39;poolId&#39;



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IAllo.Pool | pool The &#39;Pool&#39; struct for the ID of the pool passed in |

### getRegistry

```solidity
function getRegistry() external view returns (contract IRegistry)
```

Returns the current registry address




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IRegistry | registry The current registry address |

### getStrategy

```solidity
function getStrategy(uint256 _poolId) external view returns (address)
```

Returns the address of the strategy for a given &#39;poolId&#39;



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | strategy The address of the strategy for the ID of the pool passed in |

### getTreasury

```solidity
function getTreasury() external view returns (address payable)
```

Returns the current treasury address




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address payable | treasury The current treasury address |

### initialize

```solidity
function initialize(address _registry, address payable _treasury, uint256 _percentFee, uint256 _baseFee) external nonpayable
```

Initialize the Allo contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| _registry | address | Address of the registry contract |
| _treasury | address payable | Address of the treasury |
| _percentFee | uint256 | Percentage for the fee |
| _baseFee | uint256 | Base fee amount |

### isCloneableStrategy

```solidity
function isCloneableStrategy(address _strategy) external view returns (bool)
```

Checks if a strategy is cloneable (is in the cloneableStrategies mapping).



#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | The address of the strategy to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the &#39;_strategy&#39; is cloneable, otherwise &#39;false&#39; |

### isPoolAdmin

```solidity
function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool)
```

Checks if an address is a pool admin.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool to check |
| _address | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the &#39;_address&#39; is a pool admin, otherwise &#39;false&#39; |

### isPoolManager

```solidity
function isPoolManager(uint256 _poolId, address _address) external view returns (bool)
```

Checks if an address is a pool manager.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool to check |
| _address | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the &#39;_address&#39; is a pool manager, otherwise &#39;false&#39; |

### recoverFunds

```solidity
function recoverFunds(address _token, address _recipient) external nonpayable
```

Recovers funds from a pool.

*&#39;msg.sender&#39; must be a pool admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | The token to recover |
| _recipient | address | The address to send the recovered funds to |

### registerRecipient

```solidity
function registerRecipient(uint256 _poolId, bytes _data) external payable returns (address)
```

Registers a recipient and emits {Registered} event if successful and may be handled differently by each strategy.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool to register the recipient for |
| _data | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### removeFromCloneableStrategies

```solidity
function removeFromCloneableStrategies(address _strategy) external nonpayable
```

Removes a strategy from the cloneable strategies.

*&#39;msg.sender&#39; must be the Allo contract owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | The address of the strategy to remove |

### removePoolManager

```solidity
function removePoolManager(uint256 _poolId, address _manager) external nonpayable
```

Removes a pool manager from the pool.

*&#39;msg.sender&#39; must be a pool admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool to remove the manager from |
| _manager | address | The address of the manager to remove |

### updateBaseFee

```solidity
function updateBaseFee(uint256 _baseFee) external nonpayable
```

Updates the base fee.

*&#39;msg.sender&#39; must be the Allo contract owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _baseFee | uint256 | The new base fee |

### updatePercentFee

```solidity
function updatePercentFee(uint256 _percentFee) external nonpayable
```

Updates the percentage for the fee.

*&#39;msg.sender&#39; must be the Allo contract owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _percentFee | uint256 | The new percentage for the fee |

### updatePoolMetadata

```solidity
function updatePoolMetadata(uint256 _poolId, Metadata _metadata) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _metadata | Metadata | undefined |

### updateRegistry

```solidity
function updateRegistry(address _registry) external nonpayable
```

Update the registry address.

*&#39;msg.sender&#39; must be the Allo contract owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _registry | address | The new registry address |

### updateTreasury

```solidity
function updateTreasury(address payable _treasury) external nonpayable
```

Updates the treasury address.

*&#39;msg.sender&#39; must be the Allo contract owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _treasury | address payable | The new treasury address |



## Events

### BaseFeePaid

```solidity
event BaseFeePaid(uint256 indexed poolId, uint256 amount)
```

Emitted when the base fee is paid



#### Parameters

| Name | Type | Description |
|---|---|---|
| poolId `indexed` | uint256 | ID of the pool the base fee was paid for |
| amount  | uint256 | Amount of the base fee paid |

### BaseFeeUpdated

```solidity
event BaseFeeUpdated(uint256 baseFee)
```

Emitted when the base fee is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| baseFee  | uint256 | New base fee amount |

### PercentFeeUpdated

```solidity
event PercentFeeUpdated(uint256 percentFee)
```

Emitted when the percent fee is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| percentFee  | uint256 | New percentage for the fee |

### PoolCreated

```solidity
event PoolCreated(uint256 indexed poolId, bytes32 indexed profileId, contract IStrategy strategy, address token, uint256 amount, Metadata metadata)
```

Event emitted when a new pool is created



#### Parameters

| Name | Type | Description |
|---|---|---|
| poolId `indexed` | uint256 | ID of the pool created |
| profileId `indexed` | bytes32 | ID of the profile the pool is associated with |
| strategy  | contract IStrategy | Address of the strategy contract |
| token  | address | Address of the token pool was funded with when created |
| amount  | uint256 | Amount pool was funded with when created |
| metadata  | Metadata | Pool metadata |

### PoolFunded

```solidity
event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee)
```

Emitted when a pool is funded



#### Parameters

| Name | Type | Description |
|---|---|---|
| poolId `indexed` | uint256 | ID of the pool funded |
| amount  | uint256 | Amount funded to the pool |
| fee  | uint256 | Amount of the fee paid to the treasury |

### PoolMetadataUpdated

```solidity
event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata)
```

Emitted when a pools metadata is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| poolId `indexed` | uint256 | ID of the pool updated |
| metadata  | Metadata | Pool metadata that was updated |

### RegistryUpdated

```solidity
event RegistryUpdated(address registry)
```

Emitted when the registry address is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| registry  | address | Address of the new registry |

### StrategyApproved

```solidity
event StrategyApproved(address strategy)
```

Emitted when a strategy is approved and added to the cloneable strategies



#### Parameters

| Name | Type | Description |
|---|---|---|
| strategy  | address | Address of the strategy approved |

### StrategyRemoved

```solidity
event StrategyRemoved(address strategy)
```

Emitted when a strategy is removed from the cloneable strategies



#### Parameters

| Name | Type | Description |
|---|---|---|
| strategy  | address | Address of the strategy removed |

### TreasuryUpdated

```solidity
event TreasuryUpdated(address treasury)
```

Emitted when the treasury address is updated



#### Parameters

| Name | Type | Description |
|---|---|---|
| treasury  | address | Address of the new treasury |



