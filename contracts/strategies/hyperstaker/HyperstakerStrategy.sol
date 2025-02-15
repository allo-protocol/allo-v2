// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {BaseStrategy} from "../BaseStrategy.sol";
import {IAllo} from "../../core/interfaces/IAllo.sol";
import "./FunderNFT.sol";  // Importing your custom FunderNFT contract

contract HyperstakerStrategy is BaseStrategy {
    
    FunderNFT public nftContract;  // Reference to the FunderNFT contract

    /// @dev Example of an event for tracking minted NFTs (optional)
    event NFTMinted(address indexed contributor, uint256 indexed poolId);
    
    /// @notice Constructor to set the Allo contract, strategy name, and NFT contract address.
    /// @param _allo The address of the Allo contract
    /// @param _name The name of the strategy
    /// @param _nftContract The address of the deployed NFT contract
    constructor(address _allo, string memory _name, address _nftContract) BaseStrategy(_allo, _name) {
        nftContract = FunderNFT(_nftContract);  // Initialize with the NFT contract address
    }

    /// @notice Initialize function from IStrategy that needs to be implemented.
    /// @param _poolId ID of the pool to initialize
    /// @ param _data Additional initialization data (not used, hence commented out)
    function initialize(uint256 _poolId, bytes memory /* _data */) external override {
        __BaseStrategy_init(_poolId);  // Call the internal base strategy initializer
        // Additional custom initialization logic can go here, if needed
    }

    /// @notice Override _afterIncreasePoolAmount to mint NFT after the pool is funded.
    /// @ param _amount The amount by which the pool is increased (not used, hence commented out)
    function _afterIncreasePoolAmount(uint256 /* _amount */) internal override {
        // Mint an NFT to the contributor (msg.sender is the contributor)
        nftContract.mintAuto(msg.sender);  // Mint function from FunderNFT contract
        
        // Emit an event to signal that the NFT has been minted (optional)
        emit NFTMinted(msg.sender, poolId);
    }

    function _isValidAllocator(address /* _allocator */) internal pure override returns (bool) {
        // Custom logic for allocator validation, currently allowing any allocator
        return true;
    }

    function _registerRecipient(bytes memory /* _data */, address /* _sender */) internal pure override returns (address) {
        // Custom logic to register a recipient, return a placeholder address
        return address(0);
    }

    function _allocate(bytes memory /* _data */, address /* _sender */) internal pure override {
        // Custom logic for allocation, nothing implemented yet
    }

    function _distribute(address[] memory /* _recipientIds */, bytes memory /* _data */, address /* _sender */) internal pure override {
        // Custom distribution logic, nothing implemented yet
    }

    function _getPayout(address _recipientId, bytes memory _data) internal pure override returns (PayoutSummary memory) {
        uint256 payoutAmount = abi.decode(_data, (uint256));
        return PayoutSummary({recipientAddress: _recipientId, amount: payoutAmount});
    }

    function _getRecipientStatus(address /* _recipientId */) internal pure override returns (Status) {
        return Status.Accepted; // Example status
    }
}
