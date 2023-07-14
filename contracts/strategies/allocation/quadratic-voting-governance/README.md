Spec: Governance Token Quadratic Voting (QV)
---------------------------------

## Overview 
Quadratic Voting is a popular method for democratic decision-making. This strategy gates voting using a governance token, and gives eligible voters a number of voice credits equal to their token holdings. The pool's funds are distributed proportionally to the number of votes each project receives. 

## Spec
### Recipient logic
In this strategy, prospective recipients need to apply and be approved by a number of admins dictated by the pool. The pool admins can set a time window in which applications must be received.
- `registerRecipient` - function for recipient to submit application
    - if a recipient submits an application that meets all requirements, then the recipient status is set to `Pending`
    - **Customizable Settings**
        - pool admin can require recipients to have Allo registry identity in order to apply
            - if pool admin doesn't require Allo identity and the recipient doesn't have one, then `msg.sender` is used as recipient id
        - pool admin can include optional and required questions in an application, stored in metadata
            - recipient must answer questions as specified by pool admin
- `reviewApplication` - function for pool admins to approve or reject a recipient for inclusion in the round.
    - the pool admins have the ability to set how many admins must confirm a decision in order for an application to be approved or rejected.
        - For example, if the threshold is set to `2`, then two separate admins must approve or reject an application before its status updates. As soon as the recipient receives either two rejections or two approvals, admins can no longer take any action on that application. 

### Voter eligibility logic
Pool admins are able to designate a governance token that they want to use as their source of truth. The strategy takes a snapshot of token holdings on an admin-specified date and uses that as its source of truth for the voting round. Voters must hold tokens in that snapshot in order to be eligible. 

### Voting logic
In this strategy, only the eligible wallets are able to vote. Votes can only be cast during a voting window that is set by the pool admin. Each voter gets a budget of "voice credits", which they can use to "purchase" votes on as many recipients as they would like. The number of votes each voter can give to a recipient is equal to the square root of the number of voice credits they spend on that specific recipient. Votes can be fractional. 
- `allocate` — function for eligible voters to spend their voice credits
    - each eligible voter gets a number of voice credits equal to the number of governance tokens they hold in the snapshot. 
    - voice credits can be spent in batches — the contract should be aware of how many voice credits each voter has available. 
        - The contract should also know if that voter has spent voice credits on a recipient already, so that the total number of votes given is equal to the square root of the total number of voice credits. 
            - For example: A voter submitting two separate transactions of 8 voice credits each to the same recipient should receive 4 votes, not 5.65.
    - voice credits can be spent in bulk — voters can spend voice credits on multiple recipients in one transaction
    - allocate can only be called while the voting window is open
    - the contract should emit an event indicating how many votes each voter has purchased for each recipient. 

### Allocation shape
The pool funds are distributed proportionally to each recipient as indicated by the number of votes they receive. The percent of the pool they receive is equal to the percent of total votes (NOT VOICE CREDITS) that the recipient received. 

### Distribution
In this strategy, the pool admins are able to push pool funds to recipients.

- `distribute` - function for pool admin to distribute pool funds to recipients, as indicated by the calculated allocation. 
    - The pool admin should have the ability to distribute the pool in batches
