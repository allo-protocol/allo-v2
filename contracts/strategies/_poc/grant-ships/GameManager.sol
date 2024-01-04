// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {GrantShipStrategy} from "./GrantShipStrategy.sol";
import {BaseStrategy} from "../../BaseStrategy.sol";

contract GameManager is BaseStrategy {
    /// ================================
    /// ========== Models ==============
    /// ================================

    /// ===============================
    /// ======== Game State ===========
    /// ===============================

    uint256 public currentRoundId;
    uint256 public currentRoundStartTime;
    uint256 public currentRoundEndTime;
    address token;

    mapping(uint256 => GrantShipStrategy) public grantShips;

    uint256 gameFacilitatorHatId;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ======== Initialize ===========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) external {
        __BaseStrategy_init(_poolId);

        (bytes _gameParams, bytes[] _startingShips) = abi.decode(_data, (bytes, bytes[]));

        __GameState_init(_gameParams);
    }

    function __GameState_init() internal {
        // TODO: refactor if only 2 setup params
        (uint256 _gameFacilitatorId, address _token) = abi.decode(_gameData, (uint256, address));

        gameFacilitatorHatId = _gameFacilitatorId;
        token = _token;

        unchecked {
            currentRoundId++;
        }
    }

    /// @notice This contract should be able to receive native token
    receive() external payable {}
}
