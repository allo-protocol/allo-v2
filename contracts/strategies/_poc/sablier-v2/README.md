## Spec: Sablier V2 Distribution Strategy

## Overview

Sablier is a token streaming protocol that enabled by-the-second payments. This integration allows Allo pool manager to create streams with specific durations and custom distribution methods:

- `LockupLinearStrategy` for linear payment streaming
- `LockupDynamicStrategy` for custom payment streaming curves

Both strategies call the create functions which set the start time to `block.timestamp`:

- [`createWithDurations`](https://docs.sablier.com/contracts/v2/reference/core/contract.SablierV2LockupLinear#createwithdurations)
- [`createWithDeltas`](https://docs.sablier.com/contracts/v2/reference/core/contract.SablierV2LockupDynamic#createwithdeltas)

Visual images can provide a clearer understanding of the types of distribution curves you can create. For more details, please refer to Sablier's documentation, available at [docs.sablier.com](https://docs.sablier.com/apps/features#the-universal-streaming-engine).

These strategies assume that the voting systems and the allocation calculations are made **off-chain**. Then, once the grant is distributed, all calculations are managed **on-chain** by the [Sablier Protocol](https://github.com/sablier-labs/v2-core).

## Spec

### Recipient logic

In these strategies, prospective recipients only need to register for a grant. There isn't an approval step before voting.

- `registerRecipient` - function for recipient to submit application
  - if a recipient submits an application that meets all requirements, then the recipient status is set to `Pending`
  - **Customizable Settings**
    - pool manager can require recipients to have Allo registry profile in order to apply
      - if pool manager doesn't require Allo profile and the recipient doesn't have one, then `msg.sender` is used as recipient id
    - pool manager can include optional and required questions in an application, stored in metadata
      - recipient must answer questions as specified by pool manager
    - pool manager can require that the recipient include a requested grant amount

### Allocation logic

In these strategies, pool managers are able to review, approve, and reject grants for specific amounts. Only pool managers should be considered eligible allocators that can call `allocate`.

- `allocate` — function for pool managers (i.e. wallets marked as `eligible`) to either approve or reject a grant application
  - If approving, the pool manager needs to set the amount of the pool that the recipient will be streamed as part of the grant. When approving, this also updates both global and local status to `Approved`
  - If rejecting, this should update both global and local status to `Rejected`
- `setRecipientStatusToInReview` - function for pool managers to update the status of the recipient's application to signal that the application has been seen but no decision has been made. This action should keep the global status as `Pending` but set the local status to `In Review`

### Payout calculation logic

The amount set by the pool manager with `allocate` should also be set as the recipient's `payout`.

### Distribution

These strategies will use a duration payout approach, where the recipient must wait certain time period to unlock the full grant payments. The pool manager should have the ability to configure the time details for each recipient, and to approve the distribution.

- `LockupLinearStrategy`:
  - `changeRecipientDurations` - function for the pool manager to change the recipient's funding durations
- `LockupLinearStrategy`:

  - `changeRecipientSegments` - function for the pool manager to change the recipient's funding segments

- `distribute` - function for the pool manager to accept the recipient's payout, it will call the Sablier V2 contracts to create streams:
  - `SablierV2LockupLinear`
  - `SablierV2LockupDynamic`
  - You can see a list of all Sablier V2 contracts [here](https://docs.sablier.com/contracts/v2/deployments)

All stream ids will be stored in the strategy contract within the reverse mapping `_recipientStreamIds`

### Cancel Stream

When a stream is created and set to be cancelable, the pool manager has the option to invoke the `cancelStream` function. This can be useful in case any unexpected event occurs during the streaming period. Subsequently:

- The unstreamed tokens will be added back to the pool amount
- The recipient grant amount will be decreased
- The allocated grant amount will also be decreased

Also, the `Status` will be updated to `Canceled` for the recipient.
