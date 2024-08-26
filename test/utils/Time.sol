// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/StdCheats.sol";

contract Time is StdCheats {
    uint256 private _oneDayInSeconds = 86400;
    uint256 private _oneWeekInSeconds = _oneDayInSeconds * 7;
    uint256 private _today = block.timestamp;
    uint256 private _nextWeek = _today + _oneWeekInSeconds;
    uint256 private _tomorrow = _today + _oneDayInSeconds;
    uint256 private _weekAfterNext = _today + 2 * _oneWeekInSeconds;

    function oneDayInSeconds() public view returns (uint256) {
        return _oneDayInSeconds;
    }

    function today() public view returns (uint256) {
        return _today;
    }

    function yesterday() public view returns (uint256) {
        return _today - _oneDayInSeconds;
    }

    function tomorrow() public view returns (uint256) {
        return _today + _oneDayInSeconds;
    }

    function lastWeek() public view returns (uint256) {
        return _today - _oneWeekInSeconds;
    }

    function nextWeek() public view returns (uint256) {
        return _today + _oneWeekInSeconds;
    }

    function weekAfterNext() public view returns (uint256) {
        return _today + (2 * _oneWeekInSeconds);
    }

    function oneMonthFromNow() public view returns (uint256) {
        return _today + (4 * _oneWeekInSeconds);
    }
}
