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
- identity owner or member creates pool via `createPool` method on `Allo.sol`
- core QF settings are recorded on allocation strategy contract, including
    - Application start/end and voting start/end dates
    - On-chain application requirements 
    - Sybil Defense settings (minimum contribution, matching cap, donor matching eligibility requirements)
    - Pool metadata

### Application
- applicant applies to pool via `applyToPool` on `Allo.sol`
    - application only processed if application period is open
    - otherwise, revert
- allocation strategy checks that application is eligible
    - if yes, application marked as `Pending`
    - if no, application marked as `Rejected`

### Application approval
- pool owner or member makes decision via `reviewApplications` on allocation strategy contract
- 

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
