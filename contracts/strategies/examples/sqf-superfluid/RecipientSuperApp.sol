// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
    ISuperfluid,
    ISuperToken,
    ISuperApp
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {SQFSuperfluid} from "contracts/strategies/examples/sqf-superfluid/SQFSuperfluid.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";

contract RecipientSuperApp is ISuperApp {
    using SuperTokenV1Library for ISuperToken;
    using Transfer for address;

    /// ======================
    /// ======= Errors =======
    /// ======================

    /// @dev Thrown when the caller is not authorized to perform the action
    error UNAUTHORIZED();

    /// @dev Thrown when the address is zero
    error ZERO_ADDRESS();

    /// @dev Thrown when the callback caller is not the host.
    error UnauthorizedHost();

    /// @dev Thrown if a required callback wasn't implemented (overridden by the SuperApp)
    error NotImplemented();

    /// @dev Thrown when SuperTokens not accepted by the SuperApp are streamed to it
    error NotAcceptedSuperToken();

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice The type of the agreement for the Constant Flow Agreement
    bytes32 public constant CFAV1_TYPE = keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");

    /// @notice The superfluid host contract
    ISuperfluid public immutable HOST;

    /// @notice The address of the recipient
    address public immutable RECIPIENT;

    /// @notice The strategy contract
    SQFSuperfluid public immutable STRATEGY;

    /// @notice The accepted super token
    ISuperToken public immutable ACCEPTED_TOKEN;

    /// ==============================
    /// ========= Modifiers ==========
    /// ==============================

    /// @dev Check that only the recipient can call the function
    modifier onlyRecipient() {
        _checkOnlyRecipient();
        _;
    }

    constructor(address _recipient, address _strategy, address _host, ISuperToken _acceptedToken) {
        if (_strategy == address(0)) {
            revert ZERO_ADDRESS();
        }

        if (_host == address(0)) {
            revert ZERO_ADDRESS();
        }

        if (address(_acceptedToken) == address(0)) {
            revert ZERO_ADDRESS();
        }

        if (_recipient == address(0)) {
            revert ZERO_ADDRESS();
        }

        HOST = ISuperfluid(_host);
        STRATEGY = SQFSuperfluid(payable(_strategy));
        ACCEPTED_TOKEN = _acceptedToken;
        RECIPIENT = _recipient;
    }

    /// @notice Withdraw ERC20 funds in an emergency
    /// @param token The token address to withdraw
    function emergencyWithdraw(address token) external onlyRecipient {
        token.transferAmount(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /// @notice Close incoming streams in an emergency
    /// @param from The address to close the stream from
    function closeIncomingStream(address from) external onlyRecipient {
        ACCEPTED_TOKEN.deleteFlow(from, address(this));
    }

    /// @dev Accepts all super tokens
    /// @param _superToken The super token to check
    /// @return TRUE if the super token is accepted, FALSE otherwise
    function isAcceptedSuperToken(ISuperToken _superToken) public view virtual returns (bool) {
        return address(_superToken) == address(ACCEPTED_TOKEN);
    }

    /// @notice This is the main callback function called by the host
    ///      to notify the app about the callback context.
    /// @param previousFlowRate The previous flow rate
    /// @param newFlowRate The new flow rate
    /// @param sender The sender of the flow
    /// @param ctx The callback context
    /// @return newCtx The new callback context
    function onFlowCreated(int96 previousFlowRate, int96 newFlowRate, address sender, bytes calldata ctx)
        internal
        returns (bytes memory newCtx)
    {
        if (!STRATEGY.isValidAllocator(sender)) revert UNAUTHORIZED();
        newCtx = onFlowUpdated(previousFlowRate, newFlowRate, ctx);
    }

    /// @notice This is the main callback function called by the host
    ///      to notify the app about the callback context.
    /// @param previousFlowRate The previous flow rate
    /// @param newFlowRate The new flow rate
    /// @param ctx The callback context
    /// @return newCtx The new callback context
    function onFlowUpdated(int96 previousFlowRate, int96 newFlowRate, bytes calldata ctx)
        internal
        returns (bytes memory newCtx)
    {
        STRATEGY.adjustWeightings(uint256(int256(previousFlowRate)), uint256(int256(newFlowRate)));
        newCtx = _updateOutflow(ctx);
    }

    /// @notice Perform sanity checks for the hooks
    /// @param _superToken The super token to check
    function _checkHookParam(ISuperToken _superToken) internal view {
        if (msg.sender != address(HOST)) revert UnauthorizedHost();
        if (!isAcceptedSuperToken(_superToken)) revert NotAcceptedSuperToken();
    }

    /// @notice Check that only the recipient can call the function
    function _checkOnlyRecipient() internal view virtual {
        if (msg.sender != RECIPIENT) {
            revert UNAUTHORIZED();
        }
    }

    /// @dev https://Ihub.com/superfluid-finance/super-examples/blob/main/projects/tradeable-cashflow/contracts/RedirectAll.sol#L163
    /// @param ctx The callback context
    /// @return newCtx The new callback context
    function _updateOutflow(bytes memory ctx) private returns (bytes memory newCtx) {
        newCtx = ctx;

        int96 netFlowRate = ACCEPTED_TOKEN.getNetFlowRate(address(this));

        int96 outFlowRate = ACCEPTED_TOKEN.getFlowRate(address(this), RECIPIENT);

        int96 inFlowRate = netFlowRate + outFlowRate;

        if (inFlowRate == 0) {
            // The flow does exist and should be deleted.
            newCtx = ACCEPTED_TOKEN.deleteFlowWithCtx(address(this), RECIPIENT, ctx);
        } else if (outFlowRate != 0) {
            // The flow does exist and needs to be updated.
            newCtx = ACCEPTED_TOKEN.updateFlowWithCtx(RECIPIENT, inFlowRate, ctx);
        } else {
            // The flow does not exist but should be created.
            newCtx = ACCEPTED_TOKEN.createFlowWithCtx(RECIPIENT, inFlowRate, ctx);
        }
    }

    /// @dev Create the callback data
    /// @param _agreementData The agreement data
    /// @return The callback data
    function _createCbData(bytes calldata _agreementData) internal view returns (bytes memory) {
        (address sender,) = abi.decode(_agreementData, (address, address));
        (uint256 lastUpdated, int96 flowRate,,) = ACCEPTED_TOKEN.getFlowInfo(sender, address(this));

        return abi.encode(flowRate, lastUpdated);
    }

    /// ================================
    /// ===== CREATED callbacks ========
    /// ================================

    /// @dev This callback is called before the flow is created
    /// @param superToken NOT USED
    /// @param agreementClass NOT USED
    /// @param agreementId NOT USED
    /// @param agreementData NOT USED
    /// @param ctx NOT USED
    /// @return beforeData NOT USED
    function beforeAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    ) external pure override returns (bytes memory beforeData) {
        return "0x";
    }

    /// @dev This callback is called after the flow is created
    /// @param superToken The super token
    /// @param agreementClass The agreement class
    /// @param agreementId NOT USED
    /// @param agreementData The agreement data
    /// @param cbdata NOT USED
    /// @param ctx The callback context
    /// @return newCtx The new callback context
    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    ) external override returns (bytes memory newCtx) {
        _checkHookParam(superToken);
        if (!isAcceptedAgreement(agreementClass)) return ctx;

        (address sender,) = abi.decode(agreementData, (address, address));
        (, int96 flowRate,,) = superToken.getFlowInfo(sender, address(this));

        return onFlowCreated(
            0,
            flowRate,
            sender,
            ctx // userData can be acquired with `host.decodeCtx(ctx).userData`
        );
    }

    /// ================================
    /// ===== UPDATED callbacks ========
    /// ================================

    /// @dev This callback is called before the flow is updated
    /// @param superToken The super token
    /// @param agreementClass The agreement class
    /// @param agreementId NOT USED
    /// @param agreementData The agreement data
    /// @param ctx NOT USED
    /// @return beforeData NOT USED
    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    ) external view override returns (bytes memory beforeData) {
        _checkHookParam(superToken);
        if (!isAcceptedAgreement(agreementClass)) return "0x";

        return _createCbData(agreementData);
    }

    /// @dev This callback is called after the flow is updated
    /// @param superToken The super token
    /// @param agreementClass The agreement class
    /// @param agreementId NOT USED
    /// @param agreementData The agreement data
    /// @param cbdata The callback data
    /// @param ctx The callback context
    /// @return The new callback context
    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    ) external override returns (bytes memory) {
        _checkHookParam(superToken);
        if (!isAcceptedAgreement(agreementClass)) return ctx;

        (address sender,) = abi.decode(agreementData, (address, address));
        (int96 previousFlowRate,) = abi.decode(cbdata, (int96, uint256));
        (, int96 flowRate,,) = superToken.getFlowInfo(sender, address(this));

        return onFlowUpdated(
            previousFlowRate,
            flowRate,
            ctx // userData can be acquired with `host.decodeCtx(ctx).userData`
        );
    }

    /// =================================
    /// ==== TERMINATED callbacks =======
    /// =================================

    /// @dev This callback is called before the flow is terminated
    /// @param superToken The super token
    /// @param agreementClass The agreement class
    /// @param agreementId NOT USED
    /// @param agreementData The agreement data
    /// @param ctx NOT USED
    /// @return beforeData NOT USED
    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    ) external view override returns (bytes memory beforeData) {
        if (msg.sender != address(HOST) || !isAcceptedAgreement(agreementClass) || !isAcceptedSuperToken(superToken)) {
            return "0x";
        }

        return _createCbData(agreementData);
    }

    /// @dev This callback is called after the flow is terminated
    /// @param superToken The super token
    /// @param agreementClass The agreement class
    /// @param agreementId NOT USED
    /// @param agreementData NOT USED
    /// @param cbdata The callback data
    /// @param ctx The callback context
    /// @return The new callback context
    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    ) external override returns (bytes memory) {
        if (msg.sender != address(HOST) || !isAcceptedAgreement(agreementClass) || !isAcceptedSuperToken(superToken)) {
            return ctx;
        }

        (int96 previousFlowRate,) = abi.decode(cbdata, (int96, uint256));
        return onFlowUpdated(previousFlowRate, 0, ctx);
    }

    /// ================================
    /// ========== Helpers =============
    /// ================================

    /// @dev Expect Super Agreement involved in callback to be an accepted one
    ///      This function can be overridden with custom logic and to revert if desired
    ///      Current implementation expects ConstantFlowAgreement
    /// @param agreementClass The agreement class
    /// @return TRUE if the agreement is accepted, FALSE otherwise
    function isAcceptedAgreement(address agreementClass) internal view virtual returns (bool) {
        return agreementClass == address(HOST.getAgreementClass(CFAV1_TYPE));
    }
}
