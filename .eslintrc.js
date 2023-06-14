module.exports = {
    env: {
      browser: false,
      es2021: true,
      mocha: true,
      node: true,
    },
    plugins: ["@typescript-eslint", "no-only-tests"],
    extends: ["plugin:node/recommended"],
    parser: "@typescript-eslint/parser",
    parserOptions: {
      ecmaVersion: 12,
      project: ["./tsconfig.json"]
    },
    rules: {
      "node/no-unsupported-features/es-syntax": [
        "error",
        {ignores: ["modules"]},
      ],
      "no-only-tests/no-only-tests": "error",
      "no-unused-vars": ["off", {varsIgnorePattern: "_"}],
      "no-prototype-builtins": ["off"],
      "node/no-missing-import": ["off"],
      "no-unused-expressions": ["off"],
    },
  };
  
