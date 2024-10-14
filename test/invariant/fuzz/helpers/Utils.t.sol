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

    // same as forge-std
    function bound(
        uint256 x,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256 result) {
        require(
            min <= max,
            "StdUtils bound(uint256,uint256,uint256): Max is less than min."
        );

        uint256 UINT256_MAX = 2 ** 256 - 1;

        // If x is between min and max, return x directly. This is to ensure that dictionary values
        // do not get shifted if the min is nonzero. More info: https://github.com/foundry-rs/forge-std/issues/188
        if (x >= min && x <= max) return x;

        uint256 size = max - min + 1;

        // If the value is 0, 1, 2, 3, wrap that to min, min+1, min+2, min+3. Similarly for the UINT256_MAX side.
        // This helps ensure coverage of the min/max values.
        if (x <= 3 && size > x) return min + x;
        if (x >= UINT256_MAX - 3 && size > UINT256_MAX - x)
            return max - (UINT256_MAX - x);

        // Otherwise, wrap x into the range [min, max], i.e. the range is inclusive.
        if (x > max) {
            uint256 diff = x - max;
            uint256 rem = diff % size;
            if (rem == 0) return max;
            result = min + rem - 1;
        } else if (x < min) {
            uint256 diff = min - x;
            uint256 rem = diff % size;
            if (rem == 0) return min;
            result = max - rem + 1;
        }
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
