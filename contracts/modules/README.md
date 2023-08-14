<!-- abstract Base contract
 - all getter, all base variables

- internal functions for every getter (and setter)

// go through direct grants
// where isPoolActive live?

<!-- # Recipient Management / Accept Recipient -->

<!-- ## Register 
  - registry gated
  - not registry gated
  - metadata 
  - no metadata -->
<!-- 
flavors: 
  - review process
  - auto acceptance (apply, set metadata, recipientAddress, etc..)
  - only added by pool owner
  - whitelist and afterward (register apply, set metadata, recipientAddress, etc..)

  - custom registry

 ## no registration required
  - token gated
  - nft gated
  - ....
  - -> also auto acceptance (apply, set metadata, recipientAddress, etc..)

## Payout
 - set payouts for every recipient
 - set merkle tree and stuff
 - qv calculations
 - winner list
 - milestone based -> allocation depends // wtf we're doing

## Allocation
  - token vault with claim
  - multiple NFT token
  - NFT votes with voiceCredits
  - governance token voting stuff
  - other voiceCredit stuff


## Time gated registration

## Time gated allocation --> 

<!-- ## Withdrawal  -->

# Module Library

## 0. Interface and Base Contract

- Strategy interface with that includes common getters, setters, and external functions from the `Allo` interface.
- An abstract base contract with all shared base variables.
- Internal functions for each getter and setter.

Provides a foundation for other modules to build upon.

## 1. Registration
  - Registry gated
    - Extension: Custom Registry
  - Not Registry Gated
  - No Registration required
  - Restricted by Poolmanager

Extensions:
  - Recipient Metadata

## 2. Recipient Status Management
  - Manual Review
    - Extension: Threshold
  - Auto Acceptance
  - NFT Gated


# Module Development

## 0. Branching

- Create a separate branch from the main branch to serve as the primary module development branch.
- For each module being developed, create separate branches from the module main branch.
- Avoid merging the module main branch back into the repository's main branch until the module library is fully developed and tested.

```
  |    branch
main ------- modules
  |             |
  |             |_______ModuleA
  |             | /
  |             |/ merge
  |             |
  |             |
  |             |_______ModuleB
  |             | /
  |             |/ merge
  |            /
  |___________/ merge into main
  |
```

## 1. Base Contract for Shared State

We will need a abstract base contract containing:

- `IStrategy` interface
- universally shared state variables
- getter and setter as internal function signatures

**Note:** we already have a contract like this which needs to be extended during the module development.

## 2. Unified Access through Internal Getters and Setters

- Enable cross-module data access via internal getter and setter functions defined in the base contract.
- These functions must be uniquely implemented by each module category for consistent data manipulation.

**For example:**

To be able to access the information across the different modules the base contract needs to implement  functions like  

```solidity
function _setRecipientStatus(Status/uint8 ..) internal;

function _getRecipientStatus(Status/uint8 ..) internal returns (Status/uint8);
```

 which will be implemented by an module of the right category, in this case in a Recipient management module.

## 3. Replacing Structs with Mappings

Instead of using structs, modules should use mappings to store strategy-specific information.

**For Example:** 

Instead of a `Recipient` struct with a `status` property, a module should implement a `address => Status` mapping with the corresponding `getter` and `setter` (defined in the base contract).

## 4. Implementing Category-Specific Modules

- Organize modules into distinct categories based on functionality (e.g., Recipient Management, Payout, Allocation).
- Each category will have modules and potentially module extensions.

**Example for Review Module and Extension:**

- Review Module:

Create a Recipient Review module to manage reviews and recipient status changes.
Implement `_setRecipientStatus` internally for transitioning status.

```solidity
function _setRecipientStatus(..) internal virtual {
  /* managing status change */
}
```


- Review Threshold Extension:

Extend the Review Module to include a review threshold condition.
Override `_setRecipientStatus` to incorporate threshold-based logic.
Use `super._setRecipientStatus` to maintain core functionality.

```solidity
function _setRecipientStatus(..) internal override {
  if(threshold) {
    super.setRecipientStatus(..);
  }
}
```

## 5. Compiling Constraints

- Ensure that every strategy must include at least one module in each category.
- Enforce this by requiring the implementation of specific internal functions within each category.

## 6. Test Cases

- Ideally the module development should maintain the integrity of existing test cases.
- Adjustments required due to function signature changes, parameter orders, or variable names should be minimal.
- Simultaneously, we should build test cases for each module during its development phase.
- Strive to ensure that the module-specific test cases can eventually replace the current tests seamlessly.
