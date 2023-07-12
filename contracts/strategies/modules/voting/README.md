# Voting Module specs

This document outlines specs for **voting** modules, which handle how votes are cast and counted for a given pool. 

# Specs
## Open donation voting, offchain calculation
In this module, votes are cast as donations and a voter can submit a donation regardless of their eligibility status. Votes are counted offchain and uploaded by the pool admin. 

### Custom variables
- `acceptedTokens` - the list of tokens that are accepted as votes
- `finalCalculation` - the final calculations uploaded by the pool admin

### Standard functions
- `vote` - any wallet can call this function, regardless of the `isValidVoter` response. This can also support a "bulk donation", where one vote call can cast votes for multiple recipients. When a wallet calls vote the following decision tree is used:
    - is the donation token in the list of `acceptedTokens`? 
        - if no, revert
        - if yes, continue
    - do all the recipients have a `recipientEligibilityStatus` of `accepted`?
        - if no, revert
        - if yes, process transaction
    
    When a `vote` transaction is processed, the donation funds are held in the pool until funds are distributed. 

- `getResults` - returns `finalCalculation` if it exists. If it doesn't, revert. 

### Custom functions
- `getRawVotes` - Can be called by any address. Returns a table of all the votes that were cast. Each row should include: 
    - `voter` - i.e. `msg.sender`
    - `donationToken` - the token used for the vote
    - `donationAmount` - the amount of `donationToken` given to the recipient
    - `recipientID` - the recipient that received the donation
- `releaseDonations` - Callable by the pool admin. Releases all donations to their respective recipients. 
- `uploadResults` - Callable by the pool admin. Allows the pool admin to upload `finalCalculation`. 

## Single-vote-per-recipient
In this module, eligible voters are able to provide "yes" or "no" votes on every eligible recipient. 

### Standard functions
-  `vote` - if `isValidVoter` == `true`, then the voter is able to submit a "yes" or "no" vote on the recipient. 
- `getResults` - returns the number of yes and no votes for each recipient