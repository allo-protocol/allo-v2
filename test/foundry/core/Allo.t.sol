import "forge-std/Test.sol";

import {Allo} from "../../../contracts/core/Allo.sol";
import {Registry} from "../../../contracts/core/Registry.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";

import "../../../contracts/interfaces/IAllocationStrategy.sol";
import "../../../contracts/interfaces/IDistributionStrategy.sol";

// todo:
contract AlloTest is Test {
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed identityId,
        address allocationStrategy,
        address distributionStrategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    event PoolFunded(uint256 indexed poolId, uint256 amount);

    event PoolClosed(uint256 indexed poolId);

    event TreasuryUpdated(address treasury);

    event FeeUpdated(uint256 fee);

    event IdentityCreated(bytes32 indexed identityId, uint256 nonce, string name, Metadata metadata, address anchor);

    event IdentityNameUpdated(bytes32 indexed identityId, string name, address anchor);

    event IdentityMetadataUpdated(bytes32 indexed identityId, Metadata metadata);

    Allo allo;
    Registry public registry;

    address public admin;
    address public owner;
    address public member1;
    address public member2;
    address[] public members;
    address public notAMember;

    Metadata public metadata;
    string public name;
    uint256 public nonce;

    function setUp() public {
        allo = new Allo();
        owner = makeAddr("owner");

        member1 = makeAddr("member1");
        member2 = makeAddr("member2");

        metadata = Metadata({protocol: 1, pointer: "test metadata"});
        name = "New Identity";
        nonce = 2;

        registry = new Registry(admin);

        members = new address[](2);
        members[0] = member1;
        members[1] = member2;
    }

    function test_createPool() public {
        vm.expectEmit(true, false, false, true);

        bytes32 testIdentityId = _testUtilGenerateIdentityId(
            nonce,
            address(this)
        );

        // todo: test that the pool is created
        allo.createPool(
            testIdentityId,
            address(0),
            payable(address(0)),
            address(0),
            1000,
            metadata
        );

        emit PoolCreated(
            1,
            "0x12345",
            address(0),
            address(0),
            address(0),
            1000,
            metadata
        );
    }

    function test_updatePoolMetadata() public {
        // update the metadata
        allo.updatePoolMetadata(1, Metadata(1, "test metadata"));

        // check that the metadata was updated
        Allo.Pool memory pool = allo.getPoolInfo(1);
        Metadata memory poolMetadata = pool.metadata;

        assertEq(poolMetadata.protocol, 1);
        assertEq(poolMetadata.pointer, "test metadata");
    }

    // todo: move utility funcions to a library

    /// @notice Generates the anchor for the given identityId and name
    /// @param _identityId Id of the identity
    /// @param _name The name of the identity
    function _testUtilGenerateAnchor(bytes32 _identityId, string memory _name) internal pure returns (address) {
        bytes32 attestationHash = keccak256(abi.encodePacked(_identityId, _name));

        return address(uint160(uint256(attestationHash)));
    }

    /// @notice Generates the identityId based on msg.sender
    /// @param _nonce Nonce used to generate identityId
    function _testUtilGenerateIdentityId(uint256 _nonce, address sender) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, sender));
    }
}
