Spec: Donation Voting with Passport and Offchain Calculation
---------------------------------

## Overview 
There is a category of mechanisms (including Quadratic Funding or QF) allocate a funding pool based upon individual donations to eligible recipients. Essentially, the amount that an individual donates to a project is considered their "vote", which is weighted according to the type of voting calculation formula being used. 

At time of writing (June 2023), most prominent QF formulas are too computationally expensive to be calculated on-chain at a reasonable cost. As a step towards an eventual fully on-chain QF solution, this strategy functions as a hybrid solution: 
* votes are recorded **on-chain**
* the allocation is calculated **off-chain**
* the final distribution is recorded **on-chain**

This strategy also uses Passport as a voter eligibility signal as outlined below. 

## Spec
### Recipient logic
In this strategy, recipients must submit an application and be approved by pool admins. 
- **Recipient information**
    - In this strategy, recipients must provide a recipientID and a payout address at which they can receive funds. 
        - If the Allo registry setting is required, then the Allo identityID is used as the recipientID
- **Recipient eligibility**
    - Pool manager has the option to enable two separate eligibility requirements on this contract:
        - Requiring recipients to have an Allo registry identity in order to apply
        - Requiring recipients to submit answers to questions, stored in metadata
            - This metadata may include information for the front end on required / optional questions, but the contract only needs to check for whether metadata has been submitted
            - The pool manager should have a function that enables them to edit the pool metadata, which is callable at any point
- **Registering recipients**
    - `registerRecipient` can be called be anyone, and is used by prospective recipients to submit an application
        - if the recipient's application is eligible (by criteria set above), the recipient status (global and local) is set to `Pending`. If the recipient is ineligible, the transaction should revert with an error message that the application is ineligible. 
        - pool managers must set an application start and end date on the strategy. `registerRecipient` can only be called in that window, otherwise it will revert. 
    - Pool managers need a function to manually accept applications into the round. 
        - If any pool manager accepts the application, the recipient status is updated to `Approved` (global and local)
        - If any pool manager rejects the application, the recipient status is updated to `Rejected` (global and local)
        - Pool managers are able to change an approved or rejected recipient by calling the same function. 
    - Recipients are only able to have one registration in a pool. Re-registrations should be handled as follows:
        - If a recipient's current status is `Pending`, then their application info is updated and their status remains `Pending` (global and local)
        - If a recipient's current status is `Rejected`, then their application info is updated and their local status is changed to `Appealed` — global status should change to `Pending`
        - If a recipient's current status is `Accepted`, then their application info is updated and their status is changed to `Pending` (global and local)

### Allocate function logic
In this strategy, eligible participants are able to express their preferences by donating tokens to the recipients they want to receive allocations. Pool managers can opt to use Passport to determine participant eligibility. 

- the pool is able to configure Passport for voter eligibility signalling
    - If they choose to configure, all voters will be marked as `eligible` or `ineligible` depending on the Passport score
    - If they do not configure, all voters will be marked as `eligible`
- `allocate` is callable by any user, and donates tokens to accepted recipients
    - users can donate regardless of their eligibility status
    - pool manager can create an allowlist of tokens that will be accepted for donations
        - If a user tries to submit unapproved tokens the transaction should revert
    - if a user tries to donate to a recipient that is not listed as accepted, then the transaction should revert
    - pool manager must set an allocation start and end date on the strategy. 
        - `allocate` can only be called in the allocation window, otherwise it reverts
    - when a donation is made via `allocate`, the contract must store or emit:
        - the address that donated the funds
        - the address's eligibility status
        - the token they donated
        - the amount of the token they donated
        - the recipient to which they donated
        - the time at which the donation was made
    - the donated tokens are held on the contract until the end of the round.
        - the held tokens are automatically released when the allocation window ends
    - users are able to donate to multiple recipients in one transaction
    - users are able to donate as many times as they want as long as the allocation window is open

### Final allocation logic
In this strategy, the funding pool is technically distributed proportionally to votes but everything is calculated offchain. The pool manager will need to upload a final allocation to the contract, which should be the amount of the pool token that each recipient should receive. 

- `uploadAllocation` - function for pool admins to upload final allocation

### Distribution logic
In this strategy, the pool admins are able to push pool funds to recipients.

- pool managers must have a function with which to indicate that recipients are ready for distribution. This function should be able to bulk apply that status to recipients.
- `distribute` - function for anyone to distribute pool funds to recipients.
    - This function distributes the allocated funds to any recipients that are marked as ready for distribution
    - The pool manager should have the ability to distribute the pool in batches
- the pool manager must have a function with which to reclaim any undistributed pool funds. This can only be called 30 days after the allocation window ends. 
