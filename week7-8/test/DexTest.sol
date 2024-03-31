// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Dex} from "../src/Dex.sol";
import {ERC20Test} from "../src/ERC20Test.sol";

contract DexTest is Dex {
    Dex public dex;

    constructor() {
        dex = new Dex();
        ERC20Test token1_ = new ERC20Test("token1", "t1");
        ERC20Test token2_ = new ERC20Test("token2", "t2");
        dex.setTokens(address(token1_), address(token2_));
        dex.addLiquidity(address(token1_), 100 * (10 ** token1_.decimals()));
        dex.addLiquidity(address(token2_), 100 * (10 ** token2_.decimals()));
        token1_.transfer(msg.sender, 10 * (10 ** token1_.decimals()));
        token2_.transfer(msg.sender, 10 * (10 ** token2_.decimals()));
    }

    function echidna_price_is_bad() public view returns (bool) {
        return dex.getSwapPrice(token1, token2, 10 * (10 ** ERC20Test(token1).decimals())) > 0;
    }
}
