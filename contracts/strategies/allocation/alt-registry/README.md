Spec: Application from alternate registry
---------------------------------

## Overview 
Some builders have flagged that they want the ability to use alternate "registries" to determine whether or not a potential recipient is eligible to receive funds from their pool. This strategy is designed to test that specific assumption, with basic mechanisms for the non-recipient components. 

## Component Quickview
As laid out in the [components overview](https://docs.google.com/document/d/1qoOP07oMKzUCyfb4HbnyeD6ZYEQa004i5Zwqoy7-Ox8/edit), each allocation strategy consists of some key components. This is a quick overview of the relevant components for this strategy.
- **Recipient eligibility**: alternate registry
- **Recipient approval**: programmatic
- **Voter eligibility**: pool admin
- **Voting method**: simple yes/no
- **Calculation method**: simple yes/no
- **Allocation shape**: discrete amount

## Spec
### Custom Variables
This strategy will need the following custom variables:
- `poolOpen` - boolean value that represents whether the pool is accepting new applications
- `alternateRegistry` - location of alternate registry of eligible recipients

### Standard Functions
All standard functions are functions that the given user can call from the `Allo.sol` contract.
#### `createPool()`
The identity admin creates a new pool via `createPool`. At this time, the admin can set the following custom variables:
- `poolOpen`
- `alternateRegistry`

#### `registerRecipients()`

Potential recipients can register to the pool via `registerRecipients`. When the registration is submitted, the strategy uses the following decision tree to determine eligibility:

- Is `poolOpen` true?
    - If yes, proceed
    - If no, revert with message that pool is not accepting proposals
- Is recipient present in `alternateRegistry`? 
    - If yes, recipient is eligible
    - If no, revert with message that recipient must be a member of `alternateRegistry`

If the recipient is eligible, the strategy stores the application and programmatically assigns the `Accepted` local status.

#### `allocate()`
The admins of the pool manually assign allocations to recipients via the `allocate` function. Any pool admin can call `allocate()` on Allo.sol and pass in the amount of the pool to allocate to the specific recipient.

#### `generatePayouts()`
The pool admin can transfer an accepted proposal to the distribution process by calling the `generatePayouts` function. Any proposal marked as `accepted` is considered eligible to begin the distribution process. The proposal is recorded as eligible to receive their `amountRequested`. 

### Open questions