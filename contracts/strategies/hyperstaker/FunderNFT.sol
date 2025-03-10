// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Basic NFT Contract
/// @notice A simple ERC721 implementation with minting functionality.
contract FunderNFT is ERC721, Ownable {
    uint256 public tokenCounter;

    /// @notice Constructor to set the name and symbol of the NFT collection.
    constructor() ERC721("FunderNFT", "BNFT") {
        tokenCounter = 0;
    }

    /// @notice Function to mint a new NFT.
    /// @param to The address to mint the NFT to.
    /// @param tokenId The token ID for the newly minted NFT.
    function mint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    /// @notice Mint an NFT and auto-increment the token ID.
    /// @param to The address to mint the NFT to.
    function mintAuto(address to) public onlyOwner {
        _safeMint(to, tokenCounter);
        tokenCounter++;
    }

    /// @notice Override function to get the base URI for metadata (if required).
    /// @return Base URI as a string.
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://example.com/api/token/";
    }
}
