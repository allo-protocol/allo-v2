# Allo

*@thelostone-mc &lt;aditya@gitcoin.co&gt;, @0xKurt &lt;kurt@gitcoin.co&gt;, @codenamejason &lt;jason@gitcoin.co&gt;, @0xZakk &lt;zakk@gitcoin.co&gt;, @nfrgosselin &lt;nate@gitcoin.co&gt;*

> Allo

This contract is used to create &amp; manage pools as well as manage the protocol.

*The contract must be initialized with the &#39;initialize()&#39; function.*

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

*Emits &#39;RoleGranted()&#39; event. &#39;msg.sender&#39; must be a pool admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | ID of the pool |
| _manager | address | The address to add |

### addToCloneableStrategies

```solidity
function addToCloneableStrategies(address _strategy) external nonpayable
```

Add a strategy to the allowlist.

*Emits the &#39;StrategyApproved()&#39; event. &#39;msg.sender&#39; must be Allo owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | The address of the strategy |

### allocate

```solidity
function allocate(uint256 _poolId, bytes _data) external payable
```

Allocate to a recipient or multiple recipients.

*The encoded data will be specific to a given strategy requirements, reference the strategy      implementation of allocate().*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | ID of the pool |
| _data | bytes | Encoded data unique to the strategy for that pool |

### batchAllocate

```solidity
function batchAllocate(uint256[] _poolIds, bytes[] _datas) external nonpayable
```

Allocate to multiple pools

*The encoded data will be specific to a given strategy requirements, reference the strategy      implementation of allocate(). Please note that this is not a &#39;payable&#39; function, so if you      want to send funds to the strategy, you must send the funds using &#39;fundPool()&#39;.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolIds | uint256[] | IDs of the pools |
| _datas | bytes[] | encoded data unique to the strategy for that pool |

### batchRegisterRecipient

```solidity
function batchRegisterRecipient(uint256[] _poolIds, bytes[] _data) external nonpayable returns (address[] recipientIds)
```

Register multiple recipients to multiple pools.

*Returns the &#39;recipientIds&#39; from the strategy that have been registered from calling this function.      Encoded data unique to a strategy that registerRecipient() requires. Encoded &#39;_data&#39; length must match      &#39;_poolIds&#39; length or this will revert with MISMATCH(). Other requirements will be determined by the strategy.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolIds | uint256[] | ID&#39;s of the pools |
| _data | bytes[] | An array of encoded data unique to a strategy that registerRecipient() requires. |

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

Distribute to a recipient or multiple recipients.

*The encoded data will be specific to a given strategy requirements, reference the strategy      implementation of &#39;strategy.distribute()&#39;.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | ID of the pool |
| _recipientIds | address[] | Ids of the recipients of the distribution |
| _data | bytes | Encoded data unique to the strategy |

### fundPool

```solidity
function fundPool(uint256 _poolId, uint256 _amount) external payable
```

Fund a pool.

*Anyone can fund a pool and call this function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | ID of the pool |
| _amount | uint256 | amount to be deposited into the pool |

### getBaseFee

```solidity
function getBaseFee() external view returns (uint256)
```

Getter for base fee.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The base fee |

### getFeeDenominator

```solidity
function getFeeDenominator() external pure returns (uint256 FEE_DENOMINATOR)
```

Getter for the fee denominator




#### Returns

| Name | Type | Description |
|---|---|---|
| FEE_DENOMINATOR | uint256 | The fee denominator is (1e18) which represents 100% |

### getPercentFee

```solidity
function getPercentFee() external view returns (uint256)
```

Getter for fee percentage.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The fee percentage |

### getPool

```solidity
function getPool(uint256 _poolId) external view returns (struct IAllo.Pool)
```

Getter for the &#39;Pool&#39;.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IAllo.Pool | The &#39;Pool&#39; struct |

### getRegistry

```solidity
function getRegistry() external view returns (contract IRegistry)
```

Getter for registry.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IRegistry | The registry address |

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

Getter for the strategy.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of the strategy |

### getTreasury

```solidity
function getTreasury() external view returns (address payable)
```

Getter for treasury address.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address payable | The treasury address |

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

*During upgrade -&gt; a higher version should be passed to reinitializer*

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

Getter for if strategy is cloneable.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | The address of the strategy |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the strategy is cloneable, otherwise &#39;false&#39; |

### isPoolAdmin

```solidity
function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool)
```

Checks if the address is a pool admin.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool |
| _address | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the address is a pool admin, otherwise &#39;false&#39; |

### isPoolManager

```solidity
function isPoolManager(uint256 _poolId, address _address) external view returns (bool)
```

Checks if the address is a pool manager



#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | The ID of the pool |
| _address | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the address is a pool manager, otherwise &#39;false&#39; |

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

Transfer the funds recovered  to the recipient

*&#39;msg.sender&#39; must be Allo owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | The address of the token to transfer |
| _recipient | address | The address of the recipient |

### registerRecipient

```solidity
function registerRecipient(uint256 _poolId, bytes _data) external payable returns (address)
```

