# Registry

*@thelostone-mc &lt;aditya@gitcoin.co&gt;, @0xKurt &lt;kurt@gitcoin.co&gt;, @codenamejason &lt;jason@gitcoin.co&gt;, @0xZakk &lt;zakk@gitcoin.co&gt;, @nfrgosselin &lt;nate@gitcoin.co&gt;*

> Registry Contract

Registry contract for creating and managing profiles

*This contract is used to create and manage profiles for the Allo protocol      It is also used to deploy the anchor contract for each profile which acts as a proxy      for the profile and is used to receive funds and execute transactions on behalf of the profile      The Registry is also used to add and remove members from a profile and update the profile &#39;Metadata&#39;*

## Methods

### ALLO_OWNER

```solidity
function ALLO_OWNER() external view returns (bytes32)
```

Allo Owner Role for fund recovery




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

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

### acceptProfileOwnership

```solidity
function acceptProfileOwnership(bytes32 _profileId) external nonpayable
```

Transfers the ownership of the profile to the pending owner         Emits a &#39;ProfileOwnerUdpated()&#39; event.

*&#39;msg.sender&#39; must be the pending owner of the profile.       This is step two of two when transferring ownership.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; of the profile |

### addMembers

```solidity
function addMembers(bytes32 _profileId, address[] _members) external nonpayable
```

Adds members to the profile

*&#39;msg.sender&#39; must be the pending owner of the profile.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; of the profile |
| _members | address[] | The members to add |

### anchorToProfileId

```solidity
function anchorToProfileId(address) external view returns (bytes32)
```

anchor -&gt; Profile.id



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### createProfile

```solidity
function createProfile(uint256 _nonce, string _name, Metadata _metadata, address _owner, address[] _members) external nonpayable returns (bytes32)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _nonce | uint256 | undefined |
| _name | string | undefined |
| _metadata | Metadata | undefined |
| _owner | address | undefined |
| _members | address[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### getProfileByAnchor

```solidity
function getProfileByAnchor(address _anchor) external view returns (struct IRegistry.Profile)
```

Retrieve profile by anchor

*Used when you have the &#39;anchor&#39; address and want to retrieve the profile*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _anchor | address | The anchor of the profile |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IRegistry.Profile | Profile for the anchor passed |

### getProfileById

```solidity
function getProfileById(bytes32 _profileId) external view returns (struct IRegistry.Profile)
```

Retrieve profile by profileId

*Used when you have the &#39;profileId&#39; and want to retrieve the profile*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IRegistry.Profile | The Profile  for the profileId |

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
function initialize(address _owner) external nonpayable
```

Initializes the contract after an upgrade

*During upgrade -&gt; a higher version should be passed to reinitializerReverts if the &#39;_owner&#39; is the &#39;address(0)&#39;*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner | address | The owner of the contract |

### isMemberOfProfile

```solidity
function isMemberOfProfile(bytes32 _profileId, address _member) external view returns (bool)
```

Returns if the given address is an member of the profile



#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; of the profile |
| _member | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the address is an member of the profile, otherwise &#39;false&#39; |

### isOwnerOfProfile

```solidity
function isOwnerOfProfile(bytes32 _profileId, address _owner) external view returns (bool)
```

Checks if the given address is an owner of the profile



#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; of the profile |
| _owner | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the address is an owner of the profile, otherwise &#39;false&#39; |

### isOwnerOrMemberOfProfile

```solidity
function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account) external view returns (bool)
```

Checks if the address is an owner or member of the profile



#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; of the profile |
| _account | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | &#39;true&#39; if the address is an owner or member of the profile, otherwise &#39;fasle&#39; |

### profileIdToPendingOwner

```solidity
function profileIdToPendingOwner(bytes32) external view returns (address)
```

Profile.id -&gt; pending owner



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### profilesById

```solidity
function profilesById(bytes32) external view returns (bytes32 id, uint256 nonce, string name, struct Metadata metadata, address owner, address anchor)
```

Profile.id -&gt; Profile



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| id | bytes32 | undefined |
| nonce | uint256 | undefined |
| name | string | undefined |
| metadata | Metadata | undefined |
| owner | address | undefined |
| anchor | address | undefined |

### recoverFunds

```solidity
function recoverFunds(address _token, address _recipient) external nonpayable
```

Transfers any fund balance in Allo to the recipient

*&#39;msg.sender&#39; must be the Allo owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | The address of the token to transfer |
| _recipient | address | The address of the recipient |

### removeMembers

```solidity
function removeMembers(bytes32 _profileId, address[] _members) external nonpayable
```

Removes members from the profile

*&#39;msg.sender&#39; must be the pending owner of the profile.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; of the profile |
| _members | address[] | The members to remove |

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

### updateProfileMetadata

```solidity
function updateProfileMetadata(bytes32 _profileId, Metadata _metadata) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |
| _metadata | Metadata | undefined |

### updateProfileName

```solidity
function updateProfileName(bytes32 _profileId, string _name) external nonpayable returns (address)
```

Updates the name of the profile and generates new anchor.         Emits a &#39;ProfileNameUpdated()&#39; event. Note: Use caution when updating your profile name as it will generate a new anchor address Note: You can always update the name back to the original name to get the original anchor address

*&#39;msg.sender&#39; must be the owner of the profile*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |
| _name | string | The new name of the profile |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The new anchor |

### updateProfilePendingOwner

```solidity
function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner) external nonpayable
```

Updates the pending owner of the profile. Emits a &#39;ProfilePendingOwnership()&#39; event.

*&#39;msg.sender&#39; must be the owner of the profile.       This is step one of two when transferring ownership.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; of the profile |
| _pendingOwner | address | New pending owner |



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

### ProfileCreated

```solidity
event ProfileCreated(bytes32 indexed profileId, uint256 nonce, string name, Metadata metadata, address owner, address anchor)
```



*Emitted when a profile is created. This will return your anchor address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| profileId `indexed` | bytes32 | undefined |
| nonce  | uint256 | undefined |
| name  | string | undefined |
| metadata  | Metadata | undefined |
| owner  | address | undefined |
| anchor  | address | undefined |

### ProfileMetadataUpdated

```solidity
event ProfileMetadataUpdated(bytes32 indexed profileId, Metadata metadata)
```



*Emitted when a profile&#39;s metadata is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| profileId `indexed` | bytes32 | undefined |
| metadata  | Metadata | undefined |

### ProfileNameUpdated

```solidity
event ProfileNameUpdated(bytes32 indexed profileId, string name, address anchor)
```



*Emitted when a profile name is updated. This will update the anchor when the name is updated and return it.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| profileId `indexed` | bytes32 | undefined |
| name  | string | undefined |
| anchor  | address | undefined |

### ProfileOwnerUpdated

```solidity
event ProfileOwnerUpdated(bytes32 indexed profileId, address owner)
```



*Emitted when a profile owner is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| profileId `indexed` | bytes32 | undefined |
| owner  | address | undefined |

### ProfilePendingOwnerUpdated

```solidity
event ProfilePendingOwnerUpdated(bytes32 indexed profileId, address pendingOwner)
```



*Emitted when a profile pending owner is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| profileId `indexed` | bytes32 | undefined |
| pendingOwner  | address | undefined |

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




### ZERO_ADDRESS

```solidity
error ZERO_ADDRESS()
```

Thrown when address is the zero address





