import hre, { ethers } from "hardhat";
import { confirmContinue, prettyNum } from "../utils/script-utils";
import { alloConfig } from "../config/allo.config";
import { AbiCoder, concat, hexlify, toUtf8Bytes } from "ethers";
import { deployerAddress } from "../config/strategies.config";

export async function deployStrategies(strategyName: string, version: string) {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const contractDeployer = await account.getAddress();
  const blocksToWait = networkName === "localhost" ? 0 : 5;
  const balance = await ethers.provider.getBalance(contractDeployer);

  console.log(`
    ////////////////////////////////////////////////////
            Deploys ${strategyName}.sol on ${networkName}
    ////////////////////////////////////////////////////`);

  await confirmContinue({
    contract: `${strategyName}.sol`,
    chainId: chainId,
    network: networkName,
    deployerAddress: contractDeployer,
    balance: prettyNum(balance.toString()),
  });

  console.log(`Deploy ${strategyName}.sol`);

  // get deployer address
  const Deployer = await ethers.getContractFactory("Deployer");
  const deployer = Deployer.attach(deployerAddress[chainId].address);

  // deploy strategy

  var deployCode: string = "";

  try {
    const Strategy = await ethers.getContractFactory(strategyName);
    //get bytecode of strategy
    deployCode = Strategy.bytecode;

    const allo = alloConfig[chainId].allo;
    const name = strategyName + version;

    //abi.encodePacked(creationCode, abi.encode(address(allo), "TestStrategy"))

    const encodedCreationCode = hexlify(toUtf8Bytes(deployCode));

    const encodedParams = (new AbiCoder()).encode(
      ["address", "string"],
      [allo, name],
    );

    // Combine the encoded parameters
    deployCode = hexlify(
      concat([encodedCreationCode, encodedParams]),
    );
  } catch (error) {
    console.log("Strategy name not found.");
  }

  console.log("Deployer Address: ", await deployer.getAddress());
 
  try {

    console.log(" deployCode: ", deployCode)
    const strategyAddress = await deployer["deploy(string,string,bytes)"](
      strategyName,
      version,
      deployCode,
    );

    console.log(`${strategyName} deployed to:`, strategyAddress);
  } catch (error) {

    console.log("Deployment error: ", error);
  }

}

// deployStrategies().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployStrategies.ts --network sepolia
