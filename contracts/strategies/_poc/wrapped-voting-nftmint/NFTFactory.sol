// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./NFT.sol";

contract NFTFactory {
    mapping(address => bool) public isNFTContract;

    event NFTContractCreated(address nftContractAddress);

    function createNFTContract(string memory _name, string memory _symbol, uint256 _price, address _owner)
        external
        returns (address payable)
    {
        NFT nft = new NFT(_name, _symbol, _price, _owner);

        isNFTContract[address(nft)] = true;

        emit NFTContractCreated(address(nft));

        return payable(address(nft));
    }
}
