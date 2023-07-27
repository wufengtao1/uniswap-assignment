/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');

// Change private keys accordingly - ONLY FOR DEMOSTRATION PURPOSES - PLEASE STORE PRIVATE KEYS IN A SAFE PLACE
// Export your private key as
//       export PRIVKEY=0x.....
const privateKey = process.env.PRIVKEY;
const privateKeyDev = 'your key';

module.exports = {
  defaultNetwork: 'hardhat',

  networks: {
    hardhat: {},

    sepolia: {
      url: 'https://eth-sepolia-public.unifra.io',
      accounts: [privateKeyDev],
    },
    dev: {
      url: 'http://127.0.0.1:9933',
      accounts: [privateKeyDev]
    },
  },
  solidity: {
    compilers: [
      {
        version: '0.5.16',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: '0.6.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  etherscan: {
    apiKey: {
      sepolia: 'GF2MTB88Z2REPQRJJBZVJM1T2VKT51S1JX', // etherscan(https://etherscan.io/) API Key
    },
  },
  paths: {
    sources: './contracts',
    cache: './cache',
    artifacts: './artifacts',
  },
  mocha: {
    timeout: 20000,
  },
};
