import hre, { ethers, upgrades } from "hardhat";
import { alloConfig } from "../config/allo.config";
import { confirmContinue, prettyNum } from "../utils/script-utils";

async function deployCore() {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;

  console.log(`%cThis script deploys Allo V2 onto ${networkName}`, "color: white; background-color: #26bfa5;font-size: 20px");
}

deployCore().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});