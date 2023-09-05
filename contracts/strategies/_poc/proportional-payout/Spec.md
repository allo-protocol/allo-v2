Spec: Proportional Payout
---------------------------------

## Overview 

One way that some communities choose to distribute funds is proportional to
the number of votes that a project receives. In this strategy, project selection
is important and the number of projects is usually limited. Then, if a project
receives 10% of the votes, they'll receive 10% of the pool.

One example of this is GiveTogether.xyz: Privy and Gitcoin selected three
projects and put up a fund of $10,000. Everyone who signs up for a Privy wallet
can then vote on how that pool is distributed. After the voting period ends, the
funds are distributed proportionally to the number of votes each project
received.

## Spec

### Recipient logic

In this strategy, recipients are selected by the pool managers and there isn't
an approval step before voting.

**Recipient eligibility**

- Pool manager adds/removes recipients

**Recipient information**

- `recipientId`: address where funds should be sent
- `metadata`: offchain metadata for a project
- `status`: boolean value for whether a project is being added or removed

**Registering recipients**

- `registerRecipient` - function for adding/removing recipients
    - Can only be called by a Pool Manager
    - Can be used to either add or remove a recipient

### Allocate function logic

Anyone holding a Soul-bound Token (SBT) is able to vote. These will be addresses
created by Privy, who will then distribute the SBT after a user signs up using
their service.

- `allocate` — function for voters (i.e. wallet holding an SBT issued by Privy) to cast a vote for one of the projects
    - When called by an eligible voter, increments the number of votes a project has received, the total number of votes cast, and records who voted
    - A wallet can only vote once and for one project
    - `allocate` must be called during the voting window

### Final allocation logic

After the voting period ends, the amount of funds a project will be allocated is
proportional to the number of votes they received during the voting period. So
if a project received 15% of the total votes (i.e. 15 out of 100 total votes
cast), then they'll receive 15% of the pool.

### Distribution

In this strategy, the pool managers are able to push `payout` to recipients.

- `distribute` - function for pool manager to distribute each recipient's full `payout` amount to their payout wallet
    - This method should only be callable once
