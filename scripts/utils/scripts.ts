import "dotenv/config";
import { run } from "hardhat";
import readline from "readline";

// --- User verification ---
// Helper method for waiting on user input. Source: https://stackoverflow.com/a/50890409
export async function waitForInput(query: string): Promise<unknown> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) =>
    rl.question(query, (ans) => {
      rl.close();
      resolve(ans);
    })
  );
}

export async function confirmContinue(params: Record<string, unknown>) {
  console.log("\nPARAMETERS");
  console.table(params);

  const response = await waitForInput("\nDo you want to continue? y/N\n");
  if (response !== "y")
    throw new Error("Aborting script: User chose to exit script");
  console.log("\n");
}

export const prettyNum = (_n: number | string) => {
  const n = _n.toString();
  let s = "";
  for (let i = 0; i < n.length; i++) {
    if (i != 0 && i % 3 == 0) {
      s = "_" + s;
    }

    s = n[n.length - 1 - i] + s;
  };

  return s;
}

export const verifyContract = async (contract: string, verifyArgs: string[]) => {
  console.log("Verifying contract...");
  try {
    await run("verify:verify", {
      address: contract,
      constructorArguments: verifyArgs,
    });

    console.log("Contract verified!");
  } catch (err) {
    console.log(err);
  }
};