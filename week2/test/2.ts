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
        expect(await primeCounter.countPrimes.estimateGas(owner.address)).to.equal(95421);
        expect(await primeCounter.countPrimes(owner.address)).to.equal(8);

        // console.log(ethers.keccak256(ethers.toUtf8Bytes('tokenOfOwnerByIndex(address,uint256)')).slice(0, 10));
        // console.log(ethers.keccak256(ethers.toUtf8Bytes('balanceOf(address)')).slice(0, 10));

        // await primeCounter.optimizedCall(await nftEnumerable.getAddress(), owner.address, 2).then(console.log);
    });
});
