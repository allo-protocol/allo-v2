Spec: Simple Quadratic Voting (QV)
---------------------------------

## Overview 
Quadratic Voting is a popular method for democratic decision-making. This strategy implements a simple version, where an allowlist of allocators are given an equal number of voice credits that they can allocate. The pool's funds are distributed proportionally to the number of allocations each recipient receives. 

## Spec
### Recipient logic
In this strategy, prospective recipients need to apply and be approved by at least two admins. The pool managers can set a time window in which applications must be received.
- **Recipient Eligibility**
    - pool manager has the option to require recipients to have an Allo registry identity in order to apply
    - pool manager has the option to require application metadata submitted with the application
        - This metadata may include information for the front end on required / optional questions, but the contract only needs to check for whether metadata has been submitted
        - Pool manager needs to have a way to upload the application form metadata
- **Recipient Information**
    - prospective recipients must provide an address where they can receive funds
    - prospective recipients must provide a `recipientId` to be the unique identifier for their application
        - if the Allo registry is required, the `anchorId` is used is used as `recipientId`
        - if the Allo registry is not required, the recipient has the option of using their `anchorId` or `msg.sender`
- **Registering recipients** 
- pool managers must have a function for setting an application open and application close date. 
- `registerRecipient` - function for recipient to submit application
    - if a recipient submits an application that meets all configured requirements, then the recipient status (global and local) is set to `Pending`
    - applications cannot be submitted if the application window is closed
- pool managers must have a function for reviewing / approving applications
    - any pool manager can approve applications —> this updates the global and local status of the recipient to `Approved`
    - any pool manager can reject applications -> this updates the global and local status of the recipient to `Rejected`
    - pool managers can use this function to change recipient status from `Approved` to `Rejected` and vice-versa
    - Recipients are only able to have one registration in a pool. Re-registrations should be handled as follows:
        - If a recipient's current status is `Pending`, then their application info is updated and their status remains `Pending` (global and local)
        - If a recipient's current status is `Rejected`, then their application info is updated and their local status is changed to `Appealed` — global status should change to `Pending`
        - If a recipient's current status is `Accepted`, then their application info is updated and their status is changed to `Pending` (global and local)

### Allocation logic
In this strategy, only eligible allocators are able to call `allocate` — this is configured via an allowlist. Allocations can only be submitted during an allocation window that is set by the pool manager. Each allocator gets an equal budget of "voice credits", which they can use to allocate votes to as many recipients as they would like. The number of votes each allocator can give to a recipient is equal to the square root of the number of voice credits they spend on that specific recipient. Votes can be fractional. 
- **Allocator Eligibility**
    - A set of eligible allocators is set on the contract via an allowlist. All other wallets are considered `ineligible`.
- **Allocate function**
    - pool managers need a function to set how many voice credits each eligible allocator can spend.
        - In this strategy, all eligible allocators have an equal number of voice credits
    - pool managers need a function to set allocation open and allocation close dates
    - `allocate` — function for eligible allocators to spend their voice credits
        - voice credits can be spent in batches — the contract should be aware of how many voice credits each allocator has available. 
            - The contract should also know if that allocator has spent voice credits on a recipient already, so that the total number of votes given is equal to the square root of the total number of voice credits. For example: A allocator submitting two separate transactions of 8 voice credits each to the same recipient should receive 2.83 votes, not 4.
        - `allocate`can only be called if the allocation window is open
    - voice credits can be spent in bulk — allocators can spend voice credits on multiple recipients in one transaction
    - allocate can only be called while the allocation window is open
    - the contract should emit an event indicating how many votes each allocator has purchased for each recipient. 

### Payout calculation logic
This strategy calculates a `payout` for each recipient based upon the proportion of votes they received.
- The pool funds are distributed proportionally to each recipient as indicated by the number of votes they receive. The percent of the pool they receive is equal to the percent of total votes (NOT VOICE CREDITS) that the recipient received. For example:
    - Vote count
        - Recipient A received 2 votes
        - Recipient B received 3 votes
        - Recipient C received 5 votes
    - Payout amounts
        - Recipient A gets 20% of the pool
        - Recipient B gets 30% of the pool
        - Recipient C gets 50% of the pool

### Distribution
In this strategy, the pool managers are able to push `payout` to recipients.

- `distribute` - function for pool manager to distribute each recipient's full `payout` amount to their payout wallet
    - The pool manager should have the ability to distribute the pool in batches