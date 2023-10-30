import * as hre from "hardhat";
import * as dotenv from "dotenv";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-web3";
import { alloConfig } from "../config/allo.config";
import { registryConfig } from "../config/registry.config";

dotenv.config();

export async function deployAllo(_registryAddress? : string) {
    const network = await hre.network.config;
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

    const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY);

    const registryAddress = _registryAddress ? _registryAddress : registryConfig[chainId].registryProxy;

    console.log(`
        ////////////////////////////////////////////////////
                Deploys Allo.sol on ${networkName}
        ////////////////////////////////////////////////////`
    );

    const alloParams = alloConfig[chainId];
    if (!alloParams) {
      throw new Error(`Allo params not found for chainId: ${chainId}`);
    }

    console.table({
        contract: "Allo.sol",
        chainId: chainId,
        network: networkName,
        registry: registryAddress,
        treasury: alloParams.treasury,
        percentFee: alloParams.percentFee,
        baseFee: alloParams.baseFee,
        deployerAddress: deployerAddress.address,
    });

    console.log("Deploying Allo...");

    const deployer = new Deployer(hre, deployerAddress);
    const Allo = await deployer.loadArtifact("Allo");
    const instance = await hre.zkUpgrades.deployProxy(
        deployer.zkWallet, Allo,
        [
            registryAddress,
            alloParams.treasury,
            alloParams.percentFee,
            alloParams.baseFee,
        ],
        { initializer: "initialize" }
    );

    console.log("Allo deployed to:", instance.address);

    return instance.address;
}

// deployAllo().catch((error) => {
//     console.error(error);
//     process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployAllo.ts --network zksync-testnet --config era.hardhat.config.ts