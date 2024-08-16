// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {Metadata} from "contracts/core/Registry.sol";
import {IntegrationBase} from "./IntegrationBase.sol";
import {SQFSuperfluid} from "contracts/strategies/SQFSuperfluid.sol";
import {IRecipientsExtension} from "contracts/extensions/interfaces/IRecipientsExtension.sol";
import {IRecipientSuperAppFactory} from "contracts/strategies/interfaces/IRecipientSuperAppFactory.sol";
import {RecipientSuperAppFactory} from "contracts/strategies/RecipientSuperAppFactory.sol";

contract IntegrationSQFSuperfluid is IntegrationBase {
    IAllo public allo;
    SQFSuperfluid public strategy;
    IRecipientSuperAppFactory public recipientSuperAppFactory;

    address public constant PASSPORT_DECODER = address(0);
    address public constant SUPERFLUID_HOST = address(0);
    address public constant ALLOCATION_SUPER_TOKEN = address(0);

    uint256 public constant MIN_PASSPORT_SCORE = 0;
    uint256 public constant INITIAL_SUPER_APP_BALANCE = 0;

    uint256 public poolId;

    function setUp() public override {
        super.setUp();

        allo = IAllo(ALLO_PROXY);

        strategy = new SQFSuperfluid(ALLO_PROXY);
        recipientSuperAppFactory = new RecipientSuperAppFactory();

        // Deal 130k DAI to the user
        deal(DAI, userAddr, 130_000 ether);

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = userAddr;
        vm.prank(userAddr);
        poolId = allo.createPoolWithCustomStrategy(
            profileId,
            address(strategy),
            abi.encode(
                IRecipientsExtension.RecipientInitializeData({
                    metadataRequired: false,
                    registrationStartTime: uint64(block.timestamp),
                    registrationEndTime: uint64(block.timestamp + 7 days)
                }),
                SQFSuperfluid.SQFSuperfluidInitializeParams({
                    passportDecoder: PASSPORT_DECODER,
                    superfluidHost: SUPERFLUID_HOST,
                    allocationSuperToken: ALLOCATION_SUPER_TOKEN,
                    recipientSuperAppFactory: address(recipientSuperAppFactory),
                    allocationStartTime: uint64(block.timestamp),
                    allocationEndTime: uint64(block.timestamp + 7 days),
                    minPassportScore: MIN_PASSPORT_SCORE,
                    initialSuperAppBalance: INITIAL_SUPER_APP_BALANCE
                })
            ),
            DAI,
            100000 ether,
            Metadata({protocol: 0, pointer: ""}),
            managers
        );
    }

    function test_Allocate() public {
        //
    }

    function test_Distribute() public {
        //
    }
}
