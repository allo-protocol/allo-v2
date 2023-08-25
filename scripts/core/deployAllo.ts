import hre, { ethers, upgrades } from "hardhat";
import { alloConfig } from "../config/allo.config";
import { registryConfig } from "../config/registry.config";
import { confirmContinue, prettyNum, verifyContract } from "../utils/scripts";

export async function deployAllo(_registryAddress? : string) {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const blocksToWait = networkName === "localhost" ? 0 : 5;
  const balance = await ethers.provider.getBalance(deployerAddress);

  console.log(`
    ////////////////////////////////////////////////////
            Deploys Allo.sol on ${networkName}
    ////////////////////////////////////////////////////`
  );

  const alloParams = alloConfig[chainId];
  if (!alloParams) {
    throw new Error(`Allo params not found for chainId: ${chainId}`);
  }

  const registryAddress = _registryAddress ? _registryAddress : registryConfig[chainId].registryProxy;

  await confirmContinue({
    contract: "Deploy Allo.sol",
    chainId: chainId,
    network: networkName,
    registry: registryAddress,
    treasury: alloParams.treasury,
    percentFee: alloParams.percentFee,
    baseFee: alloParams.baseFee,
    deployerAddress: deployerAddress,
    balance: prettyNum(balance.toString()),
  });

  console.log("Deploying Allo...");

  const Allo = await ethers.getContractFactory("Allo");
  const instance = await upgrades.deployProxy(Allo, [
    registryAddress,
    alloParams.treasury,
    alloParams.percentFee,
    alloParams.baseFee,
  ]);
  // await instance.waitForDeployment();
  // await instance.deploymentTransaction()?.wait(blocksToWait);

  // await verifyContract(instance.target.toString());

  console.log("Allo.sol deployed to:", instance.target);

  console.log("Initializing...", instance.target);
  await instance.initialize(
    registryAddress,
    alloParams.treasury,
    alloParams.percentFee,
    alloParams.baseFee,
  );
  console.log("Registry initialized!");

  return instance.target;
}

// deployAllo().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployAllo.ts --network sepolia
