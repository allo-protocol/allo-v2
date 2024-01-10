### Concerns

- (Solved) Order of operations seems to work well. However, it would better if milestones were always submitted before allocation.
- (Solved) There may be too many ways to submit milestones.
- (Partially Solved) Refueling a ship. If a ship is refueled and they decide to fund the same recipient (likely scenario), then we have a we have a lot of state to change. We might need to put a current round Id on each recipient.

## Upcoming Changes

- (Medium) Remove applicant and hold all data on recipient as we are no longer mapping recipients by deployed ship address.
- (Medium) Integrate with chainalysis KYT protocol. Set as optional parameter for grant ships.
- (Hardcore) **Make the GameManager generic**. Use proxy pattern to make it possible to deploy many types of GrantShip.
  - The idea is to create an new interface that inherits from IStrategy. Developers can adapt existing Allo Strategies into GrantShip Strategies.
