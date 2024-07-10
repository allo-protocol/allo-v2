// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import { Allo } from "../../contracts/core/Allo.sol";

contract MockAllo is Allo {
    function mockMsgSender() external view returns (address) {
        return _msgSender();
    }

    function mockMsgData() external view returns (bytes calldata) {
        return _msgData();
    }
}