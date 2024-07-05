/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// import forge-std/Test.sol
import "forge-std/Test.sol";
/// import Mock Contract
import "test/utils/MockQFHelper.sol";
import "contracts/core/libraries/QFHelper.sol";

contract MockQFHelperTest is Test {
    MockQFHelper public mockQFHelper;

    address public funder = makeAddr("funder");
    address public recipient1 = makeAddr("recipient1");
    address public recipient2 = makeAddr("recipient2");
    uint256 public constant DONATION_1 = 100;
    uint256 public constant DONATION_2 = 200;
    uint256 public constant MATCHING_AMOUNT = 1000;

    function setUp() public {
        mockQFHelper = new MockQFHelper();
    }

    /// @notice Test the fundRecipients function, happy path
    function test_fundRecipients() public {
        uint256[] memory _donations = new uint256[](2);
        _donations[0] = DONATION_1;
        _donations[1] = DONATION_2;

        address[] memory _recipients = new address[](2);
        _recipients[0] = recipient1;
        _recipients[1] = recipient2;

        vm.prank(funder);
        mockQFHelper.fundRecipients(_recipients, _donations);

        QFHelper.Donation[] memory donations1 = mockQFHelper.getDonations(_recipients[0]);
        QFHelper.Donation[] memory donations2 = mockQFHelper.getDonations(_recipients[1]);

        assertEq(donations1.length, 1);
        assertEq(donations1[0].amount, DONATION_1);
        assertEq(donations1[0].funder, funder);

        assertEq(donations2.length, 1);
        assertEq(donations2[0].amount, DONATION_2);
        assertEq(donations2[0].funder, funder);
    }

    /// @notice Test the fundRecipients function revert when the length of recipients and amounts are not equal, unhappy path
    function testRevert_fundRecipients_LengthMissmatch() public {
        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = 100;

        address[] memory _recipients = new address[](2);
        _recipients[0] = recipient1;
        _recipients[1] = recipient2;

        vm.expectRevert(QFHelper.QFHelper_LengthMissmatch.selector);
        mockQFHelper.fundRecipients(_recipients, _amounts);
    }

    /// @notice Test the calculateMatching function using the QF formula, happy path
    function test_calculateMatching() public {
        address[] memory _recipient1 = new address[](1);
        _recipient1[0] = recipient1;

        address[] memory _recipient2 = new address[](1);
        _recipient2[0] = recipient2;

        uint256[] memory _donation1 = new uint256[](1);
        _donation1[0] = 1;

        uint256[] memory _donation2 = new uint256[](1);
        _donation2[0] = 100;

        /// Custom donation amounts
        for(uint256 i = 0; i < 5; i++) {
            /// Donate 5 times to recipient 1, 1 amount
            mockQFHelper.fundRecipients(_recipient1, _donation1);
        }
        /// Donate 1 time to recipient 2, 100 amount
        mockQFHelper.fundRecipients(_recipient2, _donation2);

        (, uint256[] memory _payouts) = mockQFHelper.getCalcuateMatchingAmount(MATCHING_AMOUNT);

        /// Based on this example https://qf.gitcoin.co/?grant=1,1,1,1,1&grant=100&grant=&grant=&match=1000
        /// the payout should be 200 for recipient 1 and 800 for recipient 2
        assertEq(_payouts.length, 2);
        assertEq(_payouts[0], 200);
        assertEq(_payouts[1], 800);
    }
}
