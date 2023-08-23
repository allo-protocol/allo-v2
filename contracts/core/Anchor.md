# Anchor.sol

The `Anchor` contract serves as a crucial utility within the Allo ecosystem, facilitating the execution of calls to target addresses. Anchors are associated with profiles and are accessible exclusively to the profile owner. This contract ensures secure and authorized interaction with external addresses, enhancing the capabilities of profiles and enabling controlled execution of operations. The contract leverages the `Registry` contract for ownership verification and access control.

## Table of Contents
- [Anchor.sol](#anchorsol)
  - [Table of Contents](#table-of-contents)
  - [Smart Contract Overview](#smart-contract-overview)
    - [Storage Variables](#storage-variables)
    - [Errors](#errors)
    - [Constructor](#constructor)
    - [External Functions](#external-functions)
    - [Actors](#actors)
  - [User Flows](#user-flows)
    - [Constructor](#constructor-1)
    - [Execute Call to a Target Address](#execute-call-to-a-target-address)


## Smart Contract Overview

* **License:** The `Anchor` contract is licensed under the AGPL-3.0-only license, promoting the use of open-source software.
* **Solidity Version:** Developed using Solidity version 0.8.19, harnessing the latest advancements in Ethereum smart contract technology.

### Storage Variables

1. `registry` (Public Immutable): A reference to the `Registry` contract instance, enabling access to profile ownership information and access control.
2. `profileId` (Public Immutable): The profile ID associated with the anchor, used to verify the caller's ownership.

### Errors

1. `UNAUTHORIZED()`: An error triggered when an unauthorized caller attempts to execute a function reserved for the profile owner.
2. `CALL_FAILED()`: An error triggered when a call to a target address fails or is 0.

### Constructor

The constructor initializes the `registry` variable with a reference to the `Registry` contract and assigns the provided profile ID to the `profileId` variable.

### External Functions

1. **`execute`**: Execute a call to a target address, sending a specified amount of native tokens and data. Only the profile owner can initiate this operation.

### Actors

* **Profile Owner:** The profile owner has exclusive access to the `Anchor` contract and can execute calls to external addresses. Ownership is verified through the associated profile ID.
* **Registry Contract:** The `Anchor` contract relies on the `Registry` contract to validate the profile owner's authorization before executing operations.

In summary, the `Anchor` smart contract offers a secure and controlled mechanism for profile owners to interact with external addresses. By utilizing the `Registry` contract for authorization, the `Anchor` contract ensures that only authorized users can execute calls. Through its well-structured storage variables, constructor, and external function, the `Anchor` contract contributes to enhancing the capabilities of profiles within the Allo ecosystem.

## User Flows

### Constructor
    
* The contract's constructor takes a `_profileId` as a parameter and sets it as the `profileId` for the contract.
* It also sets the `registry` variable by taking the sender's address as an instance of the `Registry` contract.
### Execute Call to a Target Address
    
* Users can execute a call to a target address by calling the `execute` function.
* The function requires `_target`, `_value`, and `_data` as parameters.
* The function checks if the caller is the owner of the specified profile using the `isOwnerOfProfile` function from the `Registry` contract.
* Reverts if `_target` address is `address(0)`
* It then attempts to call the `_target` address with the provided `_value` and `_data`.
* If the call is successful, the function returns the data returned by the target call.
* If the call fails, the function reverts with a `CALL_FAILED` error.