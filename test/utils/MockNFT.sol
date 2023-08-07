// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC721} from "solady/src/tokens/ERC721.sol";

contract MockNFT is ERC721 {
    uint256 private _lastTokenId;

    constructor() {}

    function mintMultiple(address _to, uint256 _amount) public {
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_to, _lastTokenId++);
        }
    }

    function mint(address _to) public {
        _safeMint(_to, _lastTokenId++);
    }

    function name() public pure override returns (string memory) {
        return "Mock NFT";
    }

    function symbol() public pure override returns (string memory) {
        return "MNFT";
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }
}