Passes _data through to the strategy for that pool.

*The encoded data will be specific to a given strategy requirements, reference the strategy      implementation of registerRecipient().*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | ID of the pool |
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

*Emits &#39;StrategyRemoved()&#39; event. &#39;msg.sender must be Allo owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _strategy | address | The address of the strategy |

### removePoolManager

```solidity
function removePoolManager(uint256 _poolId, address _manager) external nonpayable
```

Remove a pool manager

*Emits &#39;RoleRevoked()&#39; event. &#39;msg.sender&#39; must be a pool admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _poolId | uint256 | ID of the pool |
| _manager | address | The address to remove |

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

Updates the base fee.

*Use this to update the base fee. &#39;msg.sender&#39; must be Allo owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _baseFee | uint256 | The new base fee |

### updatePercentFee

```solidity
function updatePercentFee(uint256 _percentFee) external nonpayable
```

Updates the fee percentage.

*Use this to update the fee percentage. &#39;msg.sender&#39; must be Allo owner.*

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

Updates the registry address.

*Use this to update the registry address. &#39;msg.sender&#39; must be Allo owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _registry | address | The new registry address |

### updateTreasury

```solidity
function updateTreasury(address payable _treasury) external nonpayable
```

Updates the treasury address.

*Use this to update the treasury address. &#39;msg.sender&#39; must be Allo owner.*

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



## Errors

### ALLOCATION_ACTIVE

```solidity
error ALLOCATION_ACTIVE()
```

Thrown when the allocation is active.




### ALLOCATION_NOT_ACTIVE

```solidity
error ALLOCATION_NOT_ACTIVE()
```

Thrown when the allocation is not active.




### ALLOCATION_NOT_ENDED

```solidity
error ALLOCATION_NOT_ENDED()
```

Thrown when the allocation is not ended.




### ALREADY_INITIALIZED

```solidity
error ALREADY_INITIALIZED()
```

Thrown when data is already intialized




### AMOUNT_MISMATCH

```solidity
error AMOUNT_MISMATCH()
```






### ANCHOR_ERROR

```solidity
error ANCHOR_ERROR()
```



*Thrown if the anchor creation fails*


### ARRAY_MISMATCH

```solidity
error ARRAY_MISMATCH()
```

Thrown when two arrays length are not equal




### INVALID

```solidity
error INVALID()
```

Thrown as a general error when input / data is invalid




### INVALID_ADDRESS

```solidity
error INVALID_ADDRESS()
```

Thrown when an invalid address is used




### INVALID_FEE

```solidity
error INVALID_FEE()
```

Thrown when the fee is below 1e18 which is the fee percentage denominator




### INVALID_METADATA

```solidity
error INVALID_METADATA()
```

Thrown when the metadata is invalid.




### INVALID_REGISTRATION

```solidity
error INVALID_REGISTRATION()
```

Thrown when the registration is invalid.




### IS_APPROVED_STRATEGY

```solidity
error IS_APPROVED_STRATEGY()
```

Thrown when the strategy is approved and should be cloned




### MISMATCH

```solidity
error MISMATCH()
```

Thrown when mismatch in decoding data




### NONCE_NOT_AVAILABLE

```solidity
error NONCE_NOT_AVAILABLE()
```



*Thrown when the nonce passed has been used or not available*


### NOT_APPROVED_STRATEGY

```solidity
error NOT_APPROVED_STRATEGY()
```

Thrown when the strategy is not approved




### NOT_ENOUGH_FUNDS

```solidity
error NOT_ENOUGH_FUNDS()
```

Thrown when not enough funds are available




### NOT_INITIALIZED

```solidity
error NOT_INITIALIZED()
```

Thrown when data is yet to be initialized




### NOT_PENDING_OWNER

```solidity
error NOT_PENDING_OWNER()
```



*Thrown when the &#39;msg.sender&#39; is not the pending owner on ownership transfer*


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


### POOL_ACTIVE

```solidity
error POOL_ACTIVE()
```

Thrown when a pool is already active




### POOL_INACTIVE

```solidity
error POOL_INACTIVE()
```

Thrown when a pool is inactive




### RECIPIENT_ALREADY_ACCEPTED

```solidity
error RECIPIENT_ALREADY_ACCEPTED()
```

Thrown when recipient is already accepted.




### RECIPIENT_ERROR

```solidity
error RECIPIENT_ERROR(address recipientId)
```

Thrown when there is an error in recipient.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipientId | address | undefined |

### RECIPIENT_NOT_ACCEPTED

```solidity
error RECIPIENT_NOT_ACCEPTED()
```

Thrown when the recipient is not accepted.




### REGISTRATION_NOT_ACTIVE

```solidity
error REGISTRATION_NOT_ACTIVE()
```

Thrown when registration is not active.




### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```

Thrown when user is not authorized




### Unauthorized

```solidity
error Unauthorized()
```



*The caller is not authorized to call the function.*


### ZERO_ADDRESS

```solidity
error ZERO_ADDRESS()
```

Thrown when address is the zero address





