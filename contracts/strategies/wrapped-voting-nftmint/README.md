Spec: Wrapped Voting with NFT Mint
---------------------------------

## Overview 

One of the use cases we see for Allo is the automatic distribution and
redistribution of funds based on onchain activity, other than explicit
voting/allocating. Basically, Allo would allow you to take an existing onchain
protocol and turn any method into a voting method in how a pool of funds should
be distributed, just by wrapping that method in an allocation strategy.

One tangible example is our partnership with Endaoment. Endaoment has an onchain
protocol that allows anyone to donate to nonprofits using crypto. Every
nonprofit is represented by a single contract and has a `donate()` method that
you can call. To incentivize further donations, Endaoment could wrap this
`donate()` method in the `allocate()` method of a donation strategy, such that
the implementation of `allocate()`:

1. Checks to ensure that the address being donated to (the recipient, in Allo
   terms) is a contract in Endaoment's protocol
2. Calls the `donate()` method of that contract, donating the funds
3. If the donation succeeds, casting a vote inside the allocation strategy for
   that recipient

Endaoment is doing this to add Quadratic Funding as a feature to their platform,
so after a quarter (3 months) have passed, they can calculate the distribution
of a matching pool based on all the donations during that period of time. 

This is just one example. If you generalize this, it can lead to automatic
allocation of funds OR be an incentive mechanism that protocols can use in place
of staking rewards or yield.

### Additional Resources

- [Mock NFT Protocol POC](https://github.com/gabewin/wrapped-voting/tree/main)
- [Earlier draft of this spec](https://www.notion.so/gitcoin/Wrapped-Voting-Proof-of-Concept-73bff464fe914d68bd665899a28eb3f9?pvs=4)

## Spec

This will be a proof of concept implementation of wrapped voting that uses
a simple, mock NFT protocol as an example. Calling `mint()` on an NFT created by
the protocol's factory contract will be wrapped by an allocation strategy. The
NFT contract that earns the most votes (i.e. receives the most `mints()`) will
win the allocation from the pool.

### Recipient logic

In this strategy, the recipient does not need to apply. The first time they are
voted for, they are added as a recipient if the address being voted for is an
NFT contract created by the mock protocol factory contract.

**Recipient eligibility**

- The Factory contract has a mapping of the addresses for all the NFTs that it
    creates
- A recipient is eligible if they are in that mapping (i.e. the address is for
    a contract created by that factory)

**Recipient information**

- Recipients are represented by the address of the NFT contract created by the
mock protocol's factory contract

**Registering recipients**

- `registerRecipient` should do the following:
    - Check that the address provided is listed on the factory contract
    - Add them to mapping of votes (`address NFT => uint votes`) with a votes
    value of 0
- This step should be optional, such that the first time an address is voted
for, they're added to this mapping with a `votes` of `1`.

### Allocate function logic

After a voting window closes, the NFT with the most votes "wins" the pool and
the funds are distributed to that contract. The allocation strategy has a voting
window, during which votes can be accepted. When the voting window closes,
anyone call call `distribute()` to transfer the pool balance to the winning NFT.

### Final allocation logic

The winning NFT (the one with the most votes) will receive the entire pool
amount.

### Distribution

This strategy will distribute the pool in a single, lump-sum. Anyone can call
the `distribute()` function, which will transfer the funds to the winning NFT.
This can only happen after the voting window has closed though.
