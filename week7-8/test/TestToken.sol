// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Token} from "../src/Token.sol";

contract TestToken is Token {
    address echidna = tx.origin;

    constructor() {
        balances[echidna] = 10_000;
    }

    function echidna_test_balance() public view returns (bool) {
        return balances[echidna] <= 10_000;
    }

    function transfer(address to, uint256 value) public override {
        if (to == echidna) {
            revert("Echidna");
        }
        super.transfer(to, value);
    }
}
