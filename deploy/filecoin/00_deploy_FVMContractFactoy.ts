import * as dotenv from "dotenv";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import { ethers } from "hardhat";
import { Deployments } from "../../scripts/utils/scripts";

dotenv.config();

export default async ({ deployments }) => {
  const { deploy } = deployments;
  const networkName = "filecoin-calibration";
  const chainId = Number(314159);

  const deploymentIo = new Deployments(chainId, "contractFactory");

  console.log(`
    ////////////////////////////////////////////////////
        Deploys ContractFactory.sol on ${networkName}
    ////////////////////////////////////////////////////`);

  console.log("Deploying ContractFactory.sol...");

  // Filecoin Provider setup
  const provider = new ethers.JsonRpcProvider(
    "https://api.calibration.node.glif.io/rpc/v1"
  );

  const deployer = new ethers.Wallet(
    process.env.DEPLOYER_PRIVATE_KEY,
    ethers.provider
  );

  console.table({
    contract: "Deploy ContractFactory.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployer.address,
    balance: ethers.formatEther(await provider.getBalance(deployer.address)),
  });

  // Deploy ContractFactory.sol
  const ContractFactory = await deploy("ContractFactory", {
    from: deployer.address,
    args: [],
    log: true,
  });

  console.log("ContractFactory deployed to:", ContractFactory.address);
};