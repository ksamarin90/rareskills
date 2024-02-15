import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';

const tokenName = 'TokenSanction';
const tokenSymbol = 'TS';

describe('TokenSanction', () => {
    const deploy = async () => {
        const [owner, user1, user2, user3] = await ethers.getSigners();

        const Token = await ethers.getContractFactory('TokenSanction', owner);
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

    it('should sanction', async () => {
        const { token, owner, user1, user2 } = await loadFixture(deploy);

        expect(await token.connect(owner).mint(user1.address, 1000)).to.changeTokenBalance(token, user1, 1000);
        expect(await token.connect(owner).mint(user2.address, 1000)).to.changeTokenBalance(token, user2, 1000);

        expect(await token.connect(user1).transfer(owner.address, 2)).to.changeTokenBalances(
            token,
            [user1, owner],
            [-2, 2],
        );
        await token.connect(owner).setSanctioned(user1.address, true);

        await expect(token.connect(user1).transfer(owner.address, 2)).to.be.revertedWithCustomError(
            token,
            `SanctionedTransfer(address)`,
        );

        await token.connect(user1).approve(user2.address, ethers.MaxUint256);

        await expect(token.connect(owner).transferFrom(user1.address, owner.address, 2)).to.be.revertedWithCustomError(
            token,
            `SanctionedTransfer(address)`,
        );
    });
});
