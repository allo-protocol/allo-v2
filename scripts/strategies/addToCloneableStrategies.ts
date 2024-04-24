import hre, { ethers } from "hardhat";
import {
  Deployments,
} from "../utils/scripts";
import { sign } from "crypto";

export async function addToCloneableStrategies() {
  const STRATEGY_ADDRESS = "0x1CA26139eF51e754326bce8066DD335560E987D5";

  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(deployerAddress);

  const deployments = new Deployments(chainId, "allo");

  console.log(`
    //////////////////////////////////////////////////////////////////
    Add ${STRATEGY_ADDRESS} as clonable at Allo.sol on ${networkName}
    //////////////////////////////////////////////////////////////////
  `);

  const ABI = [
    "function addToCloneableStrategies(address _strategy)",
    "function isCloneableStrategy(address _strategy) view returns (bool)",
  ];
  
  const alloAddress = deployments.getAllo();

  console.table({
    contract: "Add to Cloneable Strategies",
    chainId: chainId,
    network: networkName,
    allo: alloAddress,
    strategy: STRATEGY_ADDRESS,
    deployerAddress: deployerAddress,
    balance: ethers.formatEther(balance),
  });

  console.log("Adding to cloneable..");

  const feeData = await ethers.provider.getFeeData();

  const Allo = await ethers.getContractFactory('Allo');
  const allo = await Allo.attach(alloAddress);

  await allo.addToCloneableStrategies(STRATEGY_ADDRESS,
    // {
    //   txOverrides: {
    //     maxFeePerGas: feeData.maxFeePerGas,
    //     maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
    //   }
    // }
  ).then(async () => {
    console.log("Added to cloneable.. Validating on chain");
    const isCloneableStrategy = await allo.isCloneableStrategy(STRATEGY_ADDRESS);
    console.log(`Is ${STRATEGY_ADDRESS} cloneable strategy:`, isCloneableStrategy);
  });

}

// Check if this script is the main module (being run directly)
if (require.main === module) {
  addToCloneableStrategies().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/strategies/addToCloneableStrategies.ts --network sepolia