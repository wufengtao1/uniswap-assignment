/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

require("./tasks/verify");

// Change private keys accordingly - ONLY FOR DEMOSTRATION PURPOSES - PLEASE STORE PRIVATE KEYS IN A SAFE PLACE
const privateKeyDev = "0000000000000000000000000000000000000000000000000000000000000000";

module.exports = {
  defaultNetwork: "hardhat",

  networks: {
    hardhat: {},

    sepolia: {
      // Change it to your RPC URL: https://www.alchemy.com/
      url: "https://eth-sepolia.g.alchemy.com/v2/klLLylq_Jmj_oxWKY7yeNKjjE-MOOlTB",
      accounts: [privateKeyDev],
      chainId: 11155111
    },
    dev: {
      url: "http://127.0.0.1:9933",
      accounts: [privateKeyDev]
    }
  },
  solidity: {
    compilers: [
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  etherscan: {
    apiKey: {
      sepolia: "GF2MTB88Z2REPQRJJBZVJM1T2VKT51S1JX"
    }
  },
  paths: {
    sources: "./contracts",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  }
};
