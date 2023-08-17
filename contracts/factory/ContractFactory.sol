// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CREATE3} from "solady/src/utils/CREATE3.sol";

contract ContractFactory {
    error SALT_USED();
    error UNAUTHORIZED();

    mapping(bytes32 => bool) public usedSalts;
    mapping(address => bool) public isDeployer;

    event Deployed(address indexed deployed, bytes32 indexed salt);

    constructor() {
        isDeployer[msg.sender] = true;
    }

    modifier onlyDeployer() {
        if (!isDeployer[msg.sender]) {
            revert UNAUTHORIZED();
        }
        _;
    }

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

    function setDeployer(address _deployer, bool _allowedToDeploy) external onlyDeployer {
        isDeployer[_deployer] = _allowedToDeploy;
    }
}
