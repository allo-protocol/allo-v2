# NFT









## Methods

### MINT_PRICE

```solidity
function MINT_PRICE() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### TOTAL_SUPPLY

```solidity
function TOTAL_SUPPLY() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### approve

```solidity
function approve(address account, uint256 id) external payable
```



*Sets `account` as the approved account to manage token `id`. Requirements: - Token `id` must exist. - The caller must be the owner of the token,   or an approved operator for the token owner. Emits an {Approval} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| id | uint256 | undefined |

### balanceOf

```solidity
function balanceOf(address owner) external view returns (uint256 result)
```



*Returns the number of tokens owned by `owner`. Requirements: - `owner` must not be the zero address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| result | uint256 | undefined |

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

### currentTokenId

```solidity
function currentTokenId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getApproved

```solidity
function getApproved(uint256 id) external view returns (address result)
```



*Returns the account approved to manage token `id`. Requirements: - Token `id` must exist.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| result | address | undefined |

### isApprovedForAll

```solidity
function isApprovedForAll(address owner, address operator) external view returns (bool result)
```



*Returns whether `operator` is approved to manage the tokens of `owner`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| operator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| result | bool | undefined |

### mintTo

```solidity
function mintTo(address to) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |

### name

```solidity
function name() external view returns (string)
```



*Returns the token collection name.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### owner

```solidity
function owner() external view returns (address result)
```



*Returns the owner of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| result | address | undefined |

### ownerOf

```solidity
function ownerOf(uint256 id) external view returns (address result)
```



*Returns the owner of token `id`. Requirements: - Token `id` must exist.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |

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


### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 id) external payable
```



*Equivalent to `safeTransferFrom(from, to, id, &quot;&quot;)`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| id | uint256 | undefined |

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 id, bytes data) external payable
```



*Transfers token `id` from `from` to `to`. Requirements: - Token `id` must exist. - `from` must be the owner of the token. - `to` cannot be the zero address. - The caller must be the owner of the token, or be approved to manage the token. - If `to` refers to a smart contract, it must implement   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer. Emits a {Transfer} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| id | uint256 | undefined |
| data | bytes | undefined |

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool isApproved) external nonpayable
```



*Sets whether `operator` is approved to manage the tokens of the caller. Emits an {ApprovalForAll} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |
| isApproved | bool | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool result)
```



*Returns true if this contract implements the interface defined by `interfaceId`. See: https://eips.ethereum.org/EIPS/eip-165 This function call must use less than 30000 gas.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| result | bool | undefined |

### symbol

```solidity
function symbol() external view returns (string)
```



*Returns the token collection symbol.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### tokenURI

```solidity
function tokenURI(uint256 tokenId) external pure returns (string)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 id) external payable
```



*Transfers token `id` from `from` to `to`. Requirements: - Token `id` must exist. - `from` must be the owner of the token. - `to` cannot be the zero address. - The caller must be the owner of the token, or be approved to manage the token. Emits a {Transfer} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| id | uint256 | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external payable
```



*Allows the owner to transfer the ownership to `newOwner`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### withdrawPayments

```solidity
function withdrawPayments(address payable payee) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| payee | address payable | undefined |



## Events

### Approval

```solidity
event Approval(address indexed owner, address indexed account, uint256 indexed id)
```



*Emitted when `owner` enables `account` to manage the `id` token.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | undefined |
| account `indexed` | address | undefined |
| id `indexed` | uint256 | undefined |

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved)
```



*Emitted when `owner` enables or disables `operator` to manage all of their tokens.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | undefined |
| operator `indexed` | address | undefined |
| isApproved  | bool | undefined |

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

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 indexed id)
```



*Emitted when token `id` is transferred from `from` to `to`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| id `indexed` | uint256 | undefined |



## Errors

### AccountBalanceOverflow

```solidity
error AccountBalanceOverflow()
```



*The recipient&#39;s balance has overflowed.*


### BalanceQueryForZeroAddress

```solidity
error BalanceQueryForZeroAddress()
```



*Cannot query the balance for the zero address.*


### MaxSupply

```solidity
error MaxSupply()
```






### MintPriceNotPaid

```solidity
error MintPriceNotPaid()
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


### NonExistentTokenURI

```solidity
error NonExistentTokenURI()
```






### NotOwnerNorApproved

```solidity
error NotOwnerNorApproved()
```



*Only the token owner or an approved account can manage the token.*


### TokenAlreadyExists

```solidity
error TokenAlreadyExists()
```



*The token already exists.*


### TokenDoesNotExist

```solidity
error TokenDoesNotExist()
```



*The token does not exist.*


### TransferFromIncorrectOwner

```solidity
error TransferFromIncorrectOwner()
```



*The token must be owned by `from`.*


### TransferToNonERC721ReceiverImplementer

```solidity
error TransferToNonERC721ReceiverImplementer()
```



*Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.*


### TransferToZeroAddress

```solidity
error TransferToZeroAddress()
```



*Cannot mint or transfer to the zero address.*


### Unauthorized

```solidity
error Unauthorized()
```



*The caller is not authorized to call the function.*


### WithdrawTransfer

```solidity
error WithdrawTransfer()
```







