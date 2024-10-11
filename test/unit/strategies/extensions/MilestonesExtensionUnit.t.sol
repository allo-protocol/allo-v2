// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockMockMilestonesExtension} from "test/smock/MockMockMilestonesExtension.sol";
import {IMilestonesExtension} from "contracts/strategies/extensions/milestones/IMilestonesExtension.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";

contract MilestonesExtensionUnit is Test {
    MockMockMilestonesExtension milestonesExtension;

    struct MilestoneWithoutEnums {
        uint256 amountPercentage;
        Metadata metadata;
        uint8 status;
    }

    function _parseMilestones(MilestoneWithoutEnums[] memory _rawMilestones)
        internal
        view
        returns (IMilestonesExtension.Milestone[] memory _milestones)
    {
        _milestones = new IMilestonesExtension.Milestone[](_rawMilestones.length);
        for (uint256 i = 0; i < _milestones.length; i++) {
            _milestones[i].amountPercentage = bound(_rawMilestones[i].amountPercentage, 1, type(uint128).max);
            _milestones[i].metadata = _rawMilestones[i].metadata;
            _milestones[i].status = IMilestonesExtension.MilestoneStatus(bound(uint256(_rawMilestones[i].status), 0, 6));
        }
    }

    function setUp() public {
        milestonesExtension = new MockMockMilestonesExtension(address(0), "MockMilestonesExtension");
    }

    function test___MilestonesExtension_initShouldCall_increaseMaxBid(uint256 _maxBid) external {
        milestonesExtension.mock_call__increaseMaxBid(_maxBid);

        // It should call _increaseMaxBid
        milestonesExtension.expectCall__increaseMaxBid(_maxBid);

        milestonesExtension.call___MilestonesExtension_init(_maxBid);
    }

    function test_IncreaseMaxBidWhenParametersAreValid(uint256 _maxBid) external {
        milestonesExtension.mock_call__increaseMaxBid(_maxBid);
        milestonesExtension.mock_call__checkOnlyPoolManager(address(this));

        // It should call _checkOnlyPoolManager
        milestonesExtension.expectCall__checkOnlyPoolManager(address(this));

        // It should call _increaseMaxBid
        milestonesExtension.expectCall__increaseMaxBid(_maxBid);

        milestonesExtension.increaseMaxBid(_maxBid);
    }

    function test_SetMilestonesWhenParametersAreValid(MilestoneWithoutEnums[] memory _rawMilestones) external {
        vm.assume(_rawMilestones.length > 0);
        IMilestonesExtension.Milestone[] memory _milestones = _parseMilestones(_rawMilestones);
        uint256 _requiredSum = 1e18;
        for (uint256 i = 0; i < _milestones.length - 1; i++) {
            _milestones[i].amountPercentage =
                bound(_milestones[i].amountPercentage, 1, _requiredSum + i - _milestones.length);
            _requiredSum -= _milestones[i].amountPercentage;
        }
        _milestones[_milestones.length - 1].amountPercentage = _requiredSum;

        milestonesExtension.mock_call__validateSetMilestones(address(this));

        // It should call _validateSetMilestones
        milestonesExtension.expectCall__validateSetMilestones(address(this));

        // It should emit event
        vm.expectEmit();
        emit IMilestonesExtension.MilestonesSet(_milestones.length);

        milestonesExtension.setMilestones(_milestones);

        // It should set the milestones
        for (uint256 i = 0; i < _milestones.length; i++) {
            assertEq(milestonesExtension.getMilestone(i).amountPercentage, _milestones[i].amountPercentage);
            assertEq(milestonesExtension.getMilestone(i).metadata.protocol, _milestones[i].metadata.protocol);
            assertEq(milestonesExtension.getMilestone(i).metadata.pointer, _milestones[i].metadata.pointer);
            assertEq(uint8(milestonesExtension.getMilestone(i).status), uint8(0));
        }
    }

    function test_SetMilestonesRevertWhen_AmountPercentageIsZero(
        MilestoneWithoutEnums[] memory _rawMilestones,
        uint256 _zeroPercentageIndex
    ) external {
        vm.assume(_rawMilestones.length > 0);
        IMilestonesExtension.Milestone[] memory _milestones = _parseMilestones(_rawMilestones);
        _zeroPercentageIndex = bound(_zeroPercentageIndex, 0, _milestones.length - 1);
        _milestones[_zeroPercentageIndex].amountPercentage = 0;
        milestonesExtension.mock_call__validateSetMilestones(address(this));

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_InvalidMilestone.selector);

        milestonesExtension.setMilestones(_milestones);
    }

    function test_SetMilestonesRevertWhen_TotalAmountPercentageIsDifferentFrom1e18(
        MilestoneWithoutEnums[] memory _rawMilestones
    ) external {
        vm.assume(_rawMilestones.length > 0);
        IMilestonesExtension.Milestone[] memory _milestones = _parseMilestones(_rawMilestones);
        uint256 _sum;
        for (uint256 i = 0; i < _milestones.length; i++) {
            _sum += _milestones[i].amountPercentage;
        }
        if (_sum == 1e18) _milestones[0].amountPercentage += 1;
        milestonesExtension.mock_call__validateSetMilestones(address(this));

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_InvalidMilestone.selector);

        milestonesExtension.setMilestones(_milestones);
    }

    function test_SubmitUpcomingMilestoneWhenParametersAreValid(address _recipientId, Metadata memory _metadata)
        external
    {
        milestonesExtension.mock_call__validateSubmitUpcomingMilestone(_recipientId, address(this));
        milestonesExtension.set__milestones(
            0, IMilestonesExtension.Milestone(0, Metadata(0, ""), IMilestonesExtension.MilestoneStatus.None)
        );

        // It should call _validateSubmitUpcomingMilestone
        milestonesExtension.expectCall__validateSubmitUpcomingMilestone(_recipientId, address(this));

        // It should emit event
        vm.expectEmit();
        emit IMilestonesExtension.MilestoneSubmitted(milestonesExtension.upcomingMilestone());

        milestonesExtension.submitUpcomingMilestone(_recipientId, _metadata);

        // It should set the milestone metadata
        assertEq(
            milestonesExtension.getMilestone(milestonesExtension.upcomingMilestone()).metadata.protocol,
            _metadata.protocol
        );
        assertEq(
            milestonesExtension.getMilestone(milestonesExtension.upcomingMilestone()).metadata.pointer,
            _metadata.pointer
        );

        // It should set the milestone status
        assertEq(
            uint256(milestonesExtension.getMilestone(milestonesExtension.upcomingMilestone()).status),
            uint256(IMilestonesExtension.MilestoneStatus.Pending)
        );
    }

    modifier whenParametersAreValid(uint8 _milestoneStatus) {
        vm.assume(_milestoneStatus < 7);
        IMilestonesExtension.MilestoneStatus milestoneStatus = IMilestonesExtension.MilestoneStatus(_milestoneStatus);
        milestonesExtension.mock_call__validateReviewMilestone(address(this), milestoneStatus);
        _;
    }

    function test_ReviewMilestoneWhenParametersAreValid(uint8 _milestoneStatus)
        external
        whenParametersAreValid(_milestoneStatus)
    {
        IMilestonesExtension.MilestoneStatus milestoneStatus = IMilestonesExtension.MilestoneStatus(_milestoneStatus);
        uint256 upcomingMilestone = milestonesExtension.upcomingMilestone();
        milestonesExtension.set__milestones(
            upcomingMilestone,
            IMilestonesExtension.Milestone(0, Metadata(0, ""), IMilestonesExtension.MilestoneStatus.None)
        );

        // It should call _validateReviewMilestone
        milestonesExtension.expectCall__validateReviewMilestone(address(this), milestoneStatus);

        // It should emit event
        vm.expectEmit();
        emit IMilestonesExtension.MilestoneStatusChanged(upcomingMilestone, milestoneStatus);

        milestonesExtension.reviewMilestone(milestoneStatus);

        // It should set the milestone status
        assertEq(uint256(milestonesExtension.getMilestone(upcomingMilestone).status), uint256(milestoneStatus));
    }

    function test_ReviewMilestoneWhenMilestoneStatusIsEqualToAccepted()
        external
        whenParametersAreValid(uint8(2)) // IMilestonesExtension.MilestoneStatus.Accepted
    {
        uint256 upcomingMilestone = milestonesExtension.upcomingMilestone();
        milestonesExtension.set__milestones(
            upcomingMilestone,
            IMilestonesExtension.Milestone(0, Metadata(0, ""), IMilestonesExtension.MilestoneStatus.None)
        );

        milestonesExtension.reviewMilestone(IMilestonesExtension.MilestoneStatus.Accepted);

        // It should increase upcomingMilestone
        assertEq(milestonesExtension.upcomingMilestone(), upcomingMilestone + 1);
    }

    function test__setProposalBidRevertWhen_ProposalBidParameterIsBiggerThanMaxBid(
        address _bidderId,
        uint256 _proposalBid
    ) external {
        vm.assume(_proposalBid > milestonesExtension.maxBid()); // maxBid is 0

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_ExceedingMaxBid.selector);

        milestonesExtension.call__setProposalBid(_bidderId, _proposalBid);
    }

    modifier whenParametersOfTheFunctionAreValid(uint256 _proposalBid) {
        milestonesExtension.set__maxBid(type(uint256).max);
        vm.assume(_proposalBid < milestonesExtension.maxBid());
        _;
    }

    function test__setProposalBidWhenParametersAreValid(address _bidderId, uint256 _proposalBid)
        external
        whenParametersOfTheFunctionAreValid(_proposalBid)
    {
        vm.assume(_proposalBid > 0);

        // It should emit event
        vm.expectEmit();
        emit IMilestonesExtension.SetBid(_bidderId, _proposalBid);

        milestonesExtension.call__setProposalBid(_bidderId, _proposalBid);

        // It should set the _proposalBid at bids mapping
        assertEq(milestonesExtension.bids(_bidderId), _proposalBid);
    }

    function test__setProposalBidWhenProposalBidIsEqualTo0(address _bidderId, uint256 _proposalBid)
        external
        whenParametersOfTheFunctionAreValid(_proposalBid)
    {
        _proposalBid = 0;

        milestonesExtension.call__setProposalBid(_bidderId, _proposalBid);

        // It should set the _proposalBid to maxBid
        assertEq(milestonesExtension.bids(_bidderId), type(uint256).max);
    }

    function test__validateSetMilestonesShouldCall_checkOnlyPoolManager() external {
        milestonesExtension.mock_call__checkOnlyPoolManager(address(this));

        // It should call _checkOnlyPoolManager
        milestonesExtension.expectCall__checkOnlyPoolManager(address(this));

        milestonesExtension.call__validateSetMilestones(address(this));
    }

    modifier whenArrayLengthIsMoreThanZero() {
        milestonesExtension.mock_call__checkOnlyPoolManager(address(this));
        milestonesExtension.set__milestones(
            0, IMilestonesExtension.Milestone(0, Metadata(0, ""), IMilestonesExtension.MilestoneStatus.None)
        );
        _;
    }

    function test__validateSetMilestonesWhenArrayLengthIsMoreThanZero() external whenArrayLengthIsMoreThanZero {
        milestonesExtension.call__validateSetMilestones(address(this));

        // It should delete milestones array
        assertEq(milestonesExtension.get__milestones().length, 0);
    }

    function test__validateSetMilestonesRevertWhen_FirstMilestoneStatusIsDifferentFromNone()
        external
        whenArrayLengthIsMoreThanZero
    {
        milestonesExtension.set__milestones(
            0, IMilestonesExtension.Milestone(0, Metadata(0, ""), IMilestonesExtension.MilestoneStatus.Pending)
        );

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_MilestonesAlreadySet.selector);

        milestonesExtension.call__validateSetMilestones(address(this));
    }

    function test__validateSubmitUpcomingMilestoneRevertWhen_RecipientIsNotAccepted(
        address _recipientId,
        address _sender
    ) external {
        milestonesExtension.mock_call__isAcceptedRecipient(_recipientId, false);

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_InvalidRecipient.selector);

        milestonesExtension.call__validateSubmitUpcomingMilestone(_recipientId, _sender);
    }

    function test__validateSubmitUpcomingMilestoneRevertWhen_SenderIsDifferentFromRecipientId(
        address _recipientId,
        address _sender
    ) external {
        vm.assume(_recipientId != _sender);
        milestonesExtension.mock_call__isAcceptedRecipient(_recipientId, true);

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_InvalidSubmitter.selector);

        milestonesExtension.call__validateSubmitUpcomingMilestone(_recipientId, _sender);
    }

    function test__validateSubmitUpcomingMilestoneRevertWhen_MilestoneStatusIsPending(address _recipientId) external {
        milestonesExtension.mock_call__isAcceptedRecipient(_recipientId, true);
        milestonesExtension.set__milestones(
            0, IMilestonesExtension.Milestone(0, Metadata(0, ""), IMilestonesExtension.MilestoneStatus.Pending)
        );

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_MilestonePending.selector);

        milestonesExtension.call__validateSubmitUpcomingMilestone(_recipientId, _recipientId);
    }

    function test__validateReviewMilestoneShouldCall_checkOnlyPoolManager() external {
        milestonesExtension.mock_call__checkOnlyPoolManager(address(this));
        milestonesExtension.set__milestones(
            0, IMilestonesExtension.Milestone(0, Metadata(0, ""), IMilestonesExtension.MilestoneStatus.Pending)
        );

        // It should call _checkOnlyPoolManager
        milestonesExtension.expectCall__checkOnlyPoolManager(address(this));

        milestonesExtension.call__validateReviewMilestone(address(this), IMilestonesExtension.MilestoneStatus.Accepted);
    }

    function test__validateReviewMilestoneRevertWhen_ProvidedMilestoneStatusIsNone() external {
        milestonesExtension.mock_call__checkOnlyPoolManager(address(this));

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_InvalidMilestoneStatus.selector);

        milestonesExtension.call__validateReviewMilestone(address(this), IMilestonesExtension.MilestoneStatus.None);
    }

    function test__validateReviewMilestoneRevertWhen_UpcomingMilestoneStatusIsDifferentFromPending() external {
        milestonesExtension.mock_call__checkOnlyPoolManager(address(this));
        milestonesExtension.set__milestones(
            0, IMilestonesExtension.Milestone(0, Metadata(0, ""), IMilestonesExtension.MilestoneStatus.None)
        );

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_MilestoneNotPending.selector);

        milestonesExtension.call__validateReviewMilestone(address(this), IMilestonesExtension.MilestoneStatus.Accepted);
    }

    function test__increaseMaxBidRevertWhen_ProvidedMaxBidIsSmallerThanMaxBid(uint256 _maxBid, uint256 _currentMaxBid)
        external
    {
        vm.assume(_maxBid < _currentMaxBid);
        milestonesExtension.set__maxBid(_currentMaxBid);

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_AmountTooLow.selector);

        milestonesExtension.call__increaseMaxBid(_maxBid);
    }

    function test__increaseMaxBidWhenParametersAreValid(uint256 _maxBid, uint256 _currentMaxBid) external {
        vm.assume(_maxBid > _currentMaxBid);
        milestonesExtension.set__maxBid(_currentMaxBid);

        // It should emit event
        vm.expectEmit();
        emit IMilestonesExtension.MaxBidIncreased(_maxBid);

        milestonesExtension.call__increaseMaxBid(_maxBid);

        // It should set the maxBid
        assertEq(milestonesExtension.maxBid(), _maxBid);
    }

    function test__getMilestonePayoutRevertWhen_RecipientIsNotAccepted(address _recipientId, uint256 _milestoneId)
        external
    {
        milestonesExtension.mock_call__isAcceptedRecipient(_recipientId, false);

        // It should revert
        vm.expectRevert(IMilestonesExtension.MilestonesExtension_InvalidRecipient.selector);

        milestonesExtension.call__getMilestonePayout(_recipientId, _milestoneId);
    }

    function test__getMilestonePayoutWhenRecipientIsAccepted(
        address _recipientId,
        uint256 _bid,
        uint256 _amountPercentage
    ) external {
        _bid = bound(_bid, 1, 1e18);
        _amountPercentage = bound(_amountPercentage, 1, 1e18);
        vm.assume(_bid < type(uint256).max / _amountPercentage);
        vm.assume(_bid * _amountPercentage >= 1e18);

        uint256 _milestoneId = 0;

        milestonesExtension.set__milestones(
            _milestoneId,
            IMilestonesExtension.Milestone(
                _amountPercentage, Metadata(0, ""), IMilestonesExtension.MilestoneStatus.None
            )
        );
        milestonesExtension.set__bid(_recipientId, _bid);
        milestonesExtension.mock_call__isAcceptedRecipient(_recipientId, true);

        uint256 payout = milestonesExtension.call__getMilestonePayout(_recipientId, _milestoneId);

        // It should return the milestone payout
        assertEq(
            payout,
            (milestonesExtension.bids(_recipientId) * milestonesExtension.getMilestone(_milestoneId).amountPercentage)
                / 1e18
        );
    }
}
