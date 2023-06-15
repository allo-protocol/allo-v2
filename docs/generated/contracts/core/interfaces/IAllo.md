# IAllo









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
function claim(uint256 _poolId, bytes _data) external nonpayable
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




