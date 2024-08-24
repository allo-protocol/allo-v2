// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Allo, IAllo} from "contracts/core/Allo.sol";
import {ITransparentUpgradeableProxy} from "./ITransparentUpgradeableProxy.sol";
import {IOwnable} from "./IOwnable.sol";
import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {IBiconomyForwarder} from "./IBiconomyForwarder.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {Metadata, IRegistry} from "contracts/core/Registry.sol";
import {IRecipientsExtension} from "contracts/extensions/interfaces/IRecipientsExtension.sol";
import {RecipientsExtension} from "contracts/extensions/contracts/RecipientsExtension.sol";

abstract contract IntegrationBase is Test {
    using ECDSA for bytes32;

    address public constant ALLO_PROXY = 0x1133eA7Af70876e64665ecD07C0A0476d09465a1;
    address public constant BICONOMY_FORWARDER = 0x84a0856b038eaAd1cC7E297cF34A7e72685A8693;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    bytes32 public constant DOMAIN_SEPARATOR = 0x4fde6db5140ab711910b567033f2d5e64dc4f7123d722004dd748edf6ed07abb;

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

    /// @dev Send a transaction using the Biconomy Forwarder
    function _sendWithRelayer(address _from, address _to, bytes memory _data, uint256 _userPk)
        internal
        returns (bool _success, bytes memory _returnData)
    {
        // User signs the request
        IBiconomyForwarder.ERC20ForwardRequest memory req = IBiconomyForwarder.ERC20ForwardRequest({
            from: _from,
            to: _to,
            token: address(0),
            txGas: 500_000,
            tokenGasPrice: 0,
            batchId: 0,
            batchNonce: 0,
            deadline: block.timestamp + 1 days,
            data: _data
        });
        bytes32 structHash = keccak256(
            abi.encode(
                IBiconomyForwarder(BICONOMY_FORWARDER).REQUEST_TYPEHASH(),
                req.from,
                req.to,
                req.token,
                req.txGas,
                req.tokenGasPrice,
                req.batchId,
                IBiconomyForwarder(BICONOMY_FORWARDER).getNonce(req.from, req.batchId),
                req.deadline,
                keccak256(req.data)
            )
        );
        bytes32 digest = DOMAIN_SEPARATOR.toTypedDataHash(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_userPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        // Relayer submits the request
        vm.prank(relayer);
        (_success, _returnData) = IBiconomyForwarder(BICONOMY_FORWARDER).executeEIP712(req, DOMAIN_SEPARATOR, sig);
        assertTrue(_success);
    }

    function _getApplicationStatus(address _recipientId, uint256 _status, address _strategy)
        internal
        view
        returns (IRecipientsExtension.ApplicationStatus memory)
    {
        IRecipientsExtension.Recipient memory recipient =
            RecipientsExtension(payable(_strategy)).getRecipient(_recipientId);
        uint256 recipientIndex = uint256(recipient.statusIndex) - 1;

        uint256 rowIndex = recipientIndex / 64;
        uint256 colIndex = (recipientIndex % 64) * 4;
        uint256 currentRow = RecipientsExtension(payable(_strategy)).statusesBitMap(rowIndex);
        uint256 newRow = currentRow & ~(15 << colIndex);
        uint256 statusRow = newRow | (_status << colIndex);

        return IRecipientsExtension.ApplicationStatus({index: rowIndex, statusRow: statusRow});
    }

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

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 20289932);

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
        IAllo(ALLO_PROXY).initialize(owner, registry, payable(treasury), percentFee, baseFee, BICONOMY_FORWARDER);

        // Create a profile
        vm.prank(userAddr);
        profileId = IRegistry(registry).createProfile(
            0, "Test Profile", Metadata({protocol: 1, pointer: ""}), userAddr, new address[](0)
        );
    }
}
