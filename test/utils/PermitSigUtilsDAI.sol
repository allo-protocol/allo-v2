// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {VmSafe} from "forge-std/Vm.sol";

contract PermitSigUtilsDAI {
    struct Permit {
        address holder;
        address spender;
        uint256 nonce;
        uint256 expiry;
        bool allowed;
    }

    VmSafe public vm;

    bytes32 internal DOMAIN_SEPARATOR;

    constructor(VmSafe _vm, bytes32 _DOMAIN_SEPARATOR) {
        vm = _vm;
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    // computes the hash of a permit
    function getStructHash(Permit memory _permit) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(PERMIT_TYPEHASH, _permit.holder, _permit.spender, _permit.nonce, _permit.expiry, _permit.allowed)
        );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Permit memory _permit) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(_permit)));
    }

    function sign(Permit memory permit, uint256 privateKey) public view returns (bytes memory) {
        bytes32 digest = getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return bytes.concat(r, s, bytes1(v));
    }
}
