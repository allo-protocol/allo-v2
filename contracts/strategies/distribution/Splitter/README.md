Spec: Splitter (Distribution)
---------------------------------

## Overview 
Pool owners need a simple mechanism for distributing funds to recipients. Using this strategy, pool owners can specify a list of recipients and execute (push) the fund transfer to the entire list. 

Out of scope for this contract:
* separate batching of allocation finalization (all happen in one transaction)
* separate batching of recipient distributions (all happen in one transaction)

## Spec
### Standard Functions

#### `distribute()`
The pool admin is able to submit a transaction that bulk distributes the total amount of allocated tokens to the specific recipients. It retieves the amount to be split to a recipient from an allocation strategy

## Open questions
- How will pool owners be able to revise the `payoutToken` or `amount`?
