// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @notice This contract contains all the addresses of the contracts used in the Allo V2 system
/// @dev This contract is used to make it easier to create test data using the Allo V2 contracts
contract Config {
    address public constant ALLO = 0x79536CC062EE8FAFA7A19a5fa07783BD7F792206;

    address public constant REGISTRY = 0xAEc621EC8D9dE4B524f4864791171045d6BBBe27;

    address public constant DONATIONVOTINGMERKLEPAYOUTSTRATEGYFORCLONE = 0xC88612a4541A28c221F3d03b6Cf326dCFC557C4E;

    address public constant OWNER = 0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42;

    // TODO: update this when we deploy new strategy/strategies
    address public constant DONATIONVOTINGMERKLEPAYOUTSTRATEGY = 0x99A8006096D151c030A9FC7576E168B41092099E;

    /// @notice This is a test profile ID
    bytes32 public constant TEST_PROFILE_1 = 0x2b4a116a803067abc982458913a2eac20b9348777dbe9795bf3b1aa522160415;

    /// @notice This is a test pool ID
    uint256 public constant TEST_POOL_1 = 44;

    /// @notice This is a test recipient ID
    address public constant TEST_RECIPIENT_ID_1 = 0xa671616e3580D3611139834Cd34D7838e82A04cD;
    address public constant TEST_RECIPIENT_ID_2 = 0xa671616e3580D3611139834Cd34D7838e82A04cD;
}
