Spec: Hats Protocol for Voter Eligibility
---------------------------------

# Hats Voter Eligibility

## Overview

Hats is a protocol for representing roles in an organization onchain. It uses an
ERC1155 for each role and includes the ability to grant and revoke these roles.
The wearer or a hat (address holding the ERC1155 token) is able to perform and
access anything that is gated with that token.

One uses case for Hats and Allo is to create a grants committee where the
wearer of a Hat is able to allocate capital to a given project. The Hat can be
owned by another Hat or a DAO, which controls who holds the token and is
therefore able to allocate from a pool. This strategy is a minimal proof of
concept for how this would work.

## Spec

The wearer of a hat (address holding an token in the Hats ERC1155) is able to
allocate capital from the pool managed by this strategy. A project from the
project registry applies to receive funding. They can be distributed that
funding if a Hat wearer approves their allocation. There is a delay period,
during which another Hat wearer can reject an application. Once rejected, the
status of a recipient cannot change.

### Recipient Logic

In this strategy, someone must submit an application in order to be considered
for a grant.

The `registerRecipient` function should do the following:

- If someone submits an application, they must do so with a valid anchor from
    the Registry and they must be a member of that identity
- Registration must include the anchor in the registry, the amount of funds
    requested, and offchain metadata
- Someone cannot submit more than once

**Recipient Information:**

The strategy tracks the following data for every project:

- Recipient ID: the project's anchor address in the Registry
- Amount: how much the project is requesting
- Metadata: offchain metadata about the project's application
- Status: the status of the application (None, Pending, Approved, Rejected)

The strategy also tracks the timestamp for when a recipient's application is
approved. Approval kicks off a delay window, during which time another member of
the grants committee can reject the recipient. Once the delay window has passed,
the grant can be distributed from the pool.

**Recipient Eligibility**

The strategy checks that a project applying has an anchor in the Registry, but
otherwise leaves eligibility up to the grants committee.

### Allocate Logic

The grants committee (Hats wearers) determine allocation. The strategy assumes
that they are trusted and thus given the Hat to allocation.

To approve or reject an application, one of the Hats wearers must call
`allocation()` and pass in the following:

1. `recipientId` - The address of the project being approved or rejected
2. `approval` - Boolean for whether the project is approved or rejected

The `allocate()` method takes these parameters and then sets the status
accordingly. If an application is approved, then a timestamp is recorded for
that approval. Funds can be distributed from the pool, to this project once the
delay period has passed from when the time when the timestamp is recorded.

### Payout Calculation

Projects apply with the amount of funding they'd like to receive.

### Distribution

After a project's grant is approved and the delay period has passed, funds can
be distributed. Anyone can call `distribute()` with the list of addresses to
distribute funding to. Distribute will directly transfer the funds from the pool
to the recipient.
