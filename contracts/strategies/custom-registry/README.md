Spec: Custom Registry Spec
---------------------------------

## Overview 

One thing that Allo will unlock is the ability to curate projects (in the
Registry or not) and use that curation in an allocation strategy. We saw this
use case arise with Zuzalu, where projects were listed in an onchain registry
and the team there wanted to just use that registry to filter projects in to
a registry.

Curation mechanisms can get very complicated, but they can also be very
powerful. We want to give communities the ability to experiment with different
curation mechanisms (including those using tokens) for their capital allocation
and this strategy is a proof of concept for what that could look like.

## Spec

This allocation strategy includes an implementation for a very simple registry
contract. The registry contract is a proof of concept that assumes the `owner`
role is a governance contract, like Governor Bravo. The allocation strategy
described below requires that an address be listed in the registry in order to
be a recipient.

### Recipient logic

In this strategy, prospective recipients only need to register for a grant.
There isn't an approval step before voting. 

- `registerRecipient` - function for recipient to submit application
    - If a recipient submits an application that meets all requirements, then the recipient status is set to `Pending`
    - The first and most important requirement is that the address submitted as
        the `recipientId` is listed in `SimpleProjectRegistry.sol`

### Allocation logic

In this strategy, pool managers are able to review and approve grants for
specific amounts. Only pool managers should be considered eligible allocators
that can call `allocate`.

- `allocate` — function for pool managers (i.e. wallets marked as `eligible`) to either approve or reject a grant application
    - If approving, the pool manager needs to set the amount of the pool that the recipient will receive as part of the grant. When approving, this also updates both global and local status to `Approved`
    - If rejecting, this should update both global and local status to `Rejected`
- `setIntenalRecipientStatusToInReview` - function for pool managers to update the status of the recipient's application to signal that the application has been seen but no decision has been made. This action should keep the global status as `Pending` but set the local status to `In Review`

### Payout calculation logic

The amount set by the pool manager with `allocate` should also be set as the
recipient's `payout`.

### Distribution

This strategy uses a simple, lump-sump payout approach, where the recipient
receives the granted amount in a single payment. Anyone can call distribute to
trigger a grant payout that hasn't already been paid out. 
