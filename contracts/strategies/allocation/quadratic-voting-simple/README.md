Spec: Simple Quadratic Voting (QV)
---------------------------------

## Overview 
Quadratic Voting is a popular method for democratic decision-making. This strategy implements a simple version, where an allowlist of wallet addresses are given an equal number of voice credits with which to vote. The pool's funds are distributed proportionally to the number of votes each project receives. 

## Spec
### Recipient logic
In this strategy, prospective recipients need to apply and be approved by at least two admins. The pool admins can set a time window in which applications must be received.
- `registerRecipient` - function for recipient to submit application
    - if a recipient submits an application that meets all requirements, then the recipient status is set to `Pending`
    - **Customizable Settings**
        - pool admin can require recipients to have Allo registry identity in order to apply
            - if pool admin doesn't require Allo identity and the recipient doesn't have one, then `msg.sender` is used as recipient id
        - pool admin can include optional and required questions in an application, stored in metadata
            - recipient must answer questions as specified by pool admin

### Voter eligibility logic
A set of eligible voters is set on the contract via an allowlist. All other wallets are considered `ineligible`.

### Voting logic
In this strategy, only the eligible wallets are able to vote. Votes can only be cast during a voting window that is set by the pool admin. Each voter gets an equal budget of "voice credits", which they can use to "purchase" votes on as many recipients as they would like. The number of votes each voter can give to a recipient is equal to the square root of the number of voice credits they spend on that specific recipient. Votes can be fractional. 
- `voiceCredits` — a number set by the pool admins indicating how many voice credits each eligible voter can spend.
- `allocate` — function for eligible voters to spend their voice credits
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
