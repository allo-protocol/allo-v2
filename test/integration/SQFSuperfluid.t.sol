// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Allo, IAllo} from "contracts/core/Allo.sol";
import {SQFSuperfluid} from "contracts/strategies/examples/sqf-superfluid/SQFSuperfluid.sol";
import {IRecipientsExtension} from "contracts/strategies/extensions/register/IRecipientsExtension.sol";
import {IRecipientSuperAppFactory} from "contracts/strategies/examples/sqf-superfluid/IRecipientSuperAppFactory.sol";
import {RecipientSuperAppFactory} from "contracts/strategies/examples/sqf-superfluid/RecipientSuperAppFactory.sol";
import {IOwnable} from "test/utils/IOwnable.sol";
import {ITransparentUpgradeableProxy} from "test/utils/ITransparentUpgradeableProxy.sol";
import {Metadata, IRegistry} from "contracts/core/Registry.sol";
import {IGitcoinPassportDecoder} from "contracts/strategies/examples/sqf-superfluid/IGitcoinPassportDecoder.sol";
import {RecipientsExtension} from "contracts/strategies/extensions/register/RecipientsExtension.sol";
import {ISuperfluidGovernance} from "contracts/strategies/examples/sqf-superfluid/ISuperfluidGovernance.sol";
import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IntegrationSQFSuperfluid is Test {
    using SuperTokenV1Library for ISuperToken;

    SQFSuperfluid public strategy;
    IRecipientSuperAppFactory public recipientSuperAppFactory;

    address public userAddr;
    address public recipient0Addr;
    address public recipient1Addr;
    address public recipient2Addr;

    uint256 public userPk;
    uint256 public recipient0Pk;
    uint256 public recipient1Pk;
    uint256 public recipient2Pk;

    bytes32 public profileId;

    address public alloAdmin;
    address public owner;
    address public registry;
    address public treasury;
    address public relayer;

    uint256 public percentFee;
    uint256 public baseFee;

    uint256 public poolId;

    address public constant ALLO_PROXY = 0x1133eA7Af70876e64665ecD07C0A0476d09465a1;
    address public constant PASSPORT_DECODER = 0x5558D441779Eca04A329BcD6b47830D2C6607769;
    address public constant SUPERFLUID_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;
    address public constant ALLOCATION_SUPER_TOKEN = 0x7d342726B69C28D942ad8BfE6Ac81b972349d524;
    address public constant POOL_SUPER_TOKEN = 0x4ac8bD1bDaE47beeF2D1c6Aa62229509b962Aa0d;
    address public constant SUPERFLUID_GOV = 0x0170FFCC75d178d426EBad5b1a31451d00Ddbd0D;

    uint256 public constant MIN_PASSPORT_SCORE = 30000;
    uint256 public constant INITIAL_SUPER_APP_BALANCE = 10000000000;

    // TODO: import this function from utils
    function _getApplicationStatus(address[] memory _recipientIds, uint256[] memory _statuses, address _strategy)
        internal
        view
        returns (IRecipientsExtension.ApplicationStatus memory)
    {
        IRecipientsExtension.Recipient memory recipient =
            RecipientsExtension(payable(_strategy)).getRecipient(_recipientIds[0]);
        uint256 recipientIndex = uint256(recipient.statusIndex) - 1;

        uint256 rowIndex = recipientIndex / 64;
        uint256 statusRow = RecipientsExtension(payable(_strategy)).statusesBitMap(rowIndex);
        for (uint256 i = 0; i < _recipientIds.length; i++) {
            recipient = RecipientsExtension(payable(_strategy)).getRecipient(_recipientIds[i]);
            recipientIndex = uint256(recipient.statusIndex) - 1;

            require(rowIndex == recipientIndex / 64, "_recipientIds belong to different rows");
            uint256 colIndex = (recipientIndex % 64) * 4;
            uint256 newRow = statusRow & ~(15 << colIndex);
            statusRow = newRow | (_statuses[i] << colIndex);
        }

        return IRecipientsExtension.ApplicationStatus({index: rowIndex, statusRow: statusRow});
    }

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("optimism"), 123864457);

        (userAddr, userPk) = makeAddrAndKey("user");
        (recipient0Addr, recipient0Pk) = makeAddrAndKey("recipient0");
        (recipient1Addr, recipient1Pk) = makeAddrAndKey("recipient1");
        (recipient2Addr, recipient2Pk) = makeAddrAndKey("recipient2");

        // Get the current protocol variables
        alloAdmin = address(
            uint160(uint256(vm.load(ALLO_PROXY, 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)))
        );
        owner = IOwnable(ALLO_PROXY).owner();
        registry = address(IAllo(ALLO_PROXY).getRegistry());
        treasury = address(IAllo(ALLO_PROXY).getTreasury());
        percentFee = IAllo(ALLO_PROXY).getPercentFee();
        baseFee = IAllo(ALLO_PROXY).getBaseFee();

        // Deploy the implementation
        vm.prank(alloAdmin);
        address implementation = address(new Allo());

        // Deploy the update
        vm.prank(alloAdmin);
        ITransparentUpgradeableProxy(ALLO_PROXY).upgradeTo(implementation);

        // Initialize
        vm.prank(owner);
        IAllo(ALLO_PROXY).initialize(owner, registry, payable(treasury), percentFee, baseFee, address(1));

        // Create a profile
        vm.prank(userAddr);
        profileId = IRegistry(registry).createProfile(
            0, "Test Profile", Metadata({protocol: 1, pointer: ""}), userAddr, new address[](0)
        );

        // Deploy strategy and recipient super app factory
        strategy = new SQFSuperfluid(ALLO_PROXY);
        recipientSuperAppFactory = new RecipientSuperAppFactory();

        // Authorize factory
        vm.prank(ISuperfluidGovernance(SUPERFLUID_GOV).owner());
        ISuperfluidGovernance(SUPERFLUID_GOV).setAppRegistrationKey(
            SUPERFLUID_HOST, address(recipientSuperAppFactory), "k1", block.timestamp + 4 weeks
        );

        // Creating pool (and deploying strategy)
        address[] memory managers = new address[](1);
        managers[0] = userAddr;
        vm.prank(userAddr);
        poolId = IAllo(ALLO_PROXY).createPoolWithCustomStrategy(
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
                    initialSuperAppBalance: INITIAL_SUPER_APP_BALANCE,
                    erc721s: new address[](0)
                })
            ),
            POOL_SUPER_TOKEN,
            0,
            Metadata({protocol: 0, pointer: ""}),
            managers
        );

        // Deal initial balance * recipients of DAIx to the strategy
        deal(ALLOCATION_SUPER_TOKEN, address(strategy), INITIAL_SUPER_APP_BALANCE * 2);

        // Deal initial balance of DAIx to the user
        deal(ALLOCATION_SUPER_TOKEN, userAddr, 100 ether);

        // Mock score in passport
        vm.mockCall(
            PASSPORT_DECODER,
            abi.encodeWithSelector(IGitcoinPassportDecoder.getScore.selector, userAddr),
            abi.encode(MIN_PASSPORT_SCORE)
        );

        // Register recipients
        vm.startPrank(ALLO_PROXY);
        address[] memory recipients = new address[](1);
        bytes[] memory data = new bytes[](1);

        recipients[0] = recipient0Addr;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), bytes(""));
        strategy.register(recipients, abi.encode(data), recipient0Addr);

        recipients[0] = recipient1Addr;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), bytes(""));
        strategy.register(recipients, abi.encode(data), recipient1Addr);

        recipients[0] = recipient2Addr;
        data[0] = abi.encode(address(0), Metadata({protocol: 0, pointer: ""}), bytes(""));
        strategy.register(recipients, abi.encode(data), recipient2Addr);
        vm.stopPrank();

        // Review recipients
        address[] memory _recipientIds = new address[](2);
        _recipientIds[0] = recipient0Addr;
        _recipientIds[1] = recipient1Addr;

        uint256[] memory _newStatuses = new uint256[](3);
        _newStatuses[0] = uint256(IRecipientsExtension.Status.Accepted);
        _newStatuses[1] = uint256(IRecipientsExtension.Status.Accepted);

        IRecipientsExtension.ApplicationStatus[] memory statuses = new IRecipientsExtension.ApplicationStatus[](1);
        statuses[0] = _getApplicationStatus(_recipientIds, _newStatuses, address(strategy));

        uint256 recipientsCounter = strategy.recipientsCounter();

        vm.prank(userAddr);
        strategy.reviewRecipients(statuses, recipientsCounter);
    }

    function test_Allocate() public {
        address[] memory recipients = new address[](2);
        recipients[0] = recipient0Addr;
        recipients[1] = recipient1Addr;

        // wei of DAIx per second
        int96[] memory flowRates = new int96[](2);
        flowRates[0] = 0.0001 ether;
        flowRates[1] = 0.0002 ether;

        vm.startPrank(userAddr);
        // Approve the strategy to create flows
        ISuperToken(ALLOCATION_SUPER_TOKEN).setMaxFlowPermissions(address(strategy));

        // Call allocate
        IAllo(ALLO_PROXY).allocate(poolId, recipients, new uint256[](0), abi.encode(flowRates));
        vm.stopPrank();
    }

    function test_Distribute() public {
        vm.warp(block.timestamp + 7 days);

        vm.startPrank(userAddr);

        // Fund the pool
        deal(POOL_SUPER_TOKEN, userAddr, 100 ether);
        IERC20(POOL_SUPER_TOKEN).approve(ALLO_PROXY, 100 ether);
        IAllo(ALLO_PROXY).fundPool(poolId, 100 ether);

        // Call distribute
        int96 flowRate = 0.0001 ether;
        bytes memory data = abi.encode(flowRate);
        IAllo(ALLO_PROXY).distribute(poolId, new address[](0), data);

        vm.stopPrank();
    }
}
