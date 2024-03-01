require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require("@nomicfoundation/hardhat-ethers");
require('dotenv').config();



// Updated this to just be the full URL rather than just the API key
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      accounts: {
        balance: "10000000000000000000000" // 10,000 ETH
      }
    }
  },
  arbitrum_sepolia: {
    url: process.env.ARBITRUM_ALCHEMY_KEY,
    accounts: [process.env.PRIVATE_KEY]
  },

  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  }
}
