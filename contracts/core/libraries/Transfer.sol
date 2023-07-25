// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// External Libraries
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
// Internal Libraries
import "./Native.sol";

contract Transfer is Native {
    error AMOUNT_MISMATCH();

    struct TransferData {
        address from;
        address to;
        uint256 amount;
    }

    /// @notice Transfer an amount of a token to an array of addresses
    /// @param _token The address of the token
    /// @param _transferData TransferData[]
    function _transferAmountsFrom(address _token, TransferData[] memory _transferData) internal returns (bool) {
        uint256 msgValue = msg.value;

        for (uint256 i = 0; i < _transferData.length;) {
            TransferData memory transferData = _transferData[i];

            if (_token == NATIVE) {
                msgValue -= transferData.amount;
                SafeTransferLib.safeTransferETH(transferData.to, transferData.amount);
            } else {
                SafeTransferLib.safeTransferFrom(_token, transferData.from, transferData.to, transferData.amount);
            }

            unchecked {
                i++;
            }
        }

        if (msgValue != 0) {
            revert AMOUNT_MISMATCH();
        }

        return true;
    }

    /// @notice Transfer an amount of a token to an address
    /// @param _token The address of the token
    /// @param _transferData Individual TransferData
    function _transferAmountFrom(address _token, TransferData memory _transferData) internal returns (bool) {
        uint256 amount = _transferData.amount;
        if (_token == NATIVE) {
            // Native Token
            if (msg.value < amount) {
                revert AMOUNT_MISMATCH();
            }
            SafeTransferLib.safeTransferETH(_transferData.to, amount);
        } else {
            SafeTransferLib.safeTransferFrom(_token, _transferData.from, _transferData.to, amount);
        }
        return true;
    }

    function _transferAmount(address _token, address _to, uint256 _amount) internal {
        if (_token == NATIVE) {
            SafeTransferLib.safeTransferETH(_to, _amount);
        } else {
            SafeTransferLib.safeTransfer(_token, _to, _amount);
        }
    }
}
