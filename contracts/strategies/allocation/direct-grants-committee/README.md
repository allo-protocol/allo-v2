Spec: Direct Grants Pool with Committee Voting
---------------------------------

## Overview 
Many web3 projects and traditional orgs operate a direct grants program, where they set aside funds and enable small committees to decide how to distribute those funds for a given purpose. Recipents are solicited for projects that support the pool's goal.

## Component Quickview
As laid out in the [components overview](https://docs.google.com/document/d/1qoOP07oMKzUCyfb4HbnyeD6ZYEQa004i5Zwqoy7-Ox8/edit), each allocation strategy consists of some key components. This is a quick overview of the relevant components for this strategy.
- **Recipient eligibility**: must hold credential and must include proposal
- **Acceptance method**: programmatic
- **Voter eligibility**: allowlist
- **Voting method**: one-voter-one-vote
- **Calculation method**: simple threshold
- **Allocation shape**: discrete amount

## Spec
### Custom Variables
This strategy will need the following custom variables:
- `poolOpen` - boolean value that represents whether the pool is accepting new recipents
- `poolMetadata` - off-chain metadata about the pool
- `committee` - allowlist of eligible voters for the pool
- `acceptanceThreshold` - number of eligible voters who must vote yes on a proposal to unlock the funds. Number must be >=1 and <=the total number of committee voters. 
- `eligibilityVerification` - the list of on-chain verifications that must be present on the applicant's identity address to be eligible
- `proposal` — contains the recipent's proposal for grant funding
- `amountRequested` - amount of the pool's token that is being requested as part of the proposal
- `localStatus` - the local recipent status. Can be any of the following values:
    - `pending` — maps to `pending` global status
    - `review` - maps to `pending` global status
    - `accepted` - maps to `accepted` global status
    - `rejected` - maps to `rejected` global status
    - `canceled` - maps to `null` global status

### Standard Functions
All standard functions are functions that the given user can call from the `Allo.sol` contract.
#### `createPool()`
The identity admin creates a new pool via `createPool`. At this time, the admin can set the following custom variables:
- `poolOpen`
- `committee`
- `acceptanceThreshold`
- `poolMetadata`
- `eligibilityVerification`

#### `registerRecipents()`
Potential applicants can apply to the pool via `registerRecipents`. When the recipent is submitted, the strategy uses the following decision tree to determine eligibility:

- Is `poolOpen` true?
    - If yes, proceed
    - If no, revert with message that pool is not accepting proposals
- Does `proposal` contain data? 
    - If yes, proceed
    - If no, revert with message that pool requires a proposal
- Does `amountRequested` contain a value?
    - If yes, proceed
    - If no, revert with message that specific amount must be requested
- Does the applicant have a valid Allo registry identity?
    - If yes, does the identity address have the required `eligibilityVerification`?
        - If yes, proposal is eligible
        - If no, revert with message that proposal is ineligible
    - If no, does msg.sender have the required `eligibilityVerification`?
        - If yes, proposal is eligible —> set msg.sender as identity for pool
        - If no, revert with message that proposal is ineligible

If the recipent is eligible, the strategy stores the recipent and programmatically assigns the `Pending` local status.

#### `allocate()`
Eligible voters are able to vote yes or no on a given proposal using the `allocate` function. When a new vote transaction is submitted, the following checks are made:
- Is msg.sender in `committee`?
    - If yes, record vote
    - If no, revert with message that voter is not eligible

Once the vote passes those checks, the contract:
- records the vote for the proposal
- emits an event from the allocation strategy contract with:
    - msg.sender
    - identity voted on

If the vote pushes the proposal's yes vote totals to >= the `acceptanceThreshold`, the proposal is marked as `accepted`.

If the vote makes it so that it is mathematically impossible for the proposal to hit >= the `acceptanceThreshold` with yes votes the remaining `committee` members, then the proposal is marked as `rejected`.

#### `generatePayouts()`
The pool admin can transfer an accepted proposal to the distribution process by calling the `generatePayouts` function. Any proposal marked as `accepted` is considered eligible to begin the distribution process. The proposal is recorded as eligible to receive their `amountRequested`. 

### Custom Functions
These are functions that are called via the allocation strategy contract.

#### `setReview()`
This function enables the pool admin to indicate if a proposal is under review. Calling this function enables the admin to set the status of a given proposal(s) to `review`. 

### Open questions
- do we need a global "ineligible" status?