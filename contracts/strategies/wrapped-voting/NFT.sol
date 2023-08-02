// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC721, Ownable {
    using Strings for uint256;

    error MintPriceNotPaid();
    error MaxSupply();
    error NonExistentTokenURI();
    error WithdrawTransfer();

    uint256 public currentTokenId;
    uint256 public MINT_PRICE;
    uint256 public constant TOTAL_SUPPLY = 10_000;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _price //price in wei
    ) ERC721(_name, _symbol) {
        MINT_PRICE = _price;
    }

    function safeMint(address to) public payable onlyOwner {
        if (msg.value != MINT_PRICE) {
            revert MintPriceNotPaid();
        }
        uint256 newTokenId = ++currentTokenId;
        if (newTokenId > TOTAL_SUPPLY) {
            revert MaxSupply();
        }
        _safeMint(to, newTokenId);
    }

    function tokenURI(uint256 tokenId) public pure override(ERC721) returns (string memory) {
        return string(abi.encodePacked(tokenId.toString()));
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx,) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }
}
