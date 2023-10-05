// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @notice This contract contains all the addresses of the contracts used in the Allo V2 system
/// @dev This contract is used to make it easier to create test data using the Allo V2 contracts
/// 🚨🚨 THIS IS ONLY FOR GOERLI TESTNET 🚨🚨
contract GoerliConfig {
    address public constant ALLO = 0xbb6B237a98D907b04682D8567F4a8d0b4b611a3b;

    address public constant REGISTRY = 0xBC23124Ed2655A1579291f7ADDE581fF18327D41;

    address public constant DONATIONVOTINGSTRATEGY = 0x81Abcb682cc61c463Cdbe1Ef1804CbEfC1d54d7f;
    address public constant DONATIONVOTINGMERKLEPAYOUTSTRATEGYFORCLONE = 0x81Abcb682cc61c463Cdbe1Ef1804CbEfC1d54d7f;
    address public constant RFPSIMPLESTRATEGYFORCLONE = 0x03FA47235fAF670c72dD765A4eE55Bd332308029;
    address public constant RFPCOMMITTEESTRATEGYFORCLONE = 0x9DB5B54a4f63124428e293b37A81D4e3bcC2F222;
    address public constant DIRECTGRANTSSIMPLETESTRATEGYFORCLONE = 0x4a41F242cA053DB83F7D45C92a3757fb94bD65A8;
    address public constant DONATIONVOTINGDIRECTPAYOUTSTRATEGYFORCLONE = 0x8253782db9cA148A07c19ca36A4fA0D02f45A2ca;
    address public constant DONATIONVOTINGVAULTSTRATEGYFORCLONE = 0xB42C26e4029e932CDd53981f7CbefF89e74F03c2;
    address public constant IMPACTSTREAMFORCLONE = 0x7Bb23D29BA83D92EACD99e17B32a2794A1A10cdd;

    address public constant OWNER = 0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42;

    // TODO: update this when we deploy new strategy/strategies
    address public constant DONATIONVOTISTRATEGY = 0xDecE8A9aEc94106CDfe652685243E6eB48fd50A1;
    address public constant DONATIONVOTINGMERKLEPAYOUTSTRATEGY = 0x4De257724d3896Ef3a5E60E41B2Ad602E1D43736;
    address public constant RFPSIMPLESTRATEGY = 0x221cfd45Fa6e658c2a6F83b7eBaf8237F4c29F37;
    address public constant IMPACTSTREAM = 0xeD43bb94803B60Eb93226701b143e9Dc017af199;
    // address public constant RFPCOMMITTEESTRATEGY = ;
    // address public constant DIRECTGRANTSSIMPLETESTRATEGY = ;
    // address public constant DONATIONVOTINGDIRECTPAYOUTSTRATEGY = ;
    // address public constant DONATIONVOTINGVAULTSTRATEGY = ;

    /// @notice This is a test profile ID
    bytes32 public constant TEST_PROFILE_1 = 0x844b425d3f8e8348bda70374acf679c3d94eac5fcacde608cfca77acb2a11614;
    bytes32 public constant TEST_PROFILE_2 = 0x5F8F7EF300B0E8FE0417371A068B217C49BB7235E87CCE1E53F55717F3933BD3;

    bytes32 public constant POOL_CREATOR_PROFILE_ID = 0x9d70efa6f5bb7f502cb45f2c2a4558a1c909c4c0fbb7db7abbae58e7074f1ec0;
    address public constant POOL_CREATOR_ANCHOR_ID = 0x16a200b50ebE50b7fcd347D9B33329dD77612D92;

    bytes32 public constant RECIPIENT_PROFILE_ID = 0xba623a1db131a7aed2eea599053007537d4308e3d6145c94ba1242f255d80859;
    address public constant RECIPIENT_ANCHOR_ID = 0x27a3528fA5aA9175F94C651be8Bcf75Ad3AF0bF4;

    /// @notice This is a test pool ID
    // 1 = DonationVotingStrategy
    // 6 = DirectGrantsSimpleStrategy
    // 9 = RFPSimpleStrategy (10e18, true, true)
    // 12 = DonationVotingStrategy
    // 13 = RFPSimpleStrategy (10e18, false, false)
    // 14 = ImpactStreamStrategy
    uint256 public constant TEST_POOL_1 = 16;

    /// @notice This is a test recipient ID
    address public constant TEST_RECIPIENT_ID_1 = 0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42;
    address public constant TEST_RECIPIENT_ID_2 = 0x017259e809a74A8c81aD4db516D040bB85d7C358;

    /// @notice This is a test metadata pointer for protocol 1
    string public constant TEST_METADATA_POINTER_1 = "bafybeif43xtcb7zfd6lx7rfq42wjvpkbqgoo7qxrczbj4j4iwfl5aaqv2q";
}
