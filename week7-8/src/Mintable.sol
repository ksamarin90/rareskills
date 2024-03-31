// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Token3.sol";

contract MintableToken is Token3 {
    uint256 public totalMinted;
    uint256 public totalMintable;

    constructor(uint256 totalMintable_) {
        totalMintable = totalMintable_;
    }

    function mint(uint256 value) public onlyOwner {
        require(value + totalMinted < totalMintable);
        totalMinted += value;

        balances[msg.sender] += value;
    }
}
