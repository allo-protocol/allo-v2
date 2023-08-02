// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./NFT.sol";

contract NFTFactory {
    mapping(address => bool) public isNFTContract;

    event NFTContractCreated(address nftContractAddress);

    function createNFTContract(string memory name, string memory symbol, uint256 price) external {
        NFT nft = new NFT(
            name,
            symbol,
            price
        );

        isNFTContract[address(nft)] = true;

        emit NFTContractCreated(address(nft));
    }
}
