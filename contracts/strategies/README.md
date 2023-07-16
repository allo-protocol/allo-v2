# Strategy Folder

This folder contains the implementation of various strategies for managing recipients and distributing tokens. Each subfolder represents a specific strategy and contains one or more Solidity smart contracts along with their specifications `README.md`.

## Introduction

The strategy folder in our GitHub repository is dedicated to housing different strategies for managing recipients and facilitating token distribution. The purpose of this `README.md` file is to guide the developers in writing comprehensive specifications for each strategy. The specifications should provide a clear understanding of the strategy's flow, functions, and variables. By following this template, developers will be able to create detailed and well-documented specifications for their strategies.

----
Spec: Strategy Name

### Overview

Provide a brief overview of the strategy and its purpose. Describe the high-level flow of how recipients are registered, allocations, and how tokens are distributed.

## General Specifications

### Register Recipient Logic

Describe the logic for registering recipients within the strategy. Explain the recipient status workflow, including the possible statuses (e.g., `None`, `Pending`, `Accepted`, `Rejected`) and the conditions under which the status changes. If additional functions are added to check or modify recipient status, mention them here.

#### Questions to answer

1. Are multiple registrations for a recipient allowed or just one?
2. What happens in case of a second registration, either in the case of a single registration or multiple registrations?
3. Can the address that receives the fund need to be different from the recipient's identity?
4. Which address is returned by `registerRecipient` and represents the `receipientId`?
5. How does a recipient identify themselves? Is it through an address like msg.sender, do they need an identity registered at the `Registry` contract, or another mechanism? If through the Registry, can the pool creator set a custom registry?
6. Does the pool manager need to approve the registration, or is it automatically approved? If automatically, How? Describe in detail.
7. What additional data is needed and passed during the registration process, apart from the recipient's address?
8. Is the `registerRecipient` function accessible to anyone, or is it restricted to specific roles or addresses?
9. Are there any specific conditions under which the `registerRecipient` function can or cannot be called?
10. What steps are involved in changing the recipient's status from one state to another?
11. Are there any additional functions available to check or modify the recipient's status?

### Allocator Eligibility Logic

Explain the logic for determining the eligibility of an allocator within the strategy. Specify any custom functions or conditions used to verify if an allocator is eligible to allocate.

#### Questions to answer

1. How is the eligibility of an allocator determined in this strategy? Is it through a third party, or can anyone allocate? If there are specific roles or addresses allowed to allocate, mention them here.
2. Are there any custom functions or conditions for verifying allocator eligibility? If so, describe them and their purpose in determining eligibility.
3. Can an allocator allocate multiple times or just once? Is there any restriction on the number of allocations per allocator?
4. How does the strategy handle ineligible allocators who attempt to allocate? What actions or outcomes are triggered when an ineligible allocator tries to allocate?

### Allocation Logic

Describe the logic for allocating to recipients within the strategy. Explain the process of updating the contract's data to store allocations and any associated information. If there are any special considerations or conditions, mention them here.

#### Questions to answer

1. Are there any conditions on when the `allocate` function is callable or not? Eg. a allocation period.
2. How are allocations stored in the strategy? Describe the data structure or mechanism used to track and store the allocations. What information is important to capture for each allocation?
3. How are allocations assigned to recipients? Explain the process of allocating funds, tokens or votes to the recipients. Are there any transfers or other events triggered during the allocation process?
4. In case of token allocations, are the tokens stored in the strategy and who can withdraw funds or are they sent directly to a specific recipient?
5. Are there any specific rules or conditions for allocations? For example, are there limits on the amount that can be allocated to each recipient or any other constraints that need to be considered?

### Distribution Logic

Outline the logic for distributing the pool amount to recipients within the strategy. Describe how the distribution amount per recipient is determined and any mechanisms in place to prevent double payments.

#### Questions to answer

1. Who is eligible to receive a payout? Specify the criteria or conditions that determine whether a recipient is eligible to receive a distribution from the pool.
2. What factors determine the distribution amount for each recipient? Explain the criteria or calculations used to determine the amount that each recipient should receive from the pool. Provide details on the formula or method used to calculate the payout amount for each recipient.
3. Are any additional functions needed to set the payout amounts or enable the distribution? Describe any helper functions or steps required before calling the distribute function.
4. Who can call the distribute function? In case there are restrictions, explain why they are needed and who has the authorization to invoke the distribution process.
5. Are there any conditions on when the distribute function can be called? Specify any prerequisites or constraints that need to be satisfied before calling the function.
6. Are there multiple distributions or just a single distribution? Clarify whether there are multiple rounds of distribution or if it's a one-time distribution process.
7. How are tokens distributed to recipients in this strategy? Explain the mechanism or steps involved in transferring tokens to the recipients.
8. Are any third-party services involved in the distribution process? If there are any external dependencies or integrations, provide additional information or relevant links.
9. Are there any mechanisms in place to prevent double payments? Describe any safeguards or mechanisms implemented to ensure that recipients do not receive duplicate or excessive payments.

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
