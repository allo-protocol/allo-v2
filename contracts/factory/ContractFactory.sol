// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// External
import {CREATE3} from "solady/src/utils/CREATE3.sol";

/// @title ContractFactory Contract
/// @author allo-team
/// @dev ContractFactory is used internally to deploy our contracts using CREATE3
contract ContractFactory {
    /// ======================
    /// ======= Errors =======
    /// ======================

    /// Error when the requested salt has already been used
    error SALT_USED();

    /// Error when the caller is not authorized to deploy
    error UNAUTHORIZED();

    /// ======================
    /// ======= Events =======
    /// ======================

    /// @dev Emitted when a contract is deployed
    event Deployed(address indexed deployed, bytes32 indexed salt);

    /// ======================
    /// ======= Storage ======
    /// ======================

    /// @dev Collection of used salts
    mapping(bytes32 => bool) public usedSalts;

    /// @dev Collection of authorized deployers
    mapping(address => bool) public isDeployer;

    /// ======================
    /// ======= Modifiers ====
    /// ======================

    /// @dev Modifier to ensure the caller is authorized to deploy and returns if not
    modifier onlyDeployer() {
        if (!isDeployer[msg.sender]) {
            revert UNAUTHORIZED();
        }
        _;
    }

    /// ======================
    /// ===== Constructor ====
    /// ======================

    /// @dev On deployment sets the 'msg.sender' to allowed deployer
    constructor() {
        isDeployer[msg.sender] = true;
    }

    /// ======================
    /// ====== Functions =====
    /// ======================

    /// @notice Deploys a contract using CREATE3
    /// @dev Used for our deployments
    /// @param _contractName Name of the contract to deploy
    /// @param _version Version of the contract to deploy
    /// @param creationCode Creation code of the contract to deploy
    ///
    /// @return deployedContract Address of the deployed contract
    function deploy(string memory _contractName, string memory _version, bytes memory creationCode)
        external
        payable
        onlyDeployer
        returns (address deployedContract)
    {
        // hash salt with the contract name and version
        bytes32 salt = keccak256(abi.encodePacked(_contractName, _version));

        // ensure salt has not been used
        if (usedSalts[salt]) {
            revert SALT_USED();
        }

        usedSalts[salt] = true;

        deployedContract = CREATE3.deploy(salt, creationCode, msg.value);

        emit Deployed(deployedContract, salt);
    }

    /// @notice Set the allowed deployer
    /// @dev Sets the '_deployer' to '_allowedToDeploy'
    ///
    /// Requirements: 'msg.sender' must be a deployer
    ///
    /// @param _deployer Address of the deployer to set
    /// @param _allowedToDeploy Boolean to set the deployer to
    function setDeployer(address _deployer, bool _allowedToDeploy) external onlyDeployer {
        // Set the deployer to the allowedToDeploy mapping
        isDeployer[_deployer] = _allowedToDeploy;
    }
}
