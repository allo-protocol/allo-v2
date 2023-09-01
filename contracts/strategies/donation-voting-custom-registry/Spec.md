Spec: Donation Voting with Custom Registry Spec
---------------------------------

## Overview

One thing that Allo will unlock is the ability to curate projects (in the
Registry or not) and use that curation in an allocation strategy. We saw this
use case arise with Zuzalu, where projects were listed in an onchain registry
and the team there wanted to just use that registry to filter projects into
a registry.

Curation mechanisms can get very complicated, but they can also be very
powerful. We want to give communities the ability to experiment with different
curation mechanisms (including those using tokens) for their capital allocation
and this strategy is a proof of concept for what that could look like.

## Spec

This donation voting strategy includes an implementation for a very simple registry
contract. The registry contract is a proof of concept that assumes the `owner`
role is a governance contract, like Governor Bravo. The allocation strategy
described below requires that an address be listed in the registry in order to
be a recipient.

### Recipient logic

In this strategy, recipients must submit an application and be approved by pool admins.

- **Recipient information**
  - prospective recipients must provide an address where they can receive funds
  - prospective recipients must provide the projects address as `recipientId`, which serves as the unique identifier for their registration
- **Recipient eligibility**
  - Pool manager has the option to enable two separate eligibility requirements on this contract:
    - Requiring recipients to have an registry profile in order to apply
    - Requiring recipients to submit answers to questions, stored in metadata
      - This metadata may include information for the front end on required / optional questions, but the contract only needs to check for whether metadata has been submitted
      - The pool manager should have a function that enables them to edit the pool metadata, which is callable at any point
- **Registering recipients**
  - `registerRecipient` can be called by anyone, and is used by prospective recipients to submit an application
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

In this strategy, allocators are able to express their preferences by donating tokens to the recipients they want to receive allocations. All wallets are considered eligible allocators by the contract, as actual eligibility is determined in the offchain payout calculation.

- all addresses will be marked as `eligible` allocators
- `allocate` is callable by any user, and donates tokens to accepted recipients
  - allocators can donate regardless of their eligibility status
  - pool manager can create an allowlist of tokens that will be accepted for donations
    - If an allocator tries to submit unapproved tokens the transaction should revert
  - if an allocator tries to donate to a recipient that is not listed as accepted, then the transaction should revert
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
  - allocators are able to donate to multiple recipients in one transaction
  - allocators are able to donate as many times as they want as long as the allocation window is open

### Payout calculation logic

In this strategy, the funding pool is technically distributed proportionally to votes but everything is calculated offchain. The pool manager will need to upload a final `payout` to the contract, which should include the amount of the pool token that each recipient should receive.

- a function must exist for pool managers to set the `payout` for the pool

### Distribution logic

In this strategy, the pool admins are able to push pool funds to recipients.

- pool managers must have a function with which to indicate that recipients are ready to receive their `payout`. This function should be able to bulk apply that status to recipients.
- `distribute` - function for anyone to distribute pool funds to recipients.
  - This function distributes the allocated funds to any recipients that are marked as ready for `payout`
  - The pool manager should have the ability to distribute the pool in batches
- the pool manager must have a function with which to reclaim any undistributed pool funds. This can only be called 30 days after the allocation window ends.
