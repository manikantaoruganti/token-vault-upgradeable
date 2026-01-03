// Deployment script for TokenVaultV1
const hre = require("hardhat");

async function main() {
  console.log("Deploying TokenVaultV1...");
  
  const TokenVaultV1 = await hre.ethers.getContractFactory("TokenVaultV1");
  const vault = await hre.upgrades.deployProxy(TokenVaultV1, [], {
    kind: "uups"
  });
  
  await vault.deployed();
  console.log("TokenVaultV1 deployed to:", vault.address);
  
  // Initialize the vault
  const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
  const token = await MockERC20.deploy("Test Token", "TEST");
  await token.deployed();
  
  await vault.initialize(token.address);
  console.log("TokenVaultV1 initialized with token:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
