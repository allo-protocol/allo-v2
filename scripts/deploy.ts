import { ethers, upgrades } from "hardhat";
import { prettyNum } from "../test/utils/utils";

async function main() {
  
    // Contracts are deployed using the first signer/account by default
    // const [owner, otherAccount] = await ethers.getSigners();

    const Registry = await ethers.getContractFactory("Registry");
    const registry = await upgrades.deployProxy(Registry, []);
    console.log("tx hash", registry.deployTransaction.hash);
    await registry.deployed();

    const rec = await registry.deployTransaction.wait();
    const gas = prettyNum(rec.gasUsed.toString());
    console.log(`gas used: ${gas}`)

    console.log("Registry deployed to:", registry.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
