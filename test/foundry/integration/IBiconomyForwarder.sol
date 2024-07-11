// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IBiconomyForwarder {
    struct ERC20ForwardRequest {
        address from; 
        address to; 
        address token; 
        uint256 txGas;
        uint256 tokenGasPrice;
        uint256 batchId; 
        uint256 batchNonce; 
        uint256 deadline; 
        bytes data;
    }

    function executeEIP712(
        ERC20ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes calldata sig
    ) external returns (bool success, bytes memory ret);
}