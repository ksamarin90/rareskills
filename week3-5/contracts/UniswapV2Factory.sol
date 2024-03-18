// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {UniswapV2Pair} from "./UniswapV2Pair.sol";

import {Ownable} from "solady/src/auth/Ownable.sol";

contract UniswapV2Factory is Ownable {
    address public feeTo;
    address[] public allPairs;
    mapping(address => mapping(address => address)) public getPair;

    error IDENTICAL_ADDRESSES();
    error ZERO_ADDRESS();
    error PAIR_EXISTS();

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor() {}

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if (tokenA == tokenB) revert IDENTICAL_ADDRESSES();
        if (tokenA == address(0) || tokenB == address(0)) revert ZERO_ADDRESS();
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (getPair[token0][token1] != address(0)) revert PAIR_EXISTS();
        pair = address(new UniswapV2Pair(token0, token1));
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }
}
