// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import {IAllo} from "../../../core/interfaces/IAllo.sol";

contract GameManagerFactory {
    event TemplateCreated(string name, address templateAddress);
    event FactoryInitialized(address rootAccount);
    event RootAccountSwitched(address newRootAccount);
    event GameManagerDeployed(address gameManagerAddress);

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

    function createWithoutPool(string memory _string) external onlyRoot returns (address) {
        require(templates[_string] != address(0), "Template does not exist");
        address clone = Clones.clone(templates[_string]);

        emit GameManagerDeployed(clone);
        return clone;
    }

    function getTemplateAddress(string memory _name) external view returns (address) {
        return templates[_name];
    }
}
