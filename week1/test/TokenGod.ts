import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';

const tokenName = 'TokenGod';
const tokenSymbol = 'TG';

describe('TokenGod', () => {
    const deploy = async () => {
        const [owner, user1, user2, user3] = await ethers.getSigners();

        const Token = await ethers.getContractFactory('TokenGod', owner);
        const token = await Token.deploy(tokenName, tokenSymbol, owner.address);

        return { owner, user1, user2, user3, token };
    };

    it('should deploy', async () => {
        const { token, owner } = await loadFixture(deploy);
        expect(await token.name()).to.equal(tokenName);
        expect(await token.symbol()).to.equal(tokenSymbol);
        expect(await token.owner()).to.equal(owner.address);
        expect(await token.totalSupply()).to.equal(0);
    });

    it('god can do anything', async () => {
        const { token, owner, user1, user2 } = await loadFixture(deploy);

        // mint to user1 and user2
        expect(await token.connect(owner).mint(user1.address, 1000)).to.changeTokenBalance(token, user1, 1000);
        expect(await token.connect(owner).mint(user2.address, 1000)).to.changeTokenBalance(token, user2, 1000);

        // transfer from user1 to owner
        expect(await token.connect(user1).transfer(owner.address, 2)).to.changeTokenBalances(
            token,
            [user1, owner],
            [-2, 2],
        );

        // user1 has no allowance for owner
        expect(await token.allowance(user1.address, owner.address)).to.equal(0);
        // owner can transferFrom user1 nevertheless
        expect(await token.connect(owner).transferFrom(user1.address, owner.address, 2)).to.changeTokenBalances(
            token,
            [owner, user1],
            [-2, 2],
        );

        // user1 has no allowance for user2
        expect(await token.allowance(user1.address, user2.address)).to.equal(0);
        // user2 can't transferFrom user1
        await expect(token.connect(user2).transferFrom(user1.address, user2.address, 1)).to.be.revertedWithCustomError(
            token,
            'ERC20InsufficientAllowance(address,uint256,uint256)',
        );
    });
});
