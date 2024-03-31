// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../src//Mintable.sol";

contract TestToken3 is MintableToken {
    address echidna = msg.sender;

    constructor() MintableToken(10_000) {}

    function echidna_test_balance() public view returns (bool) {
        return balances[echidna] <= 10_000;
    }
}
