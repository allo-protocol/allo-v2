
import { ethers, upgrades } from "hardhat";
import { prettyNum } from "../test/hardhat/utils/utils";

async function main() {

  // Contracts are deployed using the first signer/account by default
  // const [owner, otherAccount] = await ethers.getSigners();
  const account = (await ethers.getSigners())[0];

  console.log("Deploying ProjectRegistry...");

  const Registry = await ethers.getContractFactory("Registry", account);
  const instance = await upgrades.deployProxy(Registry, []);
  console.log("tx hash", instance.deployTransaction.hash);
  await instance.deployed();

  const rec = await instance.deployTransaction.wait();
  const gas = prettyNum(rec.gasUsed.toString());
  console.log(`gas used: ${gas}`)

  console.log("ProjectRegistry deployed to:", instance.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
