/**
 * List of supported options: https://github.com/defi-wonderland/natspec-smells?tab=readme-ov-file#options
 */

/** @type {import('@defi-wonderland/natspec-smells').Config} */
module.exports = {
  include: [
    'contracts/(core|extensions)/**/*.sol',
    'contracts/strategies/*.sol',
  ],
  exclude: 'contracts/strategies/*/**.sol',
  enforceInheritdoc: false,
};