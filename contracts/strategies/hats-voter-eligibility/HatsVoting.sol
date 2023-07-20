// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IAllo} from "../../core/IAllo.sol";
import {BaseStrategy} from "../BaseStrategy.sol";
import {ERC721} from "@solady/tokens/ERC721.sol";

contract HatsStrategy is BaseStrategy {
    // constant for Hats contract address
    address constant HATS = 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137;

    // store the hat ID
    uint256 public hatId;

    function initialize(uint256 _poolId, bytes memory _data) external
    override {
        // pull hat ID from _data
    };

    function allocate(bytes memory _data, address _sender) external payable
    override onlyAllo {
        // Check _sender holds a hat

    }
}
