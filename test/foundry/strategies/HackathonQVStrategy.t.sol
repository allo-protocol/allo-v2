// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

// Test libraries
import {QVBaseStrategyTest} from "./QVBaseStrategy.t.sol";
import {HackathonQVStrategy} from "../../../contracts/strategies/qv-hackathon/HackathonQVStrategy.sol";
import {MockERC721} from "../../utils/MockERC721.sol";
// External Libraries
import {ERC721} from "solady/src/tokens/ERC721.sol";
import {
    Attestation,
    AttestationRequest,
    AttestationRequestData,
    IEAS,
    RevocationRequest
} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {
    ISchemaRegistry,
    ISchemaResolver,
    SchemaRecord
} from "@ethereum-attestation-service/eas-contracts/contracts/ISchemaRegistry.sol";

import {MockEAS, MockSchemaRegistry} from "../../utils/MockEAS.sol";

contract HackathonQVStrategyTest is QVBaseStrategyTest {
    ISchemaRegistry public schemaRegistry;
    HackathonQVStrategy.EASInfo public easInfo;
    MockERC721 public nft;
    IEAS public eas;

    uint256 public maxVoiceCreditsPerAllocator;

    function setUp() public override {
        eas = IEAS(address(new MockEAS()));
        schemaRegistry = ISchemaRegistry(address(new MockSchemaRegistry()));

        easInfo = HackathonQVStrategy.EASInfo({
            eas: eas,
            schemaRegistry: schemaRegistry,
            schemaUID: 0,
            schema: "idk",
            revocable: false
        });

        nft = new MockERC721();
        nft.mint(randomAddress(), 1);

        /**
         */
        super.setUp();
    }

    function _createStrategy() internal override returns (address) {
        return address(new HackathonQVStrategy(address(allo()), "MockStrategy"));
    }

    function hQvStrategy() internal view returns (HackathonQVStrategy) {
        return (HackathonQVStrategy(payable(_strategy)));
    }

    function _initialize() internal override {
        vm.startPrank(address(allo()));
        hQvStrategy().initialize(
            poolId,
            abi.encode(
                easInfo,
                address(nft),
                abi.encode(
                    metadataRequired,
                    maxVoiceCreditsPerAllocator,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime
                )
            )
        );

        vm.startPrank(pool_admin());
        _createPoolWithCustomStrategy();
    }

    function _createPoolWithCustomStrategy() internal override {
        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(_strategy),
            abi.encode(
                easInfo,
                address(nft),
                abi.encode(
                    metadataRequired,
                    maxVoiceCreditsPerAllocator,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime
                )
            ),
            address(token),
            0 ether, // TODO: setup tests for failed transfers when a value is passed here.
            poolMetadata,
            pool_managers()
        );
    }
}
