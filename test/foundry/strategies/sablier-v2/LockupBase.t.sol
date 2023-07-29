pragma solidity 0.8.19;

import {IERC20} from "@sablier/v2-core/types/Tokens.sol";
import {Test} from "forge-std/Test.sol";

import {Accounts} from "../../shared/Accounts.sol";
import {EventSetup} from "../../shared/EventSetup.sol";
import {RegistrySetupFull} from "../../shared/RegistrySetup.sol";

import {Allo} from "../../../../contracts/core/Allo.sol";
import {Metadata} from "../../../../contracts/core/libraries/Metadata.sol";

contract LockupBase_Test is Test, Accounts, EventSetup, RegistrySetupFull {
    Allo internal allo;
    IERC20 internal GTC = IERC20(0xDe30da39c46104798bB5aA3fe8B9e0e1F348163F);

    Metadata internal poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});
    Metadata internal strategyMetadata = Metadata({protocol: 2, pointer: "StrategyMetadata"});
    bool internal useRegistryAnchor = false;

    function setUp() public virtual {
        vm.createSelectFork({blockNumber: 17_787_058, urlOrAlias: "mainnet"});

        __RegistrySetupFull();

        allo = new Allo();
        vm.label(address(allo), "Allo");

        allo.initialize(address(registry()), allo_treasury(), 0, 0);
    }

    function __StrategySetup(address strategy, bytes memory data) internal returns (uint256 poolId) {
        poolId = allo.createPoolWithCustomStrategy(
            poolIdentity_id(), strategy, data, address(GTC), 0, poolMetadata, pool_managers()
        );
    }
}
