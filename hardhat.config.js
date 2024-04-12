require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const AVALANCHE_PRIVATE_KEY = "33621e93a1e43c33e170ce601a3a82c873155fa2f1407269fb1e4d467b2800b2";
const ETHERSCAN_API_KEY = "HC8VG9WFGD61N3FWMVPTI6MJI1Q5TCG9CB";
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.9",
  etherscan: {
    // Your API key for Snowtrace
    // Obtain one at https://snowtrace.io/
    apiKey: `${ETHERSCAN_API_KEY}`,
  },
  networks: {
    avalanche: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      accounts: [`${AVALANCHE_PRIVATE_KEY}`]
    }
  }
};
