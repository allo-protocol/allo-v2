/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// import forge-std/Test.sol
import "forge-std/Test.sol";
/// import Mock Contract
import "test/utils/MockQVHelper.sol";
import "contracts/core/libraries/QVHelper.sol";

contract MockQVHelperTest is Test {
    MockQVHelper public mockQVHelper;

    address public recipient1 = makeAddr("recipient1");
    address public recipient2 = makeAddr("recipient2");
    uint256 public constant POOL_BALANCE = 100;

    function setUp() public {
        mockQVHelper = new MockQVHelper();
    }

    /// @notice Test the vote function, happy path
    function test_vote() public {
        address[] memory _recipients = new address[](2);
        _recipients[0] = recipient1;
        _recipients[1] = recipient2;

        uint256[] memory _votes = new uint256[](2);
        _votes[0] = 1;
        _votes[1] = 2;

        mockQVHelper.vote(_recipients, _votes);

        assertEq(mockQVHelper.getVotes(_recipients[0]), 1);
        assertEq(mockQVHelper.getVotes(_recipients[1]), 2);
    }

    /// @notice Test the vote function revert when the length of recipients and votes are not equal, unhappy path
    function testRevert_vote_LengthMissmatch() public {
        address[] memory _recipients = new address[](1);
        _recipients[0] = recipient1;

        uint256[] memory _votes = new uint256[](2);
        _votes[0] = 1;
        _votes[1] = 2;

        vm.expectRevert(QVHelper.QVHelper_LengthMissmatch.selector);
        mockQVHelper.vote(_recipients, _votes);
    }

    /// @notice Test the voteWithCredits function, happy path
    function test_voteWithCredits() public {
        address[] memory _recipients = new address[](2);
        _recipients[0] = recipient1;
        _recipients[1] = recipient2;

        uint256[] memory _voiceCredits = new uint256[](2);
        _voiceCredits[0] = 1;
        _voiceCredits[1] = 2;

        mockQVHelper.voteWithCredits(_recipients, _voiceCredits);

        assertEq(mockQVHelper.getVoiceCredits(_recipients[0]), 1);
        assertEq(mockQVHelper.getVoiceCredits(_recipients[1]), 2);
    }

    /// @notice Test the voteWithCredits function revert when the length of recipients and voiceCredits are not equal, unhappy path
    function testRevert_voteWithCredits_LengthMissmatch() public {
        address[] memory _recipients = new address[](1);
        _recipients[0] = recipient1;

        uint256[] memory _voiceCredits = new uint256[](2);
        _voiceCredits[0] = 1;
        _voiceCredits[1] = 2;

        vm.expectRevert(QVHelper.QVHelper_LengthMissmatch.selector);
        mockQVHelper.voteWithCredits(_recipients, _voiceCredits);
    }

    /// @notice Test the getPayoutAmount function after voting with vote
    function test_getPayoutAmount() public {
        address[] memory _recipients = new address[](2);
        _recipients[0] = recipient1;
        _recipients[1] = recipient2;

        uint256[] memory _votes = new uint256[](2);
        _votes[0] = 1;
        _votes[1] = 2;

        mockQVHelper.vote(_recipients, _votes);

        (uint256[] memory _payouts) = mockQVHelper.getPayoutAmount(_recipients, POOL_BALANCE);

        assertEq(_payouts[0], 33);
        assertEq(_payouts[1], 66);
    }

    /// @notice Test the getPayoutAmount function after voting with voteWithCredits
    function test_getPayoutAmountWithCredits() public {
        address[] memory _recipients = new address[](2);
        _recipients[0] = recipient1;
        _recipients[1] = recipient2;

        uint256[] memory _voiceCredits = new uint256[](2);
        _voiceCredits[0] = 1;
        _voiceCredits[1] = 4;

        mockQVHelper.voteWithCredits(_recipients, _voiceCredits);

        (uint256[] memory _payouts) = mockQVHelper.getPayoutAmount(_recipients, POOL_BALANCE);

        assertEq(_payouts[0], 33);
        assertEq(_payouts[1], 66);
    }
}
