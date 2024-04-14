// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Denial} from "../src/Denial.sol";
import {DenialAttacker} from "../src/DenialAttacker.sol";

contract DenialTest is Test {
    Denial public denial;
    DenialAttacker public denialAttacker;

    function setUp() public {
        denial = new Denial();
        deal(address(denial), 100 ether);
        denialAttacker = new DenialAttacker(denial);
    }

    function test_Deny() public {
        address owner = denial.owner();

        denial.setWithdrawPartner(address(denialAttacker));

        vm.expectRevert();
        vm.startPrank(owner);
        denial.withdraw{gas: 1000_000}();
        vm.stopPrank();
    }
}
