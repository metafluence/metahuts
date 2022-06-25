async function main() {
  const MyNFT = await ethers.getContractFactory("NftRoom")

  // Start deployment, returning a promise that resolves to a contract object
  const myNFT = await upgrades.deployProxy(MyNFT)


  await myNFT.deployed()
  console.log("Contract deployed to address:", myNFT.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
