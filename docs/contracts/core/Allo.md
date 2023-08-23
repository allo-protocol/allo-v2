# Allo

*allo-team*

> ___            ___        ___        ___         /\  \          /\__\      /\__\      /\  \        /::\  \        /:/  /     /:/  /     /::\  \       /:/\:\  \      /:/  /     /:/  /     /:/\:\  \      /::\~\:\  \    /:/  /     /:/  /     /:/  \:\  \     /:/\:\ \:\__\  /:/__/     /:/__/     /:/__/ \:\__\     \/__\:\/:/  /  \:\  \     \:\  \     \:\  \ /:/  /          \::/  /    \:\  \     \:\  \     \:\  /:/  /          /:/  /      \:\  \     \:\  \     \:\/:/  /         /:/  /        \:\__\     \:\__\     \::/  /         \/__/          \/__/      \/__/      \/__/

The Allo core contract

*This contract is used to create &amp; manage pools as well as manage the protocol. It      is the core of all things Allo. Requirements: The contract must be initialized with the &#39;initialize()&#39; function*

## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### NATIVE

```solidity
function NATIVE() external view returns (address)
```

Address of the native token




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### addPoolManager

```solidity
function addPoolManager(uint256 _poolId, address _manager) external nonpayable
```

Add a pool manager

*emits &#39;RoleGranted()&#39; event Requirements: The caller must be a pool admin*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The pool id |
| _manager | address | The address to add |

### addToCloneableStrategies

```solidity
function addToCloneableStrategies(address _strategy) external nonpayable
```

Add a strategy to the allowlist

*Only callable by the owner, emits the &#39;StrategyApproved()&#39; event Requirements: The caller must be allo owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | The address of the strategy |

### allocate

```solidity
function allocate(uint256 _poolId, bytes _data) external payable
```

passes _data &amp; msg.sender through to the strategy for that pool

*Calls the internal _allocate() function Requirements: This will be determined by the strategy*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | id of the pool |
| _data | bytes | encoded data unique to the strategy for that pool |

### batchAllocate

```solidity
function batchAllocate(uint256[] _poolIds, bytes[] _datas) external nonpayable
```

vote to multiple pools Requirements: This will be determined by the strategy



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolIds | uint256[] | ids of the pools |
| _datas | bytes[] | encoded data unique to the strategy for that pool |

### batchRegisterRecipient

```solidity
function batchRegisterRecipient(uint256[] _poolIds, bytes[] _data) external nonpayable returns (address[] recipientIds)
```

Register multiple recipients to multiple pools

*Returns the recipientIds from the strategy that have been registered from calling this funciton Requirements: Encoded &#39;_data&#39; length must match _poolIds length or this will revert with MISMATCH()               Other requirements will be determined by the strategy*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolIds | uint256[] | Id of the pools |
| _data | bytes[] | Encoded data unique to a strategy that registerRecipient() requires |

#### Returns

| Name | Type | Description |
|---|---|---|
| recipientIds | address[] | The recipientIds that have been registered |

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

### createPool

