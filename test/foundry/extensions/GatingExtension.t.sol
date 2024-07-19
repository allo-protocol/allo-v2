pragma solidity 0.8.19;

import "forge-std/Test.sol";

// External Libraries
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IEAS, Attestation} from "eas-contracts/IEAS.sol";

// Test libraries
import {MockGatingExtension} from "../../utils/MockGatingExtension.sol";
import {IGatingExtension} from "../../../contracts/core/interfaces/IGatingExtension.sol";

contract GatingExtensionTest is Test {
    MockGatingExtension public gatingExtension;
    address public allo = makeAddr("allo");
    address public eas = makeAddr("eas");
    uint256 public poolId = 1;

    /// actors
    address public actor = makeAddr("actor");
    /// token
    address public token = makeAddr("token");
    address public nft = makeAddr("nft");

    function setUp() public {
        gatingExtension = new MockGatingExtension(allo);

        /// initialize
        vm.prank(allo);
        gatingExtension.initialize(poolId, abi.encode(IGatingExtension.GatingExtensionInitializeParams(eas)));
    }

    function test_initialize() public {
        assertEq(gatingExtension.eas(), eas);
    }

    function test_onlyWithERC20() public {
        /// mock balance of actor
        vm.mockCall(token, abi.encodeWithSelector(IERC20(token).balanceOf.selector, actor), abi.encode(1000));
        // actor has 1000 allo
        vm.prank(actor);
        gatingExtension.onlyErc20Helper(token, 1000);
    }

    function testRevert_onlyWithERC20_tokenZeroAddress() public {
        address _token = address(0);
        vm.expectRevert(IGatingExtension.GatingExtension_INVALID_TOKEN.selector);
        vm.prank(actor);
        gatingExtension.onlyErc20Helper(_token, 1000);
    }

    function testRevert_onlyWithERC20_actorZeroAddress() public {
        vm.expectRevert(IGatingExtension.GatingExtension_INVALID_ACTOR.selector);
        vm.prank(address(0));
        gatingExtension.onlyErc20Helper(token, 1000);
    }

    function testRevert_onlyWithERC20_insufficientBalance() public {
        vm.mockCall(token, abi.encodeWithSelector(IERC20(token).balanceOf.selector, actor), abi.encode(1000));
        vm.expectRevert(IGatingExtension.GatingExtension_INSUFFICIENT_BALANCE.selector);
        vm.prank(actor);
        gatingExtension.onlyErc20Helper(token, 1001);
    }

    function test_onlyWithNFT() public {
        vm.mockCall(nft, abi.encodeWithSelector(IERC721(nft).balanceOf.selector, actor), abi.encode(1));
        vm.prank(actor);
        gatingExtension.onlyWithNFTHelper(nft);
    }

    function testRevert_onlyWithNFT_nftZeroAddress() public {
        address _nft = address(0);
        vm.expectRevert(IGatingExtension.GatingExtension_INVALID_TOKEN.selector);
        vm.prank(actor);
        gatingExtension.onlyWithNFTHelper(_nft);
    }

    function testRevert_onlyWithNFT_actorZeroAddress() public {
        vm.expectRevert(IGatingExtension.GatingExtension_INVALID_ACTOR.selector);
        vm.prank(address(0));
        gatingExtension.onlyWithNFTHelper(nft);
    }

    function testRevert_onlyWithNFT_actorNotOwner() public {
        vm.mockCall(nft, abi.encodeWithSelector(IERC721(nft).balanceOf.selector, actor), abi.encode(0));
        vm.expectRevert(IGatingExtension.GatingExtension_INSUFFICIENT_BALANCE.selector);
        vm.prank(actor);
        gatingExtension.onlyWithNFTHelper(nft);
    }

    function test_onlyWithAttestation() public {
        /// mock values
        bytes32 _schema = keccak256("schema");
        bytes32 _uid = keccak256("uid");

        Attestation memory attestation = Attestation({
            uid: _uid,
            schema: _schema,
            time: 0,
            expirationTime: 0,
            revocationTime: 0,
            refUID: bytes32(0),
            recipient: actor,
            attester: actor,
            revocable: false,
            data: bytes("0x")
        });

        vm.mockCall(eas, abi.encodeWithSelector(IEAS(eas).getAttestation.selector, _uid), abi.encode(attestation));
        vm.prank(actor);
        gatingExtension.onlyWithAttestationHelper(_schema, actor, _uid);
    }

    function testRevert_onlyWithAttestation_invalidSchema() public {
        /// mock values
        bytes32 _schema = keccak256("schema");
        bytes32 _uid = keccak256("uid");

        Attestation memory attestation = Attestation({
            uid: _uid,
            schema: keccak256("wrong"),
            time: 0,
            expirationTime: 0,
            revocationTime: 0,
            refUID: bytes32(0),
            recipient: actor,
            attester: actor,
            revocable: false,
            data: bytes("0x")
        });

        vm.mockCall(eas, abi.encodeWithSelector(IEAS(eas).getAttestation.selector, _uid), abi.encode(attestation));
        vm.expectRevert(IGatingExtension.GatingExtension_INVALID_ATTESTATION_SCHEMA.selector);
        vm.prank(actor);
        gatingExtension.onlyWithAttestationHelper(_schema, actor, _uid);
    }

    function testRevert_onlyWithAttestation_invalidAttester() public {
        /// mock values
        bytes32 _schema = keccak256("schema");
        bytes32 _uid = keccak256("uid");

        Attestation memory attestation = Attestation({
            uid: _uid,
            schema: _schema,
            time: 0,
            expirationTime: 0,
            revocationTime: 0,
            refUID: bytes32(0),
            recipient: actor,
            attester: address(0),
            revocable: false,
            data: bytes("0x")
        });

        vm.mockCall(eas, abi.encodeWithSelector(IEAS(eas).getAttestation.selector, _uid), abi.encode(attestation));
        vm.expectRevert(IGatingExtension.GatingExtension_INVALID_ATTESTATION_ATTESTER.selector);
        vm.prank(actor);
        gatingExtension.onlyWithAttestationHelper(_schema, actor, _uid);
    }
}
