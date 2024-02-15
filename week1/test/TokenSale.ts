import { loadFixture, time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';

const tokenName = 'TokenSale';
const tokenSymbol = 'TS';

describe('TokenSale', () => {
    const deploy = async () => {
        const [owner, user1, user2, user3] = await ethers.getSigners();

        const BaseToken = await ethers.getContractFactory('TestERC20', owner);
        const baseToken = await BaseToken.deploy('test usd', 'TUSD');

        const TokenSale = await ethers.getContractFactory('TokenSale', owner);
        const tokenSale = await TokenSale.deploy(tokenName, tokenSymbol, await baseToken.getAddress());

        return { owner, user1, user2, user3, baseToken, tokenSale };
    };

    it('should deploy', async () => {
        const { tokenSale, baseToken } = await loadFixture(deploy);
        expect(await tokenSale.name()).to.equal(tokenName);
        expect(await tokenSale.symbol()).to.equal(tokenSymbol);
        expect(await tokenSale.baseToken()).to.equal(await baseToken.getAddress());
        expect(await tokenSale.totalSupply()).to.equal(0);
    });

    it('should mint tokens from zero', async () => {
        const { tokenSale, user1, user2, user3, baseToken } = await loadFixture(deploy);
        const amount = ethers.parseEther('1000');
        for (const user of [user1, user2, user3]) {
            expect(await baseToken.connect(user).mint(user.address, amount)).to.changeTokenBalance(
                baseToken,
                user,
                amount,
            );
            await baseToken.connect(user).approve(tokenSale.getAddress(), ethers.MaxUint256);
        }
        await tokenSale.connect(user1).buy(1000);

        await baseToken.balanceOf(user1.address).then(console.log);
        await tokenSale.balanceOf(user1.address).then(console.log);

        await tokenSale.connect(user2).buy(1000);

        await baseToken.balanceOf(user2.address).then(console.log);
        await tokenSale.balanceOf(user2.address).then(console.log);

        await tokenSale.connect(user3).buy(1000);

        await baseToken.balanceOf(user3.address).then(console.log);
        await tokenSale.balanceOf(user3.address).then(console.log);

        await time.increase(60);

        await tokenSale.connect(user1).sell(1000);

        await baseToken.balanceOf(user1.address).then(console.log);
        await tokenSale.balanceOf(user1.address).then(console.log);

        await tokenSale.connect(user2).sell(1000);

        await baseToken.balanceOf(user2.address).then(console.log);
        await tokenSale.balanceOf(user2.address).then(console.log);

        await tokenSale.connect(user3).sell(1000);

        await baseToken.balanceOf(user3.address).then(console.log);
        await tokenSale.balanceOf(user3.address).then(console.log);
    });
});
