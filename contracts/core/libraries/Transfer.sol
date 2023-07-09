// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract Transfer {
    using SafeERC20 for IERC20;

    error TRANSFER_FAILED();
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
            if (_token == address(0)) {
                msgValue -= transferData.amount;
                _transferNative(transferData.to, transferData.amount);
            } else {
                IERC20(_token).safeTransferFrom(transferData.from, transferData.to, transferData.amount);
            }

            unchecked {
                i++;
            }
        }

        if (msgValue != 0) {
            revert AMOUNT_MISMATCH();
        }

        // Note: if transfer fails, tx reverts. Otherwise, return true.
        return true;
    }

    /// @notice Transfer an amount of a token to an address
    /// @param _token The address of the token
    /// @param _transferData Individual TransferData
    function _transferAmountFrom(address _token, TransferData memory _transferData) internal returns (bool) {
        uint256 amount = _transferData.amount;
        if (amount == 0) {
            revert TRANSFER_FAILED();
        }
        if (_token == address(0)) {
            // Native Token
            if (msg.value < amount) {
                revert AMOUNT_MISMATCH();
            }
            return _transferNative(_transferData.to, amount);
        } else {
            // ERC20 Token
            IERC20(_token).safeTransferFrom(_transferData.from, _transferData.to, amount);

            // Note: if transfer fails, tx reverts. Otherwise, return true.
            return true;
        }
    }

    function _transferNative(address _to, uint256 _amount) internal returns (bool) {
        if (_amount == 0) {
            revert TRANSFER_FAILED();
        }

        (bool sent,) = _to.call{value: _amount}("");

        if (!sent) {
            revert TRANSFER_FAILED();
        }

        return sent;
    }

    function _transferAmount(address _token, address _to, uint256 _amount) internal {
        if (_amount == 0) {
            revert TRANSFER_FAILED();
        }
        if (_token == address(0)) {
            _transferNative(_to, _amount);
        } else {
            // ERC20 Token
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }
}
