Spec: Simple Request for Proposal (RFP)
---------------------------------

## Overview 
Many organizations accomplish tasks by outsourcing the work to expert teams. In this model, they create a Request for Proposal (RFP), where they outline the specifications of the work they would like done and solicit proposals. Ultimately, a decision maker awards the RFP to one proposal. 

## Component Quickview
As laid out in the [components overview](https://docs.google.com/document/d/1qoOP07oMKzUCyfb4HbnyeD6ZYEQa004i5Zwqoy7-Ox8/edit), each allocation strategy consists of some key components. This is a quick overview of the relevant components for this strategy.
- **Recipient eligibility**: must be in registry and have proposal
- **Acceptance method**: programmatic
- **Voter eligibility**: allowlist
- **Voting method**: single decision
- **Calculation method**: none
- **Allocation shape**: discrete amount

## Spec
### Custom Variables
This strategy will need the following custom variables:
- `poolOpen` - boolean value that represents whether the pool is accepting new proposals
- `rfpMetadata` - off-chain metadata about the rfp (details, etc)
- `decisionMaker` - single address that is allowed to vote
- `proposal` — contains the recipent's proposal for the rfp
- `proposalBid` - amount of the pool's token that is being requested for the proposal
- `localStatus` - the local recipent status. Can be any of the following values:
    - `pending` — maps to `pending` global status
    - `accepted` - maps to `accepted` global status
    - `rejected` - maps to `rejected` global status
    - `canceled` - maps to `null` global status

### Standard Functions
All standard functions are functions that the given user can call from the `Allo.sol` contract.
#### `createPool()`
The identity admin creates a new pool via `createPool`. At this time, the admin can set the following custom variables:
- `poolOpen`
- `rfpMetadata`
- `decisionMaker`

#### `registerRecipents()`
Potential applicants can apply to the pool via `registerRecipents`. When the recipent is submitted, the strategy uses the following decision tree to determine eligibility:

- Is `poolOpen` true?
    - If yes, proceed
    - If no, revert with message that pool is not accepting proposals
- Does the applicant have a valid Allo registry identity?
    - If yes, proceed
    - If no, revert that valid registry identity is required
- Does `proposal` contain data? 
    - If yes, proceed
    - If no, revert with message that pool requires a proposal
- Does `proposalBid` contain a value?
    - If yes, the recipent is eligible
    - If no, revert with message that specific bid must be requested

If the recipent is eligible, the strategy stores the recipent and programmatically assigns the `Pending` local status.

#### `allocate()`
The decision maker is able to choose which proposal (if any) will win the RFP using the `allocate` function. When a new allocate transaction is submitted, the following checks are made:
- Does msg.sender == `decisionMaker`?
    - If yes, record vote
    - If no, revert with message that voter is not eligible

Within the `allocate` function, the decision maker is able to give one of two commands:
- Select a winning recipent —> this marks the recipent as `accepted` and all other recipents as `rejected`.
- Choose not to accept bids —> this marks all recipents as `rejected`

#### `generatePayouts()`
The `generatePayouts` function checks if there is an accepted recipent.
- If there is an `accepted` recipent, that recipent is moved to the distribution process
- If all recipents are `pending`, the transaction reverts with the message that a winner has not been selected yet
- If all recipents are `rejected`, the funds are made available to be reclaimed by the pool admin

### Open questions
- do we need a global "ineligible" status?