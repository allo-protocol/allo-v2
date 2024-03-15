// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IAllo} from "../core/interfaces/IAllo.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

// The BridgeAdapter contract is used to receive the allocation data from the bridging solution together with the tokens
// Preparing the data for the allocation and calling the AlloV2 contract looks like this -on the sending chain-:
// 1. Get permit signature
//  bytes memory signature = getPermitTransferSignature(permitData, voterKey, DOMAIN_SEPARATOR_TYPEHASH);
//
// 2. Encode allocate data (recipientId, p2data)
//  Permit2Data memory p2data = Permit2Data({ permit: permitData, signature: signature });
//  bytes memory strategyData = abi.encode(voter, recipient, p2data);
//
// 4. Encode data for allocate call
//  bytes memory _allocateData = abi.encode(poolId, strategyData);
//
// 5. Depending on the bridge, we need to encode data with target address
// bytes memory _preparedData = abi.encode(address(bridgeAdapter), _data);

contract BridgeAdapter is Ownable, Pausable {
    address public alloV2;

    constructor(address _allo, address _admin) {
        alloV2 = _allo;
    }

    // Bridging solutions like Li.Fi and Decent allow for direct contracts calls (compared to the Connext which add validation steps in a custom adapter)
    // @dev The bridging solution will also deposit the tokens on the balance of the BridgeAdapter contract
    function receiveAllocate(bytes memory _preparedData) external payable whenNotPaused {
        decodeAndAllocate(_preparedData);
    }

    function decodeAndAllocate(bytes memory _preparedData) internal {
        // Encoded address and bytes are provided via the bridge msg
        (, bytes memory _allocateData) = abi.decode(_preparedData, (address, bytes));

        // Decode bytes to get poolId and strategyData
        // The voter is encoded in the _allocateData, needed for emitting Allocate from the strategy
        (uint256 _poolId, bytes memory _strategyData) = abi.decode(_allocateData, (uint256, bytes));

        // TODO we could decode the permit data and set the allowance for AlloV2 to not have to use infinite approvals

        // At this point, the BridgeAdapter will be msg.sender on AlloV2 and the tokens will be on the balance of the BridgeAdapter
        IAllo(alloV2).allocate{value: msg.value}(_poolId, _allocateData);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}