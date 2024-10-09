// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, Vm} from "forge-std/Test.sol";
import {IStdCheats} from "./IStdCheats.sol";

// override forge-std:
// - vm, avoiding unsupported cheatcode
// - assertEq, allowing custom message in Medusa
// - assertTrue, allowing custom message in Medusa
// - makeAddr, bypassing the limitation of non-existing label cheatcode
// etc
contract Utils {
    IStdCheats internal vm =
        IStdCheats(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));

    event TestFailure(string reason);
    event AddressMade(string label, address addressGenerated);

    function makeAddr(string memory label) internal returns (address) {
        address genAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(label))))
        );
        emit AddressMade(label, genAddress);
        return genAddress;
    }

    function assertEq(uint256 a, uint256 b) internal {
        assertEq(a, b, "assertEq: a != b");
    }

    function assertEq(uint256 a, uint256 b, string memory reason) internal {
        if (a != b) {
            emit TestFailure(reason);
            assert(false);
        }
    }

    function assertEq(address a, address b) internal {
        assertEq(a, b, "assertEq: a != b");
    }

    function assertEq(address a, address b, string memory reason) internal {
        if (a != b) {
            emit TestFailure(reason);
            assert(false);
        }
    }

    function assertTrue(bool a) internal {
        assertTrue(a, "assertTrue: !a");
    }

    function assertTrue(bool a, string memory reason) internal {
        if (!a) {
            emit TestFailure(reason);
            assert(false);
        }
    }
}

// when debugging using forge, comment the previous utils/uncomment this one for extra-comfort
// contract Utils is Test {
// }
