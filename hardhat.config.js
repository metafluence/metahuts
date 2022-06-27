/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const { API_URL, PRIVATE_KEY } = process.env;

module.exports = {
   solidity: {
      version: "0.8.12",
      settings: {
         optimizer: {
           enabled: true,
           runs: 200
         }
       }
   },
   defaultNetwork: "bsc_testnet",
   // settings: {
   //    optimizer: {
   //      enabled: true,
   //      runs: 2000,
   //    },
   //  },
   networks: {
      hardhat: {},
      bsc_testnet: {
         url: "https://data-seed-prebsc-1-s1.binance.org:8545",
         chainId: 97,
         accounts:
           process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
       },
       bsc_mainnet: {
         url: "https://bsc-dataseed.binance.org/",
         chainId: 56,
         accounts:
           process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
       },
   },
}