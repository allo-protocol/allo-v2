# ERC1967Proxy







*This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an implementation address that can be changed. This address is stored in storage in the location specified by https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn&#39;t conflict with the storage layout of the implementation behind the proxy.*


## Events

### AdminChanged

```solidity
event AdminChanged(address previousAdmin, address newAdmin)
```



*Emitted when the admin account has changed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| previousAdmin  | address | undefined |
| newAdmin  | address | undefined |

### BeaconUpgraded

```solidity
event BeaconUpgraded(address indexed beacon)
```



*Emitted when the beacon is changed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| beacon `indexed` | address | undefined |

### Upgraded

```solidity
event Upgraded(address indexed implementation)
```



*Emitted when the implementation is upgraded.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| implementation `indexed` | address | undefined |



