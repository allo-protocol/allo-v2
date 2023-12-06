import { hexValue } from "@ethersproject/bytes";
import { parseEther } from "@ethersproject/units";
import { AbiCoder } from "ethers";
import hre, { ethers, network } from "hardhat";

const HOST_ADDR = "0x4E583d9390082B65Bef884b629DFA426114CED6d"; // mainnet host addr
const HOST_ABI = ["function getGovernance() external view returns (address)"];
const GOV_II_ABI = [
  "function setConfig(address host, address superToken, bytes32 key, uint256 value) external",
  "function setAppRegistrationKey(address host, address deployer, string memory registrationKey, uint256 expirationTs) external",
  "function getConfigAsUint256(address host, address superToken, bytes32 key) external view returns (uint256 value)",
  "function verifyAppRegistrationKey(address host, address deployer, string memory registrationKey) external view returns (bool validNow, uint256 expirationTs)",
  "function owner() public view returns (address)",
];
const encoder = new AbiCoder();

function getHost(hostAddr: string, providerOrSigner: any) {
  const hostInstance = new ethers.Contract(
    hostAddr,
    HOST_ABI,
    providerOrSigner
  );

  return hostInstance;
}

function getGovernance(govAddr: any, providerOrSigner: any) {
  const govInstance = new ethers.Contract(
    govAddr,
    GOV_II_ABI,
    providerOrSigner
  );

  return govInstance;
}

async function impersonate(addr: any) {
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [addr],
  });

  await network.provider.send("hardhat_setBalance", [
    addr,
    hexValue(parseEther("1000000")),
  ]);

  return await ethers.getSigner(addr);
}

function getConfigKey(deployerAddr: any, registrationKey: string) {
  return ethers.keccak256(
    encoder.encode(
      ["string", "address", "string"],
      [
        "org.superfluid-finance.superfluid.appWhiteListing.registrationKey",
        deployerAddr,
        registrationKey,
      ]
    )
  );
}

async function setRegistrationKey(
  hostAddr: string,
  govAddr: any,
  govOwnerAddr: any,
  deployerAddr: any
) {
  console.log("impersonating", govOwnerAddr);
  // impersonate the contract owner so we can modify things (also funds it with some balance)
  const govOwnerSigner = await impersonate(govOwnerAddr);

  console.log("retrieving the governance");
  // get the superfluid governance instance
  const govInstance = getGovernance(govAddr, govOwnerSigner);

  console.log("generating the key");
  // generate a registration key, and pack it up
  const registrationKey = `GM-${Date.now()}`;
  const configKey = getConfigKey(deployerAddr, registrationKey);
  let tx = await govInstance.setConfig(
    hostAddr,
    "0x0000000000000000000000000000000000000000",
    configKey,
    Math.floor(Date.now() / 1000) + 3600 * 24 * 180 // 180 day expiration
  );
  await tx.wait();

  return registrationKey;
}

async function checkRegistrationKey(
  hostAddr: string,
  govAddr: any,
  govOwnerAddr: any,
  deployerAddr: any,
  registrationKey: string
) {
  const govOwnerSigner = await impersonate(govOwnerAddr);
  const govInstance = getGovernance(govAddr, govOwnerSigner);

  const configKey = getConfigKey(deployerAddr, registrationKey);
  let r = await govInstance.getConfigAsUint256(
    hostAddr,
    "0x0000000000000000000000000000000000000000",
    configKey
  );

  return r;
}

// ----------------------------------------------------------------------------
// THE MAINOOOOOOOOOOOOR
// ----------------------------------------------------------------------------

// npx hardhat node --fork <rpc>
// npx hardhat run --network localhost scripts/deploy-my-super-app.js
async function main() {
  const network = await hre.ethers.provider.getNetwork();
  console.log("in network", network.name, network.chainId);

  const signer = await hre.ethers.provider.getSigner();
  const signerAddr = await signer.getAddress();
  console.log("deploying with signer", signerAddr);

  const hostInstance = getHost(HOST_ADDR, signer);
  const govAddr = await hostInstance.getGovernance();
  const govInstance = getGovernance(govAddr, signer);
  const govOwnerAddr = await govInstance.owner();

  console.log("setting the registration key");
  const registrationKey = await setRegistrationKey(
    HOST_ADDR,
    govAddr,
    govOwnerAddr,
    signerAddr
  );
  console.log("registration key", registrationKey);

  console.log("checking the registration key");
  const r = await checkRegistrationKey(
    HOST_ADDR,
    govAddr,
    govOwnerAddr,
    signerAddr,
    registrationKey
  );
  console.log(r);

  const factory = await hre.ethers.getContractFactory("MySuperApp");
  const mySuperApp = await factory.deploy(HOST_ADDR, registrationKey);
  await mySuperApp.deployed();
  console.log("MySuperApp contract deployed to", mySuperApp.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
