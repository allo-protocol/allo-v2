# Registry









## Methods

### addIdentityOwner

```solidity
function addIdentityOwner(bytes32 identityId, address newOwner) external nonpayable
```

Associate a new owner with a project



#### Parameters

| Name | Type | Description |
|---|---|---|
| identityId | bytes32 | ID of previously created project |
| newOwner | address | address of new project owner |

### createIdentity

```solidity
function createIdentity(MetaPtr metadata) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| metadata | MetaPtr | undefined |

### getProjectOwners

```solidity
function getProjectOwners(bytes32 identityId) external view returns (address[])
```

Retrieve list of project owners



#### Parameters

| Name | Type | Description |
|---|---|---|
| identityId | bytes32 | ID of project |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | List of current owners of given project |

### identities

```solidity
function identities(bytes32) external view returns (bytes32 id, struct MetaPtr metadata)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| id | bytes32 | undefined |
| metadata | MetaPtr | undefined |

### identitiesCount

```solidity
function identitiesCount() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### identityOwners

```solidity
function identityOwners(bytes32) external view returns (uint256 count)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| count | uint256 | undefined |

### identityOwnersCount

```solidity
function identityOwnersCount(bytes32 identityId) external view returns (uint256)
```

Retrieve count of existing project owners



#### Parameters

| Name | Type | Description |
|---|---|---|
| identityId | bytes32 | ID of project |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Count of owners for given project |

### initialize

```solidity
function initialize() external nonpayable
```

Initializes the contract after an upgrade

*In future deploys of the implementation, an higher version should be passed to reinitializer*


### removeIdentityOwner

```solidity
function removeIdentityOwner(bytes32 identityId, address prevOwner, address owner) external nonpayable
```

Disassociate an existing owner from a project



#### Parameters

| Name | Type | Description |
|---|---|---|
| identityId | bytes32 | ID of previously created project |
| prevOwner | address | Address of previous owner in OwnerList |
| owner | address | Address of new Owner |

### updateIdentityMetadata

```solidity
function updateIdentityMetadata(bytes32 identityId, MetaPtr metadata) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| identityId | bytes32 | undefined |
| metadata | MetaPtr | undefined |



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

### MetadataUpdated

```solidity
event MetadataUpdated(bytes32 indexed identityId, MetaPtr metaPtr)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| identityId `indexed` | bytes32 | undefined |
| metaPtr  | MetaPtr | undefined |

### OwnerAdded

```solidity
event OwnerAdded(bytes32 indexed identityId, address indexed owner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| identityId `indexed` | bytes32 | undefined |
| owner `indexed` | address | undefined |

### OwnerRemoved

```solidity
event OwnerRemoved(bytes32 indexed identityId, address indexed owner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| identityId `indexed` | bytes32 | undefined |
| owner `indexed` | address | undefined |

### ProjectCreated

```solidity
event ProjectCreated(bytes32 indexed identityId, address indexed owner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| identityId `indexed` | bytes32 | undefined |
| owner `indexed` | address | undefined |



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



