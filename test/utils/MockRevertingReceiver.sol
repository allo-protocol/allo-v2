// SPDX-License_Identifier: MIT

pragma solidity ^0.8.22;

contract MockRevertingReceiver {
    receive() external payable {
        revert("MockRevertingReceiver: Revert");
    }
}
