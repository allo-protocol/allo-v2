pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {Accounts} from "../shared/Accounts.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {AlloSetup} from "../shared/AlloSetup.sol";
import {MockToken} from "../utils/MockToken.sol";

import {HatsCommitteeStrategy} from
"../../../contracts/strategies/hats-voter-eligibility/HatsCommitteeStrategy.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {IHats} from "@hats-protocol/Interfaces/IHats.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

interface IHatsVotingTest {
    enum InternalRecipientStatus {
        None,       // Default (No application)
        Pending,    // Application submitted (pending review)
        Accepted,   // Application accepted (approved, pending delay period)
        Rejected,   // Application rejected (denied)
        Distributed // Application distributed (funds transferred)
    }

    struct Recipient {
        address recipientId;
        uint256 amount;
        Metadata metadata;
        InternalRecipientStatus status;
    }

    error UNAUTHORIZED();
    error RECIPIENT_ALREADY_REGISTERED();
    error RECIPIENT_ERROR(address recipientId);
    error DELAY_NOT_MET();

    event Initialized(address allo, bytes32 identityId, uint256 poolId, bytes data);
    event Skim(address skimmer, address token, uint256 amountToTreasury, uint256 amountToSkimmer);
    event Registered(address indexed recipientId, bytes data, address sender);
    event Allocated(address indexed recipientId, uint256 amount, address token, address sender);
    event Distributed(address indexed recipientId, address recipientAddress, uint256 amount, address sender);
    event Rejected(address indexed recipientId);
    event PoolActive(bool active);
}

