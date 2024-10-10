
# Strategies Libraries

The `strategies/libraries` directory contains essential helper libraries that facilitate the implementation of various strategy-related logic. These libraries encapsulate complex calculations and utilities, making strategy contracts more modular and reusable.

## Available Libraries

### 1. **QVHelper.sol**

This library is designed to assist in the implementation of Quadratic Voting (QV) strategies. Quadratic voting allows participants to cast votes where the cost of each additional vote increases quadratically, giving more weight to collective decision-making.

#### Key Features:
- Supports the voting process for recipients, including tallying votes and calculating the final payouts.
- Provides functions for handling votes and voice credits for each recipient.
- Helps calculate payouts based on total votes and the pool amount.

### 2. **QFHelper.sol**

This library is a helper for Quadratic Funding (QF) strategies. It helps calculate the matching amounts for projects based on community donations, ensuring that projects with broad community support get higher funding.

#### Key Features:
- Manages donation state for recipients and tracks total contributions.
- Calculates matching amounts for each recipient using the Quadratic Funding formula.
- Supports multiple recipients and donation amounts, simplifying the funding process.

## Usage

These libraries can be imported into your strategy contracts and used to handle quadratic voting and funding logic efficiently. Here’s a small example of using the `QVHelper` library in a strategy:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../libraries/QVHelper.sol";
import "./BaseStrategy.sol";

contract QuadraticVotingStrategy is BaseStrategy {
    using QVHelper for QVHelper.VotingState;

    QVHelper.VotingState internal votingState;

    function vote(address[] memory _recipients, uint256[] memory _votes) external {
        votingState.vote(votingState, _recipients, _votes);
    }
}
```

## Libraries Overview

-   **QVHelper.sol**: Focuses on quadratic voting strategies, allowing for vote tallying and payout calculation based on total votes.
-   **QFHelper.sol**: Helps implement quadratic funding mechanisms, including donation tracking and matching fund calculations.

These libraries enable more efficient and secure development of strategies that require quadratic logic. They abstract away complex mathematical operations while offering a modular and reusable solution for various strategy types.
