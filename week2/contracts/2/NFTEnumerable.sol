// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "hardhat/console.sol";

contract NFTEnumerable is ERC721Enumerable {
    constructor() ERC721("NFTEnumerable", "NFTE") {
        for (uint256 i = 1; i <= 20; ) {
            _mint(msg.sender, i);
            unchecked {
                i++;
            }
        }
    }
}
