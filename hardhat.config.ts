import { HardhatUserConfig } from 'hardhat/config';
import 'hardhat-gas-reporter';
import 'hardhat-contract-sizer';
import '@nomicfoundation/hardhat-toolbox';

export const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: '0.8.20',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 10000,
                    },
                },
            },
            {
                version: '0.4.17',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 10000,
                    },
                },
            },
        ],
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS ? true : false,
    },
};
