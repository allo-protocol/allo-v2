# BeaconProxy







*This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}. The beacon address is stored in storage slot `uint256(keccak256(&#39;eip1967.proxy.beacon&#39;)) - 1`, so that it doesn&#39;t conflict with the storage layout of the implementation behind the proxy. _Available since v3.4._*


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



