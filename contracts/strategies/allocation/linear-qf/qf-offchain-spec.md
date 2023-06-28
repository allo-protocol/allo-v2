Spec: Quadratic Funding with Offchain Calculation
---------------------------------

## Overview 
Quadratic Funding (QF) is a category of mechanisms that distribute a funding pool based upon individual donations to eligible recipients. Essentially, the amount that an individual donates to a project is considered their "vote", which is weighted according to the type of QF calculation formula being used. 

At time of writing (June 2023), most prominent QF formulas are too computationally expensive to be calculated on-chain at a reasonable cost. As a step towards an eventual fully on-chain QF solution, this strategy functions a hybrid solution: 
* votes are recorded **on-chain**
* the distribution is calculated **off-chain**
* the final distribution is recorded **on-chain**

In order to facilitate this, the contract will emit vote events so that off-chain calculation services can pull in the relevant data. 

## User flows
Full flow is shown here: 
![Alt text](<Strategy Evaluation - QF Vote with events.png>)

### Pool Creation
- identity admin creates pool via `createPool` method on `Allo.sol`
- QF settings will require storing a mix of on-chain and off-chain data on the strategy contract:
    - On-chain settings:
        - Application start/end 
        - Voting start/end dates
        - Is Allo registry identity required? yes/no
    - Off-chain settings:
        - Sybil Defense settings (minimum contribution, matching cap, donor matching eligibility requirements)
        - Pool metadata

### Local application statuses
Applications can have one of the following local statuses. An application can only be assigned one status at any given time.
- `Pending` - a valid application has been submitted, but no decision has been made. 
    - Maps to `Pending` global status. 
- `Rejected` - not accepted to the pool, and not eligible for fund allocation. 
    - Maps to `Rejected` global status.
- `Accepted` - accepted to the pool, and eligible for fund allocation.
    - Maps to `Accepted` global status.
- `Re-applied` — the application was originally `Rejected`, but a new application has been submitted. No decision has been made on the reapplication. 
    - Maps to `Pending` global status.


### Application
- applicant applies to pool via `applyToPool` on `Allo.sol`
- strategy checks that application is valid:
    - Is application period open?
        - If no, revert with message that application period is closed
    - If Allo registry identity required, does the application have valid Allo registry identity?
        - If no, revert with message that pool requires a valid Allo registry identity
- If application is valid, mark as `Pending`


### Application approval
- pool admin makes decision via `reviewApplications` on allocation strategy contract. Pool admin can only set applications to `Accepted` or `Rejected`. 
    

### Re-application
- Re-applications are submitted via `applyToPool` on `Allo.sol`, but handled as follows:
    - If application is valid (see decision tree above), then proceed to following checks
    - If the original application's local status is `Pending`, then the application is reverted with the message that application has already been submitted
    - If the original application's local status is `Rejected`, then set application's status as `Re-applied`


### Donation voting
- donor submits donation via `allocate` on `Allo.sol`
    - donation only processed if voting period is open
    - donations can be sent in native tokens or ERC20s
    - donation(s) immediately distributed to recipient
    - event emitted on allocation strategy contract with:
        - donated token address
        - amount of donated token
        - donor address
        - recipient identifier

*Note:* the pool owner will have the flexibility to decide which calculation service that they want to use. Currently there are two known off-chain solutions that this implementation should support:
- Graph indexer: https://github.com/allo-protocol/graph
- Allo indexer: https://github.com/gitcoinco/allo-indexer
### Finalize distribution
- pool owner uploads a final distribution to the allocation strategy
- pool owner sets the amounts as ready for payout

## Open questions
- Which pool settings need to be recorded on-chain vs in pool metadata?
    - Sybil defense settings?
    - Accepted donation tokens?
    - calculation service/tool?
- Which application statuses do we want on this pool?
