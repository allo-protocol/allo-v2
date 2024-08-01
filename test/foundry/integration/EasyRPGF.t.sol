// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Allo} from "contracts/core/Allo.sol";
import {Registry, Metadata} from "contracts/core/Registry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EasyRPGF} from "contracts/strategies/EasyRPGF.sol";

contract IntegrationQVSimple is Test {
    Allo public allo;
    Registry public registry;
    EasyRPGF public strategy;

    address public owner;
    address public treasury;
    address public profileOwner;
    address public recipient0;
    address public recipient1;
    address public recipient2;

    bytes32 public profileId;

    uint256 public poolId;

    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 20289932);

        owner = makeAddr("owner");
        treasury = makeAddr("treasury");
        profileOwner = makeAddr("profileOwner");
        recipient0 = makeAddr("recipient0");
        recipient1 = makeAddr("recipient1");
        recipient2 = makeAddr("recipient2");

        // Deploying contracts
        allo = new Allo();
        registry = new Registry();
        strategy = new EasyRPGF(address(allo));

        // Initialize contracts
        allo.initialize(owner, address(registry), payable(treasury), 0, 0, address(1)); // NOTE: trusted forwarder is not used
        registry.initialize(owner);

        // Creating profile
        vm.prank(profileOwner);
        profileId = registry.createProfile(
            0, "Test Profile", Metadata({protocol: 0, pointer: ""}), profileOwner, new address[](0)
        );

        // Deal
        deal(dai, profileOwner, 100000 ether);
        vm.prank(profileOwner);
        IERC20(dai).approve(address(allo), 100000 ether);

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = profileOwner;
        vm.prank(profileOwner);
        poolId = allo.createPoolWithCustomStrategy(
            profileId,
            address(strategy),
            abi.encode(),
            dai,
            100000 ether,
            Metadata({protocol: 0, pointer: ""}),
            managers
        );
    }

    function test_Revert_Allocate() public {
        vm.expectRevert(EasyRPGF.NOOP.selector);
        vm.prank(address(allo));
        strategy.allocate(new address[](0), new uint256[](0), "", address(0));
    }

    function test_Distribute() public {
        address[] memory recipients = new address[](3);
        recipients[0] = recipient0;
        recipients[1] = recipient1;
        recipients[2] = recipient2;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        amounts[1] = 20 ether;
        amounts[2] = 30 ether;

        vm.prank(address(allo));
        strategy.distribute(recipients, abi.encode(amounts), profileOwner);

        assertEq(IERC20(dai).balanceOf(recipient0), 10 ether);
        assertEq(IERC20(dai).balanceOf(recipient1), 20 ether);
        assertEq(IERC20(dai).balanceOf(recipient2), 30 ether);
        assertEq(strategy.getPoolAmount(), 100000 ether - 60 ether);
    }
}
