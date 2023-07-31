// NOTE: Update this file anytime a new Registry is deployed.

type RegistryConfig = {
  registry: string;
  owner: string;
};

type DeployParams = Record<number, RegistryConfig>;

// NOTE: This will be the owner address for each registy on each network.
export const registryConfig: DeployParams = {
  11155111: {
    registry: "0xD8471D139e1DBceC97eD14BD69bDF8001d28F6Fa",
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
};
