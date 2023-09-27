// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @notice This contract contains all the addresses of the contracts used in the Allo V2 system
/// @dev This contract is used to make it easier to create test data using the Allo V2 contracts
/// 🚨🚨 THIS IS ONLY FOR GOERLI TESTNET 🚨🚨
contract GoerliConfig {
    address public constant ALLO = 0xbb6B237a98D907b04682D8567F4a8d0b4b611a3b;

    address public constant REGISTRY = 0xBC23124Ed2655A1579291f7ADDE581fF18327D41;

    address public constant DONATIONVOTINGMERKLEPAYOUTSTRATEGYFORCLONE = 0x81Abcb682cc61c463Cdbe1Ef1804CbEfC1d54d7f;
    address public constant RFPSIMPLESTRATEGYFORCLONE = 0x03FA47235fAF670c72dD765A4eE55Bd332308029;
    address public constant RFPCOMMITTEESTRATEGYFORCLONE = 0x9DB5B54a4f63124428e293b37A81D4e3bcC2F222;
    address public constant DIRECTGRANTSSIMPLETESTRATEGYFORCLONE = 0x4a41F242cA053DB83F7D45C92a3757fb94bD65A8;
    address public constant DONATIONVOTINGDIRECTPAYOUTSTRATEGYFORCLONE = 0x8253782db9cA148A07c19ca36A4fA0D02f45A2ca;
    address public constant DONATIONVOTINGVAULTSTRATEGYFORCLONE = 0xB42C26e4029e932CDd53981f7CbefF89e74F03c2;

    address public constant OWNER = 0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42;

    // TODO: update this when we deploy new strategy/strategies
    address public constant DONATIONVOTINGMERKLEPAYOUTSTRATEGY = 0x4De257724d3896Ef3a5E60E41B2Ad602E1D43736;
    address public constant RFPSIMPLESTRATEGY = 0x99A8006096D151c030A9FC7576E168B41092099E;
    // address public constant RFPCOMMITTEESTRATEGY = ;
    // address public constant DIRECTGRANTSSIMPLETESTRATEGY = ;
    // address public constant DONATIONVOTINGDIRECTPAYOUTSTRATEGY = ;
    // address public constant DONATIONVOTINGVAULTSTRATEGY = ;

    /// @notice This is a test profile ID
    bytes32 public constant TEST_PROFILE_1 = 0x844b425d3f8e8348bda70374acf679c3d94eac5fcacde608cfca77acb2a11614;
    bytes32 public constant TEST_PROFILE_2 = 0x5F8F7EF300B0E8FE0417371A068B217C49BB7235E87CCE1E53F55717F3933BD3;

    /// @notice This is a test pool ID
    uint256 public constant TEST_POOL_1 = 1;

    /// @notice This is a test recipient ID
    address public constant TEST_RECIPIENT_ID_1 = 0xa671616e3580D3611139834Cd34D7838e82A04cD;
    address public constant TEST_RECIPIENT_ID_2 = 0xa671616e3580D3611139834Cd34D7838e82A04cD;

    /// @notice This is a test metadata pointer for protocol 1
    string public constant TEST_METADATA_POINTER_1 = "bafybeif43xtcb7zfd6lx7rfq42wjvpkbqgoo7qxrczbj4j4iwfl5aaqv2q";
}
