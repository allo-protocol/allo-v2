# SimpleProjectRegistry

*@0xZakk &lt;zakk@gitcoin.co&gt;*

> Simple Project Registry

This contract is a simple implementation of a registry. It is intended to show that strategies can leverage their own registries. It assumes an owner, like a DAO, with explicit permission to add and remove projects from the registry.



## Methods

### addProject

```solidity
function addProject(address _project) external nonpayable
```

Add a project to the registry



#### Parameters

| Name | Type | Description |
|---|---|---|
| _project | address | The project to add |

### addProjects

```solidity
function addProjects(address[] _projects) external nonpayable
```

Add an array projects to the registry



#### Parameters

| Name | Type | Description |
|---|---|---|
| _projects | address[] | The projects to add |

### cancelOwnershipHandover

```solidity
function cancelOwnershipHandover() external payable
```



*Cancels the two-step ownership handover to the caller, if any.*


### completeOwnershipHandover

```solidity
function completeOwnershipHandover(address pendingOwner) external payable
```



*Allows the owner to complete the two-step ownership handover to `pendingOwner`. Reverts if there is no existing ownership handover requested by `pendingOwner`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| pendingOwner | address | undefined |

### owner

```solidity
function owner() external view returns (address result)
```



*Returns the owner of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| result | address | undefined |

### ownershipHandoverExpiresAt

```solidity
function ownershipHandoverExpiresAt(address pendingOwner) external view returns (uint256 result)
```



*Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| pendingOwner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| result | uint256 | undefined |

### projects

```solidity
function projects(address) external view returns (bool)
```

The projects in the registry



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### removeProject

```solidity
function removeProject(address _project) external nonpayable
```

Remove a project from the registry



#### Parameters

| Name | Type | Description |
|---|---|---|
| _project | address | The project to remove |

### removeProjects

```solidity
function removeProjects(address[] _projects) external nonpayable
```

Remove an array of projects from the registry



#### Parameters

| Name | Type | Description |
|---|---|---|
| _projects | address[] | The projects to remove |

### renounceOwnership

```solidity
function renounceOwnership() external payable
```



*Allows the owner to renounce their ownership.*


### requestOwnershipHandover

```solidity
function requestOwnershipHandover() external payable
```



*Request a two-step ownership handover to the caller. The request will automatically expire in 48 hours (172800 seconds) by default.*


### transferOwnership

```solidity
function transferOwnership(address newOwner) external payable
```



*Allows the owner to transfer the ownership to `newOwner`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |



## Events

### OwnershipHandoverCanceled

```solidity
event OwnershipHandoverCanceled(address indexed pendingOwner)
```



*The ownership handover to `pendingOwner` has been canceled.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| pendingOwner `indexed` | address | undefined |

### OwnershipHandoverRequested

```solidity
event OwnershipHandoverRequested(address indexed pendingOwner)
```



*An ownership handover to `pendingOwner` has been requested.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| pendingOwner `indexed` | address | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed oldOwner, address indexed newOwner)
```



*The ownership is transferred from `oldOwner` to `newOwner`. This event is intentionally kept the same as OpenZeppelin&#39;s Ownable to be compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173), despite it not being as lightweight as a single argument event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| oldOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### ProjectAdded

```solidity
event ProjectAdded(address indexed project)
```

Emitted when a project is added to the Registry



#### Parameters

| Name | Type | Description |
|---|---|---|
| project `indexed` | address | The project that was added |

### ProjectRemoved

```solidity
event ProjectRemoved(address indexed project)
```

Emitted when a project is removed from the Registry



#### Parameters

| Name | Type | Description |
|---|---|---|
| project `indexed` | address | The project that was removed |



## Errors

### ALREADY_EXISTS

```solidity
error ALREADY_EXISTS()
```

Error when a project is already in the registry




### DOESNT_EXIST

```solidity
error DOESNT_EXIST()
```






### NewOwnerIsZeroAddress

```solidity
error NewOwnerIsZeroAddress()
```



*The `newOwner` cannot be the zero address.*


### NoHandoverRequest

```solidity
error NoHandoverRequest()
```



*The `pendingOwner` does not have a valid handover request.*


### Unauthorized

```solidity
error Unauthorized()
```



*The caller is not authorized to call the function.*



