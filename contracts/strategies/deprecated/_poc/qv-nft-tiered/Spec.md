Spec: NFT-Gated Quadratic Voting (QV) with Tiered Allocation
---------------------------------

## Overview 
Quadratic Voting is a popular method for democratic decision-making. This strategy gates allocations using NFTs, and allows holders of different NFTs to have different amounts of voice credits. The pool's funds are distributed proportionally to the number of votes each project receives, with caps on the maximum amount of the pool that one recipient can receive. 

## Spec
### Recipient logic
In this strategy, recipients must submit an application and be approved by pool admins. 
- **Recipient information**
    - prospective recipients must provide an address where they can receive funds
    - prospective recipients must provide an address as `recipientId`, which serves as the unique identifier for their registration
        - if the Allo registry is required, the `anchorId` is used as `recipientId`
        - if the Allo registry is not required, the recipient has the option of using their `anchorId` or `msg.sender`
- **Recipient eligibility**
    - Pool manager has the option to enable two separate eligibility requirements on this contract:
        - Requiring recipients to have an Allo registry profile in order to apply
        - Requiring recipients to submit answers to questions, stored in metadata
            - This metadata may include information for the front end on required / optional questions, but the contract only needs to check for whether metadata has been submitted
            - The pool manager should have a function that enables them to edit the pool metadata, which is callable at any point
- **Registering recipients**
    - `registerRecipient` can be called by anyone, and is used by prospective recipients to submit an application
        - if the recipient's application is eligible (by criteria set above), the recipient status (global and local) is set to `Pending`. If the recipient is ineligible, the transaction should revert with an error message that the application is ineligible. 
        - pool managers must set an application start and end date on the strategy. `registerRecipient` can only be called in that window, otherwise it will revert. 
    - Pool managers need a function to manually accept applications into the round. 
        - If any pool manager accepts the application, the recipient status is updated to `Approved` (global and local)
        - If any pool manager rejects the application, the recipient status is updated to `Rejected` (global and local)
        - Pool managers are able to change an approved or rejected recipient by calling the same function. 
    - Recipients are only able to have one registration in a pool. Re-registrations should be handled as follows:
        - If a recipient's current status is `Pending`, then their application info is updated and their status remains `Pending` (global and local)
        - If a recipient's current status is `Rejected`, then their application info is updated and their local status is changed to `Appealed` — global status should change to `Pending`
        - If a recipient's current status is `Accepted`, then their application info is updated and their status is changed to `Pending` (global and local)

### Allocation logic
In this strategy, pool managers are able to set multiple NFTs as their eligibility gates for allocators. As long as a wallet holds at least one of those NFTs they are marked as `eligible`. Allocations can only be cast during a allocation window that is set by the pool manager. Each allocator gets a budget of "voice credits", which they can use to "purchase" votes on as many recipients as they would like. The budget of voice credits is dictated by the NFT(s) that the allocator holds. The number of votes each allocator can give to a recipient is equal to the square root of the number of voice credits they spend on that specific recipient. Votes can be fractional. 
- **Allocator Eligibility**
    - Pool managers need a function to indicate which NFTs will be used to determine eligibility in the pool.
        - As part of this, they need to be able to indicate how many voice credits each NFT is worth. For example, a wallet holding `NFT-A` may get 100 credits, while a wallet holding `NFT-B` may get 250 credits. 
        - In this strategy, a user can accumulate multiple voice credits if they hold multiple NFTs. In the example above, a user holding NFTs A and B will get 350 credits. 
- **Allocate function**
    - `allocate` — function for eligible allocators to spend their voice credits
        - voice credits can be spent in batches — the contract should be aware of how many voice credits each allocator has available. 
            - The contract should also know if that allocator has spent voice credits on a recipient already, so that the total number of votes given is equal to the square root of the total number of voice credits. 
                - For example: A allocator submitting two separate transactions of 4 voice credits each to the same recipient should receive 2.83 votes, not 4.
        - voice credits can be spent in bulk — allocators can spend voice credits on multiple recipients in one transaction
        - allocate can only be called while the voting window is open
        - the contract should emit an event indicating how many votes each allocator has purchased for each recipient. 

### Payout calculation logic
The pool funds are distributed proportionally to each recipient as indicated by the number of votes they receive. The percent of the pool they receive is equal to the percent of total votes (NOT VOICE CREDITS) that the recipient received. 
- The pool manager has the ability to set a cap percentage, where no single recipient is allowed to receive more than the cap percentage of the pool. In the case that a recipient is over the cap, the excess is redistributed to projects under the cap using their vote percentage. 

### Distribution
In this strategy, the pool managers are able to push pool funds to recipients.

- `distribute` - function for pool manager to distribute pool funds to recipients, as indicated by the calculated allocation. 
    - The pool manager should have the ability to distribute the pool in batches
