Spec: Micro Grants
---------------------------------

### Overview

Micro-grants are a common way for communities to engage with their members and empower them to pursue projects that contribute to the community's overall mission. We see similar micro-grant programs across web3, including in large DAOs and web3 communities like Gitcoin, Celo, and ENS. While many communities have these programs, access to these grants can be difficult.

Most communities use their existing governance process to allocate and distribute these micro-grants. This means that a $5,000 grant to distribute merch at a hackathon (for example) has to go through the same, long governance process as protocol updates. Proposals are considered one-off, instead of evaluated side-by-side. Everyone in the community weighs in, whether that's appropriate or not.

## General Specifications

The pool creator would have to specify
    - registry profile is needed for registration
    - approved allocators
    - approval threshold 
    - max requested amount
    - allocation start time
    - allocation end time

### Recipient Logic

- **Recipient eligibility**
    - If `useRegistryAnchor` is `true`, only a profile member can register on behalf of the profile and `recipientId` will be `anchorAddress`
    - If `useRegistryAnchor` is `false`, any can register and `recipientId` will be `msg.sender`
- **Recipient information**
    - Recipient would have to provide
        - `recipientAddress` can be different from the `recipientId`
        - `requestedAmount` which has to be lesser than or equal to max amount
        - `metadata`
- **Registering recipients**
    - Anyone can register a recipient 
    - On registering/updating, the recipient is defaulted to `Pending` status
    - Re-registration is allowed until the recipient does not have an allocation

### Allocation Logic 


- **Allocator Eligibility**
    This would be whitelist which can be maintained by the `poolManager`. Once the minimum threshold is reached , the recipient is marked as `Accepted` and funds are `distributed`

- **Allocate function** 
   - An approved allocator can call `allocate` once per recipient. 
   - An allocator can can approve / reject application 
   - One threshold for `approval` is reached, recipient is marked as `Accepted` and funds are `distributed` to them


### Payout Calculation Logic

    - No payout calculation logic  


### Distribution Logic

    - No distribute logic

## Developer Specifications

### Data Parameter

The following functions may require a data parameter to be passed in. This parameter contains specific information or parameters necessary for the proper execution of the function. Please refer to the descriptions below for each function and provide the required data format or content.

- `initialize(uint256 _poolId, bytes memory _data)`: The `_data` parameter should contain the initialization data required for the strategy including 
    - `maxRequestedAmount`, 
    - `approvalThreshold`,
    - `useRegistryAnchor`
    - `allocationStartTime`
    - `allocationEndTime`

- `registerRecipients(bytes memory _data, address _sender)`: The `_data` parameter should contain the data required for recipient registration. 
    - `recipientAddress`
    - `recipientId` which would updated based on the `useRegistryAnchor`
    - `requestedAmount`
    - `metadata`

- `allocate(bytes memory _data, address _sender)`: The `_data` parameter should contain the data necessary for the allocation process.
    - `recipientId`
    - `status`

- `distribute(address[] memory _recipientIds, bytes memory _data, address _sender)`: This function reverts

### Additional Functions

- `withdraw(address)`: can be be called after `allocationEndTime` to withdraw leftover funds
- `setApprovalThreshold`: Cannot be changed after `allocationStartTime`
- `increaseMaxRequestedAmount`: Cannot be changed after `allocationStartTime`
- `addAllocators(address[])` to mark `address` as true. Cannot be changed after `allocationStartTime`
- `removeAllocators(address[])` to mark `address` as false. Cannot be changed after `allocationStartTime`

### Variables

- `mapping allocators`
