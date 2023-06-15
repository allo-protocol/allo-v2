# IRegistry









## Methods

### createIdentity

```solidity
function createIdentity(IRegistry.IdentityDetails _identityDetails, address[] _owners) external nonpayable returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _identityDetails | IRegistry.IdentityDetails | undefined |
| _owners | address[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### identities

```solidity
function identities(uint256 _projectId) external view returns (struct IRegistry.IdentityDetails)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _projectId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IRegistry.IdentityDetails | undefined |

### isOwnerOfIdentity

```solidity
function isOwnerOfIdentity(uint256 _identityId, address _owner) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _identityId | uint256 | undefined |
| _owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |




