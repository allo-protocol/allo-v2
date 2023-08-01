import hre, { ethers, upgrades } from "hardhat";
import { confirmContinue, prettyNum } from "../utils/script-utils";

async function upgradeAllo() {
    const network = await ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    let account;
    let accountAddress;
    const blocksToWait = hre.network.name === "localhost" ? 0 : 10;

    account = (await ethers.getSigners())[0];
    accountAddress = await account.getAddress();
    const balance = await ethers.provider.getBalance(accountAddress);

    console.log(`This script upgrades the Allo contract on ${networkName}`);

    const PROXY_ADDRESS = "0x174b26eD4DF62A21189fF498834DE05077531EBD";

    await confirmContinue({
        contract: "Upgrading Allo",
        chainId: network.chainId,
        network: network.name,
        account: accountAddress,
        balance: prettyNum(balance.toString()),
        proxyAddress: PROXY_ADDRESS,
      });

    console.log("Upgrading Allo...");

    const AlloV2 = await ethers.getContractFactory("Allo", account);
    const instance = await upgrades.upgradeProxy(PROXY_ADDRESS, AlloV2);
    // console.log("tx hash", instance.deployTransaction);
    // await instance.deployed(blocksToWait);

    // const gas = await instance.deployTransaction.estimateGas();
    // console.log(`gas used: ${gas}`)

    console.log("Allo upgraded");
}

upgradeAllo().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/upgradeAllo.ts --network sepolia