Spec: Hackathon Quadratic allocation (QV)
---------------------------------

## Overview 
Quadratic allocation is a popular method for democratic decision-making. This strategy is designed to facilitate allocation for the winners of a hackathon. An organizer is able to programmatically say who is an eligible recipient and decide to gate allocation using Passport. The pool funds are distributed in tiers based on each recipients place in the quadratic vote. 

## Spec
### Recipient logic
In this strategy, recipients do not need to apply — they are automatically added to the pool if they are eligible. The pool manager uses an Allo profile and an EAS attestation to indicate eligible recipients. Any Allo identities that have the manager-designated attestation are eligible recipients. 
- **Recipient Eligibility**
    - Pool managers will manually add recipients to the pool. 
- **Register recipients**
    - `registerRecipients` - Function for pool managers to add addresses to their pool. When they are added, an EAS attestation is automatically issued that they are part of the hackathon. 
    - Eligible recipients will also need functions to: 
        - add a payout address for this pool
        - update metadata for this pool

### Allocation logic
In this strategy, only wallets that hold a specific NFT are eligible to allocate. Allocations can only be submitted during a allocation window that is set by the pool manager. Each allocator gets a budget of "voice credits", which they can use to "purchase" votes on as many recipients as they would like. The number of votes each allocator can give to a recipient is equal to the square root of the number of voice credits they spend on that specific recipient. Votes can be fractional. 
- **Allocator Eligibility**
    - Wallets are only eligible if they hold a specific NFT.
        - Pool managers must have the ability to configure which NFT is required in order to vote. 
- **Allocate Function**
    - `allocate` — function for eligible allocators to spend their voice credits
        - the pool manager is able to designate the number of voice credits that each user gets 
        - voice credits can be spent in batches — the contract should be aware of how many voice credits each allocator has available. 
            - The contract should also know if that allocator has spent voice credits on a recipient already, so that the total number of votes given is equal to the square root of the total number of voice credits. For example: A allocator submitting two separate transactions of 4 voice credits each to the same recipient should receive 2.83 votes, not 4.
    - voice credits can be spent in bulk — allocators can spend voice credits on multiple recipients in one transaction
    - allocate can only be called while the allocation window is open
    - the contract should emit an event indicating how many votes each allocator has purchased for each recipient. 

### Payout calculation logic
The `payout` for each recipient is determined by their rank in total number of received votes (NOT VOICE CREDITS). 
- the pool manager can configure which rank positions receive funds and what percentage of the pool each place gets.
    - For example, the pool manager can say that first place gets 50%, second place gets 30%, and so on.

### Distribution logic
In this strategy, the pool managers are able to push pool funds to recipients.

- `distribute` - function for pool manager to distribute pool funds to recipients, as indicated by the calculated payouts. 
    - The pool manager should have the ability to distribute the pool in batches
