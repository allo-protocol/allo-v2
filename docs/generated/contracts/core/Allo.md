# Allo









## Methods

### allocate

```solidity
function allocate(uint256 _poolId, bytes _data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _data | bytes | undefined |

### applyToPool

```solidity
function applyToPool(uint256 _poolId, bytes _data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _data | bytes | undefined |

### claim

```solidity
function distribute(uint256 _poolId, bytes _data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _data | bytes | undefined |

### createPool

```solidity
function createPool(IAllo.PoolData _poolData, address _poolToken, uint256 _poolAmt) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolData | IAllo.PoolData | undefined |
| _poolToken | address | undefined |
| _poolAmt | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### createPool

```solidity
function createPool(address allocationStrategy, uint256 startTime, uint256 endTime) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| allocationStrategy | address | undefined |
| startTime | uint256 | undefined |
| endTime | uint256 | undefined |

### finalize

```solidity
function finalize(uint256 _poolId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |

### fundPool

```solidity
function fundPool(uint256 _poolId, address _poolToken, uint256 _poolAmt) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |
| _poolToken | address | undefined |
| _poolAmt | uint256 | undefined |

### getPoolInfo

```solidity
function getPoolInfo(uint256 _poolId) external view returns (struct IAllo.PoolData, string)
```

calls out to the registry to get the project metadata



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IAllo.PoolData | undefined |
| _1 | string | undefined |

### initialize

```solidity
function initialize() external nonpayable
```

Initializes the contract after an upgrade

*In future deploys of the implementation, an higher version should be passed to reinitializer*




## Events

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |



## Errors

### AlreadyInitialized

```solidity
error AlreadyInitialized()
```



*The contract is already initialized.*


### NotInitializing

```solidity
error NotInitializing()
```



*The contract is not initializing.*
