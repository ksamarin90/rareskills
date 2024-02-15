// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {OwnableERC20} from "./OwnableERC20.sol";

contract TokenSale is OwnableERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) OwnableERC20(name_, symbol_, owner_) {}
}
