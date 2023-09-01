# ContractFactory

*@thelostone-mc &lt;aditya@gitcoin.co&gt;, @0xKurt &lt;kurt@gitcoin.co&gt;, @codenamejason &lt;jason@gitcoin.co&gt;, @0xZakk &lt;zakk@gitcoin.co&gt;, @nfrgosselin &lt;nate@gitcoin.co&gt;*

> ContractFactory



*ContractFactory is used internally to deploy our contracts using CREATE3*

## Methods

### deploy

```solidity
function deploy(string _contractName, string _version, bytes creationCode) external payable returns (address deployedContract)
```

Deploys a contract using CREATE3.

*Used for our deployments.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _contractName | string | Name of the contract to deploy |
| _version | string | Version of the contract to deploy |
| creationCode | bytes | Creation code of the contract to deploy |

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedContract | address | Address of the deployed contract |

### isDeployer

```solidity
function isDeployer(address) external view returns (bool)
```

Collection of authorized deployers.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### setDeployer

```solidity
function setDeployer(address _deployer, bool _allowedToDeploy) external nonpayable
```

Set the allowed deployer.

*&#39;msg.sender&#39; must be a deployer.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _deployer | address | Address of the deployer to set |
| _allowedToDeploy | bool | Boolean to set the deployer to |

### usedSalts

```solidity
function usedSalts(bytes32) external view returns (bool)
```

Collection of used salts.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |



## Events

### Deployed

```solidity
event Deployed(address indexed deployed, bytes32 indexed salt)
```

Emitted when a contract is deployed.



#### Parameters

| Name | Type | Description |
|---|---|---|
| deployed `indexed` | address | undefined |
| salt `indexed` | bytes32 | undefined |



## Errors

### SALT_USED

```solidity
error SALT_USED()
```

Thrown when the requested salt has already been used.




### UNAUTHORIZED

```solidity
error UNAUTHORIZED()
```

Thrown when the caller is not authorized to deploy.





