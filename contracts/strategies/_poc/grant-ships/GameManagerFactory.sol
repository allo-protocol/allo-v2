// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import {IAllo} from "../../../core/interfaces/IAllo.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";

contract GameManagerFactory {
    event TemplateCreated(string name, address templateAddress);
    event FactoryInitialized(address rootAccount);
    event RootAccountSwitched(address newRootAccount);
    event GameManagerDeployed(address gameManagerAddress, string templateName);
    event GameManagerDeployedWithPool(
        address gameManagerAddress,
        bytes32 profileId,
        uint256 poolId,
        string templateName,
        address tokenAddress,
        bytes initData,
        Metadata poolMetadata,
        Metadata profileMetadata
    );

    address public rootAccount;
    IAllo public allo;

    mapping(string => address) public templates;

    constructor(address _rootAccount, address _alloAddress) {
        rootAccount = _rootAccount;
        allo = IAllo(_alloAddress);

        emit FactoryInitialized(_rootAccount);
    }

    modifier onlyRoot() {
        require(msg.sender == rootAccount, "Only root account can call this function");
        _;
    }

    function setTemplate(string memory _name, address _template) external onlyRoot {
        require(templates[_name] == address(0), "Template already exists");
        templates[_name] = _template;

        emit TemplateCreated(_name, _template);
    }

    function switchRootAccount(address _newRootAccount) external onlyRoot {
        rootAccount = _newRootAccount;
        emit RootAccountSwitched(_newRootAccount);
    }

    function cloneTemplate(string memory _name) public onlyRoot returns (address) {
        require(templates[_name] != address(0), "Template does not exist");
        address clone = Clones.clone(templates[_name]);

        emit GameManagerDeployed(clone, _name);
        return clone;
    }

    function cloneWithPool(
        string memory _name,
        uint256 _nonce,
        Metadata memory _profileMetadata,
        Metadata memory _poolMetadata,
        bytes memory _initData,
        address _tokenAddress
    ) external onlyRoot returns (address) {
        address deployedAddress = cloneTemplate(_name);

        bytes32 profileId =
            allo.getRegistry().createProfile(_nonce, _name, _profileMetadata, address(this), new address[](0));

        uint256 poolId = allo.createPoolWithCustomStrategy(
            profileId, deployedAddress, _initData, _tokenAddress, 0, _poolMetadata, new address[](0)
        );

        emit GameManagerDeployedWithPool(
            deployedAddress, profileId, poolId, _name, _tokenAddress, _initData, _poolMetadata, _profileMetadata
        );

        return deployedAddress;
    }

    function getTemplateAddress(string memory _name) external view returns (address) {
        return templates[_name];
    }
}
