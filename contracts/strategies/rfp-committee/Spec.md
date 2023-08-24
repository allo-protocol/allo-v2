Spec: Committee Request for Proposal (RFP)
---------------------------------

## Overview 
Many organizations accomplish tasks by outsourcing the work to expert teams. In this model, they create a Request for Proposal (RFP), where they outline the specifications of the work they would like done and solicit proposals. This RFP strategy allows a committee of decision makers to award a winner, then pay out in milestones. 

## Spec
### Recipient logic
In this strategy, prospective recipients only need to apply for a grant. There isn't an approval step before voting. 
- `registerRecipient` - function for recipient to submit application
    - if a recipient submits an application that meets all requirements, then the recipient status is set to `Pending`
    - **Customizable Settings**
        - pool admin can require recipients to have Allo registry profile in order to apply
            - if pool admin doesn't require Allo profile and the recipient doesn't have one, then `msg.sender` is used as recipient id
        - pool admin can include the full RFP, as well as optional and required questions in an application, stored in metadata
            - pool admin must specify the maximum amount they are willing to pay — this is the pool amount stored on the contract. 
            - recipient must answer questions as specified by pool admin
        - pool admin can require that the recipient include a proposed bid for the work
            - if they do, the proposed bid cannot be more than the pool amount stored on the contract

### Voter eligibility logic
A committee of eligible voters is set on the contract via an allowlist. All other wallets are considered `ineligible`.

### Voting logic
In this strategy, only the eligible committee members are able to vote. Each member gets one "yes" vote, which they can give to any recipient with an eligible bid. Each member has the ability to change their vote, in which case their vote is reassigned from the original chosen recipient to the new chosen recipient. 
- `voteThreshold` — a number set by the pool admins indicating how many yes votes a project must have to win. This number must be <= the number of wallet addresses on the committee allowlist. 
- `allocate` — function for committee members to give their yes vote to a bid
    - as soon as a bid has the required number of yes votes, they are designated the winner and no more votes are allowed
    - When a bid is designated the winner, that recipient is marked as `Accepted` and all other recipients are marked as `Rejected`
    - When the winning bid is selected, their proposed bid amount is what is recorded as the amount of the pool they receive. 

### Allocation shape
The winning recipient will receive the specific amount that was in their accepted bid. If there is money left over from the max pool amount, the pool admin can reclaim the funds. 

### Distribution
This strategy will use a milestone-based payout approach, where the recipient must meet certain criteria to unlock the full grant payments. Any pool admin (not just the designated decision-maker) should have the ability to configure the milestones for each recipient, and to approve the distribution at each gate. 
- `setMilestones` - function for the pool admin to configure the recipient's funding distribution milestones
    - this should allow them to set N number of payout gates, indicate the percentage of funds that will be unlocked by each gate, and save metadata that records details about each payment gate.
- `submitMilestone` - function for the recipient to request the payment of the next gate. They should have the ability to submit metadata with details about the gate. 
- `unlockMilestone` - function for the pool admin to accept the recipient's submission and pay out the next gate. They should have the ability to release the gate regardless of whether the recipient has submitted a request for the next gate. 
