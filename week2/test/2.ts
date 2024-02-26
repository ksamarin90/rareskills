import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Smart contract ecosystem 2', () => {
    const deploy = async () => {
        const [owner] = await ethers.getSigners();
        const nfrEnumerableFactory = await ethers.getContractFactory('NFTEnumerable');
        const nftEnumerable = await nfrEnumerableFactory.deploy();
        const primeCounterFactory = await ethers.getContractFactory('PrimeCounter');
        const primeCounter = await primeCounterFactory.deploy(await nftEnumerable.getAddress());
        return {
            owner,
            nftEnumerable,
            primeCounter,
        };
    };

    it('should deploy', async () => {
        const { primeCounter, nftEnumerable } = await loadFixture(deploy);
        expect(await primeCounter.nft()).to.equal(await nftEnumerable.getAddress());
    });

    it('should count primes', async () => {
        const { primeCounter, owner, nftEnumerable } = await loadFixture(deploy);
        // 108385
        // 105601
        // 101505
        // 101209
        // 97780
        // 97765
        // 96691
        // 95651
        // 95572
        // 95421
        // 92795
        expect(await primeCounter.countPrimes.estimateGas(owner.address)).to.equal(92795);
        expect(await primeCounter.countPrimes(owner.address)).to.equal(8);
    });
});
