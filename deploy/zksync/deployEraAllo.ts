import * as hre from "hardhat";
import * as dotenv from "dotenv";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-ethers";
import { Deployments, verifyContract } from "../../scripts/utils/scripts";
import { alloConfig } from "../../scripts/config/allo.config";
dotenv.config();

export default async function () {
  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const deployerAddress = new Wallet(
    process.env.DEPLOYER_PRIVATE_KEY as string
  );

  const deployments = new Deployments(chainId, "allo");
  const registryAddress = deployments.getRegistry();

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
    deployer.zkWallet,
    Allo,
    [
      alloParams.owner,
      registryAddress,
      alloParams.treasury,
      alloParams.percentFee,
      alloParams.baseFee,
    ],
    { initializer: "initialize" }
  );

  await instance.waitForDeployment();
  const proxyContractAddress = await instance.getAddress();

  console.log("Allo deployed to:", proxyContractAddress);

  const objToWrite = {
    name: "Allo",
    proxy: proxyContractAddress,
    treasury: alloParams.treasury,
    percentFee: alloParams.percentFee,
    baseFee: alloParams.baseFee,
    registry: registryAddress,
    owner: alloParams.owner,
    deployerAddress: deployerAddress.address,
  };

  deployments.write(objToWrite);

  await verifyContract(proxyContractAddress, []);

  return proxyContractAddress;
}


// Note: Deploy script to run in terminal:
// npx hardhat compile --network zkSyncTestnet --config era.hardhat.config.ts
// npx hardhat deploy-zksync --network zkSyncTestnet --config era.hardhat.config.ts --script deployAllo.ts