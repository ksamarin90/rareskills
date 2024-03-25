-   Math.mulDiv(uint256,uint256,uint256) (../node\*modules/@openzeppelin/contracts/utils/math/Math.sol#123-202) has bitwise-xor operator ^ instead of the exponentiation operator \*\*: - inverse = (3 \_ denominator) ^ 2 (../node_modules/@openzeppelin/contracts/utils/math/Math.sol#184)

False. It is not exponentiation.

-   Math.mulDiv(uint256,uint256,uint256) (../node_modules/@openzeppelin/contracts/utils/math/Math.sol#123-202) performs a multiplication on the result of a division: - denominator = denominator / twos (../node_modules/@openzeppelin/contracts/utils/math/Math.sol#169) - inverse = (3 \* denominator) ^ 2 (../node_modules/@openzeppelin/contracts/utils/math/Math.sol#184)

Kinda true. But not sure it is wrong in Openzeppelin.

-   Ownable2Step.transferOwnership(address).newOwner (../node_modules/@openzeppelin/contracts/access/Ownable2Step.sol#35) lacks a zero-check on : - \_pendingOwner = newOwner (../node_modules/@openzeppelin/contracts/access/Ownable2Step.sol#36)

True.

-   Reentrancy in Stake.claim(uint256) (contracts/1/Stake.sol#50-57):
    External calls: - reward.mint(msg.sender,rewardAmount) (contracts/1/Stake.sol#55)
    Event emitted after the call(s): - Claimed(msg.sender,tokenId) (contracts/1/Stake.sol#56)

True.

-   Reentrancy in Stake.withdraw(uint256) (contracts/1/Stake.sol#59-65):
    External calls: - nft.safeTransferFrom(address(this),msg.sender,tokenId) (contracts/1/Stake.sol#63)
    Event emitted after the call(s): - Withdrawn(msg.sender,tokenId) (contracts/1/Stake.sol#64)

True.

-   Stake.claim(uint256) (contracts/1/Stake.sol#50-57) uses timestamp for comparisons
    Dangerous comparisons: - stake.timestamp + rewardInterval > block.timestamp (contracts/1/Stake.sol#53)

True.

-   Stake (contracts/1/Stake.sol#9-66) should inherit from IERC721Receiver (../node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol#11-28)

True.

-   Reentrancy in NFT.withdraw() (contracts/1/NFT.sol#77-80):
    External calls: - address(owner()).transfer(address(this).balance) (contracts/1/NFT.sol#78)
    Event emitted after the call(s): - Withdrawn(owner(),address(this).balance) (contracts/1/NFT.sol#79)

True.
