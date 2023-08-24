# IAllo









## Methods

### addPoolManager

```solidity
function addPoolManager(uint256 _poolId, address _manager) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _manager | address | undefined |

### addToCloneableStrategies

```solidity
function addToCloneableStrategies(address _strategy) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | undefined |

### allocate

```solidity
function allocate(uint256 _poolId, bytes _data) external payable
```



*Allocates funds to a recipient and emits {Allocated} event if successful Note: Each strategy will handle the allocation of funds differently*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _data | bytes | undefined |

### batchAllocate

```solidity
function batchAllocate(uint256[] _poolIds, bytes[] _datas) external nonpayable
```



*Allocates funds to multiple recipients and emits {Allocated} event if successful for each recipient Note: Each strategy will handle the allocation of funds differently*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolIds | uint256[] | undefined |
| _datas | bytes[] | undefined |

### batchRegisterRecipient

```solidity
function batchRegisterRecipient(uint256[] _poolIds, bytes[] _data) external nonpayable returns (address[])
```



*Registers a batch of recipients and emits {Registered} event if successful for each recipient      and may be handled differently by each strategy Requirements: determined by the strategy*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolIds | uint256[] | undefined |
| _data | bytes[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### distribute

```solidity
function distribute(uint256 _poolId, address[] _recipientIds, bytes _data) external nonpayable
```



*Distributes funds to recipients and emits {Distributed} event if successful Note: Each strategy will handle the distribution of funds differently*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _recipientIds | address[] | undefined |
| _data | bytes | undefined |

### fundPool

```solidity
function fundPool(uint256 _poolId, uint256 _amount) external payable
```



*Funds a pool and emits {PoolFunded} event if successful Requirements: None, but &#39;msg.value&#39; must be greater than 0 if the token is the native token               or &#39;_amount&#39; must be greater than 0 if the token is not the native token*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _amount | uint256 | undefined |

### getBaseFee

```solidity
function getBaseFee() external view returns (uint256)
```



*Returns the current base fee*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getFeeDenominator

```solidity
function getFeeDenominator() external view returns (uint256)
```



*Returns the current fee denominator - set at 1e18 to represent 100%*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getPercentFee

```solidity
function getPercentFee() external view returns (uint256)
```



*Returns the current percent fee*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getPool

```solidity
function getPool(uint256) external view returns (struct IAllo.Pool)
```



*Returns the &#39;Pool&#39; struct for a given &#39;poolId&#39;*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IAllo.Pool | undefined |

### getRegistry

```solidity
function getRegistry() external view returns (contract IRegistry)
```



*Returns the current registry address*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IRegistry | undefined |

### getStrategy

```solidity
function getStrategy(uint256 _poolId) external view returns (address)
```



*Returns the address of the strategy for a given &#39;poolId&#39;*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getTreasury

```solidity
function getTreasury() external view returns (address payable)
```



*Returns the current treasury address*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address payable | undefined |

### initialize

```solidity
function initialize(address _registry, address payable _treasury, uint256 _percentFee, uint256 _baseFee) external nonpayable
```

==================================== ==== External/Public Functions ===== ====================================



#### Parameters

| Name | Type | Description |
|---|---|---|
| _registry | address | undefined |
| _treasury | address payable | undefined |
| _percentFee | uint256 | undefined |
| _baseFee | uint256 | undefined |

### isCloneableStrategy

```solidity
function isCloneableStrategy(address) external view returns (bool)
```



*Checks if a strategy is cloneable (is in the cloneableStrategies mapping) and returns a boolean*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isPoolAdmin

```solidity
function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool)
```



*Checks if an address is a pool admin and returns a boolean*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _address | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isPoolManager

```solidity
function isPoolManager(uint256 _poolId, address _address) external view returns (bool)
```



*Checks if an address is a pool manager and returns a boolean*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _address | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### recoverFunds

```solidity
function recoverFunds(address _token, address _recipient) external nonpayable
```

Requirements: &#39;msg.sender&#39; must be a pool admin



#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | undefined |
| _recipient | address | undefined |

### registerRecipient

```solidity
function registerRecipient(uint256 _poolId, bytes _data) external payable returns (address)
```



*Registers a recipient and emits {Registered} event if successful and may be handled differently by each strategy Requirements: determined by the strategy*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _data | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### removeFromCloneableStrategies

```solidity
function removeFromCloneableStrategies(address _strategy) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | undefined |

### removePoolManager

```solidity
function removePoolManager(uint256 _poolId, address _manager) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _manager | address | undefined |

### updateBaseFee

```solidity
function updateBaseFee(uint256 _baseFee) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _baseFee | uint256 | undefined |

### updatePercentFee

```solidity
function updatePercentFee(uint256 _percentFee) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _percentFee | uint256 | undefined |

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





#### Parameters

| Name | Type | Description |
|---|---|---|
| _registry | address | undefined |

### updateTreasury

```solidity
function updateTreasury(address payable _treasury) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _treasury | address payable | undefined |



## Events

### BaseFeePaid

```solidity
event BaseFeePaid(uint256 indexed poolId, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| poolId `indexed` | uint256 | undefined |
| amount  | uint256 | undefined |

### BaseFeeUpdated

```solidity
event BaseFeeUpdated(uint256 baseFee)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| baseFee  | uint256 | undefined |

### PercentFeeUpdated

```solidity
event PercentFeeUpdated(uint256 percentFee)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| percentFee  | uint256 | undefined |

### PoolCreated

```solidity
event PoolCreated(uint256 indexed poolId, bytes32 indexed profileId, contract IStrategy strategy, address token, uint256 amount, Metadata metadata)
```

====================== ======= Events ======= ======================



#### Parameters

| Name | Type | Description |
|---|---|---|
| poolId `indexed` | uint256 | undefined |
| profileId `indexed` | bytes32 | undefined |
| strategy  | contract IStrategy | undefined |
| token  | address | undefined |
| amount  | uint256 | undefined |
| metadata  | Metadata | undefined |

### PoolFunded

```solidity
event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| poolId `indexed` | uint256 | undefined |
| amount  | uint256 | undefined |
| fee  | uint256 | undefined |

### PoolMetadataUpdated

```solidity
event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| poolId `indexed` | uint256 | undefined |
| metadata  | Metadata | undefined |

### RegistryUpdated

```solidity
event RegistryUpdated(address registry)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registry  | address | undefined |

### StrategyApproved

```solidity
event StrategyApproved(address strategy)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| strategy  | address | undefined |

### StrategyRemoved

```solidity
event StrategyRemoved(address strategy)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| strategy  | address | undefined |

### TreasuryUpdated

```solidity
event TreasuryUpdated(address treasury)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| treasury  | address | undefined |



## Errors

### INVALID_FEE

```solidity
error INVALID_FEE()
```






### IS_APPROVED_STRATEGY

```solidity
error IS_APPROVED_STRATEGY()
```






### MISMATCH

```solidity
error MISMATCH()
```






### NOT_APPROVED_STRATEGY

```solidity
error NOT_APPROVED_STRATEGY()
```






### NOT_ENOUGH_FUNDS

```solidity
error NOT_ENOUGH_FUNDS()
```






### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```

====================== ======= Errors ======= ======================




### ZERO_ADDRESS

```solidity
error ZERO_ADDRESS()
```







