Spec: Donation Voting with Passport and Offchain Calculation
---------------------------------

## Overview 
Many web3 projects and traditional orgs operate a direct grants program, where they set aside funds and enable small committees to decide how to distribute those funds for a given purpose. Recipients are solicited for projects that support the pool's goal.

## Component Quickview
As laid out in the [components overview](https://docs.google.com/document/d/1qoOP07oMKzUCyfb4HbnyeD6ZYEQa004i5Zwqoy7-Ox8/edit), each allocation strategy consists of some key components. This is a quick overview of the relevant components for this strategy.
- **Recipient eligibility**: must hold credential and must include proposal
- **Acceptance method**: programmatic
- **Voter eligibility**: allowlist
- **Voting method**: one-voter-one-vote
- **Calculation method**: simple threshold
- **Allocation shape**: discrete amount

## Spec
### Recipient logic
In this strategy, prospective recipients only need to apply for a grant. There isn't an approval step before voting. 
- `registerRecipient` - function for recipient to submit application
    - if a recipient submits an application that meets all requirements, then the recipient status is set to `Pending`
    - **Customizable Settings**
        - pool admin can require recipients to have Allo registry identity in order to apply
            - if pool admin doesn't require Allo identity and the recipient doesn't have one, then `msg.sender` is used as recipient id
        - pool admin can include optional and required questions in an application, stored in metadata
            - recipient must answer questions as specified by pool admin
        - pool admin can require that the recipient include a requested grant amount

### Voter eligibility logic
Only pool admins should be able to vote in this strategy. All other addresses should be marked `ineligible`

### Voting logic
In this strategy, pool admins are able to review and approve grants for specific amounts. 
- `vote` — function for pool admins (i.e. wallets marked as `eligible`) to either approve or reject a grant application
    - If approving, the pool admin needs to set the amount of the pool that the recipient will receive as part of the grant. When approving, this also updates both global and local status to `Approved`
    - If rejecting, this should update both global and local status to `Rejected`
- `updateApplicationStatus` - function for pool admins to update the status of the recipient's application to signal that the application has been seen but no decision has been made. This action should keep the global status as `Pending` but set the local status to `In Review`

### Allocation shape
The recipient will receive the amount set by the pool admin with the `vote` function. 

### Distribution
This strategy will use a milestone-based payout approach, where the recipient must meet certain criteria to unlock the full grant payments. The pool admin should have the ability to configure the milestones for each recipient, and to approve the distribution at each gate. 
- `setMilestones` - function for the pool admin to configure the recipient's funding distribution milestones
    - this should allow them to set N number of payout gates, indicate the percentage of funds that will be unlocked by each gate, and save metadata that records details about each payment gate.
- `submitMilestone` - function for the recipient to request the payment of the next gate. They should have the ability to submit metadata with details about the gate. 
- `unlockMilestone` - function for the pool admin to accept the recipient's submission and pay out the next gate. They should have the ability to release the gate regardless of whether the recipient has submitted a request for the next gate. 