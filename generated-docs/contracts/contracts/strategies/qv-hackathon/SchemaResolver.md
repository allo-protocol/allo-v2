# SchemaResolver



> A base resolver contract





## Methods

### VERSION

```solidity
function VERSION() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### attest

```solidity
function attest(Attestation attestation) external payable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| attestation | Attestation | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isPayable

```solidity
function isPayable() external pure returns (bool)
```

Returns whether the resolver supports ETH transfers.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### multiAttest

```solidity
function multiAttest(Attestation[] attestations, uint256[] values) external payable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| attestations | Attestation[] | undefined |
| values | uint256[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### multiRevoke

```solidity
function multiRevoke(Attestation[] attestations, uint256[] values) external payable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| attestations | Attestation[] | undefined |
| values | uint256[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### revoke

```solidity
function revoke(Attestation attestation) external payable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| attestation | Attestation | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |




## Errors

### AccessDenied

```solidity
error AccessDenied()
```






### InsufficientValue

```solidity
error InsufficientValue()
```






### NotPayable

```solidity
error NotPayable()
```







