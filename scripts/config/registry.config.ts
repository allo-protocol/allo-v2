// NOTE: Update this file anytime a new Registry is deployed.

type RegistryConfig = {
  registryImplementation: string;
  registryProxy: string;
  owner: string;
};

type DeployParams = Record<number, RegistryConfig>;

// NOTE: This will be the owner address for each registy on each network.
export const registryConfig: DeployParams = {
  // Mainnet
  1: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // Goerli
  5: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // Sepolia
  11155111: {
    registryImplementation: "0xa850B156d256Ba38C56E62C84421218b27B82031",
    registryProxy: "0xC5CcdcF78a8a789Ef0DfEcD6f3126D3b91D48fe5",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // PGN
  424: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // PGN Sepolia
  58008: {
    registryImplementation: "0xa850B156d256Ba38C56E62C84421218b27B82031",
    registryProxy: "0xC5CcdcF78a8a789Ef0DfEcD6f3126D3b91D48fe5",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // Optimism
  10: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // Optimism Goerli
  420: {
    registryImplementation: "0xa850B156d256Ba38C56E62C84421218b27B82031",
    registryProxy: "0xC5CcdcF78a8a789Ef0DfEcD6f3126D3b91D48fe5",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // Fantom
  250: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // Fantom Testnet
  4002: {
    registryImplementation: "0xa850b156d256ba38c56e62c84421218b27b82031",
    registryProxy: "0xfF65C1D4432D23C45b0730DaeCd03b6B92cd074a",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // Celo Mainnet
  42220: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // Celo Testnet Alfajores
  44787: {
    registryImplementation: "0xa850B156d256Ba38C56E62C84421218b27B82031",
    registryProxy: "0xC5CcdcF78a8a789Ef0DfEcD6f3126D3b91D48fe5",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // zkSync-testnet
  280: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
  // zkSync-mainnet
  324: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
  },
};