```solidity
function createPool(bytes32 _profileId, address _strategy, bytes _initStrategyData, address _token, uint256 _amount, Metadata _metadata, address[] _managers) external payable returns (uint256 poolId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |
| _strategy | address | undefined |
| _initStrategyData | bytes | undefined |
| _token | address | undefined |
| _amount | uint256 | undefined |
| _metadata | Metadata | undefined |
| _managers | address[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| poolId | uint256 | undefined |

### createPoolWithCustomStrategy

```solidity
function createPoolWithCustomStrategy(bytes32 _profileId, address _strategy, bytes _initStrategyData, address _token, uint256 _amount, Metadata _metadata, address[] _managers) external payable returns (uint256 poolId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |
| _strategy | address | undefined |
| _initStrategyData | bytes | undefined |
| _token | address | undefined |
| _amount | uint256 | undefined |
| _metadata | Metadata | undefined |
| _managers | address[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| poolId | uint256 | undefined |

### distribute

```solidity
function distribute(uint256 _poolId, address[] _recipientIds, bytes _data) external nonpayable
```

passes _data &amp; msg.sender through to the disribution strategy for that pool Requirements: This will be determined by the strategy



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | id of the pool |
| _recipientIds | address[] | undefined |
| _data | bytes | encoded data unique to the strategy for that pool |

### fundPool

```solidity
function fundPool(uint256 _poolId, uint256 _amount) external payable
```

Fund a pool

*Calls the internal _fundPool() function Requirements: None, anyone can fund a pool*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | id of the pool |
| _amount | uint256 | extra amount of the token to be deposited into the pool |

### getBaseFee

```solidity
function getBaseFee() external view returns (uint256)
```

Getter for base fee




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getFeeDenominator

```solidity
function getFeeDenominator() external pure returns (uint256 FEE_DENOMINATOR)
```

Getter for the fee denominator




#### Returns

| Name | Type | Description |
|---|---|---|
| FEE_DENOMINATOR | uint256 | The fee denominator (1e18) which represents 100% |

### getPercentFee

```solidity
function getPercentFee() external view returns (uint256)
```

Getter for fee percentage




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getPool

```solidity
function getPool(uint256 _poolId) external view returns (struct IAllo.Pool)
```

Getter for the &#39;Pool&#39;



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IAllo.Pool | undefined |

### getRegistry

```solidity
function getRegistry() external view returns (contract IRegistry)
```

Getter for registry




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IRegistry | undefined |

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```



*Returns the admin role that controls `role`. See {grantRole} and {revokeRole}. To change a role&#39;s admin, use {_setRoleAdmin}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### getStrategy

```solidity
function getStrategy(uint256 _poolId) external view returns (address)
```

Return the strategy for a pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The pool id |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | address |

### getTreasury

```solidity
function getTreasury() external view returns (address payable)
```

Getter for treasury address




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address payable | undefined |

### grantRole

```solidity
function grantRole(bytes32 role, address account) external nonpayable
```



*Grants `role` to `account`. If `account` had not been already granted `role`, emits a {RoleGranted} event. Requirements: - the caller must have ``role``&#39;s admin role. May emit a {RoleGranted} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```



*Returns `true` if `account` has been granted `role`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### initialize

```solidity
function initialize(address _registry, address payable _treasury, uint256 _percentFee, uint256 _baseFee) external nonpayable
```

Initializes the contract after an upgrade

*During upgrade -&gt; an higher version should be passed to reinitializer*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _registry | address | The address of the registry |
| _treasury | address payable | The address of the treasury |
| _percentFee | uint256 | The percentage fee |
| _baseFee | uint256 | The base fee |

### isCloneableStrategy

```solidity
function isCloneableStrategy(address _strategy) external view returns (bool)
```

Getter for if strategy is cloneable



#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isPoolAdmin

```solidity
function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool)
```

Checks if the address is a pool admin



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The pool id |
| _address | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool |

### isPoolManager

```solidity
function isPoolManager(uint256 _poolId, address _address) external view returns (bool)
```

Checks if the address is a pool manager



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The pool id |
| _address | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool |

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

### recoverFunds

```solidity
function recoverFunds(address _token, address _recipient) external nonpayable
```

Transfer thefunds recovered  to the recipient Requirements: The caller must be a pool owner



#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | The address of the token to transfer |
| _recipient | address | The address of the recipient |

### registerRecipient

```solidity
function registerRecipient(uint256 _poolId, bytes _data) external payable returns (address)
```

Passes _data through to the strategy for that pool Requirements: This will be determined by the strategy



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | Id of the pool |
| _data | bytes | Encoded data unique to a strategy that registerRecipient() requires |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | recipientId The recipientId that has been registered |

### removeFromCloneableStrategies

```solidity
function removeFromCloneableStrategies(address _strategy) external nonpayable
```

Remove a strategy from the allowlist

*Only callable by the owner, emits &#39;StrategyRemoved()&#39; event Requirements: The caller must be allo owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | The address of the strategy |

### removePoolManager

```solidity
function removePoolManager(uint256 _poolId, address _manager) external nonpayable
```

Remove a pool manager

*emits &#39;RoleRevoked()&#39; event Requirements: The caller must be a pool admin*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The pool id |
| _manager | address | The address remove |

### renounceOwnership

```solidity
function renounceOwnership() external payable
```



*Allows the owner to renounce their ownership.*


### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from the calling account. Roles are often managed via {grantRole} and {revokeRole}: this function&#39;s purpose is to provide a mechanism for accounts to lose their privileges if they are compromised (such as when a trusted device is misplaced). If the calling account had been revoked `role`, emits a {RoleRevoked} event. Requirements: - the caller must be `account`. May emit a {RoleRevoked} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### requestOwnershipHandover

```solidity
function requestOwnershipHandover() external payable
```



*Request a two-step ownership handover to the caller. The request will automatically expire in 48 hours (172800 seconds) by default.*


### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from `account`. If `account` had been granted `role`, emits a {RoleRevoked} event. Requirements: - the caller must have ``role``&#39;s admin role. May emit a {RoleRevoked} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See {IERC165-supportsInterface}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external payable
```



*Allows the owner to transfer the ownership to `newOwner`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### updateBaseFee

```solidity
function updateBaseFee(uint256 _baseFee) external nonpayable
```

Updates the base fee

*Use this to update the base fee Requirements: The caller must be allo owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _baseFee | uint256 | The new base fee |

### updatePercentFee

```solidity
function updatePercentFee(uint256 _percentFee) external nonpayable
```

Updates the fee percentage

*Use this to update the fee percentage Requirements: The caller must be allo owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _percentFee | uint256 | The new fee |

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

Updates the registry address

*Use this to update the registry address Requirements: The caller must be allo owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _registry | address | The new registry address |

### updateTreasury

```solidity
function updateTreasury(address payable _treasury) external nonpayable
```

Updates the treasury address

*Use this to update the treasury address Requirements: The caller must be allo owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _treasury | address payable | The new treasury address |



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

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

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

### RoleAdminChanged

```solidity
event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
```



*Emitted when `newAdminRole` is set as ``role``&#39;s admin role, replacing `previousAdminRole` `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite {RoleAdminChanged} not being emitted signaling this. _Available since v3.1._*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| previousAdminRole `indexed` | bytes32 | undefined |
| newAdminRole `indexed` | bytes32 | undefined |

### RoleGranted

```solidity
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
```



*Emitted when `account` is granted `role`. `sender` is the account that originated the contract call, an admin role bearer except when using {AccessControl-_setupRole}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

### RoleRevoked

```solidity
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
```



*Emitted when `account` is revoked `role`. `sender` is the account that originated the contract call:   - if using `revokeRole`, it is the admin role bearer   - if using `renounceRole`, it is the role bearer (i.e. `account`)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

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

### AMOUNT_MISMATCH

```solidity
error AMOUNT_MISMATCH()
```






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


### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```

====================== ======= Errors ======= ======================




### Unauthorized

```solidity
error Unauthorized()
```



*The caller is not authorized to call the function.*


### ZERO_ADDRESS

```solidity
error ZERO_ADDRESS()
```







