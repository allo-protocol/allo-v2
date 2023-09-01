# IRegistry

*@thelostone-mc &lt;aditya@gitcoin.co&gt;, @0xKurt &lt;kurt@gitcoin.co&gt;, @codenamejason &lt;jason@gitcoin.co&gt;, @0xZakk &lt;zakk@gitcoin.co&gt;, @nfrgosselin &lt;nate@gitcoin.co&gt;*

> IRegistry Interface

Interface for the Registry contract and exposes all functions needed to use the Registry         within the Allo protocol.

*The Registry Interface is used to interact with the Allo protocol and create profiles      that can be used to interact with the Allo protocol. The Registry is the main contract      that all other contracts interact with to get the &#39;Profile&#39; information needed to      interact with the Allo protocol. The Registry is also used to create new profiles      and update existing profiles. The Registry is also used to add and remove members      from a profile. The Registry will not always be used in a strategy and will depend on      the strategy being used.*

## Methods

### acceptProfileOwnership

```solidity
function acceptProfileOwnership(bytes32 _profileId) external nonpayable
```



*Accepts the pending &#39;owner&#39; of the &#39;_profileId&#39; passed in Requirements: Only the pending owner can accept the ownership*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; to accept the ownership for |

### addMembers

```solidity
function addMembers(bytes32 _profileId, address[] _members) external nonpayable
```



*Adds members to the &#39;_profileId&#39; passed in Requirements: Only the &#39;Profile&#39; owner can add members*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; to add members to |
| _members | address[] | The members to add to the &#39;_profileId&#39; passed in |

### createProfile

```solidity
function createProfile(uint256 _nonce, string _name, Metadata _metadata, address _owner, address[] _members) external nonpayable returns (bytes32 profileId)
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
| profileId | bytes32 | undefined |

### getProfileByAnchor

```solidity
function getProfileByAnchor(address _anchor) external view returns (struct IRegistry.Profile profile)
```



*Returns the &#39;Profile&#39; for an &#39;_anchor&#39; passed*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _anchor | address | The &#39;anchor&#39; to return the &#39;Profile&#39; for |

#### Returns

| Name | Type | Description |
|---|---|---|
| profile | IRegistry.Profile | The &#39;Profile&#39; for the &#39;_anchor&#39; passed |

### getProfileById

```solidity
function getProfileById(bytes32 _profileId) external view returns (struct IRegistry.Profile profile)
```



*Returns the &#39;Profile&#39; for a &#39;_profileId&#39; passed*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; to return the &#39;Profile&#39; for |

#### Returns

| Name | Type | Description |
|---|---|---|
| profile | IRegistry.Profile | The &#39;Profile&#39; for the &#39;_profileId&#39; passed |

### isMemberOfProfile

```solidity
function isMemberOfProfile(bytes32 _profileId, address _member) external view returns (bool isMemberOfProfile)
```



*Returns a boolean if the &#39;_account&#39; is a member of the &#39;_profileId&#39; passed in*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; to check if the &#39;_account&#39; is a member of |
| _member | address | The &#39;member&#39; to check if they are a member of the &#39;_profileId&#39; passed in |

#### Returns

| Name | Type | Description |
|---|---|---|
| isMemberOfProfile | bool | A boolean if the &#39;_account&#39; is a member of the &#39;_profileId&#39; passed in |

### isOwnerOfProfile

```solidity
function isOwnerOfProfile(bytes32 _profileId, address _owner) external view returns (bool isOwnerOfProfile)
```



*Returns a boolean if the &#39;_account&#39; is an owner of the &#39;_profileId&#39; passed in*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; to check if the &#39;_account&#39; is an owner of |
| _owner | address | The &#39;owner&#39; to check if they are an owner of the &#39;_profileId&#39; passed in |

#### Returns

| Name | Type | Description |
|---|---|---|
| isOwnerOfProfile | bool | A boolean if the &#39;_account&#39; is an owner of the &#39;_profileId&#39; passed in |

### isOwnerOrMemberOfProfile

```solidity
function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account) external view returns (bool isOwnerOrMemberOfProfile)
```



*Returns a boolean if the &#39;_account&#39; is a member or owner of the &#39;_profileId&#39; passed in*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; to check if the &#39;_account&#39; is a member or owner of |
| _account | address | The &#39;account&#39; to check if they are a member or owner of the &#39;_profileId&#39; passed in |

#### Returns

| Name | Type | Description |
|---|---|---|
| isOwnerOrMemberOfProfile | bool | A boolean if the &#39;_account&#39; is a member or owner of the &#39;_profileId&#39; passed in |

### recoverFunds

```solidity
function recoverFunds(address _token, address _recipient) external nonpayable
```



*Recovers funds from the contract Requirements: Must be the Allo owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | The token you want to use to recover funds |
| _recipient | address | The recipient of the recovered funds |

### removeMembers

```solidity
function removeMembers(bytes32 _profileId, address[] _members) external nonpayable
```



*Removes members from the &#39;_profileId&#39; passed in Requirements: Only the &#39;Profile&#39; owner can remove members*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; to remove members from |
| _members | address[] | The members to remove from the &#39;_profileId&#39; passed in |

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
function updateProfileName(bytes32 _profileId, string _name) external nonpayable returns (address anchor)
```



*Updates the &#39;name&#39; of the &#39;_profileId&#39; passed in and returns the new &#39;anchor&#39; address Requirements: Only the &#39;Profile&#39; owner can update the name Note: The &#39;name&#39; and &#39;nonce&#39; are used to generate the &#39;anchor&#39; address and this will update the &#39;anchor&#39;       so please use caution. You can always recreate your &#39;anchor&#39; address by updating the name back       to the original name used to create the profile.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; to update the name for |
| _name | string | The new &#39;name&#39; value |

#### Returns

| Name | Type | Description |
|---|---|---|
| anchor | address | The new &#39;anchor&#39; address |

### updateProfilePendingOwner

```solidity
function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner) external nonpayable
```



*Updates the pending &#39;owner&#39; of the &#39;_profileId&#39; passed in Requirements: Only the &#39;Profile&#39; owner can update the pending owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _profileId | bytes32 | The &#39;profileId&#39; to update the pending owner for |
| _pendingOwner | address | The new pending &#39;owner&#39; value |



## Events

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



