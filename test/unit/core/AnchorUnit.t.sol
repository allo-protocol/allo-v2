// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {Anchor} from "contracts/core/Anchor.sol";
import {Registry} from "contracts/core/Registry.sol";
import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";

contract AnchorUnit is Test {
    function test_ConstructorShouldSetRegistry(bytes32 _profileId, address _registry) external {
        // it should set registry
        Anchor anchor = new Anchor(_profileId, _registry);
        assertEq(address(anchor.registry()), _registry);
    }

    function test_ConstructorShouldSetProfileId(bytes32 _profileId, address _registry) external {
        // it should set profileId
        Anchor anchor = new Anchor(_profileId, _registry);
        assertEq(anchor.profileId(), _profileId);
    }

    function test_ExecuteRevertWhen_CallerIsNotTheProfileIdOwner(address _target, uint256 _value, bytes memory _data)
        external
    {
        // it should revert
        (Anchor _anchor, address _registry, bytes32 _profileId) = _initAnchor();

        address notOwner = makeAddr("notOwner");

        vm.mockCall(
            _registry,
            abi.encodeWithSelector(Registry.isOwnerOfProfile.selector, _profileId, notOwner),
            abi.encode(false)
        );

        vm.prank(notOwner);

        vm.expectRevert(Anchor.UNAUTHORIZED.selector); // Expect a revert with the UNAUTHORIZED error

        _anchor.execute(_target, _value, _data);
    }

    function test_ExecuteRevertWhen_targetIsTheZeroAddress(uint256 _value, bytes memory _data) external {
        // it should revert
        (Anchor _anchor, address _registry, bytes32 _profileId) = _initAnchor();

        address profileOwner = makeAddr("profileOwner");

        vm.mockCall(
            _registry,
            abi.encodeWithSelector(Registry.isOwnerOfProfile.selector, _profileId, profileOwner),
            abi.encode(true)
        );

        vm.prank(profileOwner);

        vm.expectRevert(Anchor.CALL_FAILED.selector); // Expect a revert with the CALL_FAILED error

        _anchor.execute(address(0), _value, _data);
    }

    modifier whenTargetIsNotTheZeroAddress(address _target) {
        vm.assume(_target != address(0));
        _;
    }

    function test_ExecuteRevertWhen_TheCallToTargetFails(address _target, uint256 _value, bytes memory _data)
        external
        whenTargetIsNotTheZeroAddress(_target)
    {
        // it should revert
        (Anchor _anchor, address _registry, bytes32 _profileId) = _initAnchor();

        address profileOwner = makeAddr("profileOwner");

        vm.mockCall(
            _registry,
            abi.encodeWithSelector(Registry.isOwnerOfProfile.selector, _profileId, profileOwner),
            abi.encode(true)
        );
        vm.mockCallRevert(_target, _data, "");

        vm.prank(profileOwner);

        vm.expectRevert(Anchor.CALL_FAILED.selector); // Expect a revert with the CALL_FAILED error

        _anchor.execute(_target, _value, _data);
    }

    function test_ExecuteWhenTheCallToTargetSucceeds(
        address _target,
        uint256 _value,
        bytes memory _data,
        bytes memory _returnedData
    ) external whenTargetIsNotTheZeroAddress(_target) {
        vm.assume(_target != address(vm));
        assumeNotPrecompile(_target);

        // it should return the data returned by the call
        // it should call target with value and data
        (Anchor _anchor, address _registry, bytes32 _profileId) = _initAnchor();

        address profileOwner = makeAddr("profileOwner");

        vm.mockCall(
            _registry,
            abi.encodeWithSelector(Registry.isOwnerOfProfile.selector, _profileId, profileOwner),
            abi.encode(true)
        );

        vm.mockCall(_target, _value, _data, _returnedData);

        vm.prank(profileOwner);

        vm.deal(address(_anchor), _value);

        vm.expectCall(_target, _value, _data);

        bytes memory returnedData = _anchor.execute(_target, _value, _data);

        assertEq(returnedData, _returnedData);
    }

    function test_ReceiveShouldReceiveNativeTokens(uint256 _value) external {
        // it should receive native tokens
        (Anchor _anchor, address _registry, bytes32 _profileId) = _initAnchor();

        assertEq(address(_anchor).balance, 0); // Check if the balance of the contract has been updated

        hoax(makeAddr("funder"), _value);

        address(_anchor).call{value: _value}("");

        assertEq(address(_anchor).balance, _value); // Check if the balance of the contract has been updated
    }

    function test_Erc721HolderShouldReturnTheOnERC721ReceivedSelector(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external {
        // it should return the onERC721Received selector
        (Anchor _anchor, address _registry, bytes32 _profileId) = _initAnchor();

        bytes4 retval = _anchor.onERC721Received(_operator, _from, _tokenId, _data);
        assertEq(retval, IERC721Receiver.onERC721Received.selector);
    }

    function test_Erc1155HolderShouldReturnTheOnERC1155ReceivedSelector(
        address _operator,
        address _from,
        uint256 _tokenId,
        uint256 _value,
        bytes memory _data
    ) external {
        // it should return the onERC1155Received selector
        (Anchor _anchor, address _registry, bytes32 _profileId) = _initAnchor();

        bytes4 retval = _anchor.onERC1155Received(_operator, _from, _tokenId, _value, _data);
        assertEq(retval, IERC1155Receiver.onERC1155Received.selector);
    }

    function test_Erc1155HolderBatchShouldReturnTheOnERC1155BatchReceivedSelector(
        address _operator,
        address _from,
        uint256[] memory _tokenIds,
        uint256[] memory _values,
        bytes memory _data
    ) external {
        // it should return the onERC1155BatchReceived selector
        (Anchor _anchor, address _registry, bytes32 _profileId) = _initAnchor();

        bytes4 retval = _anchor.onERC1155BatchReceived(_operator, _from, _tokenIds, _values, _data);
        assertEq(retval, IERC1155Receiver.onERC1155BatchReceived.selector);
    }

    function _initAnchor() internal returns (Anchor _anchor, address _registry, bytes32 _profileId) {
        _registry = address(new Registry());
        _profileId = bytes32("profileId");
        _anchor = new Anchor(_profileId, _registry);
    }
}
