Spec: Donation Allocation with Offchain Calculation
---------------------------------

## Overview 
There is a category of mechanisms (including Quadratic Funding or QF) allocate a funding pool based upon individual donations to eligible recipients. Essentially, the amount that an individual donates to a project is considered their "vote", which is weighted according to the type of voting calculation formula being used. 

At time of writing (June 2023), most prominent QF formulas are too computationally expensive to be calculated on-chain at a reasonable cost. As a step towards an eventual fully on-chain QF solution, this strategy functions as a hybrid solution: 
* votes are recorded **on-chain**
* the allocation is calculated **off-chain**
* the final distribution is recorded **on-chain**

In order to facilitate this, the contract will emit vote events so that off-chain calculation services can pull in the relevant data. 

## Component Quickview
As laid out in the [components overview](https://docs.google.com/document/d/1qoOP07oMKzUCyfb4HbnyeD6ZYEQa004i5Zwqoy7-Ox8/edit), each allocation strategy consists of some key components. This is a quick overview of the relevant componets for this strategy.
- **Recipient eligibility**: registry identity required
- **Acceptance method**: single admin manual review
- **Voter eligibility**: offchain eligibility
- **Voting method**: donation voting
- **Calculation method**: offchain calculation
- **Allocation shape**: proportional distribution

## Spec
### Custom Variables
This strategy will need the following custom variables:
- `registerStartTime` — the time at which recipients can start being submitted
- `registerEndTime` - the time at which recipients can no longer be submitted
- `votingStartTime` - the time at which votes can start being submitted
- `votingEndTime` - the time at which votes can no longer be submitted
- `identityRequired` - boolean property for whether or not a valid Allo Identity is required for recipient
- `acceptedDonationToken` - the list of tokens (can include the chain's native token) that are accepted for donations
- `poolMetadata` - Additional pool information stored offchain. This will likely include: 
    - minimum Contribution
    - matchingCap
    - donor matching eligibility requirements (i.e. Passport)
    - Pool details (name, details, etc)
- `localStatus` - the recipient statuses specific to this strategy. Valid statuses are:
    - `Pending` - a valid recipient has been submitted, but no decision has been made
        - maps to `Pending` global status
    - `Rejected` - not accepted to the pool, and not eligible for fund allocation.
        - Maps to `Rejected` global status.
    - `Accepted` - accepted to the pool, and eligible for fund allocation.
        - Maps to `Accepted` global status.
    - `Re-applied` — the recipient was originally `Rejected`, but a new recipient has been submitted. No decision has been made on the rerecipient. 
        - Maps to `Pending` global status.

### Standard Functions
All standard functions are functions that the given user can call from the `Allo.sol` contract.
#### `createPool()`
The identity admin creates a new pool via `createPool`. At this time, the admin can set the following variables:
- `registerStartTime` 
- `registerEndTime` 
- `votingStartTime`
- `votingEndTime`
- `identityRequired`
- `acceptedDonationToken`
- `poolMetadata`

#### `registerRecipients()`
Potential applicants can apply to the pool via `registerRecipients`. When the recipient is submitted, the strategy uses the following decision tree to determine eligibility:

- Is `identityRequired` true? 
    - If yes, does the recipient have valid Allo registry identity?
        - If yes, proceed
        - If no, revert with message that pool requires a valid Allo registry identity
    - If no, does the recipient have valid Allo registry identity?
        - If yes, proceed with registry identity
        - If no, assign unique identity and proceed
- Is the recipient timestamp between `registerStartTime` and `registerEndTime`?
    - If no, revert with message that recipient period is closed
    - If yes, the recipient is eligible.


If the recipient is eligible, the strategy stores the recipient and assigns one of the following local statuses:
- `Pending` — the identity has not already submitted an recipient OR the identity has an existing recipient currently marked as `Pending`
- `Re-applied` — the identity has already submitted an recipient that is currently marked as `Rejected`

#### `allocate()`
Donors are able to submit donations to specific recipients via the `allocate` function. The transaction can include donations to one or to multiple recipients. When a new donation is submitted, the following checks are made:
- Is the donation timestamp between `votingStartTime` and `votingEndTime`?
    - If yes, proceed
    - If no, revert with message that donation period is closed
- Do the donation recipients have the `Accepted` status?
    - If yes, proceed
    - If no, revert with message that the recipients are not valid recipients
- Is the donation in a valid token from the `acceptedDonationToken` list?
    - If yes, proceed
    - If no, revert with message that donation must be in approved token

Once the donation passes those checks, the contract:
- immediately distributes donations to their recipients
- emits an event from the allocation strategy contract with:
    - donated token address
    - amount of donated token
    - donor address
    - recipient identifier

#### `generatePayouts()`
The pool admin can begin the distribution process by calling the `generatePayouts` function. Because the calculations for this strategy are being handled off-chain and will be uploaded manually (see `setAllocation` function below), there is a chance that the `poolAllocation` does not have a set amount. If the admin calls `generatePayouts` when the allocation is null, then the transaction should revert with the message that the allocation is not set. 

### Custom Functions
These are functions that are called via the allocation strategy contract.

#### `reviewRecipients()`
This function enables the pool admin to decided whether or not an eligible recipient is accepted into the pool. The admin is able to call this function to assign an `Accepted` or `Rejected` status to any eligible recipient (regardless of current status). Note that the admin should be able to bulk assign statuses. 

#### `setAllocation()`
Since all voter eligibility and calculations are occuring off-chain, the pool admin needs a way to record their calculated allocation on chain. Using this function, the admin can upload an allocation mapping to the contract, which can be referenced from the `generatePayouts` function. 
