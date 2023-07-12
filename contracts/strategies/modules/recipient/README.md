# Recipient Module specs

This document outlines specs for **recipient** modules, which handle how recipients are added to a given pool. 

# Specs
## Open Timed Application, Manual Single Approval
In this strategy, any prospective recipients must apply to the round during a specific time period and be manually accepted by a pool admin. 

### Custom Variables
- `applicationOpenDate` — the date when the pool begins accepting applications
- `applicationCloseDate` - the date when the pool stops accepting applications
- `applicationData` - metadata for the application process (what questions are required and recipients' responses)
- `reviewerList` - allowlist of addresses that are able to review applications
- `recipientStatus` - —> how do we want to handle this?

### Standard Functions
- `registerRecipients` - callable by the recipient admin from Allo.sol, this submits a given recipient to the pool as an applicant and automatically marks their status as `Pending`. 
    - If the recipient does not have an Allo registry identity, then `msg.sender` is used as recipient ID

### Custom Functions
- `reviewRecipient` - callable by any address in `reviewerList`, this allows a reviewer to indicate whether they want to approve or reject a recipient. 
    - If approved, the `recipientStatus` is changed to `Approved`
    - If rejected, the `recipientStatus` is changed to `Rejected`

## Open Rolling Application, Manual Single Approval
In this strategy, any prospective recipients may apply to the round at any time and be manually accepted by a pool admin. 

### Custom Variables
- `applicationData` - metadata for the application process (what questions are required and recipients' responses)
- `reviewerList` - allowlist of addresses that are able to review applications
- `recipientStatus` - —> how do we want to handle this?

### Standard Functions
- `registerRecipients` - callable by the recipient admin from Allo.sol, this submits a given recipient to the pool as an applicant and automatically marks their status as `Pending`. 
    - If the recipient does not have an Allo registry identity, then `msg.sender` is used as recipient ID

### Custom Functions
- `reviewRecipient` - callable by any address in `reviewerList`, this allows a reviewer to indicate whether they want to approve or reject a recipient. 
    - If approved, the `recipientStatus` is changed to `Approved`
    - If rejected, the `recipientStatus` is changed to `Rejected`

## NFT-Gated Timed Application, Manual Single Approval
In this strategy, a prospective recipient must hold a specific NFT in order to apply to the round during an application period and be manually accepted by a pool admin. 

### Custom Variables
- `applicationOpenDate` — the date when the pool begins accepting applications
- `applicationCloseDate` - the date when the pool stops accepting applications
- `applicationData` - metadata for the application process (what questions are required and recipients' responses)
- `applicationRequirements` — the NFT that the address is required to hold
- `reviewerList` - allowlist of addresses that are able to review applications
- `recipientStatus` - —> how do we want to handle this?

### Standard Functions
- `registerRecipients` - callable by the recipient admin from Allo.sol, this submits a given recipient to the pool as an applicant 
    - If the recipient ID does not hold `applicationRequirements` then the transaction is reverted
    - If the recipient does hold `applicationRequirements` then the `recipientStatus` is updated to `Pending`

### Custom Functions
- `reviewRecipient` - callable by any address in `reviewerList`, this allows a reviewer to indicate whether they want to approve or reject a recipient. 
    - If approved, the `recipientStatus` is changed to `Approved`
    - If rejected, the `recipientStatus` is changed to `Rejected`

## Admin-generated recipient list
In this strategy, a pool admin is able to register the recipients for their pool.

### Standard Functions
- `registerRecipients` - callable by the pool admin from Allo.sol, this allows the admin to submit a list of recipient IDs that are eligible.
    - All recipient IDs are marked as `Accepted` when this happens