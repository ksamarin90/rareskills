// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TokenWithSanctions is ERC20, Ownable {
    mapping(address => bool) public sanctioned;

    event Sanctioned(address account, bool value);

    error SanctionedTransfer(address user);

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC20(name_, symbol_) Ownable(owner_) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function setSanctioned(address account, bool value) external onlyOwner {
        sanctioned[account] = value;
        emit Sanctioned(account, value);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        address from = _msgSender();
        if (sanctioned[from]) revert SanctionedTransfer(from);
        if (sanctioned[to]) revert SanctionedTransfer(to);
        _transfer(from, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (sanctioned[from]) revert SanctionedTransfer(from);
        if (sanctioned[to]) revert SanctionedTransfer(to);
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }
}
