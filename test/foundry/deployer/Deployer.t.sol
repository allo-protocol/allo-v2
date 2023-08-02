pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {Deployer} from "../../../contracts/deployer/Deployer.sol";
import {TestStrategy} from "../../utils/TestStrategy.sol";

contract DeployerTest is Test {
    Deployer deployerInstance;
    address public deployerAddress;

    function setUp() public {
        deployerAddress = makeAddr("deployerAddress");
        deployerInstance = new Deployer();
        deployerInstance.setDeployer(deployerAddress, true);
    }

    function test_constructor() public {
        assertTrue(deployerInstance.isDeployer(address(this)));
        assertTrue(deployerInstance.isDeployer(deployerAddress));
    }

    function test_deploy_shit() public {
        // Deploy a contract and check that it was deployed successfully
        bytes memory creationCode = type(TestStrategy).creationCode;
        address deployedAddress = deployerInstance.deploy(
            "TestStrategy", "v1", abi.encodePacked(creationCode, abi.encode(makeAddr("allo"), "TestStrategy"))
        );

        assertNotEq(deployedAddress, address(0));
        assertEq(TestStrategy(deployedAddress).getStrategyId(), keccak256(abi.encode("TestStrategy")));
    }

    function testRevert_deploy_UNAUTHORIZED() public {
        vm.expectRevert(Deployer.UNAUTHORIZED.selector);

        bytes memory creationCode = type(TestStrategy).creationCode;
        vm.prank(makeAddr("alice"));
        deployerInstance.deploy(
            "TestStrategy", "v1", abi.encodePacked(creationCode, abi.encode(makeAddr("allo"), "TestStrategy"))
        );
    }

    function testRevert_deploy_SALT_USED() public {
        bytes memory creationCode = type(TestStrategy).creationCode;
        deployerInstance.deploy(
            "TestStrategy", "v1", abi.encodePacked(creationCode, abi.encode(makeAddr("allo"), "TestStrategy"))
        );

        vm.expectRevert(Deployer.SALT_USED.selector);
        deployerInstance.deploy(
            "TestStrategy", "v1", abi.encodePacked(creationCode, abi.encode(makeAddr("allo"), "TestStrategy"))
        );
    }

    function test_setDeployer() public {
        address newDeployerAddress = makeAddr("bob");

        assertFalse(deployerInstance.isDeployer(newDeployerAddress));
        deployerInstance.setDeployer(newDeployerAddress, true);
        assertTrue(deployerInstance.isDeployer(newDeployerAddress));
    }

    function testRevert_setDeployer_UNAUTHORIZED() public {
        address newDeployerAddress = makeAddr("bob");

        vm.expectRevert(Deployer.UNAUTHORIZED.selector);
        vm.prank(makeAddr("alice"));
        deployerInstance.setDeployer(newDeployerAddress, true);
    }
}
