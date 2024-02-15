// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {OwnableERC20} from "./OwnableERC20.sol";

contract TokenSanction is OwnableERC20 {
    mapping(address => bool) public sanctioned;

    event Sanctioned(address account, bool value);

    error SanctionedTransfer(address user);

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) OwnableERC20(name_, symbol_, owner_) {}

    function setSanctioned(address account, bool value) external onlyOwner {
        sanctioned[account] = value;
        emit Sanctioned(account, value);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        address from = _msgSender();
        _complyWithSanctions(from, to);
        _transfer(from, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _complyWithSanctions(from, to);
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _complyWithSanctions(address from, address to) internal view {
        if (sanctioned[from]) revert SanctionedTransfer(from);
        if (sanctioned[to]) revert SanctionedTransfer(to);
    }
}
