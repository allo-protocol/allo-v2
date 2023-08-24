Spec: Governance Token Quadratic Voting (QV)
---------------------------------

## Overview 
Quadratic Voting is a popular method for democratic decision-making. This strategy gates allocations using a governance token, and gives eligible allocators a number of voice credits equal to their token holdings. The pool's funds are distributed proportionally to the number of votes each project receives. 

The token used for this strategy must implement the `getPastVotes(address account, uint256 timepoint)` function as specified in `EIP-5808`.

## Spec
### Recipient logic
In this strategy, prospective recipients need to apply and be approved by a number of pool managers dictated by the strategy. The pool managers must set a time window in which applications must be received.
- **Recipient Eligibility**
    - pool manager has the option to require recipients to have an Allo registry profile in order to apply
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
    - pool managers must have a function to set how many managers must confirm a decision in order for an application to be approved or rejected.
        - For example, if the threshold is set to `2`, then two separate managers must approve or reject an application before its status updates. 
    - pool managers must have a function for reviewing / approving applications.
        - as soon as the recipient receives the required threshold of rejections or  approvals, the recipient status is updated and managers can no longer take any action on that application unless the recipient re-applies. 
            - if the recipient receives a number of approvals equal to the threshold, they are approved and their global / local status are set to `Approved`
            - if the recipient receives a number of rejections equal to the threshold, they are approved and their global / local status are set to `Rejected`
            - if managers have reviewed the application but it has not yet hit the threshold for approval or rejection, the global / local status remains `Pending`
    - Recipients are only able to have one registration in a pool. Re-registrations should be handled as follows:
        - If a recipient's current status is `Pending`, then their application info is updated and their status remains `Pending` (global and local)
        - If a recipient's current status is `Rejected`, then their application info is updated and their local status is changed to `Appealed` — global status should change to `Pending`
        - If a recipient's current status is `Accepted`, then their application info is updated and their status is changed to `Pending` (global and local)

### Allocation logic
Pool managers are able to designate a governance token that they want to use as their source of truth. The pool manager defines the timestamp of the token snapshot. Allocators must hold tokens in that snapshot in order to be eligible. Each allocator gets a budget of "voice credits", which they can use to "purchase" votes on as many recipients as they would like. The number of votes each allocator can give to a recipient is equal to the square root of the number of voice credits they spend on that specific recipient. Votes can be fractional. Allocations can only be cast during a voting window that is set by the pool manager.  
- **Allocator Eligibility**
    - only wallets that hold the required governance token in the strategy's snapshot are considered `eligible`. All other wallets are `ineligible`. 
- **Allocate function**
    - `allocate` — function for eligible allocator to spend their voice credits
        - each eligible allocator gets a number of voice credits equal to the number of governance tokens they hold in the snapshot. 
        - voice credits can be spent in batches — the contract should be aware of how many voice credits each allocator has available. 
            - The contract should also know if that allocator has spent voice credits on a recipient already, so that the total number of votes given is equal to the square root of the total number of voice credits. 
                - For example: A allocator submitting two separate transactions of 4 voice credits each to the same recipient should receive 2.83 votes, not 4.
        - voice credits can be spent in bulk — allocators can spend voice credits on multiple recipients in one transaction
        - allocate can only be called while the allocation window is open
        - the contract should emit an event indicating how many votes each allocator has purchased for each recipient. 

### Payout calculation logic
The pool funds are distributed proportionally to each recipient as indicated by the number of votes they receive. The percent of the pool they receive is equal to the percent of total votes (NOT VOICE CREDITS) that the recipient received. 

### Distribution
In this strategy, the pool managers are able to push pool funds to recipients.

- `distribute` - function for pool manager to distribute pool funds to recipients, as indicated by the calculated allocation. 
    - The pool manager should have the ability to distribute the pool in batches
