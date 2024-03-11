// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {GameManagerFactory} from "../../../../contracts/strategies/_poc/grant-ships/GameManagerFactory.sol";
import {RegistrySetupFull} from "../../shared/RegistrySetup.sol";
import {AlloSetup} from "../../shared/AlloSetup.sol";
import {GameManagerStrategy} from "../../../../contracts/strategies/_poc/grant-ships/GameManagerStrategy.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";

contract GameManagerFactoryTest is Test, RegistrySetupFull, AlloSetup {
    GameManagerFactory internal _gameManagerFactory;
    address rootAccount = makeAddr("root");
    string public gameManagerStrategyId = "GameManagerStrategy_v1.2";
    Metadata internal dummyMetadata = Metadata(1, "dummy");

    uint256 facilitatorHatId = 2210716038082491793464205775877905354575872088332293351845461877587968;
    address arbAddress = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address hatsAddress = 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137;

    function gameManagerFactory() public view returns (GameManagerFactory) {
        return _gameManagerFactory;
    }

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));
        _gameManagerFactory = new GameManagerFactory(rootAccount,address(allo()));
    }

    function testCreate() public {
        _registerGameManager();

        vm.startPrank(rootAccount);
        address cloneAddress = _gameManagerFactory.cloneTemplate(gameManagerStrategyId);
        vm.stopPrank();

        GameManagerStrategy(payable(cloneAddress));
    }

    function testCreateWithPool() public {
        _registerGameManager();

        bytes memory initData = abi.encode(facilitatorHatId, hatsAddress, rootAccount);

        vm.startPrank(rootAccount);
        address cloneAddress = _gameManagerFactory.cloneWithPool(
            gameManagerStrategyId, 0, dummyMetadata, dummyMetadata, initData, arbAddress
        );
        vm.stopPrank();

        GameManagerStrategy gameManagerStrategy = GameManagerStrategy(payable(cloneAddress));

        assertEq(gameManagerStrategy.gameFacilitatorHatId(), facilitatorHatId);
        assertEq(gameManagerStrategy.rootAccount(), rootAccount);
        assertEq(gameManagerStrategy.token(), arbAddress);
    }

    function _registerGameManager() private returns (address) {
        GameManagerStrategy gameManagerTemplate = new GameManagerStrategy(address(allo()), gameManagerStrategyId);

        vm.startPrank(rootAccount);
        _gameManagerFactory.setTemplate(gameManagerStrategyId, address(gameManagerTemplate));
        vm.stopPrank();

        return address(gameManagerTemplate);
    }
}
