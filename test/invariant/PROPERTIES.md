# Properties & invariants

## Actors-based

| id  | property                                                                                                          | covered |
| --- | :---------------------------------------------------------------------------------------------------------------- | ------- |
| 1   | one should always be able to pull/push correct (based on strategy) allocation for recipient                       |   []    |
| 2   | a token allocation never “disappears” (withdraw cannot impact an allocation)                                      |   []    |
| 3   | an address can only withdraw if has allocation                                                                    |   []    |
| 4   | profile owner can always create a pool                                                                            |   []    |
| 5   | profile owner is the only one who can always add/remove/modify profile members (name ⇒ new anchor())              |   []    |
| 6   | profile owner is the only one who can always initiate a change of profile owner (2 steps)                         |   []    |
| 7   | profile member can always create a pool                                                                           |   []    |
| 8   | only profile owner or member can create a pool                                                                    |   []    |
| 9   | initial admin is always the creator of the pool                                                                   |   []    |
| 10  | pool admin can always change admin (but not to address(0))                                                        |   []    |
| 11  | pool admin can always add/remove pool managers                                                                    |   []    |
| 12  | pool manager can always withdraw within strategy limits/logic                                                     |   []    |
| 13  | pool manager can always change metadata                                                                           |   []    |
| 14  | allo owner can always change base fee (flat) and percent flee (./. funding amt) to any arbitrary value (max 100%) |   []    |
| 15  | allo owner can always change the treasury address/trustred forwarded/etc                                          |   []    |
| 16  | allo owner can always recover funds from allo contract ( (non-)native token )                                     |   []    |
| 17  | only funds not allocated can be withdrawn                                                                         |   []    |
| 18  | anyone can increase fund in a pool, if strategy (hook) logic allows so and if more than base fee                  |   []    |
| 19  | every deposit/pool creation must take the correct fee on the amount deposited, forwarded to the treasury          |   []    |


## Other leads

- After a pool creation, getting a pool should always return valid data for profileId and strategy address. [STATE TRANSITION]
- Allo must be initialised before creating/managing pools [VALID STATE]
- `percentFee` should never be more than 1e18 [VARIABLE TRANSITION]
- `_poolIndex` should only increase by 1 with each new pool created [VARIABLE TRANSITION]
- `recoverFunds` should always transfer all the contract’s specified tokens to the recipient [HIGH LEVEL]
- Funding a pool should always increase the strategy’s `poolAmount` [STATE TRANSITION]
- Funding a pool should deduct the `percentFee` and transfer the remaining tokens [UNIT]
- Pool must be created before being able to get funds (strategy address is valid) [STATE TRANSITION]
- Creating a pool should deduct the `baseFee` [UNIT]
- Only a profile of the registry can create a pool [HIGH LEVEL]
- Two pools can never have the same pool id [VALID STATE]
- A strategy should never be initialised more than once [UNIT]
- Creating a pool by cloning an existing strategy should deploy the strategy with a clean state [STATE TRANSITION]
- Creating a pool with an amount higher than 0 should fund the strategy contract with the amount minus the fees [STATE TRANSITION]
- Creating a pool should always make the sender pool admin [HIGH LEVEL
- Two profiles should never have the same anchor [HIGH LEVEL]
- After creating a profile the owner and anchor must be valid [STATE TRANSITION]
- Updating the profile’s name should deploy a new anchor [UNIT]
- To change a profile’s owner, the new owner must accept ownership first [STATE TRANSITION]

# Coverage

## Allo.sol
| Function Name                     | Sighash  | Function Signature                                                                             | Handler |
| --------------------------------- | -------- | ---------------------------------------------------------------------------------------------- | ------- |
| initialize                        | 4b636f72 | initialize(address,address,address,uint256,uint256,address)                                    | NA      |
| createPoolWithCustomStrategy      | e1007d4a | createPoolWithCustomStrategy(bytes32,address,bytes,address,uint256,(uint256,string),address[]) | []      |
| createPool                        | 77da8caf | createPool(bytes32,address,bytes,address,uint256,(uint256,string),address[])                   | [x]      |
| updatePoolMetadata                | 5f9ca138 | updatePoolMetadata(uint256,(uint256,string))                                                   | [x]      |
| updateRegistry                    | 1a5da6c8 | updateRegistry(address)                                                                        | []      |
| updateTreasury                    | 7f51bb1f | updateTreasury(address)                                                                        | []      |
| updatePercentFee                  | f54fc4a0 | updatePercentFee(uint256)                                                                      | [x]      |
| updateBaseFee                     | 8e690186 | updateBaseFee(uint256)                                                                         | [x]      |
| updateTrustedForwarder            | f90b0311 | updateTrustedForwarder(address)                                                                | []      |
| addPoolManagers                   | 7025b800 | addPoolManagers(uint256,address[])                                                             | []      |
| removePoolManagers                | ed8cae16 | removePoolManagers(uint256,address[])                                                          | []      |
| addPoolManagersInMultiplePools    | 2d50cce5 | addPoolManagersInMultiplePools(uint256[],address[])                                            | []      |
| removePoolManagersInMultiplePools | cf9d5057 | removePoolManagersInMultiplePools(uint256[],address[])                                         | []      |
| recoverFunds                      | 24ae6a27 | recoverFunds(address,address)                                                                  | []      |
| registerRecipient                 | 1919ede6 | registerRecipient(uint256,address[],bytes)                                                     | []      |
| batchRegisterRecipient            | 4653ebed | batchRegisterRecipient(uint256[],address[][],bytes[])                                          | []      |
| fundPool                          | 5acd6fac | fundPool(uint256,uint256)                                                                      | []      |
| allocate                          | 2037568f | allocate(uint256,address[],uint256[],bytes)                                                    | []      |
| batchAllocate                     | da49d0c9 | batchAllocate(uint256[],address[][],uint256[][],uint256[],bytes[])                             | []      |
| distribute                        | 3a5fbd92 | distribute(uint256,address[],bytes)                                                            | []      |
| changeAdmin                       | 6cc5af29 | changeAdmin(uint256,address)                                                                   | []      |

## Anchor.sol
| Function Name | Sighash  | Function Signature             | Handler |
| ------------- | -------- | ------------------------------ | ------- |
| execute       | b61d27f6 | execute(address,uint256,bytes) | [x]*     |
* Every call is constrained as either coming from an anchor or an eoa, when coming from an anchor, it is with a valid payload

## Registry.sol
| Function Name             | Sighash  | Function Signature                                               | Handler |
| ------------------------- | -------- | ---------------------------------------------------------------- | ------- |
| initialize                | c4d66de8 | initialize(address)                                              | NA      |
| createProfile             | 3a92f65f | createProfile(uint256,string,(uint256,string),address,address[]) | []      |
| updateProfileName         | cf189ff2 | updateProfileName(bytes32,string)                                | []      |
| updateProfileMetadata     | ac402839 | updateProfileMetadata(bytes32,(uint256,string))                  | []      |
| updateProfilePendingOwner | 3b66dacd | updateProfilePendingOwner(bytes32,address)                       | []      |
| acceptProfileOwnership    | 2497f3c6 | acceptProfileOwnership(bytes32)                                  | []      |
| addMembers                | 5063f361 | addMembers(bytes32,address[])                                    | []      |
| removeMembers             | e0cf1e4c | removeMembers(bytes32,address[])                                 | []      |
| recoverFunds              | 24ae6a27 | recoverFunds(address,address)                                    | []      |
