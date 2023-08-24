# Registry

*allo-team*

> Registry

Registry contract for creating and managing profiles

*This contract is used to create and manage profiles for the Allo protocol*

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

Transfers the ownership of the profile to the pending owner Requirements: Must be the pending owner of the profile to accept ownership

*Only pending owner can claim ownership*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |

### addMembers

```solidity
function addMembers(bytes32 _profileId, address[] _members) external nonpayable
```

Adds members to the profile Requirements: Must be the owner of the profile to add members



#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |
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

*This can be used when you have the &#39;anchor&#39; address and want to retrieve the profile*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _anchor | address | The anchor of the profile |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IRegistry.Profile | Profile The profile for the anchor passed |

### getProfileById

```solidity
function getProfileById(bytes32 _profileId) external view returns (struct IRegistry.Profile)
```

Retrieve profile by profileId

*This can be used when you have the &#39;profileId&#39; and want to retrieve the profile*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IRegistry.Profile | Profile The profile for the profileId |

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

### isMemberOfProfile

```solidity
function isMemberOfProfile(bytes32 _profileId, address _member) external view returns (bool)
```

Returns if the given address is an member of the profile



#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |
| _member | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if the address is an member of the profile |

### isOwnerOfProfile

```solidity
function isOwnerOfProfile(bytes32 _profileId, address _owner) external view returns (bool)
```

Returns if the given address is an owner of the profile



#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |
| _owner | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if the address is an owner of the profile |

### isOwnerOrMemberOfProfile

```solidity
function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account) external view returns (bool)
```

Returns if the given address is an owner or member of the profile



#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |
| _account | address | The address to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | bool Returns true if the address is an owner or member of the profile |

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



*Transfer thefunds recovered  to the recipient*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | The address of the token to transfer |
| _recipient | address | The address of the recipient Requirements: Only the Allo owner can recover funds |

### removeMembers

```solidity
function removeMembers(bytes32 _profileId, address[] _members) external nonpayable
```

Removes members from the profile Requirements: Must be the owner of the profile to remove members



#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |
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

Updates the name of the profile and generates new anchor Requirements: Must be the owner of the profile Note: Use caution when updating your profile name as it will generate a new anchor address Note: You can always update the name back to the original name to get the original anchor address

*Only owner can update the name*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |
| _name | string | The new name of the profile |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### updateProfilePendingOwner

```solidity
function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner) external nonpayable
```

Updates the pending owner of the profile Requirements: Must be the owner of the profile to update the owner



#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The profileId of the profile |
| _pendingOwner | address | New pending owner |



## Events

### ProfileCreated

```solidity
event ProfileCreated(bytes32 indexed profileId, uint256 nonce, string name, Metadata metadata, address owner, address anchor)
```



*Event emitted when a profile is created Note: This will return your anchor address*

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



*Event emitted when a profile&#39;s metadata is updated*

#### Parameters

| Name | Type | Description |
|---|---|---|
| profileId `indexed` | bytes32 | undefined |
| metadata  | Metadata | undefined |

### ProfileNameUpdated

```solidity
event ProfileNameUpdated(bytes32 indexed profileId, string name, address anchor)
```



*Event emitted when a profile name is updated Note: This will update the anchor when the name is updated and return it*

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



*Event emitted when a profile owner is updated*

#### Parameters

| Name | Type | Description |
|---|---|---|
| profileId `indexed` | bytes32 | undefined |
| owner  | address | undefined |

### ProfilePendingOwnerUpdated

```solidity
event ProfilePendingOwnerUpdated(bytes32 indexed profileId, address pendingOwner)
```



*Event emitted when a profile pending owner is updated*

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

### AMOUNT_MISMATCH

```solidity
error AMOUNT_MISMATCH()
```






### NONCE_NOT_AVAILABLE

```solidity
error NONCE_NOT_AVAILABLE()
```



*Returned when the nonce passed has been used or not available*


### NOT_PENDING_OWNER

```solidity
error NOT_PENDING_OWNER()
```



*Returned when the &#39;msg.sender&#39; is not the pending owner on ownership transfer*


### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```



*Returned when the &#39;msg.sender&#39; is not authorized*


### ZERO_ADDRESS

```solidity
error ZERO_ADDRESS()
```



*Returned if any address check is the zero address*



