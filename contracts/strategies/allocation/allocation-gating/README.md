Allocation Gating
---------------------------------

## Overview 
Some builders have flagged that they want the ability create pools that don't require applications, where anyone who has taken some action is automatically an eligible recipient in their pool. This is a strategy stub to test that format. Gating would be done during allocation and the means of gating could be 
- A recipient owings an ERC721
- A recipient having a token balance above a threshold

## Component Quickview
As laid out in the [components overview](https://docs.google.com/document/d/1qoOP07oMKzUCyfb4HbnyeD6ZYEQa004i5Zwqoy7-Ox8/edit), each allocation strategy consists of some key components. This is a quick overview of the relevant components for this strategy.
- **Recipient eligibility**: automatic
- **Recipient approval**: programmatic
- **Voter eligibility**: pool admin
- **Voting method**: simple yes/no
- **Calculation method**: simple yes/no
- **Allocation shape**: discrete amount

## Spec
### Custom Variables
This strategy will need the following custom variables:
- `alternateRegistry` - location of alternate registry of eligible recipients, and logic for how to interpret that information

### Standard Functions
All standard functions are functions that the given user can call from the `Allo.sol` contract.
#### `createPool()`
The identity admin creates a new pool via `createPool`. At this time, the admin can set the following custom variables:
- `alternateRegistry`

#### `allocate()`
The admins of the pool manually assign allocations to recipients via the `allocate` function. Any pool admin can call `allocate()` on Allo.sol and pass in the amount of the pool to allocate to a specific recipient address. When `allocate` is called, the contract checks whether the recipient is present in `alternateRegistry`. 
- If present, the `allocate()` call is processed
- If not present, the call is reverted

#### `generatePayouts()`
The pool admin can transfer an accepted proposal to the distribution process by calling the `generatePayouts` function. Any proposal marked as `accepted` is considered eligible to begin the distribution process. The proposal is recorded as eligible to receive their `amountRequested`. 