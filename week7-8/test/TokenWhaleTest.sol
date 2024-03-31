// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../src/TokenWhale.sol";

contract TokenWhaleTest is TokenWhale {
    constructor() TokenWhale(msg.sender) {}

    function echidna_owner_minted_more() public view returns (bool) {
        return !isComplete();
    }
}
