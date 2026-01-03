// Upgrade script from TokenVaultV1 to TokenVaultV2
const hre = require("hardhat");

async function main() {
  const VAULT_PROXY_ADDRESS = process.env.VAULT_PROXY || "0x...";
  
  console.log("Upgrading TokenVault to V2...");
  
  const TokenVaultV2 = await hre.ethers.getContractFactory("TokenVaultV2");
  const vaultV2 = await hre.upgrades.upgradeProxy(VAULT_PROXY_ADDRESS, TokenVaultV2);
  
  console.log("TokenVault upgraded to V2 at:", vaultV2.address);
  console.log("V2 adds: Yield tracking, double-claiming prevention");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
