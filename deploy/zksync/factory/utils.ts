import hre from "hardhat";
import { Deployments, verifyContract } from "../../../scripts/utils/scripts";
import { Wallet } from "zksync-ethers";
import { Addressable } from "ethers";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

export async function deployStrategyFactories(
  contractName: string,
  strategyName: string,
  version: string,
  args: any = []
): Promise<string|Addressable> {

  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY as string);

  const deploymentIo = new Deployments(chainId, contractName);
 
  const fileName = contractName.toLowerCase();
  const deployments = new Deployments(chainId, fileName);
  const alloAddress = deployments.getAllo();

  console.log(`
    ////////////////////////////////////////////////////
        Deploys ${contractName}.sol on ${networkName}
    ////////////////////////////////////////////////////`
  );

  console.table({
    contract: `Deploy ${contractName}.sol`,
    strategyName: strategyName,
    version: version,
    args: args,
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress.address,
  });

  console.log(`Deploying ${contractName}.sol...`);

  const deployer = new Deployer(hre, deployerAddress);
  const artifact = await deployer.loadArtifact(
    contractName
  );

  const strategyNameWithVersion = strategyName + version;

  const instance = await deployer.deploy(artifact, [alloAddress, strategyNameWithVersion, ...args]);
  const CONTRACT_ADDRESS = await instance.getAddress();

  console.log(`${artifact.contractName} was deployed to ${CONTRACT_ADDRESS}`);

  const objToWrite = {
    name: strategyName,
    version: version,
    address: instance.target,
    deployerAddress: deployerAddress.address,
  };

  deploymentIo.write(objToWrite);

  await verifyContract(CONTRACT_ADDRESS, [alloAddress, strategyNameWithVersion, ...args]);

  return instance.target;
}