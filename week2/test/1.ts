import { loadFixture, time } from '@nomicfoundation/hardhat-network-helpers';
import { StandardMerkleTree } from '@openzeppelin/merkle-tree';
import { expect } from 'chai';
import { ethers } from 'hardhat';

const getProof = (tree: StandardMerkleTree<(string | number)[]>, address: string) => {
    for (const [i, value] of tree.entries()) {
        if (value[1] === address) {
            return { proof: tree.getProof(i), index: value[0] };
        }
    }
    throw new Error('Address not found in the tree');
};

describe('Smart contract ecosystem 1', () => {
    const deploy = async () => {
        const [owner, privilegedUser1, privilegedUser2, simpleUser1, simpleUser2] = await ethers.getSigners();
        const tree = StandardMerkleTree.of(
            [
                [0, privilegedUser1.address],
                [1, privilegedUser2.address],
            ],
            ['uint256', 'address'],
        );
        const stakeFactory = await ethers.getContractFactory('Stake');
        const stake = await stakeFactory.deploy(tree.root);
        const reward = await ethers.getContractAt('Reward', await stake.reward());
        const nft = await ethers.getContractAt('NFT', await stake.nft());
        return {
            owner,
            privilegedUser1,
            privilegedUser2,
            simpleUser1,
            simpleUser2,
            tree,
            stake,
            reward,
            nft,
        };
    };
    it('should deploy', async () => {
        const { stake, nft, reward } = await loadFixture(deploy);
        expect(await stake.rewardAmount()).to.equal(ethers.parseEther('10'));
        expect(await stake.rewardInterval()).to.equal(24 * 60 * 60);
        expect(await stake.reward()).to.equal(await reward.getAddress());
        expect(await stake.nft()).to.equal(await nft.getAddress());
        expect(await nft.price()).to.equal(ethers.parseEther('1'));
        expect(await reward.owner()).to.equal(await stake.getAddress());
    });

    it('privileged users should be able to mint nft with and without discount', async () => {
        const { privilegedUser1, nft, tree } = await loadFixture(deploy);
        const price = await nft.price();
        const discountPrice = await nft.discountPrice();

        // Mint with discount
        const { proof, index } = getProof(tree, privilegedUser1.address);
        expect(
            await nft.connect(privilegedUser1).mintWithDiscount(proof, index, { value: discountPrice }),
        ).to.changeEtherBalances([privilegedUser1, nft], [-discountPrice, discountPrice]);
        expect(await nft.ownerOf(1)).to.equal(privilegedUser1.address);
        await expect(nft.ownerOf(0)).to.be.revertedWithCustomError(nft, 'ERC721NonexistentToken(uint256)');

        // repeated discount mint is not allowed
        await expect(
            nft.connect(privilegedUser1).mintWithDiscount(proof, index, { value: discountPrice }),
        ).to.be.revertedWithCustomError(nft, 'DiscountAlreadyApplied()');

        // but simple mint without discount works
        expect(await nft.connect(privilegedUser1).mint({ value: price })).to.changeEtherBalances(
            [privilegedUser1, nft],
            [-price, price],
        );
        expect(await nft.ownerOf(2)).to.equal(privilegedUser1.address);
    });

    it('simple users should be able to mint nft only with the regular price. only owner can withdraw ETH', async () => {
        const { simpleUser1, privilegedUser1, nft, tree, owner } = await loadFixture(deploy);
        const price = await nft.price();
        const { proof, index } = getProof(tree, privilegedUser1.address);
        await expect(
            nft.connect(simpleUser1).mintWithDiscount(proof, index, { value: price }),
        ).to.be.revertedWithCustomError(nft, 'InvalidProof()');
        await expect(nft.connect(simpleUser1).mint({ value: price })).to.changeEtherBalances(
            [simpleUser1, nft],
            [-price, price],
        );
        expect(await nft.ownerOf(1)).to.equal(simpleUser1.address);

        // only owner can withdraw the ETH from the contract
        await expect(nft.connect(simpleUser1).withdraw()).to.be.revertedWithCustomError(
            nft,
            'OwnableUnauthorizedAccount(address)',
        );
        expect(await nft.connect(owner).withdraw()).to.changeEtherBalances([nft, owner], [-price, price]);
    });

    it('users should be able to stake and earn rewards', async () => {
        const { simpleUser1, simpleUser2, reward, nft, stake } = await loadFixture(deploy);
        const price = await nft.price();
        const rewardAmount = await stake.rewardAmount();
        const rewardInterval = await stake.rewardInterval();

        // Mint nft
        await nft.connect(simpleUser1).mint({ value: price });
        // Stake nft
        await nft
            .connect(simpleUser1)
            ['safeTransferFrom(address,address,uint256)'](simpleUser1.address, await stake.getAddress(), 1);
        expect(await nft.ownerOf(1)).to.equal(await stake.getAddress());
        // only owner of nft can unstake
        await expect(stake.connect(simpleUser2).withdraw(1)).to.be.revertedWithCustomError(stake, 'NotOwnerOfNFT()');
        await stake.connect(simpleUser1).withdraw(1);
        expect(await nft.ownerOf(1)).to.equal(simpleUser1.address);
        // but without waiting for the reward interval there will be no reward
        expect(await reward.balanceOf(simpleUser1.address)).to.equal(0);

        // claiming the reward
        await nft
            .connect(simpleUser1)
            ['safeTransferFrom(address,address,uint256)'](simpleUser1.address, await stake.getAddress(), 1);

        await time.increase(rewardInterval);
        // only owner of nft can claim
        await expect(stake.connect(simpleUser2).claim(1)).to.be.revertedWithCustomError(stake, 'NotOwnerOfNFT()');
        expect(await stake.connect(simpleUser1).claim(1)).to.changeEtherBalances(
            [stake, simpleUser1],
            [0, rewardAmount],
        );

        await time.increase(rewardInterval);

        await expect(stake.connect(simpleUser2).claim(1)).to.be.revertedWithCustomError(stake, 'NotOwnerOfNFT()');
        expect(await stake.connect(simpleUser1).claim(1)).to.changeEtherBalances(
            [stake, simpleUser1],
            [0, rewardAmount],
        );

        expect(await reward.balanceOf(simpleUser1.address)).to.equal(rewardAmount * 2n);
        await stake.connect(simpleUser1).withdraw(1);
        expect(await nft.ownerOf(1)).to.equal(simpleUser1.address);
    });
});
