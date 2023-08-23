# IRegistry

*allo-team*

> IRegistry Interface The Registry contract is used to store and manage all the profiles that are created within the Allo protocol

Interface for the Registry contract and exposes all functions needed to use the Registry         within the Allo protocol



## Methods

### acceptProfileOwnership

```solidity
function acceptProfileOwnership(bytes32 _profileId) external nonpayable
```



*Accepts the pending &#39;owner&#39; of the &#39;_profileId&#39; passed in Requirements: Only the pending owner can accept the ownership*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |

### addMembers

```solidity
function addMembers(bytes32 _profileId, address[] _members) external nonpayable
```



*Adds members to the &#39;_profileId&#39; passed in Requirements: Only the &#39;Profile&#39; owner can add members*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |
| _members | address[] | undefined |

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



*Returns the &#39;Profile&#39; for an &#39;_anchor&#39; passed*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _anchor | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IRegistry.Profile | undefined |

### getProfileById

```solidity
function getProfileById(bytes32 _profileId) external view returns (struct IRegistry.Profile)
```



*Returns the &#39;Profile&#39; for a &#39;_profileId&#39; passed*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IRegistry.Profile | undefined |

### isMemberOfProfile

```solidity
function isMemberOfProfile(bytes32 _profileId, address _member) external view returns (bool)
```



*Returns a boolean if the &#39;_account&#39; is a member of the &#39;_profileId&#39; passed in*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |
| _member | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isOwnerOfProfile

```solidity
function isOwnerOfProfile(bytes32 _profileId, address _owner) external view returns (bool)
```



*Returns a boolean if the &#39;_account&#39; is an owner of the &#39;_profileId&#39; passed in*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |
| _owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isOwnerOrMemberOfProfile

```solidity
function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account) external view returns (bool)
```



*Returns a boolean if the &#39;_account&#39; is a member or owner of the &#39;_profileId&#39; passed in*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |
| _account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### recoverFunds

```solidity
function recoverFunds(address _token, address _recipient) external nonpayable
```



*Recovers funds from the contract Requirements: Must be the Allo owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | undefined |
| _recipient | address | undefined |

### removeMembers

```solidity
function removeMembers(bytes32 _profileId, address[] _members) external nonpayable
```



*Removes members from the &#39;_profileId&#39; passed in Requirements: Only the &#39;Profile&#39; owner can remove members*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |
| _members | address[] | undefined |

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



*Updates the &#39;name&#39; of the &#39;_profileId&#39; passed in and returns the new &#39;anchor&#39; address Requirements: Only the &#39;Profile&#39; owner can update the name Note: The &#39;name&#39; and &#39;nonce&#39; are used to generate the &#39;anchor&#39; address and this will update the &#39;anchor&#39;       so please use caution. You can always recreate your &#39;anchor&#39; address by updating the name back       to the original name used to create the profile.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |
| _name | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### updateProfilePendingOwner

```solidity
function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner) external nonpayable
```



*Updates the pending &#39;owner&#39; of the &#39;_profileId&#39; passed in Requirements: Only the &#39;Profile&#39; owner can update the pending owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | undefined |
| _pendingOwner | address | undefined |



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



## Errors

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



