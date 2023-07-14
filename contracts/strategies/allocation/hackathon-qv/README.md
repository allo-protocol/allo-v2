Spec: Hackathon Quadratic Voting (QV)
---------------------------------

## Overview 
Quadratic Voting is a popular method for democratic decision-making. This strategy is designed to facilitate voting for the winners of a hackathon. An organizer is able to programmatically say who is an eligible recipient and decide to gate voting using Passport. The pool funds are distributed in tiers based on each recipients place in the quadratic vote. 

## Spec
### Recipient logic
In this strategy, the pool admin uses an Allo identity and an EAS attestation to indicate eligible recipients. Any Allo identities that have the admin-designated attestation are eligible recipients. 
- `registerRecipient` - function for pool admin to indicate the attestation that a recipient must have to be eligible. 
- `updateRecipientList` — function that anyone can call to pull the latest list of eligible recipients
- `updateRecipient` — function that the identity admin can use to add metadata about their project

### Voter eligibility logic
Pool admins are able configure Passport to gate voting. A voter must meet the community's Passport requirements in order to be marked as eligible. 

### Voting logic
In this strategy, only the eligible wallets are able to vote. Votes can only be cast during a voting window that is set by the pool admin. Each voter gets a budget of "voice credits", which they can use to "purchase" votes on as many recipients as they would like. The number of votes each voter can give to a recipient is equal to the square root of the number of voice credits they spend on that specific recipient. Votes can be fractional. 
- `allocate` — function for eligible voters to spend their voice credits
    - the pool admin is able to designate the number of voice credits that each user gets 
    - voice credits can be spent in batches — the contract should be aware of how many voice credits each voter has available. 
        - The contract should also know if that voter has spent voice credits on a recipient already, so that the total number of votes given is equal to the square root of the total number of voice credits. 
            - For example: A voter submitting two separate transactions of 8 voice credits each to the same recipient should receive 4 votes, not 5.65.
    - voice credits can be spent in bulk — voters can spend voice credits on multiple recipients in one transaction
    - allocate can only be called while the voting window is open
    - the contract should emit an event indicating how many votes each voter has purchased for each recipient. 

### Allocation shape
The pool funds are distributed based on recipients' rank in total number of received votes (NOT VOICE CREDITS). 
- the pool admin can configure which rank positions receive funds and what percentage of the pool each place gets.
    - For example, the pool admin can say that first place gets 50%, second place gets 30%, and so on.

### Distribution
In this strategy, the pool admins are able to push pool funds to recipients.

- `distribute` - function for pool admin to distribute pool funds to recipients, as indicated by the calculated allocation. 
    - The pool admin should have the ability to distribute the pool in batches
