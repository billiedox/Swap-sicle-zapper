const hre = require('hardhat')

async function main() {
  await hre.run('verify:verify', {
    address: '0x6B99CBC724F81745c639615417Dd0B2e4740c8c1',
    constructorArguments: ["0xC7f372c62238f6a5b79136A9e5D16A2FD7A3f0F5"],
  })
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })