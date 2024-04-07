// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DoesNotWrite} from "../src/DoesNotWrite.sol";

contract DoesNotWriteTest is Test {
    DoesNotWrite public c;

    function setUp() public {
        c = new DoesNotWrite();
    }

    function test_write_to_storage() external {
        c.addElement(DoesNotWrite.Foo(1));
        c.addElement(DoesNotWrite.Foo(2));

        assertEq(c.getElement(0).bar, 1, "1");
        assertEq(c.getElement(1).bar, 2, "1");

        c.moveToSlot0();

        assertEq(c.getElement(0).bar, 2, "1");
    }
}
