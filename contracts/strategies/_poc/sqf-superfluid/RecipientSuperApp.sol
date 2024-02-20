// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    SuperAppDefinitions
} from
    "../../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperTokenV1Library} from
    "../../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {IInstantDistributionAgreementV1} from
    "../../../../lib/superfluid-protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";

import {SQFSuperFluidStrategy} from "./SQFSuperFluidStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RecipientSuperApp is ISuperApp {
    error UNAUTHORIZED();

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

    address public recipient;
    SQFSuperFluidStrategy public immutable strategy;
    ISuperToken public immutable acceptedToken;

    modifier onlyRecipient() {
        _checkOnlyRecipient();
        _;
    }

    constructor(address _recipient, address _strategy, address _host, ISuperToken _acceptedToken) {
        HOST = ISuperfluid(_host);

        if (address(_strategy) == address(0)) {
            revert ZERO_ADDRESS();
        }
        strategy = SQFSuperFluidStrategy(_strategy);
        acceptedToken = _acceptedToken;
        recipient = _recipient;
    }

    /// @notice Withdraw ERC20 funds in an emergency
    function emergencyWithdraw(address token) external onlyRecipient {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /// @notice Close incoming streams in an emergency
    function closeIncomingStream(address from) external onlyRecipient {
        acceptedToken.deleteFlow(from, address(this));
    }

    /// @dev Accepts all super tokens
    function isAcceptedSuperToken(ISuperToken _superToken) public view virtual returns (bool) {
        return address(_superToken) == address(acceptedToken);
    }

    /// @notice This is the main callback function called by the host
    ///      to notify the app about the callback context.
    function onFlowCreated(int96 previousFlowRate, int96 newFlowRate, address sender, bytes calldata ctx)
        internal
        returns (bytes memory newCtx)
    {
        if (!strategy.isValidAllocator(sender)) revert UNAUTHORIZED();
        newCtx = onFlowUpdated(previousFlowRate, newFlowRate, ctx);
    }

    /// @notice This is the main callback function called by the host
    ///      to notify the app about the callback context.
    function onFlowUpdated(int96 previousFlowRate, int96 newFlowRate, bytes calldata ctx)
        internal
        returns (bytes memory newCtx)
    {
        strategy.adjustWeightings(uint256(int256(previousFlowRate)), uint256(int256(newFlowRate)));
        newCtx = _updateOutflow(ctx);
    }

    function _checkHookParam(ISuperToken _superToken) internal view {
        if (msg.sender != address(HOST)) revert UnauthorizedHost();
        if (!isAcceptedSuperToken(_superToken)) revert NotAcceptedSuperToken();
    }

    function _checkOnlyRecipient() internal view virtual {
        if (msg.sender != recipient) {
            revert UNAUTHORIZED();
        }
    }

    // https://Ihub.com/superfluid-finance/super-examples/blob/main/projects/tradeable-cashflow/contracts/RedirectAll.sol#L163
    function _updateOutflow(bytes memory ctx) private returns (bytes memory newCtx) {
        newCtx = ctx;

        int96 netFlowRate = acceptedToken.getNetFlowRate(address(this));

        int96 outFlowRate = acceptedToken.getFlowRate(address(this), recipient);

        int96 inFlowRate = netFlowRate + outFlowRate;

        if (inFlowRate == 0) {
            // The flow does exist and should be deleted.
            newCtx = acceptedToken.deleteFlowWithCtx(address(this), recipient, ctx);
        } else if (outFlowRate != 0) {
            // The flow does exist and needs to be updated.
            newCtx = acceptedToken.updateFlowWithCtx(recipient, inFlowRate, ctx);
        } else {
            // The flow does not exist but should be created.
            newCtx = acceptedToken.createFlowWithCtx(recipient, inFlowRate, ctx);
        }
    }

    function _createCbData(bytes calldata _agreementData) internal view returns (bytes memory) {
        (address sender,) = abi.decode(_agreementData, (address, address));
        (uint256 lastUpdated, int96 flowRate,,) = acceptedToken.getFlowInfo(sender, address(this));

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

    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32, /*agreementId*/
        bytes calldata agreementData,
        bytes calldata /*ctx*/
    ) external view override returns (bytes memory /*beforeData*/ ) {
        _checkHookParam(superToken);
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

    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32, /*agreementId*/
        bytes calldata agreementData,
        bytes calldata /*ctx*/
    ) external view override returns (bytes memory /*beforeData*/ ) {
        if (msg.sender != address(HOST) || !isAcceptedAgreement(agreementClass) || !isAcceptedSuperToken(superToken)) {
            return "0x";
        }

        return _createCbData(agreementData);
    }

    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32, /*agreementId*/
        bytes calldata, /*agreementData*/
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

    /**
     * @dev Expect Super Agreement involved in callback to be an accepted one
     *      This function can be overridden with custom logic and to revert if desired
     *      Current implementation expects ConstantFlowAgreement
     */
    function isAcceptedAgreement(address agreementClass) internal view virtual returns (bool) {
        return agreementClass == address(HOST.getAgreementClass(CFAV1_TYPE));
    }
}
