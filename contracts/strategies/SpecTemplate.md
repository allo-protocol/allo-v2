# Strategy Folder

This folder contains the implementation of various strategies for managing recipients and distributing tokens. Each subfolder represents a specific strategy and contains one or more Solidity smart contracts along with their specifications `SpecTemplate.md`.

## Introduction

The strategy folder in our GitHub repository is dedicated to housing different strategies for managing recipients and facilitating token distribution. The purpose of this `SpecTemplate.md` file is to guide the developers in writing comprehensive specifications for each strategy. The specifications should provide a clear understanding of the strategy's flow, functions, and variables. By following this template, developers will be able to create detailed and well-documented specifications for their strategies.

----
Spec: Strategy Name

### Overview

Provide a brief overview of the strategy and its purpose. Describe the high-level flow of how recipients are registered, allocations, and how tokens are distributed.

## General Specifications

### Recipient Logic

Explain the logic for determining how recipients are added to the strategy's pool. This should include how the eligibility of a recipient is determined, the logic for registering eligible recipients, the recipient status workflow (including a list of available statuses such as `None`, `Pending`, `Accepted`, `Rejected`), and the conditions under which status changes. . Specify any custom functions or conditions that will be required. 

#### Questions to answer

- **Recipient eligibility**
    - What criteria determine the eligibility of a recipient to register in this strategy? Are there any specific requirements or conditions?
    - Are there any additional custom functions or conditions for verifying recipient eligibility?
- **Recipient information**
    - How does a recipient identify themselves? Is it through an address like msg.sender, do they need an profile registered at the `Registry` contract, or another mechanism? 
        - If through the Registry, can the pool creator set a custom registry?
        - Which address is returned by `registerRecipient` and represents the `recipientId`?
        - Can the address that receives the funds be different from the recipient's profile?
    - What additional data is needed and passed during the registration process, apart from the recipient's address?
- **Registering recipients**
    - Is the `registerRecipient` function accessible to anyone, or is it restricted to specific roles or addresses?
    - Are there any specific conditions under which the `registerRecipient` function can or cannot be called?
    - How does the strategy handle ineligible registrations? Are they automatically rejected, or is there a specific process in place?
    - Does the pool manager need to approve the registration, or is it automatically approved? 
        - If automatically, how? Describe in detail.
        - If manually, how? Who needs to approve?   
    - Are there any limits on the number of recipients that can be registered? If so, what are those limits and how are they enforced?
    - Are multiple registrations for a recipient allowed or just one?
        - What happens in case of a second registration, either in the case of a single registration or multiple registrations?
    - What steps are involved in changing the recipient's status from one state to another?
    - Are there any additional functions available to check or modify the recipient's status?

### Allocation Logic 

Explain the logic for how the strategy will allow eligible allocators to express an opinion about how the pool's funds should be allocated. This should include how allocators are determined to be eligible, the logic for the allocate function, and any special considerations or conditions.

#### Questions to answer

- **Allocator Eligibility**
    - How is the eligibility of an allocator determined in this strategy? Is it through a third party, or can anyone allocate? If there are specific roles or addresses allowed to allocate, mention them here.
    - Are there any custom functions or conditions for verifying allocator eligibility? If so, describe them and their purpose in determining eligibility.
- **Allocate function**
    - Are there any conditions on when the `allocate` function is callable or not? 
        - Is there an allocation period?
        - Can an allocator allocate multiple times or just once? Is there any restriction on the number of allocations per allocator?
        - How does the strategy handle ineligible allocators who attempt to allocate? What actions or outcomes are triggered when an ineligible allocator tries to allocate?
        - How is the data from allocate calls stored in the strategy? Describe the data structure or mechanism used to track and store the allocate data. What information is important to capture?
    - In case of allocations that require token donations, are the tokens stored in the strategy or are they sent directly to a specific recipient? If they are stored, who can withdraw funds?
    - Are there any specific rules or conditions for allocations? For example, are there limits on the amount that can be allocated to each recipient or any other constraints that need to be considered?

### Payout Calculation Logic

Explain the logic for how the strategy will calculate the pool's final `payout` from the allocations expressed by allocators. This should include any calculation formulas, the shape of the final payouts, and special considerations.

#### Questions to answer
- What factors determine the payout amount for each recipient? Explain the criteria or calculations used to determine the amount that each recipient should receive from the pool. Provide details on the formula or method used to calculate the payout amount for each recipient.
- What is the shape of the final payouts? Are they proportional, winner-take-all, etc?
- Are there any transfers or other events triggered during the calculation process?
- Are any additional functions needed to set the final `payout` amounts? Describe any helper functions or steps required.


### Distribution Logic

Outline the logic for how the `payout` amounts will be distributed to recipients. Describe any mechanisms in place to prevent double payments.

#### Questions to answer

- Who is eligible to receive a payout? Specify the criteria or conditions that determine whether a recipient is eligible to receive a distribution from the pool.
- Who can call the distribute function? In case there are restrictions, explain why they are needed and who has the authorization to invoke the distribution process.
- Are there any conditions on when the distribute function can be called? Specify any prerequisites or constraints that need to be satisfied before calling the function.
- Are there multiple distributions or just a single distribution? Clarify whether there are multiple rounds of distribution or if it's a one-time distribution process.
- How are tokens distributed to recipients in this strategy? Explain the mechanism or steps involved in transferring tokens to the recipients.
- Are any third-party services involved in the distribution process? If there are any external dependencies or integrations, provide additional information or relevant links.
- Are there any mechanisms in place to prevent double payments? Describe any safeguards or mechanisms implemented to ensure that recipients do not receive duplicate or excessive payments.

## Developer Specifications

### Data Parameter

The following functions may require a data parameter to be passed in. This parameter contains specific information or parameters necessary for the proper execution of the function. Please refer to the descriptions below for each function and provide the required data format or content.

- `initialize(uint256 _poolId, bytes memory _data)`: The `_data` parameter should contain the initialization data required for the strategy. Provide the expected format or structure of the data, and specify any important information or parameters that need to be included.

- `registerRecipients(bytes memory _data, address _sender)`: The `_data` parameter should contain the data required for recipient registration. Specify the expected format or structure of the data, and provide details on the information or parameters that need to be included.

- `allocate(bytes memory _data, address _sender)`: The `_data` parameter should contain the data necessary for the allocation process. Describe the expected format or structure of the data, and specify any important information or parameters that need to be included.

- `distribute(address[] memory _recipientIds, bytes memory _data, address _sender)`: The `_data` parameter should contain the data specific to the distribution process. Explain the expected format or structure of the data, and provide details on the information or parameters that need to be included.

### Additional Functions

If any custom functions have been introduced as part of the strategy, list and describe them here. Provide information about their purpose, input parameters, return values, and any important considerations for their usage.

### Variables

List and explain the important variables used within the strategy. Provide details about their purpose, usage, and any special considerations related to their values or updates.

### Additional Considerations

If there are any other important considerations or specifications specific to this strategy, mention them here.
