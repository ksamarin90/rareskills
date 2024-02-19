import { loadFixture, time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { UntrustedEscrow } from '../typechain-types';

describe('UntrustedEscrow', () => {
    const deploy = async () => {
        const [deployer, seller1, seller2, buyer1, buyer2] = await ethers.getSigners();

        const UntrustedEscrow = await ethers.getContractFactory('UntrustedEscrow', deployer);
        const untrustedEscrow = (await UntrustedEscrow.deploy()) as UntrustedEscrow;

        const TetherToken = await ethers.getContractFactory('TetherToken', deployer);
        const tetherToken = await TetherToken.deploy(ethers.parseUnits('1000000', 6), 'TETHER', 'USDT', 6);

        await tetherToken.transfer(buyer1.address, ethers.parseUnits('1000', 6));
        await tetherToken.transfer(buyer2.address, ethers.parseUnits('1000', 6));

        const TestERC20 = await ethers.getContractFactory('TestERC20', deployer);
        const testERC20 = await TestERC20.deploy('Test', 'erc20');

        await testERC20.mint(buyer1.address, ethers.parseUnits('1000', 6));
        await testERC20.mint(buyer2.address, ethers.parseUnits('1000', 6));

        return { untrustedEscrow, seller1, seller2, buyer1, buyer2, deployer, tetherToken, testERC20 };
    };

    it('should deploy', async () => {
        const { untrustedEscrow } = await loadFixture(deploy);
        expect(await untrustedEscrow.LOCKUP_PERIOD()).equal(60 * 60 * 24 * 3);
    });

    it('should escrow', async () => {
        const { untrustedEscrow, seller1, buyer1, testERC20, tetherToken, buyer2 } = await loadFixture(deploy);

        await untrustedEscrow.connect(seller1).setSellerPriceDetails([
            { token: await testERC20.getAddress(), amount: ethers.parseUnits('10', 6) },
            { token: await tetherToken.getAddress(), amount: ethers.parseUnits('12', 6) },
        ]);

        expect(await untrustedEscrow.sellerPriceDetails(seller1.address, await testERC20.getAddress())).equal(
            ethers.parseUnits('10', 6),
        );
        expect(await untrustedEscrow.sellerPriceDetails(seller1.address, await tetherToken.getAddress())).equal(
            ethers.parseUnits('12', 6),
        );

        await testERC20.connect(buyer1).approve(untrustedEscrow.getAddress(), ethers.MaxUint256);
        await tetherToken.connect(buyer1).approve(untrustedEscrow.getAddress(), ethers.MaxUint256);

        await expect(
            untrustedEscrow
                .connect(buyer1)
                .buy(seller1.address, { token: await testERC20.getAddress(), amount: ethers.parseUnits('9', 6) }),
        ).to.be.revertedWithCustomError(untrustedEscrow, 'InvalidPrice()');
        await expect(
            untrustedEscrow
                .connect(buyer1)
                .buy(seller1.address, { token: await testERC20.getAddress(), amount: ethers.parseUnits('10', 6) }),
        ).to.changeTokenBalances(
            testERC20,
            [buyer1, await untrustedEscrow.getAddress()],
            [ethers.parseUnits('-10', 6), ethers.parseUnits('10', 6)],
        );
        await expect(
            untrustedEscrow
                .connect(buyer1)
                .buy(seller1.address, { token: await testERC20.getAddress(), amount: ethers.parseUnits('10', 6) }),
        ).to.be.revertedWithCustomError(untrustedEscrow, 'AlreadyPayed()');

        await testERC20.connect(buyer2).approve(untrustedEscrow.getAddress(), ethers.MaxUint256);
        await tetherToken.connect(buyer2).approve(untrustedEscrow.getAddress(), ethers.MaxUint256);

        await expect(
            untrustedEscrow
                .connect(buyer2)
                .buy(seller1.address, { token: await testERC20.getAddress(), amount: ethers.parseUnits('12', 6) }),
        ).to.be.revertedWithCustomError(untrustedEscrow, 'InvalidPrice()');
        await expect(
            untrustedEscrow
                .connect(buyer2)
                .buy(seller1.address, { token: await tetherToken.getAddress(), amount: ethers.parseUnits('13', 6) }),
        ).to.changeTokenBalances(
            tetherToken,
            [buyer2, await untrustedEscrow.getAddress()],
            [ethers.parseUnits('-13', 6), ethers.parseUnits('12', 6)],
        );
        await expect(
            untrustedEscrow
                .connect(buyer2)
                .buy(seller1.address, { token: await testERC20.getAddress(), amount: ethers.parseUnits('13', 6) }),
        ).to.be.revertedWithCustomError(untrustedEscrow, 'AlreadyPayed()');

        await expect(untrustedEscrow.connect(seller1).withdraw([buyer1.address])).to.be.revertedWithCustomError(
            untrustedEscrow,
            'Locked()',
        );
        await expect(untrustedEscrow.connect(seller1).withdraw([buyer2.address])).to.be.revertedWithCustomError(
            untrustedEscrow,
            'Locked()',
        );
        await expect(
            untrustedEscrow.connect(seller1).withdraw([buyer1.address, buyer2.address]),
        ).to.be.revertedWithCustomError(untrustedEscrow, 'Locked()');

        await time.increase(60 * 60 * 24 * 3);

        await expect(untrustedEscrow.connect(seller1).withdraw([buyer1.address])).to.changeTokenBalances(
            testERC20,
            [seller1, await untrustedEscrow.getAddress()],
            [ethers.parseUnits('10', 6), ethers.parseUnits('-10', 6)],
        );

        await expect(untrustedEscrow.connect(seller1).withdraw([buyer2.address])).to.changeTokenBalances(
            tetherToken,
            [seller1, await untrustedEscrow.getAddress()],
            [ethers.parseUnits('11', 6), ethers.parseUnits('-12', 6)],
        );
    });
});
