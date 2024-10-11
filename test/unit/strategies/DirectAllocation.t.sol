// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DirectAllocationStrategy} from "strategies/examples/direct-allocation/DirectAllocation.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";

contract DirectAllocationTest is Test {
    event Initialized(uint256 poolId, bytes data);
    event DirectAllocated(address indexed recipient, uint256 amount, address token, address sender);

    DirectAllocationStrategy directAllocationStrategy;

    address mockAlloAddress;

    function setUp() external {
        /// create a mock allo address
        mockAlloAddress = makeAddr("allo");
        /// create the direct allocation strategy
        directAllocationStrategy = new DirectAllocationStrategy(mockAlloAddress);
    }

    function test_InitializeWhenCalled(uint256 _poolId) external {
        vm.assume(_poolId != 0);
        // it should emit event
        vm.expectEmit(true, true, true, true);
        emit Initialized(_poolId, "");

        vm.prank(mockAlloAddress);
        directAllocationStrategy.initialize(_poolId, "");
        // it should initialize the base strategy
        assertEq(directAllocationStrategy.getPoolId(), _poolId);
    }

    function test_AllocateRevertWhen_RecipientsAndAmountsLengthMissmatch(
        address[] memory _recipients,
        uint256[] memory _amounts,
        address _sender
    ) external {
        vm.assume(_recipients.length != _amounts.length);

        address[] memory _tokens = new address[](_recipients.length);
        bytes memory _data = abi.encode(_tokens);

        vm.expectRevert(Errors.ARRAY_MISMATCH.selector);

        vm.prank(mockAlloAddress);
        directAllocationStrategy.allocate(_recipients, _amounts, _data, _sender);
    }

    function test_AllocateRevertWhen_RecipientsAndTokensLengthMissmatch(address[] memory _recipients, address _sender)
        external
    {
        uint256[] memory _amounts = new uint256[](_recipients.length);

        address[] memory _tokens = new address[](_recipients.length + 1);
        bytes memory _data = abi.encode(_tokens);

        vm.expectRevert(Errors.ARRAY_MISMATCH.selector);

        vm.prank(mockAlloAddress);
        directAllocationStrategy.allocate(_recipients, _amounts, _data, _sender);
    }

    function test_AllocateWhenCalledWithValidParameters(address _sender) external {
        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = 1_000;

        address[] memory _recipients = new address[](1);
        _recipients[0] = makeAddr("recipient");

        address[] memory _tokens = new address[](1);
        _tokens[0] = makeAddr("token");

        bytes memory _data = abi.encode(_tokens);

        /// it should emit event
        vm.expectEmit(true, true, true, true);
        emit DirectAllocated(_recipients[0], _amounts[0], _tokens[0], _sender);

        vm.prank(mockAlloAddress);
        directAllocationStrategy.allocate(_recipients, _amounts, _data, _sender);
    }

    function test_DistributeRevertWhen_Called(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
    {
        vm.expectRevert(Errors.NOT_IMPLEMENTED.selector);

        vm.prank(mockAlloAddress);
        directAllocationStrategy.distribute(_recipientIds, _data, _sender);
    }

    function test_RegisterRevertWhen_Called(address[] memory _recipients, bytes memory _data, address _sender)
        external
    {
        vm.expectRevert(Errors.NOT_IMPLEMENTED.selector);

        vm.prank(mockAlloAddress);
        directAllocationStrategy.register(_recipients, _data, _sender);
    }

    function test_ReceiveRevertWhen_Called() external {
        vm.expectRevert(Errors.NOT_IMPLEMENTED.selector);

        /// send ether to the strategy
        payable(address(directAllocationStrategy)).transfer(1 ether);
    }
}
