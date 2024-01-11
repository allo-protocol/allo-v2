// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// External Libraries
import "forge-std/Test.sol";
import {IHats} from "hats-protocol/Interfaces/IHats.sol";

contract HatsSetupLive is Test {
    struct HatWearer {
        address wearer;
        uint256 id;
    }

    IHats internal _hats_;
    address internal _eligibility = makeAddr("eligibility");
    address internal _toggle = makeAddr("toggle");

    HatWearer internal _topHat;
    HatWearer internal _facilitator;

    HatWearer[3] internal _teamAccounts;
    HatWearer[3] internal _shipOperators;

    function __HatsSetupLive() internal {
        _hats_ = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);
        _createHats();
    }

    function hats() public view returns (IHats) {
        return _hats_;
    }

    function topHat() public view returns (HatWearer memory) {
        return _topHat;
    }

    function facilitator() public view returns (HatWearer memory) {
        return _facilitator;
    }

    function team(uint32 _index) public view returns (HatWearer memory) {
        return _teamAccounts[_index];
    }

    function shipOperator(uint32 _index) public view returns (HatWearer memory) {
        return _shipOperators[_index];
    }

    function _createHats() internal {
        _topHat.wearer = makeAddr("topHatWearer");
        _topHat.id = hats().mintTopHat(topHat().wearer, "Top Hat", "https://wwww/tophat.com/");

        vm.startPrank(topHat().wearer);
        //Todo: make this a pool admin once tests are back up and running
        _facilitator.wearer = makeAddr("gameFacilitator");
        _facilitator.id = hats().createHat(topHat().id, "Facilitator Hat", 2, _eligibility, _toggle, true, "");
        hats().mintHat(facilitator().id, facilitator().wearer);
        vm.stopPrank();

        for (uint32 i = 0; i < 3;) {
            vm.startPrank(topHat().wearer);

            HatWearer storage currentShip = _teamAccounts[i];

            currentShip.wearer = makeAddr(string.concat("Ship ", vm.toString(i + 1)));
            currentShip.id = hats().createHat(
                topHat().id, string.concat("Ship Hat ", vm.toString(i + 1)), 1, _eligibility, _toggle, true, ""
            );

            hats().mintHat(team(i).id, team(i).wearer);

            vm.stopPrank();

            vm.startPrank(team(i).wearer);

            HatWearer storage currentShipOperator = _shipOperators[i];

            currentShipOperator.wearer = makeAddr(string.concat("Ship Operator ", vm.toString(i + 1)));
            currentShipOperator.id = hats().createHat(
                team(i).id, string.concat("Ship Hat ", vm.toString(i + 1)), 1, _eligibility, _toggle, true, ""
            );

            hats().mintHat(shipOperator(i).id, shipOperator(i).wearer);

            vm.stopPrank();

            unchecked {
                ++i;
            }
        }
    }
}
