// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC721Enumerable} from "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

contract PrimeCounter {
    IERC721Enumerable public immutable nft;

    constructor(IERC721Enumerable nft_) {
        nft = nft_;
    }

    function countPrimes(address owner) external view returns (uint256 count) {
        uint256 balance = balanceOf(address(nft), owner);

        unchecked {
            for (uint256 i = balance - 1; i > 0; ) {
                if (isPrime(nft.tokenOfOwnerByIndex(owner, i))) {
                    // if (isPrime(optimizedCall(address(nft), owner, i))) {
                    ++count;
                }
                --i;
            }
        }
        return count;
    }

    function isPrime(uint256 n) internal pure returns (bool) {
        if (n < 2) return false;
        if (n == 2) return true;
        unchecked {
            if (n % 2 == 0) return false;
            for (uint256 i = 3; i * i <= n; ) {
                if (n % i == 0) return false;
                i += 2;
            }
        }
        return true;
    }

    function balanceOf(
        address contractAddress,
        address user
    ) internal view returns (uint256 result) {
        assembly {
            mstore(0x00, hex"70a08231")
            mstore(0x04, user)
            let success := staticcall(gas(), contractAddress, 0, 0x24, 0x60, 0x20)
            if iszero(success) {
                revert(0x00, 0x00)
            }
            result := mload(0x60)
        }
    }

    // function optimizedCall(
    //     address contractAddress,
    //     address user,
    //     uint256 index
    // ) public view returns (uint256 result) {
    //     assembly {
    //         mstore(0x00, hex"2f745c59")
    //         mstore(0x04, user)
    //         mstore(0x24, index)
    //         let success := staticcall(gas(), contractAddress, 0, 0x44, 0x60, 0x20)
    //         if iszero(success) {
    //             revert(0x00, 0x00)
    //         }
    //         result := mload(0x60)
    //     }
    // }
}
