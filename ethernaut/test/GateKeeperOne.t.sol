// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GateKeeperOne} from "../src/GateKeeperOne.sol";
import {GateKeeperOneAttacker} from "../src/GateKeeperOneAttacker.sol";

contract GateKeeperOneTest is Test {
    GateKeeperOne public gate;
    GateKeeperOneAttacker public attacker;

    function setUp() public {
        gate = new GateKeeperOne();
        attacker = new GateKeeperOneAttacker(gate);
    }

    function test_attack() public {
        for (uint256 i = 100_000; i < 3_000_000; i++) {
            try attacker.attack{gas: i}() {
                assertEq(gate.entrant(), tx.origin);
                break;
            } catch (bytes memory reason) {}
        }
    }
}
