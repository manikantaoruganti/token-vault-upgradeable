const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("TokenVaultV1", function () {
  let vault;
  let token;
  let owner;
  let user1;
  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();

    // Deploy mock token
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    token = await MockERC20.deploy("Test Token", "TEST");
    await token.deployed();

    // Mint tokens to user
    await token.mint(user1.address, ethers.parseEther("1000"));

    // Deploy vault proxy
    const TokenVaultV1 = await ethers.getContractFactory("TokenVaultV1");
    vault = await upgrades.deployProxy(TokenVaultV1, [], { kind: "uups" });
    await vault.deployed();

    // Initialize vault
    await vault.initialize(token.address);
  });

  describe("Deposit", function () {
    it("Should allow users to deposit tokens", async function () {
      const depositAmount = ethers.parseEther("100");
      await token.connect(user1).approve(vault.address, depositAmount);
      await vault.connect(user1).deposit(depositAmount);

      const balance = await vault.balanceOf(user1.address);
      expect(balance).to.equal(depositAmount);
    });
  });

  describe("Withdraw", function () {
    it("Should allow users to withdraw tokens", async function () {
      const depositAmount = ethers.parseEther("100");
      await token.connect(user1).approve(vault.address, depositAmount);
      await vault.connect(user1).deposit(depositAmount);

      const withdrawAmount = ethers.parseEther("50");
      await vault.connect(user1).withdraw(withdrawAmount);

      const balance = await vault.balanceOf(user1.address);
      expect(balance).to.equal(ethers.parseEther("50"));
    });
  });
});
