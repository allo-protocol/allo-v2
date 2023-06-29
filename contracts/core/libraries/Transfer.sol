import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Transfer {

    error TRANSFER_FAILED();

    struct Payout {
        address to;
        uint256 amount;
    }

    /// @notice Transfer an amount of a token to an address
    function transferPayouts (address _token, Payout[] memory payouts) external {
        for (uint256 i = 0; i < payouts.length; i++) {
            _transferAmount(_token, payouts[i]);
        }
    }

    /// @notice Transfer an amount of a token to an address
    /// @param _to The address to transfer to
    /// @param _payout Individual Payout
    function _transferAmount(address _token, Payout _payout) private {
        if (_token == address(0)) {
            // Native Token
            (bool sent,) = _payout.to.call{value: _payout.amount}("");
            if (!sent) {
                revert TRANSFER_FAILED();
            }
        } else {
            // ERC20 Token
            IERC20(_token).transfer(_payout.to, _payout.amount);
        }
    }
}
