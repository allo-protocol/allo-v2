Spec: Direct Grants Pool with Single-Admin Approval and Milestone Payouts
---------------------------------

## Overview 
Many web3 projects and traditional orgs operate a direct grants program, where they set aside funds and enable small committees to decide how to distribute those funds for a given purpose. Recipients are solicited for projects that support the pool's goal.

## Spec
### Recipient logic
In this strategy, prospective recipients only need to apply for a grant. There isn't an approval step before voting. 
- `registerRecipient` - function for recipient to submit application
    - if a recipient submits an application that meets all requirements, then the recipient status is set to `Pending`
    - **Customizable Settings**
        - pool manager can require recipients to have Allo registry identity in order to apply
            - if pool manager doesn't require Allo identity and the recipient doesn't have one, then `msg.sender` is used as recipient id
        - pool manager can include optional and required questions in an application, stored in metadata
            - recipient must answer questions as specified by pool manager
        - pool manager can require that the recipient include a requested grant amount

### Allocate function logic
In this strategy, pool managers are able to review and approve grants for specific amounts. Only pool managers should be able to call `allocate`.
- `allocate` — function for pool managers (i.e. wallets marked as `eligible`) to either approve or reject a grant application
    - If approving, the pool manager needs to set the amount of the pool that the recipient will receive as part of the grant. When approving, this also updates both global and local status to `Approved`
    - If rejecting, this should update both global and local status to `Rejected`
- `updateApplicationStatus` - function for pool managers to update the status of the recipient's application to signal that the application has been seen but no decision has been made. This action should keep the global status as `Pending` but set the local status to `In Review`

### Final allocation logic
The recipient will receive the amount set by the pool manager with the `allocate` function. 

### Distribution
This strategy will use a milestone-based payout approach, where the recipient must meet certain criteria to unlock the full grant payments. The pool manager should have the ability to configure the milestones for each recipient, and to approve the distribution at each gate. 
- `setMilestones` - function for the pool manager to configure the recipient's funding distribution milestones
    - this should allow them to set N number of payout gates, indicate the percentage of funds that will be unlocked by each gate, and save metadata that records details about each payment gate.
- `submitMilestone` - function for the recipient to request the payment of the next gate. They should have the ability to submit metadata with details about the gate. 
- `unlockMilestone` - function for the pool manager to accept the recipient's submission and pay out the next gate. They should have the ability to release the gate regardless of whether the recipient has submitted a request for the next gate. 
