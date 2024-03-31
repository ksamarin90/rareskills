// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {DexWrapper} from "../src/DexWrapper.sol";
import {ERC20Test} from "../src/ERC20Test.sol";

contract DexTest {
    DexWrapper public dex;
    address user;

    constructor() {
        user = msg.sender;
        dex = new DexWrapper();
        ERC20Test token1_ = new ERC20Test("token1", "t1");
        ERC20Test token2_ = new ERC20Test("token2", "t2");
        dex.setTokens(address(token1_), address(token2_));
        token1_.approve(address(dex), type(uint256).max);
        token2_.approve(address(dex), type(uint256).max);
        dex.addLiquidity(address(token1_), 100);
        dex.addLiquidity(address(token2_), 100);
        token1_.transfer(msg.sender, 10);
        token2_.transfer(msg.sender, 10);
    }

    function echidna_price_is_bad() public view returns (bool) {
        uint256 dexBalance1 = dex.balanceOf(dex.token1(), address(dex));
        uint256 dexBalance2 = dex.balanceOf(dex.token2(), address(dex));
        return dexBalance1 + dexBalance2 >= 200;
    }

    // fuzzer found that there is a logical error in getSwapPrice function
    // repetitive swapping here and back results in lost of funds
    // the greater the swap the quicker funds can be drained

    // 100 - 100 | k = 10000
    // swapping 10 here and back

    // without k
    // 110 - 90
    // 98 - 100

    // with k
    // 110 - 91 | k = 10010
    // 100 - 101 | k = 11000

    // swapping 10 here and back

    // without k
    // 150 - 50
    // 0 - 100

    // with k
    // 150 - 67 | 10050
    // 86 - 117 | 10062
}
