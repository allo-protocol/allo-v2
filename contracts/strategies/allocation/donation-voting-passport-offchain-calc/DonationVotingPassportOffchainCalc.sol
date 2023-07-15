// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {BaseStrategy} from "../../BaseStrategy.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";
import {Metadata} from "../../../core/libraries/Metadata.sol";

contract DonationVotingPassportOffchainCalc is BaseStrategy, ReentrancyGuard {
    /// ===============================
    /// ========== Errors =============
    /// ===============================

    error INVALID_TOKEN();

    /// ================================
    /// ========== Storage =============
    /// ================================

    bool public usePassport;
    address public passportAddress;
    bool public useRegistry;
    address public registryAddress;

    // poolId => tokenAddress
    mapping(address => bool) public allowedTokens;

    /// ======================
    /// ======= Events =======
    /// ======================

    /// ===============================
    /// ======== Modifiers ============
    /// ===============================

    modifier isPoolAdmin() {
        if (!allo.isPoolAdmin(poolId, msg.sender)) {
            revert BaseStrategy_UNAUTHORIZED();
        }
        _;
    }

    // NOTE: the spec only mentioned the pool admin, added this in case we need both?
    modifier isPoolManager() {
        if (!allo.isPoolManager(poolId, msg.sender)) {
            revert BaseStrategy_UNAUTHORIZED();
        }
        _;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @dev _data is abi encoded (boolean usePassport, address passportAddress, boolean useRegistry, address registryAddress)
    // NOTE: anything we want to add to the _data? Added note in BaseStrategy initialize()
    function initialize(uint256 _poolId, bytes memory _data) public override {
        super.initialize(_poolId, _data);

        // initialize passport and registry as needed
        (bool _usePassport, address _passportAddress, bool _useRegistry, address _registryAddress) =
            abi.decode(_data, (bool, address, bool, address));
        if (_usePassport) {
            passportAddress = _passportAddress;
        } else if (_useRegistry) {
            registryAddress = _registryAddress;
        }
    }

    // Note: no eligibility check to vote, anyone can vote. Just the token check.
    function vote(address _token) external payable nonReentrant {
        // check if approved token
        if (!allowedTokens[_token]) {
            revert INVALID_TOKEN();
        }

        // todo
    }

    function reviewApplication(RecipientStatus status) external isPoolAdmin {
        // todo
    }

    function reviewApplications(RecipientStatus[] memory status) external isPoolAdmin {
        // todo
    }

    function getPassportScore() external view returns (uint256) {
        // todo
    }

    /// @notice function for pool admins to upload final allocation
    function uploadAllocation() external isPoolAdmin {
        // todo
    }

    function releaseDonations() external isPoolAdmin {
        // todo
    }

    function addAllowedToken(address _token) external isPoolAdmin {
        allowedTokens[_token] = true;
    }

    function removeAllowedToken(address _token) external isPoolAdmin {
        allowedTokens[_token] = false;
    }

    function getIsAllowedToken(address _token) external view returns (bool) {
        return allowedTokens[_token];
    }

    // Note: not sure if we want to allow this? Or just have it be set in initialize()?
    function setPassportAddress(address _passportAddress) external isPoolAdmin {
        passportAddress = _passportAddress;
    }

    function setRegistryAddress(address _registryAddress) external isPoolAdmin {
        registryAddress = _registryAddress;
    }

    /// ====================================
    /// ======= Strategy Functions =========
    /// ====================================

    function registerRecipients(bytes memory _data, address _sender) external payable onlyAllo returns (address) {}

    function getRecipientStatus(address _recipientId) public view override returns (RecipientStatus) {}

    function isValidAllocator(address _allocator) public view returns (bool) {}

    function allocate(bytes memory _data, address _sender) external payable onlyAllo nonReentrant {}

    function getPayouts(address[] memory _recipientIds, bytes memory, address)
        external
        view
        returns (uint256[] memory payouts)
    {}

    /// @notice function for pool admin to distribute pool funds to recipients, as indicated by the allocation added with uploadAllocation()
    function distribute(address[] memory, bytes memory, address _sender) external onlyAllo nonReentrant {}

    /// ====================================
    /// ======= Internal Functions =========
    /// ====================================
}