contract HatsVotingTest is IHatsVotingTest, Test, Accounts, RegistrySetupFull, AlloSetup {
    uint256 public poolId;
    Metadata public poolMetadata;
    MockToken public token;
    uint256 public poolSize = 100_000e18;

    HatsCommitteeStrategy public strategy;
    IHats public HATS;

    address public hatAdmin;
    uint256 public topHatId;
    uint256 public hatId;

    address public hatWearer1;
    address public hatWearer2;
    address public nonHatWearer;

    // -----------------------
    // Test: Setup
    // -----------------------

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));

        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        // Set address for the HATS contract
        HATS = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);

        // Create mock token to distribute in pool
        token = new MockToken();
        token.mint(
            address(pool_admin()),
            poolSize
        );

        vm.prank(pool_admin());
        token.increaseAllowance(
            address(allo()),
            poolSize
        );

        // Create Top Hat and Hat
        hatAdmin = makeAddr("hat_admin");

        vm.prank(hatAdmin);
        topHatId = HATS.mintTopHat(
            hatAdmin,
            "Top Hat",
            "https://example.com/top-hat.png"
        );

        vm.prank(hatAdmin);
        hatId = HATS.createHat(
            topHatId,
            "Hat",
            7,
            address(1),
            address(2),
            false,
            "https://example.com/hat.png"
        );

        nonHatWearer = makeAddr("non_hat_wearer");
        hatWearer1 = makeAddr("hat_wearer_1");
        hatWearer2 = makeAddr("hat_wearer_2");

        vm.startPrank(hatAdmin);

        HATS.mintHat(hatId, hatWearer1);
        HATS.mintHat(hatId, hatWearer2);

        vm.stopPrank();

        // Create pool with strategy
        strategy = new HatsCommitteeStrategy(address(allo()), "HatsVoting");

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy(
            poolIdentity_id(),
            address(strategy),
            abi.encode(
                hatId
            ),
            address(token),
            poolSize,
            poolMetadata,
            pool_managers()
        );
    }

    // -----------------------
    // Test: Base Strategy Tests
    // -----------------------

    /// @notice Test that the hatId is set correctly
    function testHatsStrategy__SetsHatId() public {
        assertEq(strategy.hatId(), hatId);
    }

    /// @notice Test that hat wearers are wearing hats
    function testHatsStrategy__HatWearersWearHats() public {
        assertEq(HATS.isWearerOfHat(hatWearer1, hatId), true);
        assertEq(HATS.isWearerOfHat(hatWearer2, hatId), true);
    }

    /// @notice The getAllo method of the strategy returns the right address for
    //Allo core
    function testHatsStrategy__GetAlloReturnsAllo() public {
        assertEq(address( strategy.getAllo() ), address(allo()));
    }

    /// @notice The getPoolId method returns the correct Id for the pool
    function testHatsStrategy__GetPoolIdReturnsPoolId() public {
        assertEq(strategy.getPoolId(), poolId);
    }

    /// @notice The getStrategyId method returns the correct strategy Id
    function testHatsStrategy__GetStrategyIdReturnsStrategyId() public {
        assertEq(
            strategy.getStrategyId(),
            keccak256(abi.encode("HatsVoting"))
        );
    }

    // -----------------------
    // Test: Method Permissions
    // -----------------------

    // Cannot directly call initialize
    // Cannot call registerRecipient
    // Cannot call allocate
    // Cannot call distribute

    // -----------------------
    // Test: Valid Allocator
    // -----------------------

    /// @notice Test that the allocator is valid (wears a hat)
    function testHatsStrategy__AllocatorIsHatWearer() public {
        // Hat Wearer
        assertEq(
            strategy.isValidAllocator(hatWearer1),
            true
        );
        
        // Non-hat wearer
        assertEq(
            strategy.isValidAllocator(nonHatWearer),
            false
        );

        // Can Become a Valid Hat Wearer
        address hatTip = makeAddr("hat_tip");
        assertEq(
            strategy.isValidAllocator(hatTip),
            false
        );

        vm.prank(hatAdmin);
        HATS.mintHat(hatId, hatTip);

        assertEq(
            strategy.isValidAllocator(hatTip),
            true
        );
    }

    // -----------------------
    // Test: Registering Recipients
    // -----------------------

    /// @notice Test to ensure that someone trying to register with an address
    //that is not an anchor in the Registry will result in an UNAUTHORIZED error
    function testHatsStrategy__NonAnchorCannotRegister() public {
        // Make an address that is not an anchor
        address recipientId = makeAddr("recipient");
        Metadata memory metadata = Metadata({protocol: 1, pointer: "RecipientMetadata"});
        uint256 amount = 1000;

        vm.expectRevert(UNAUTHORIZED.selector);
        allo().registerRecipient(
            poolId,
            abi.encode(
                recipientId,
                amount,
                metadata
            )
        );
    }

    /// @notice Ensure the address applying is a member of the recipient identity
    function testHatsStrategy__NonMemberCannotRegister() public {
        // Make an address that is not a member of the recipient identity
        address applyer = pool_notAManager();

        // Recipient Data
        Metadata memory metadata = Metadata({protocol: 1, pointer: "RecipientMetadata"});
        uint256 amount = 1000;

        // Apply as the non-member address
        vm.startPrank(applyer);

        vm.expectRevert(UNAUTHORIZED.selector);
        allo().registerRecipient(
            poolId,
            abi.encode(
                poolIdentity_anchor(),
                amount,
                metadata
            )
        );

        vm.stopPrank();
    }

    /// @notice A member is able to register on behalf of their identity. This
    //emits the Registered event and adds the recipient to the recipients mapping
    function testHatsStrategy__CanRegister() public {
        address identityMember = identity1_members()[0];

        // Recipient Data
        address recipientId = identity1_anchor();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "RecipientMetadata"});
        uint256 amount = 1000;

        bytes memory recipientData = abi.encode(
            recipientId,
            amount,
            metadata
        );

        vm.expectEmit();
        emit Registered(recipientId, recipientData, identityMember);

        // Apply as the member address
        vm.startPrank(identityMember);
        allo().registerRecipient(
            poolId,
            recipientData
        );
        vm.stopPrank();

        HatsCommitteeStrategy.Recipient memory actualRecipient
        = strategy.getRecipient(recipientId);

        assertEq(actualRecipient.recipientId, recipientId);
        assertEq(actualRecipient.amount, amount);
        assertEq(actualRecipient.metadata.protocol, metadata.protocol);
        assertEq(actualRecipient.metadata.pointer, metadata.pointer);
        assertEq(uint256(actualRecipient.status), 1);
    }

    /// @notice An Identity is not able to register more than once
    function testHatsStrategy__CannotRegisterTwice() public {
        address[] memory identityMembers = identity1_members();

        // Recipient Data
        address recipientId = identity1_anchor();
        Metadata memory metadata = Metadata({protocol: 1, pointer: "RecipientMetadata"});
        uint256 amount = 1000;

        // Apply as the member address
        vm.prank(identityMembers[0]);
        allo().registerRecipient(
            poolId,
            abi.encode(
                recipientId,
                amount,
                metadata
            )
        );

        vm.startPrank(identityMembers[1]);
        vm.expectRevert(RECIPIENT_ALREADY_REGISTERED.selector);
        allo().registerRecipient(
            poolId,
            abi.encode(
                recipientId,
                amount,
                metadata
            )
        );
        vm.stopPrank();
    }

    // -----------------------
    // Test: Allocating Tokens
    // -----------------------

    /// @notice If a non-Hat wearer tries to allocate, it will revert with an UNAUTHORIZED error
    function testHatsStrategy__NonHatWearerCannotAllocate() public {
        Recipient memory testRecipient = _registerRecipient();

        address fakeAllocator = makeAddr("fake_allocator");

        // Apply as the member address
        vm.startPrank(fakeAllocator);
        vm.expectRevert(UNAUTHORIZED.selector);
        allo().allocate(
            poolId,
            abi.encode(
                testRecipient.recipientId,
                true
            )
        );
        vm.stopPrank();
    }

    /// @notice Hat wearer can successfully allocate tokens to a recipient
    function testHatsStrategy__HatWearerCanAllocate() public {
        Recipient memory testRecipient = _registerRecipient();

        // Apply as the member address
        vm.startPrank(hatWearer1);
        vm.expectEmit();
        emit Allocated(testRecipient.recipientId, testRecipient.amount, address( token ), hatWearer1);

        allo().allocate(
            poolId,
            abi.encode(
                testRecipient.recipientId,
                true
            )
        );
        vm.stopPrank();

        HatsCommitteeStrategy.Recipient memory actualRecipient
        = strategy.getRecipient(testRecipient.recipientId);

        assertEq(actualRecipient.recipientId, testRecipient.recipientId);
        assertEq(actualRecipient.amount, testRecipient.amount);
        assertEq(actualRecipient.metadata.protocol, testRecipient.metadata.protocol);
        assertEq(actualRecipient.metadata.pointer, testRecipient.metadata.pointer);
        assertEq(uint256(actualRecipient.status), 2);
    }

    /// @notice Allocating to a project sets approvalTime correctly
    function testHatsStrategy__AllocatingSetsApprovalTime() public {
        Recipient memory testRecipient = _registerRecipient();

        _doAllocation(poolId, testRecipient.recipientId, true);

        uint256 actualApprovalTime = strategy.approvalTime(testRecipient.recipientId);

        assertEq(actualApprovalTime, block.timestamp);
    }

    /// @notice If a Hat wearer tries to allocate to a recipient that has
    //already been allocated to, it will revert with an UNAUTHORIZED error
    function testHatsStrategy__CannotAllocateTwice() public {
        // First Allocation
        Recipient memory testRecipient = _registerRecipient();
        _doAllocation(poolId, testRecipient.recipientId, true);

        // Second allocation (should revert)
        vm.expectRevert(UNAUTHORIZED.selector);
        _doAllocation(poolId, testRecipient.recipientId, true);
    }

    /// @notice Hat wearer can successfully reject allocation to a recipient
    function testHatsStrategy__CanRejectAllocation() public {
        Recipient memory testRecipient = _registerRecipient();
        HatsCommitteeStrategy.Recipient memory actualRecipient
        = strategy.getRecipient(testRecipient.recipientId);

        // Status should be pending
        assertEq(uint256(actualRecipient.status), 1);

        vm.expectEmit();
        emit Rejected(testRecipient.recipientId);

        // Reject allocation (false)
        _doAllocation(poolId, testRecipient.recipientId, false);

        // Status should be rejected now
        actualRecipient = strategy.getRecipient(testRecipient.recipientId);
        assertEq(uint256(actualRecipient.status), 3);
    }

    /// @notice An application can be rejected by another Hat wearer after it's
    //been approved and before funds have been distributed
    function testHatsStrategy__CanRejectAfterAllocated() public {
        Recipient memory testRecipient = _registerRecipient();
        _doAllocation(poolId, testRecipient.recipientId, true);

        HatsCommitteeStrategy.Recipient memory actualRecipient
        = strategy.getRecipient(testRecipient.recipientId);

        // Status should be approved
        assertEq(uint256(actualRecipient.status), 2);

        // Reject allocation (false)
        vm.expectEmit();
        emit Rejected(testRecipient.recipientId);
        _doAllocation(poolId, testRecipient.recipientId, false);


        // Status should be rejected now
        assertEq(uint256(actualRecipient.status), 3);
    }

    /// - Cannot reject an application after funds have been distributed

    /// @notice If a Hat wearer tries to allocate to a non-registered recipient, it will revert with an UNAUTHORIZED error
    function testHatsStrategy__CannotAllocateToNonRegisteredRecipient() public {
        // Recipient Data
        address recipientId = makeAddr("recipient");

        // Apply as the member address
        vm.startPrank(hatWearer1);
        vm.expectRevert(UNAUTHORIZED.selector);
        allo().allocate(
            poolId,
            abi.encode(
                recipientId,
                true
            )
        );
        vm.stopPrank();
    }

    // -----------------------
    // Test: Distributing Tokens
    // -----------------------

    // - Rejects distribution if delay hasn't passed
    // - Rejects distribution if not approved
    // - Transfers tokens from pool to recipient (pool balance decreases, recipient balance increases)
    // - Transfers tokens from pool to recipient (emits Distributed event)
    // - Can transfer to multiple recipients at once
    // - distribute creates payoutSummary

    // -----------------------
    // Test: Helper Functions
    // -----------------------

    // - getPayouts returns correct payouts
    // - isValidAllocator returns true if allocator is hat wearer
    // - isValidAllocator returns false if allocator is not hat wearer

    // -----------------------
    // Test: InternalRecipientStatus
    // -----------------------
    // - Returns None if not registered
    // - Returns Pending if registered
    // - Returns Allocated if allocated
    // - Returns Rejected if Rejected
    // - Returns Distributed if distributed

    // -----------------------
    // Test: Helper Methods
    // -----------------------
    function _registerRecipient() internal returns (Recipient memory) {
        address identityMember = identity1_members()[0];
        Recipient memory recipient = Recipient({
            recipientId: identity1_anchor(),
            amount: 1000,
            metadata: Metadata({protocol: 1, pointer: "RecipientMetadata"}),
            status: InternalRecipientStatus.None
        });

        bytes memory recipientData = abi.encode(
            recipient.recipientId,
            recipient.amount,
            recipient.metadata
        );
        vm.startPrank(identityMember);
        allo().registerRecipient(
            poolId,
            recipientData
        );
        vm.stopPrank();

        return recipient;
    }

    function _doAllocation(uint256 _poolId, address _recipientId, bool _status) internal {
        vm.startPrank(hatWearer1);
        allo().allocate(
            _poolId,
            abi.encode(
                _recipientId,
                _status
            )
        );
        vm.stopPrank();
    }
}
