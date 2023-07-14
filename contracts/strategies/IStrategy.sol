// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IStrategy {
    enum RecipientStatus {
        None,
        Pending,
        Accepted,
        Rejected
    }

    struct Payout {
        address payoutAddress;
        uint256 amount;
    }

    // the default BaseStrategy version will not use the data
    // if a strategy wants to use it, they will overwrite it, use it, and then call super.initialize()
    function initialize(bytes32 _identityId, uint256 _poolId, bytes memory _data) external;

    // this is used to check if balance in strategy is equal / lesser than pool.amount stored in Allo.sol
    // If it is greater, the difference will be split between the treasury and the msg.sender
    function skim(address token) external;

    // this is called via allo.sol to register recipients
    // it can change their status all the way to Accepted, or to Pending if there are more steps
    // if there are more steps, additional functions should be added to allow the owner to check
    // this could also check attestations directly and then Accept
    function registerRecipients(bytes memory _data, address _sender) external payable returns (address);

    // simply returns the status of a recipient
    // probably tracked in a mapping, but will depend on the implementation
    // for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those
    // since there is no need for Pending or Rejected
    function getRecipientStatus(address _recipientId) external view returns (RecipientStatus);

    // simply returns whether a voter is valid or not, will usually be true for all
    function isValidAllocater(address _allocator) external view returns (bool);

    // only called via allo.sol by users to allocate votes to a recipient
    // this will update some data in this contract to store votes, etc.
    function allocate(bytes memory _data, address _sender) external payable;

    // this will return the payout for recipients
    function getRecipientPayouts(address[] memory _recipientId, bytes memory _data)
        external
        view
        returns (Payout[] memory summaries);

    // this will distribute tokens to recipients
    // most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    // this contract will need to track the amount paid already, so that it doesn't double pay
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
}
