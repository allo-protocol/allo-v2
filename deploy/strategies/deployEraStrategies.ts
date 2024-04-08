import hre, { ethers } from "hardhat";
import { Validator } from "../../scripts/utils/Validator";
import { Args, deployContractUsingFactoryOnEra } from "../../scripts/utils/deployProxy";
import { Deployments, verifyContract } from "../../scripts/utils/scripts";
import { Wallet } from "zksync-ethers";

export async function deployEraStrategies(
  strategyName: string,
  version: string,
  additionalArgs?: Args,
): Promise<string> {
  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY as string);

  const fileName = strategyName.toLowerCase();
  const deployments = new Deployments(chainId, fileName);

  const alloAddress = deployments.getAllo();

  console.log(`
    ////////////////////////////////////////////////////
      Deploys ${strategyName}.sol on ${networkName}
    ////////////////////////////////////////////////////
  `);

  console.table({
    contract: `${strategyName}.sol`,
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress.address,
  });

  console.log(`Deploying ${strategyName}.sol`);

  const types = ["address", "string"].concat(additionalArgs?.types ?? []);
  const values = [alloAddress, strategyName + version].concat(
    additionalArgs?.values ?? [],
  );

  // TODO: UPDATE FOR ERA
  const impl = await deployContractUsingFactoryOnEra(
    deployments.getContractFactory(),
    strategyName,
    version,
    {
      types,
      values,
    },
  );

  const hashBytesStrategyName = ethers.keccak256(
    new ethers.AbiCoder().encode(["string"], [strategyName + version]),
  );

  const objToWrite = {
    id: hashBytesStrategyName,
    name: strategyName,
    version: version,
    address: impl.toString(),
    deployerAddress: deployerAddress.address,
  };

  deployments.write(objToWrite);

  await verifyContract(impl, [...values]);

  const validator = await new Validator(strategyName, impl);
  await validator.validate("getAllo", [], alloAddress);
  await validator.validate("getStrategyId", [], hashBytesStrategyName);

  return impl.toString();
}