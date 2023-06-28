Spec: Simple Push (Distribution)
---------------------------------

## Overview 
Pool owners need a simple mechanism for distributing funds to recipients. Using this strategy, pool owners can specify a list of recipients and execute (push) the fund transfer to the entire list. 

Out of scope for this contract:
* batching allocation finalization (all happen in one transaction)
* batching recipient distributions (all happen in one transaction)


## User flows
Full flow is shown here: 

### Pool Creation
Pool owner specifies two key pieces of data on the distribution strategy when the round is created: 
* `payoutToken` — the token (can be native or ERC20) in which the pool will be denominated and paid out
* `amount` — the amount of the `payoutToken` that will be in the pool

### Generate payout
When an allocation strategy has finalized its list of recipients, the pool owner calls `finalize` on `Allo.sol`. When this happens:
* `Allo.sol` calls `generatePayout` on the allocation strategy, which returns a distribution mapping of recipients to the percent of the pool they should receive
* `Allo.sol` calls `activateDistribution` on the distribution strategy, which saves the returned distribution mapping on the distribution strategy contract.

### Distribute
Once a distribution mapping has been set on the distribution strategy contract, the pool owner calls `distribute` directly on the same contract. This loops through every recipient and transfers the indicated amount (`amount` * percent of pool in mapping) of the `payoutToken` to the recipient. 

## Open questions
- How will pool owners be able to revise the `payoutToken` or `amount`?
