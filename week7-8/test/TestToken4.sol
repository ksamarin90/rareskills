// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../src/Token4.sol";

///      ```
///      solc-select use 0.8.0
///      echidna program-analysis/echidna/exercises/exercise4/template.sol --contract TestToken --test-mode assertion
///      ```
///      or by providing a config
///      ```
///      echidna program-analysis/echidna/exercises/exercise4/template.sol --contract TestToken --config program-analysis/echidna/exercises/exercise4/config.yaml
///      ```
contract TestToken4 is Token4 {
    function transfer(address to, uint256 value) public override {
        // TODO: include `assert(condition)` statements that
        // detect a breaking invariant on a transfer.
        // Hint: you may use the following to wrap the original function.
        uint256 senderInitialBalance = balances[msg.sender];
        uint256 receiverInitialBalance = balances[to];
        super.transfer(to, value);
        assert(balances[msg.sender] <= senderInitialBalance);
        assert(balances[to] >= receiverInitialBalance);
    }
}
