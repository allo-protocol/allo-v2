// SPDX-License-Identifier = MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from
    "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

import {Allo} from "contracts/core/Allo.sol";

contract DeployAllo is Script {
    function run() public {
        vm.startBroadcast();
        (address allo, address alloImplementation) = _deploy();
        vm.stopBroadcast();

        console.log("Deployed Allo at address: %s", allo);
        console.log("Allo implementation at address: %s", alloImplementation);
    }

    function _deploy() internal returns (address alloAddress, address alloImplementation) {
        (
            address owner,
            address registry,
            address treasury,
            uint256 percentFee,
            uint256 baseFee,
            address trustedForwarder,
            address proxyAdmin
        ) = _getAlloParams();

        alloImplementation = address(new Allo());

        if (proxyAdmin == address(0)) {
            ProxyAdmin admin = new ProxyAdmin();
            admin.transferOwnership(owner);
            proxyAdmin = address(admin);
        }

        alloAddress = address(
            new TransparentUpgradeableProxy(
                address(alloImplementation),
                proxyAdmin, // initial owner address for proxy admin
                abi.encodeCall(
                    Allo.initialize, (owner, registry, payable(treasury), percentFee, baseFee, trustedForwarder)
                )
            )
        );
    }

    function _getAlloParams()
        internal
        view
        returns (
            address owner,
            address registry,
            address treasury,
            uint256 percentFee,
            uint256 baseFee,
            address trustedForwarder,
            address proxyAdmin
        )
    {
        // Mainnet
        if (block.chainid == 1) {
            owner = 0x34d82D1ED8B4fB6e6A569d6D086A39f9f734107E;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x34d82D1ED8B4fB6e6A569d6D086A39f9f734107E;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Goerli
        else if (block.chainid == 5) {
            owner = 0x91AE7C39D43fbEA2E564E5128ac0469200e50da1;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x91AE7C39D43fbEA2E564E5128ac0469200e50da1;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Sepolia
        else if (block.chainid == 11155111) {
            owner = 0xD5e7B9A4587a6760a308b9D6E7956a41023d7Bb2;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0xD5e7B9A4587a6760a308b9D6E7956a41023d7Bb2;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Optimism
        else if (block.chainid == 10) {
            owner = 0x791BB7b7e16982BDa029893077EEb4F77A2CD564;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x791BB7b7e16982BDa029893077EEb4F77A2CD564;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Optimism Goerli
        else if (block.chainid == 420) {
            owner = 0x2709Ec5Fbe9Ed9b985Bd9F2C9587E09A8Fa8af33;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x2709Ec5Fbe9Ed9b985Bd9F2C9587E09A8Fa8af33;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Celo Mainnet
        else if (block.chainid == 42220) {
            owner = 0x8AA4514A31A69e3cba946F8f29899Bc189b01f2C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8AA4514A31A69e3cba946F8f29899Bc189b01f2C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Celo Testnet Alfajores
        else if (block.chainid == 44787) {
            owner = 0x0C08E6cA059907769a42F95274f0b2b9D96fA4D2;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x0C08E6cA059907769a42F95274f0b2b9D96fA4D2;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Polygon Mainnet
        else if (block.chainid == 137) {
            owner = 0xc8c4F1b9980B583E3428F183BA44c65D78C15251;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0xc8c4F1b9980B583E3428F183BA44c65D78C15251;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Mumbai
        else if (block.chainid == 80001) {
            owner = 0x00F06079089ca6F56D64682b8F3D4C6b067b612C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x00F06079089ca6F56D64682b8F3D4C6b067b612C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Arbitrum One
        else if (block.chainid == 42161) {
            owner = 0xEfEAB1ea32A5d7c6B1DE6192ee531A2eF51198D9;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0xEfEAB1ea32A5d7c6B1DE6192ee531A2eF51198D9;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Arbitrum Sepolia
        else if (block.chainid == 421614) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Base Mainnet
        else if (block.chainid == 8453) {
            owner = 0x850a5515123f49c298DdF33E581cA01bFF928FEf;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x850a5515123f49c298DdF33E581cA01bFF928FEf;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Base Testnet Goerli
        else if (block.chainid == 84531) {
            owner = 0xB145b7742A5a082C4f334981247E148dB9dF0cb3;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0xB145b7742A5a082C4f334981247E148dB9dF0cb3;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Optimism Sepolia
        else if (block.chainid == 11155420) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Fuji
        else if (block.chainid == 43113) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0xf7B93519a3A1790F97f7b14E6f118A139187843e;
        }
        // Avalanche Mainnet
        else if (block.chainid == 43114) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Scroll
        else if (block.chainid == 534352) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Fantom
        else if (block.chainid == 250) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Fantom Testnet
        else if (block.chainid == 4002) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // ZkSync Mainnet
        else if (block.chainid == 324) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0xaa376Ef759c1f5A8b0B5a1e2FEC5C23f3bF30246;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x0000000000000000000000000000000000000000;
        }
        // ZkSync Sepolia Testnet
        else if (block.chainid == 300) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0xaa376Ef759c1f5A8b0B5a1e2FEC5C23f3bF30246;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x0000000000000000000000000000000000000000;
        }
        // Filecoin Mainnet
        else if (block.chainid == 314) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Filecoin Calibration Testnet
        else if (block.chainid == 314159) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0xb91DBEb018789d712EDC1a9e6C6AdC891BD5Ec2c;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x7DE1218DCDC3628F839b19a3aF5ACF092C35BcDE;
        }
        // Sei Devnet
        else if (block.chainid == 713715) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x2447dD8C1f4cd4361a649564Bd441787edf8c03A;
        } else if (block.chainid == 1329) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Lukso Mainnet
        else if (block.chainid == 42) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        }
        // Lukso Testnet
        else if (block.chainid == 4201) {
            owner = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            registry = 0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3;
            treasury = 0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C;
            percentFee = 0;
            baseFee = 0;
            trustedForwarder = 0x0000000000000000000000000000000000000000;
            proxyAdmin = 0x758b87af7fdB4783f848a1dDEa1F025dC48B9858;
        } else {
            revert("Network not supported");
        }
    }
}
