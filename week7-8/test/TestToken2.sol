// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Token2} from "../src/Token2.sol";

contract TestToken2 is Token2 {
    constructor() {
        pause(); // pause the contract
        owner = address(0); // lose ownership
    }

    function echidna_cannot_be_unpause() public view returns (bool) {
        // TODO: add the property
        return paused();
    }
}
