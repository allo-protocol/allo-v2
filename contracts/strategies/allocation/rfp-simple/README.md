Spec: Simple Request for Proposal (RFP)
---------------------------------

## Overview 
Many organizations accomplish tasks by outsourcing the work to expert teams. In this model, they create a Request for Proposal (RFP), where they outline the specifications of the work they would like done and solicit proposals. This RFP strategy allows one decision maker to award a winner, then pay out in milestones. 

## Spec
### Recipient logic
In this strategy, prospective recipients only need to apply for a grant. There isn't an approval step before voting. 
- **Recipient eligibility**
    - Pool manager can require recipients to have Allo registry identity in order to apply
    - Pool manager can require recipients to submit application information
        - If this is configured, all application content and formatting is stored off-chain with a pointer to that data saved to the contract
        - Pool manager can also save metadata about the pool off-chain
- **Recipient information**
    - prospective recipients must provide a recipientID and an address where they can receive funds
        - if an Allo registry identity is required, then that identity is used as the recipientID
- **Registering recipients**
    - `registerRecipient` - function for recipient to submit application
        - as long as the recipient submits an application that meets all requirements, then the recipient status is set to `Pending` (global and local)
    - applications must include a bid amount. If the recipient does not enter a bid, it is automatically set to the total pool amount.

### Allocate function logic
In this strategy, anyone can view the applications but only the pool managers can view the bid amounts. Additionally, only the pool manager is eligible to call allocate in this. All other addresses are marked `ineligible`. 
- `allocate` — function for pool manager (i.e. wallet marked as `eligible`) to select the winning bid
    - When selecting the winning bid, that recipient is marked as `Accepted` and all other recipients are marked as `Rejected`
    - When the winning bid is selected, their proposed bid amount is what is recorded as the amount of the pool they receive. 

### Final allocation logic
The winning recipient will receive the specific amount that was in their accepted bid. If there is money left over from the max pool amount, the pool manager can reclaim the funds. 

### Distribution
This strategy will use a milestone-based payout approach, where the recipient must meet certain criteria to unlock the full grant payments. Any pool manager (not just the designated decision-maker) should have the ability to configure the milestones for the recipient, and to approve the distribution at each gate. 
- this strategy must include a function for the pool manager to configure the recipient's funding distribution milestones
    - this should allow them to set N number of payout gates, indicate the percentage of funds that will be unlocked by each gate, and save metadata that records details about each payment gate.
    - this function should be callable up until the first distribution payment is made
- there must be a function for the recipient to request the payment of the next gate. They should have the ability to submit metadata with details about the work they did to unlock the gate. 
- there must be a function for the pool manager to review the recipient's submission and pay out the next gate (this could be `distribute`). 
    - They should have the ability to release the gate regardless of whether the recipient has submitted a request for the next gate. 
    - They should also have the ability to reject the milestone or request more information before releasing payment
- `getPayouts` should return the total amount left to be paid to the recipient (not just what they're owed in the next milestone)
