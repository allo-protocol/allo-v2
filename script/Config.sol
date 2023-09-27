// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @notice This contract contains all the addresses of the contracts used in the Allo V2 system
/// @dev This contract is used to make it easier to create test data using the Allo V2 contracts
contract Config {
    address public constant ALLO = 0xbb6B237a98D907b04682D8567F4a8d0b4b611a3b;

    address public constant REGISTRY = 0xBC23124Ed2655A1579291f7ADDE581fF18327D41;

    address public constant DONATIONVOTINGMERKLEPAYOUTSTRATEGYFORCLONE = 0x81Abcb682cc61c463Cdbe1Ef1804CbEfC1d54d7f;

    address public constant OWNER = 0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42;

    // TODO: update this when we deploy new strategy/strategies
    address public constant DONATIONVOTINGMERKLEPAYOUTSTRATEGY = 0x99A8006096D151c030A9FC7576E168B41092099E;

    // FIXME: this is not the right address
    address public constant RFPSIMPLESTRATEGY = 0x99A8006096D151c030A9FC7576E168B41092099E;

    /// @notice This is a test profile ID
    bytes32 public constant TEST_PROFILE_1 = 0x844b425d3f8e8348bda70374acf679c3d94eac5fcacde608cfca77acb2a11614;

    /// @notice This is a test pool ID
    uint256 public constant TEST_POOL_1 = 44;

    /// @notice This is a test recipient ID
    address public constant TEST_RECIPIENT_ID_1 = 0xa671616e3580D3611139834Cd34D7838e82A04cD;
    address public constant TEST_RECIPIENT_ID_2 = 0xa671616e3580D3611139834Cd34D7838e82A04cD;

    /// @notice This is a test metadata pointer for protocol 1
    string public constant TEST_METADATA_POINTER_1 = "bafybeif43xtcb7zfd6lx7rfq42wjvpkbqgoo7qxrczbj4j4iwfl5aaqv2q";
}
