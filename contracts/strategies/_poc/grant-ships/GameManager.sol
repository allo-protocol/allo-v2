// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {GrantShipStrategy} from "./GrantShipStrategy.sol";

contract GameManager {
    uint256 public currentRoundId;
    uint256 public currentRoundStartTime;
    uint256 public currentRoundEndTime;

    GrantShipStrategy[] grantShips;

    uint256 gameFacilitatorHatId;

    constructor() {}
}
