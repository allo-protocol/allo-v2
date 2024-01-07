// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC721} from "solady/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "solady/auth/Ownable.sol";

contract NFT is ERC721, Ownable {
    using Strings for uint256;

    error MintPriceNotPaid();
    error MaxSupply();
    error NonExistentTokenURI();
    error WithdrawTransfer();

    uint256 public currentTokenId;
    uint256 public MINT_PRICE;
    uint256 public constant TOTAL_SUPPLY = 5;

    string internal __name;
    string internal __symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _price, //price in wei
        address _owner
    ) {
        __name = _name;
        __symbol = _symbol;
        MINT_PRICE = _price;
        _initializeOwner(_owner);
    }

    function name() public view virtual override returns (string memory) {
        return __name;
    }

    function symbol() public view virtual override returns (string memory) {
        return __symbol;
    }

    function mintTo(address to) external payable {
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

    /// @notice Receive function
    receive() external payable {}
}
