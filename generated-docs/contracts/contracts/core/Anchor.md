# Anchor

*@thelostone-mc &lt;aditya@gitcoin.co&gt;, @0xKurt &lt;kurt@gitcoin.co&gt;, @codenamejason &lt;jason@gitcoin.co&gt;, @0xZakk &lt;zakk@gitcoin.co&gt;, @nfrgosselin &lt;nate@gitcoin.co&gt;*

> Anchor contract

Anchors are associated with profiles and are accessible exclusively by the profile owner. This contract ensures secure         and authorized interaction with external addresses, enhancing the capabilities of profiles and enabling controlled         execution of operations. The contract leverages the `Registry` contract for ownership verification and access control.



## Methods

### execute

```solidity
function execute(address _target, uint256 _value, bytes _data) external nonpayable returns (bytes)
```

Execute a call to a target address

*&#39;msg.sender&#39; must be profile owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _target | address | The target address to call |
| _value | uint256 | The amount of native token to send |
| _data | bytes | The data to send to the target address |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | Data returned from the target address |

### profileId

```solidity
function profileId() external view returns (bytes32)
```

The profileId of the allowed profile to execute calls




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### registry

```solidity
function registry() external view returns (contract Registry)
```

The registry contract on any given network/chain




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract Registry | undefined |




## Errors

### CALL_FAILED

```solidity
error CALL_FAILED()
```

Throws when the call to the target address fails




### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```

Throws when the caller is not the owner of the profile





