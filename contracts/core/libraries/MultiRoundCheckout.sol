// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";

import "../libraries/Errors.sol";
import "../interfaces/IVotable.sol";
import "../interfaces/IDAIPermit.sol";

contract MultiRoundCheckout is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, Errors {
    // todo: this exists twice in the codebase - line 95 of DonationVotingMerkleDistributionBaseStrategy
    // if we inherhit this contract into the strategy contract we can remove the one in the strategy contract.
    struct Permit2Data {
        ISignatureTransfer.PermitTransferFrom permit;
        bytes signature;
    }

    enum PermitType {
        None,
        Permit,
        PermitDAI,
        Permit2
    }

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * vote: votes for multiple rounds at once with ETH.
     * votes is a 2d array. first index is the index of the round address in the second param.
     */
    function vote(bytes[][] memory votes, address[] memory rounds, uint256[] memory amounts)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        if (votes.length != rounds.length) {
            revert MISMATCH();
        }

        if (amounts.length != rounds.length) {
            revert MISMATCH();
        }

        // possible previous balance + msg.value
        uint256 initialBalance = address(this).balance;

        for (uint256 i = 0; i < rounds.length;) {
            IVotable round = IVotable(payable(rounds[i]));
            round.vote{value: amounts[i]}(votes[i]);

            unchecked {
                ++i;
            }
        }

        if (address(this).balance != initialBalance - msg.value) {
            revert EXCESS_AMOUNT_SENT();
        }
    }

    /**
     * voteERC20Permit: votes for multiple rounds at once with ERC20Permit tokens.
     */
    function voteERC20Permit(
        bytes[][] memory votes,
        address[] memory rounds,
        uint256[] memory amounts,
        uint256 totalAmount,
        address token,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant whenNotPaused {
        if (votes.length != rounds.length) {
            revert MISMATCH();
        }

        if (amounts.length != rounds.length) {
            revert MISMATCH();
        }

        uint256 initialBalance = IERC20Upgradeable(token).balanceOf(address(this));

        try IERC20PermitUpgradeable(token).permit(msg.sender, address(this), totalAmount, deadline, v, r, s) {}
        catch Error(string memory reason) {
            if (IERC20Upgradeable(token).allowance(msg.sender, address(this)) < totalAmount) {
                revert(reason);
            }
        } catch (bytes memory reason) {
            if (IERC20Upgradeable(token).allowance(msg.sender, address(this)) < totalAmount) {
                revert(string(reason));
            }
        }

        IERC20Upgradeable(token).transferFrom(msg.sender, address(this), totalAmount);

        for (uint256 i = 0; i < rounds.length;) {
            IVotable round = IVotable(rounds[i]);
            IERC20Upgradeable(token).approve(address(round.votingStrategy()), amounts[i]);
            round.vote(votes[i]);

            unchecked {
                ++i;
            }
        }

        if (IERC20Upgradeable(token).balanceOf(address(this)) != initialBalance) {
            revert EXCESS_AMOUNT_SENT();
        }
    }

    /**
     * voteDAIPermit: votes for multiple rounds at once with DAI.
     */
    function voteDAIPermit(
        bytes[][] memory votes,
        address[] memory rounds,
        uint256[] memory amounts,
        uint256 totalAmount,
        address token,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant whenNotPaused {
        if (votes.length != rounds.length) {
            revert MISMATCH();
        }

        if (amounts.length != rounds.length) {
            revert MISMATCH();
        }

        uint256 initialBalance = IERC20Upgradeable(token).balanceOf(address(this));

        try IDAIPermit(token).permit(msg.sender, address(this), nonce, deadline, true, v, r, s) {}
        catch Error(string memory reason) {
            if (IERC20Upgradeable(token).allowance(msg.sender, address(this)) < totalAmount) {
                revert(reason);
            }
        } catch (bytes memory reason) {
            if (IERC20Upgradeable(token).allowance(msg.sender, address(this)) < totalAmount) {
                revert(string(reason));
            }
        }

        IERC20Upgradeable(token).transferFrom(msg.sender, address(this), totalAmount);

        for (uint256 i = 0; i < rounds.length;) {
            IVotable round = IVotable(rounds[i]);
            IERC20Upgradeable(token).approve(address(round.votingStrategy()), amounts[i]);
            round.vote(votes[i]);

            unchecked {
                ++i;
            }
        }

        if (IERC20Upgradeable(token).balanceOf(address(this)) != initialBalance) {
            revert EXCESS_AMOUNT_SENT();
        }
    }

    /**
     * donate function for v2 multi-round checkout
     * @param _data array of round addresses
     */
    function donateV2(bytes memory _data) public payable nonReentrant whenNotPaused {
        (address[] memory rounds, PermitType[] memory permitType, Permit2Data[] memory p2Data) =
            abi.decode(_data, (address[], PermitType[], Permit2Data[]));
        if (rounds.length != p2Data.length) {
            revert MISMATCH();
        }

        if (rounds.length != permitType.length) {
            revert MISMATCH();
        }

        for (uint256 i = 0; i < rounds.length;) {
            IVotable round = IVotable(payable(rounds[i]));
            if (permitType[i] == PermitType.Permit) {
                IERC20PermitUpgradeable(round.votingStrategy()).permit(
                    msg.sender,
                    address(this),
                    type(uint256).max,
                    type(uint256).max,
                    type(uint8).max,
                    bytes32(0),
                    bytes32(0)
                );
            } else if (permitType[i] == PermitType.PermitDAI) {
                IDAIPermit(round.votingStrategy()).permit(
                    msg.sender,
                    address(this),
                    type(uint256).max,
                    type(uint256).max,
                    true,
                    type(uint8).max,
                    bytes32(0),
                    bytes32(0)
                );
            } else if (permitType[i] == PermitType.Permit2) {
                // ISignatureTransfer.PermitTransferFrom memory permit = p2Data[i].permit;
                // bytes memory signature = p2Data[i].signature;
                // ISignatureTransfer(round.votingStrategy()).permitTransferFrom(permit, signature);
            }

            // round.allocate{value: msg.value}();

            unchecked {
                ++i;
            }
        }

        // todo: do we want return anything? `_allocate()` emits `Allocated()` event
    }
}
