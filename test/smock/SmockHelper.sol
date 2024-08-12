// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

contract SmockHelper is Test {
    function deployMock(string memory _label, bytes memory _creationCode, bytes memory _encodedArgs)
        internal
        returns (address _deployed)
    {
        bytes memory _bytecode = abi.encodePacked(_creationCode, _encodedArgs);
        assembly {
            mstore(0x0, _creationCode)
            _deployed := create2(0, add(_bytecode, 0x20), mload(_bytecode), "Wonderland")
        }
        vm.label(_deployed, _label);
        vm.allowCheatcodes(_deployed);
    }
}
