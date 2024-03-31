// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Dex} from "./Dex.sol";

contract DexWrapper is Dex {
    constructor() Dex() {}

    function swap(bool direct, uint amount) public {
        (address tokenA, address tokenB) = direct ? (token1, token2) : (token2, token1);
        super.swap(tokenA, tokenB, amount);
    }
}
