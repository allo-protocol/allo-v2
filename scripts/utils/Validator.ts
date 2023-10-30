import { Addressable } from "ethers";
import { ethers } from "hardhat";

export class Validator {
  contractName: string;
  contract: string;
  instanceFactory: any;
  instance: any;

  constructor(contractName: string, contract: string | Addressable) {
    this.contractName = contractName;
    this.contract = contract as string;

    return (async (): Promise<Validator> => {
      await this.init();
      return this;
    })() as unknown as Validator;
  }

  async init() {
    this.instanceFactory = await ethers.getContractFactory(this.contractName);
    this.instance = await this.instanceFactory.attach(this.contract);
  }

  public async validate(
    functionName: string,
    args: any[],
    expectedResult: string
  ) {
    logGray(`\n\tValidating ${functionName}(${args}) == ${expectedResult}`);
    try {
      const result = await this.instance[functionName](...args);
      if (result.toString().toLowerCase() === expectedResult.toLowerCase()) {
        logGreen(`\t✅ PASSED with Result: ${expectedResult}`);
      } else {
        logRed(`\t❌ FAILED with Result: ${result}`);
      }
    } catch (e) {
      logRed(`\t❌❌❌ FAILED with Error: ${e}`);
    }
  }
}

const logGreen = (msg: string) => {
  console.log("\x1b[32m%s\x1b[0m", msg);
};

const logRed = (msg: string) => {
  console.log("\x1b[31m%s\x1b[0m", msg);
};

const logGray = (msg: string) => {
  console.log("\x1b[90m%s\x1b[0m", msg);
};
