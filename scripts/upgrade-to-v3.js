// Upgrade script from TokenVaultV2 to TokenVaultV3
const hre = require("hardhat");

async function main() {
  const VAULT_PROXY_ADDRESS = process.env.VAULT_PROXY || "0x...";
  const WITHDRAWAL_DELAY = process.env.WITHDRAWAL_DELAY || 7 * 24 * 60 * 60; // 7 days
  
  console.log("Upgrading TokenVault to V3...");
  
  const TokenVaultV3 = await hre.ethers.getContractFactory("TokenVaultV3");
  const vaultV3 = await hre.upgrades.upgradeProxy(VAULT_PROXY_ADDRESS, TokenVaultV3);
  
  // Set withdrawal delay
  await vaultV3.setWithdrawalDelay(WITHDRAWAL_DELAY);
  
  console.log("TokenVault upgraded to V3 at:", vaultV3.address);
  console.log("V3 adds: Withdrawal delays, emergency withdrawals, rate limiting");
  console.log("Withdrawal delay set to:", WITHDRAWAL_DELAY, "seconds");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
