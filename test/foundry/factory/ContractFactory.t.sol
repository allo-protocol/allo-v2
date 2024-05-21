pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {ContractFactory} from "../../../contracts/factories/ContractFactory.sol";
import {TestStrategy} from "../../utils/TestStrategy.sol";

contract ContractFactoryTest is Test {
    ContractFactory factoryInstance;
    address public deployerAddress;

    function setUp() public {
        deployerAddress = makeAddr("deployerAddress");
        factoryInstance = new ContractFactory();
        factoryInstance.setDeployer(deployerAddress, true);
    }

    function test_constructor() public {
        assertTrue(factoryInstance.isDeployer(address(this)));
        assertTrue(factoryInstance.isDeployer(deployerAddress));
    }

    function test_deploy_shit() public {
        // Deploy a contract and check that it was deployed successfully
        bytes memory creationCode = type(TestStrategy).creationCode;
        address deployedAddress = factoryInstance.deploy(
            "TestStrategy", "v1", abi.encodePacked(creationCode, abi.encode(makeAddr("allo"), "TestStrategy"))
        );

        assertNotEq(deployedAddress, address(0));
        assertEq(TestStrategy(deployedAddress).getStrategyId(), keccak256(abi.encode("TestStrategy")));
    }

    function testRevert_deploy_UNAUTHORIZED() public {
        vm.expectRevert(ContractFactory.UNAUTHORIZED.selector);

        bytes memory creationCode = type(TestStrategy).creationCode;
        vm.prank(makeAddr("alice"));
        factoryInstance.deploy(
            "TestStrategy", "v1", abi.encodePacked(creationCode, abi.encode(makeAddr("allo"), "TestStrategy"))
        );
    }

    function testRevert_deploy_SALT_USED() public {
        bytes memory creationCode = type(TestStrategy).creationCode;
        factoryInstance.deploy(
            "TestStrategy", "v1", abi.encodePacked(creationCode, abi.encode(makeAddr("allo"), "TestStrategy"))
        );

        vm.expectRevert(ContractFactory.SALT_USED.selector);
        factoryInstance.deploy(
            "TestStrategy", "v1", abi.encodePacked(creationCode, abi.encode(makeAddr("allo"), "TestStrategy"))
        );
    }

    function test_setDeployer() public {
        address newContractFactoryAddress = makeAddr("bob");

        assertFalse(factoryInstance.isDeployer(newContractFactoryAddress));
        factoryInstance.setDeployer(newContractFactoryAddress, true);
        assertTrue(factoryInstance.isDeployer(newContractFactoryAddress));
    }

    function testRevert_setDeployer_UNAUTHORIZED() public {
        address newContractFactoryAddress = makeAddr("bob");

        vm.expectRevert(ContractFactory.UNAUTHORIZED.selector);
        vm.prank(makeAddr("alice"));
        factoryInstance.setDeployer(newContractFactoryAddress, true);
    }
}
