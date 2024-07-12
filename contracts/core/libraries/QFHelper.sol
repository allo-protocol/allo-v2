// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "solady/utils/FixedPointMathLib.sol";

/// @title QF Helper Library
/// @notice A helper library for Quadratic Funding
/// @dev Handles the donation and voting of recipients and calculates the matching amount
///      for each recipient using the Quadratic Funding formula
library QFHelper {
    /// Using EnumerableSet for EnumerableSet.AddressSet to store the recipients
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Error thrown when the number of recipients and amounts are not equal
    error QFHelper_LengthMissmatch();

    /// Struct that defines a donation
    /// @param amount The amount of the donation
    /// @param funder The address of the funder
    struct Donation {
        uint256 amount;
        address funder;
    }

    /// Struct that defines the state of the donations to recipients
    /// @param recipients The set of recipients
    /// @param sqrtDonationsSum The sum of the square root of the donations for each recipient
    /// @param donations The donations for each recipient
    /// @param totalContributions The total contributions of all recipients
    struct State {
        EnumerableSet.AddressSet recipients;
        mapping(address => uint256) sqrtDonationsSum;
        mapping(address => Donation[]) donations;
        uint256 totalContributions;
    }

    /// @notice Votes for recipients by donating
    /// @param _state The state of the donations
    /// @param _recipients The recipients to donate to
    /// @param _amounts The amounts to donate to each recipient
    /// @param _funder The address of the funder
    /// @dev The number of recipients and amounts should be equal and the same index
    ///      should correspond to the same recipient and amount
    function fund(State storage _state, address[] memory _recipients, uint256[] memory _amounts, address _funder)
        internal
    {
        uint256 _recipientsLength = _recipients.length;
        /// Check if the number of recipients and amounts are equal
        if (_recipientsLength != _amounts.length) revert QFHelper_LengthMissmatch();

        for (uint256 i = 0; i < _recipientsLength; i++) {
            /// Add the recipient to the set if it doesn't exist
            if (!_state.recipients.contains(_recipients[i])) {
                _state.recipients.add(_recipients[i]);
            }
            /// Add the donation to the recipient
            _state.donations[_recipients[i]].push(Donation({amount: _amounts[i], funder: _funder}));

            /// Calculate the square root of the donation amount and add it to the sum of donations
            uint256 _sqrtDonationsSum = _state.sqrtDonationsSum[_recipients[i]];
            _sqrtDonationsSum += FixedPointMathLib.sqrt(_amounts[i]);
            _state.sqrtDonationsSum[_recipients[i]] = _sqrtDonationsSum;
        }
    }

    /// @notice Calculates and stores the total contributions of all recipients
    /// @dev The total contributions is the sum of the square of the square root of the donations
    ///      for each recipient. This should only be called once after all donations have been made
    /// @param _state The state of the donations
    function calculateTotalContributions(State storage _state) internal {
        uint256 _totalContributions;
        for (uint256 i = 0; i < _state.recipients.length(); i++) {
            address _recipient = _state.recipients.at(i);
            uint256 _sqrtDonationsSum = _state.sqrtDonationsSum[_recipient];
            _totalContributions += _sqrtDonationsSum * _sqrtDonationsSum;
        }

        _state.totalContributions = _totalContributions;
    }

    /// @notice Calculates the matching amount for a recipient using the Quadratic Funding formula
    /// @param _state The state of the donations
    /// @param _matchingAmount The total matching amount
    /// @param _recipient The recipient to calculate the matching amount for
    /// @return _amount The matching amount for the recipient
    function calculateMatching(State storage _state, uint256 _matchingAmount, address _recipient)
        internal
        returns (uint256 _amount)
    {
        /// get the sqrt sum of donations for the recipient
        uint256 _sqrtDonationsSum = _state.sqrtDonationsSum[_recipient];
        /// square the sqrt sum of donations
        uint256 _squareDonationsSum = _sqrtDonationsSum * _sqrtDonationsSum;

        /// calculate the divisor
        uint256 _divisor = _matchingAmount / _state.totalContributions;
        /// calculate the matching amount
        _amount = _squareDonationsSum * _divisor;
    }
}
