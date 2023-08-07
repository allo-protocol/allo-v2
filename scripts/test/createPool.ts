import hre, { ethers } from "hardhat";
import { alloConfig } from "../config/allo.config";
import { confirmContinue, prettyNum } from "../utils/script-utils";

export async function createPool() {

    const network = await ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

    const account = (await ethers.getSigners())[0];
    const deployerAddress = await account.getAddress();
    const blocksToWait = hre.network.name === "localhost" ? 0 : 5;

    const balance = await ethers.provider.getBalance(deployerAddress);

    const allo = alloConfig[chainId].allo;

    await confirmContinue({
        contract: "allo: create pool",
        chainId: chainId,
        network: networkName,
        deployerAddress: deployerAddress,
        allo: allo,
        balance: prettyNum(balance.toString())
    });

    console.log("Creating pool...");
    const instance = await ethers.getContractAt('Allo', allo);

    await instance.createPoolWithCustomStrategy({
        // profileId: ,
        // strategyId: ,
        // initStrategyData: ,
        // token: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
        // amount: 0,
        // metadata: {
        //     protocol: 1,
        //     pointer: "bafybeia4khbew3r2mkflyn7nzlvfzcb3qpfeftz5ivpzfwn77ollj47gqi"
        // },
        // managers: []
    });

    console.log("pool created at:", instance.target);
  
    return instance.target;
}

// createPool().catch((error) => {
//     console.error(error);
//     process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/createPool.ts --network sepolia