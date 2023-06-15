import { ethers, upgrades } from "hardhat";
import { prettyNum } from "./utils/utils";

describe("Registry", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployRegistryContract() {

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Registry = await ethers.getContractFactory("Registry");
    const registry = await upgrades.deployProxy(Registry, []);
    console.log("tx hash", registry.deployTransaction.hash);
    await registry.deployed();

    const rec = await registry.deployTransaction.wait();
    const gas = prettyNum(rec.gasUsed.toString());
    console.log(`gas used: ${gas}`)

    console.log("Registry deployed to:", registry.address);

    return { registry, owner, otherAccount };
  }

  describe("Deployment", function () {
    const data = deployRegistryContract();

    console.log(data);
  });
});