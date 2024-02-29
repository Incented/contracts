require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');

const keys = require("./constants.js");


module.exports = {
  solidity: "0.8.24",
  networks: {
    arbitrum_sepolia: {
      url: `https://arb-sepolia.g.alchemy.com/v2/${keys.ARBITRUM_ALCHEMY_KEY}`,
      accounts: [keys.PRIVATE_KEY]
    },
  },
};