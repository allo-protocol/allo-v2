// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    SuperAppDefinitions
} from "@superfluid-contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperTokenV1Library} from "@superfluid-contracts/apps/SuperTokenV1Library.sol";
import {IInstantDistributionAgreementV1} from
    "@superfluid-contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";

import {SQFSuperFluidStrategy} from "./SQFSuperFluidStrategy.sol";

contract RecipientSuperApp is ISuperApp {
    using SuperTokenV1Library for ISuperToken;

    bytes32 public constant CFAV1_TYPE = keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");

    ISuperfluid public immutable HOST;

    /// @notice Index ID. Never changes.
    uint32 public constant INDEX_ID = 0;

    error ZERO_ADDRESS();

    /// @dev Thrown when the callback caller is not the host.
    error UnauthorizedHost();

    /// @dev Thrown if a required callback wasn't implemented (overridden by the SuperApp)
    error NotImplemented();

    /// @dev Thrown when SuperTokens not accepted by the SuperApp are streamed to it
    error NotAcceptedSuperToken();

    SQFSuperFluidStrategy public immutable strategy;
    ISuperToken public immutable acceptedToken;

    constructor(
        address _strategy,
        address _host,
        ISuperToken _acceptedToken,
        bool _activateOnCreated,
        bool _activateOnUpdated,
        bool _activateOnDeleted,
        string memory _registrationKey
    ) {
        HOST = ISuperfluid(_host);

        uint256 callBackDefinitions =
            SuperAppDefinitions.APP_LEVEL_FINAL | SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP;

        if (!_activateOnCreated) {
            callBackDefinitions |= SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP;
        }

        if (!_activateOnUpdated) {
            callBackDefinitions |= SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP;
        }

        if (!_activateOnDeleted) {
            callBackDefinitions |= SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;
        }

        HOST.registerAppWithKey(callBackDefinitions, _registrationKey);

        if (address(_strategy) == address(0)) {
            revert ZERO_ADDRESS();
        }
        strategy = SQFSuperFluidStrategy(_strategy);
        acceptedToken = _acceptedToken;
    }

    /// @dev Accepts all super tokens
    function isAcceptedSuperToken(ISuperToken _superToken) public view virtual returns (bool) {
        return address(_superToken) == address(acceptedToken);
    }

    /// @notice This is the main callback function called by the host
    ///      to notify the app about the callback context.
    function onFlowUpdated(address sender, int96 previousFlowRate, int96 newFlowRate, bytes calldata ctx)
        internal
        returns (bytes memory)
    {
        strategy.adjustWeightings(previousFlowRate, newFlowRate, sender);
        return _updateOutflow(ctx);
    }

    function _checkHookParam(address _agreementClass, ISuperToken _superToken) internal view {
        if (msg.sender != address(HOST)) revert UnauthorizedHost();
        if (!isAcceptedSuperToken(_superToken)) revert NotAcceptedSuperToken();
    }

    // https://github.com/superfluid-finance/super-examples/blob/main/projects/tradeable-cashflow/contracts/RedirectAll.sol#L163
    function _updateOutflow(bytes calldata ctx) private returns (bytes memory newCtx) {
        newCtx = ctx;

        int96 netFlowRate = _acceptedToken.getNetFlowRate(address(this));

        int96 outFlowRate = _acceptedToken.getFlowRate(address(this), _receiver);

        int96 inFlowRate = netFlowRate + outFlowRate;

        if (inFlowRate == 0) {
            // The flow does exist and should be deleted.
            newCtx = _acceptedToken.deleteFlowWithCtx(address(this), _receiver, ctx);
        } else if (outFlowRate != 0) {
            // The flow does exist and needs to be updated.
            newCtx = _acceptedToken.updateFlowWithCtx(_receiver, inFlowRate, ctx);
        } else {
            // The flow does not exist but should be created.
            newCtx = _acceptedToken.createFlowWithCtx(_receiver, inFlowRate, ctx);
        }
    }

    function _createCbData(bytes calldata _agreementData) internal pure returns (bytes memory) {
        (address sender,) = abi.decode(agreementData, (address, address));
        (uint256 lastUpdated, int96 flowRate,,) = superToken.getFlowInfo(sender, address(this));

        return abi.encode(flowRate, lastUpdated);
    }

    /// ================================
    /// ===== CREATED callbacks ========
    /// ================================

    function beforeAgreementCreated(
        ISuperToken, /*superToken,*/
        address, /*agreementClass,*/
        bytes32, /*agreementId*/
        bytes calldata, /*agreementData*/
        bytes calldata /*ctx*/
    ) external pure override returns (bytes memory /*beforeData*/ ) {
        return "0x";
    }

    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32, /*agreementId*/
        bytes calldata agreementData,
        bytes calldata, /*cbdata*/
        bytes calldata ctx
    ) external override returns (bytes memory newCtx) {
        _checkHookParam(agreementClass, superToken);

        (address sender,) = abi.decode(agreementData, (address, address));
        (, int96 flowRate,,) = superToken.getFlowInfo(sender, address(this));

        return onFlowUpdated(
            sender,
            0,
            flowRate,
            ctx // userData can be acquired with `host.decodeCtx(ctx).userData`
        );
    }

    /// ================================
    /// ===== UPDATED callbacks ========
    /// ================================

    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32, /*agreementId*/
        bytes calldata agreementData,
        bytes calldata /*ctx*/
    ) external pure override returns (bytes memory /*beforeData*/ ) {
        _checkHookParam(agreementClass, superToken);
        if (!isAcceptedAgreement(agreementClass)) return "0x";

        return _createCbData(agreementData);
    }

    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32, /*agreementId*/
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    ) external override returns (bytes memory) {
        _checkHookParam(agreementClass, superToken);

        (address sender,) = abi.decode(agreementData, (address, address));
        (int96 previousFlowRate,) = abi.decode(cbdata, (int96, uint256));
        (, int96 flowRate,,) = superToken.getFlowInfo(sender, address(this));

        return onFlowUpdated(
            sender,
            previousFlowRate,
            flowRate,
            ctx // userData can be acquired with `host.decodeCtx(ctx).userData`
        );
    }

    /// =================================
    /// ==== TERMINATED callbacks =======
    /// =================================

    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32, /*agreementId*/
        bytes calldata agreementData,
        bytes calldata /*ctx*/
    ) external pure override returns (bytes memory /*beforeData*/ ) {
        if (msg.sender != address(HOST) || !isAcceptedAgreement(agreementClass) || !isAcceptedSuperToken(superToken)) {
            return "0x";
        }

        return _createCbData(agreementData);
    }

    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32, /*agreementId*/
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    ) external override returns (bytes memory) {
        if (msg.sender != address(HOST) || !isAcceptedAgreement(agreementClass) || !isAcceptedSuperToken(superToken)) {
            return ctx;
        }

        (address sender,) = abi.decode(agreementData, (address, address));
        (, int96 previousFlowRate) = abi.decode(cbdata, (uint256, int96));
        // (, int96 flowRate,,) = superToken.getFlowInfo(sender, address(this));
        return onFlowUpdated(sender, previousFlowRate, 0, ctx);
    }

    /// ================================
    /// ========== Helpers =============
    /// ================================

    /**
     * @dev Expect Super Agreement involved in callback to be an accepted one
     *      This function can be overridden with custom logic and to revert if desired
     *      Current implementation expects ConstantFlowAgreement
     */
    function isAcceptedAgreement(address agreementClass) internal view virtual returns (bool) {
        return agreementClass == address(HOST.getAgreementClass(CFAV1_TYPE));
    }
}
