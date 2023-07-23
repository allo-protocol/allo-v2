// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAllo} from "../../core/IAllo.sol";
import {IRegistry} from "../../core/IRegistry.sol";
import {DirectGrantsSimpleStrategy} from "../../strategies/direct-grants-simple/DirectGrantsSimpleStrategy.sol";
import {Metadata} from "../../core/libraries/Metadata.sol";

contract DirectGrantsSafeStrategy is DirectGrantsSimpleStrategy {
    /// ================================
    /// ========== Storage =============
    /// ================================

    address public vault;

    /// ======================
    /// ======= Events =======
    /// ======================

    event VaultAddressUpdated(address vaultAddress);

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) DirectGrantsSimpleStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    function initialize(uint256 _poolId, bytes memory _data) public override {
        // todo:

        __DirectGrantsSafeStrategy_init(_poolId, _data);
    }

    function __DirectGrantsSafeStrategy_init(uint256 _poolId, bytes memory _data) internal {
        (bool registryGating, bool metadataRequired, bool grantAmountRequired) = abi.decode(_data, (bool, bool, bool));

        __DirectGrantsSimpleStrategy_init(_poolId, registryGating, metadataRequired, grantAmountRequired);
    }

    /// ===============================
    /// ====== Internal Functions======
    /// ===============================

    function _payWithSafe(PayoutSummary calldata _payment) internal {
        // address vault = _payment.vault != address(0) ? _payment.vault : vaultAddress;

        // IAllowanceModule allowanceModule = IAllowanceModule(_payment.allowanceModule);
        // allowanceModule.executeAllowanceTransfer(
        //     vault,
        //     _payment.token,
        //     payable(address(this)),
        //     uint96(_payment.amount + _fees.protocolFeeAmount + _fees.roundFeeAmount),
        //     address(0),
        //     0,
        //     msg.sender,
        //     _payment.allowanceSignature // allowanceSignature should contain _payment.amount + protocolFeeAmount + roundFeeAmount as the amount
        // );

        // _transferAmount(_payment.token, payable(_payment.grantAddress), _payment.amount);
        // if (_fees.protocolFeeAmount > 0 && _fees.protocolTreasury != address(0)) {
        //     _transferAmount(_payment.token, payable(_fees.protocolTreasury), _fees.protocolFeeAmount);
        // }
        // if (_fees.roundFeeAmount > 0 && _fees.roundFeeAddress != address(0)) {
        //     _transferAmount(_payment.token, payable(_fees.roundFeeAddress), _fees.roundFeeAmount);
    }

    function _payWithWallet(PayoutSummary calldata _payoutSummary) internal {
        // if (_payment.token == address(0)) revert DirectStrategy__payout_NativeTokenNotAllowed();

        // address vault = _payment.vault != address(0) ? _payment.vault : vaultAddress;

        // /// @dev erc20 transfer to grant address
        // // slither-disable-next-line arbitrary-send-erc20,reentrancy-events,
        // IERC20Upgradeable(_payment.token).safeTransferFrom(vault, _payment.grantAddress, _payment.amount);

        // if (_fees.protocolFeeAmount > 0 && _fees.protocolTreasury != address(0)) {
        //     IERC20Upgradeable(_payment.token).safeTransferFrom(vault, _fees.protocolTreasury, _fees.protocolFeeAmount);
        // }

        // // deduct round fee
        // if (_fees.roundFeeAmount > 0 && _fees.roundFeeAddress != address(0)) {
        //     IERC20Upgradeable(_payment.token).safeTransferFrom(vault, _fees.roundFeeAddress, _fees.roundFeeAmount);
        // }
    }
}
