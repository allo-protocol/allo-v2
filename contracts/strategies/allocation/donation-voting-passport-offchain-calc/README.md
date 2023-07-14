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
In this strategy, recipients must apply and be approved by pool admins. 
- `registerRecipient` - function for recipient to submit application
    - if a recipient submits an application that meets all requirements, then the recipient status is set to `Pending`
    - **Customizable Settings**
        - pool admin can require recipients to have Allo registry identity in order to apply
            - if pool admin doesn't require Allo identity and the recipient doesn't have one, then `msg.sender` is used as recipient id
        - pool admin can include optional and required questions in an application, stored in metadata
            - recipient must answer questions as specified by pool admin
        - pool admin can require the recipient to have verified credentials for Twitter or Github
            - recipient must have those credentials on their recipient id
- `reviewApplication` - function for pool admins to manually accept applications into the round
    - If a pool admin accepts the application, the recipient status is updated to `Approved`
    - If a pool admin rejects the application, the recipient status is updated to `Rejected`

### Voter eligibility logic
In this strategy, the pool admin can use Passport to signal whether the voter should be considered eligible. 

- the pool admin should be able to configure whether they want to use Passport for voter eligibility signalling
    - If they choose to configure, all voters will be marked as `eligible` or `ineligible` depending on the Passport score
    - If they do not configure, all voters will be marked as `eligible`

### Voting logic
In this strategy, voters submit a vote by donating tokens to recipients. The donations are held in the protocol until the round ends, then the pool admin is able to release those funds. Any voter can submit a donation, but only eligible voters (as measured by Passport) will receive matching in the off-chain calculation.  

- `vote` - function for voters to submit donations to recipients
    - voters can submit donations regardless of their eligibility status
    - **Customizable Settings** 
        - pool admin can create an allowlist of tokens that will be accepted for donations
            - If a voter tries to submit unapproved tokens the transaction should revert

### Allocation shape
In this strategy, the funding pool is technically distributed proportionally to votes but everything is calculated offchain. The pool admin will need to upload a final allocation to the contract, which should be the amount of the pool token that each recipient should receive. 

- `uploadAllocation` - function for pool admins to upload final allocation

### Distribution logic
In this strategy, the pool admins are able to push pool funds to recipients. They are also able to release the donation funds.

- `distribute` - function for pool admin to distribute pool funds to recipients, as indicated by the allocation added with `uploadAllocation`
    - If there is no allocation uploaded, then this should revert
    - The pool admin should have the ability to distribute the pool in batches
- `releaseDonations` - function for pool admin to release donation funds to recipients
