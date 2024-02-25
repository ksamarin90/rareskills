// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Reward} from "./Reward.sol";
import {NFT} from "./NFT.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Stake {
    using SafeERC20 for Reward;

    struct StakeInfo {
        address owner;
        uint96 timestamp;
    }

    event Deposited(address indexed user, uint256 tokenId);
    event Claimed(address indexed user, uint256 tokenId);
    event Withdrawn(address indexed user, uint256 tokenId);

    error InvalidNFT();
    error NotOwnerOfNFT();
    error RewardLocked();

    NFT public immutable nft;
    Reward public immutable reward;
    uint256 public constant rewardAmount = 10 ether;
    uint256 public constant rewardInterval = 1 days;

    // tokenId to StakeInfo
    mapping(uint256 => StakeInfo) public stakes;

    constructor(bytes32 merkleRoot_) {
        nft = new NFT("StakeNFT", "SNFT", merkleRoot_, msg.sender);
        reward = new Reward("StakeReward", "STR");
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (msg.sender != address(nft)) revert InvalidNFT();
        stakes[tokenId] = StakeInfo(from, uint96(block.timestamp));
        emit Deposited(from, tokenId);
        return this.onERC721Received.selector;
    }

    function claim(uint256 tokenId) external {
        StakeInfo storage stake = stakes[tokenId];
        if (stake.owner != msg.sender) revert NotOwnerOfNFT();
        if (stake.timestamp + rewardInterval > block.timestamp) revert RewardLocked();
        stake.timestamp = uint96(block.timestamp);
        reward.mint(msg.sender, rewardAmount);
        emit Claimed(msg.sender, tokenId);
    }

    function withdraw(uint256 tokenId) external {
        StakeInfo memory stake = stakes[tokenId];
        if (stake.owner != msg.sender) revert NotOwnerOfNFT();
        delete stakes[tokenId];
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Withdrawn(msg.sender, tokenId);
    }
}
