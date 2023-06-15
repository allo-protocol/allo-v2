# Allo









## Methods

### initialize

```solidity
function initialize() external nonpayable
```

Initializes the contract after an upgrade

*In future deploys of the implementation, an higher version should be passed to reinitializer*




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



## Errors

### AlreadyInitialized

```solidity
error AlreadyInitialized()
```



*The contract is already initialized.*


### NotInitializing

```solidity
error NotInitializing()
```



*The contract is not initializing.*



