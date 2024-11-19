const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vault Contract", function () {
  let Vault, vault;
  let Token, asset, rewardToken, tokenHoney, tokenNectar;
  let Gauge, Plugin, SwapRouter, KodiakRouter, KodiakVault;
  let owner, user1, user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy Mock Tokens
    Token = await ethers.getContractFactory("MockERC20");
    asset = await Token.deploy("Asset Token", "ASSET", ethers.utils.parseEther("1000000"));
    rewardToken = await Token.deploy("Reward Token", "REWARD", ethers.utils.parseEther("1000000"));
    tokenHoney = await Token.deploy("Honey Token", "HONEY", ethers.utils.parseEther("1000000"));
    tokenNectar = await Token.deploy("Nectar Token", "NECTAR", ethers.utils.parseEther("1000000"));

    // Deploy Mock External Contracts
    const MockGauge = await ethers.getContractFactory("MockGauge");
    Gauge = await MockGauge.deploy();

    const MockPlugin = await ethers.getContractFactory("MockPlugin");
    Plugin = await MockPlugin.deploy();

    const MockSwapRouter = await ethers.getContractFactory("MockSwapRouter");
    SwapRouter = await MockSwapRouter.deploy();

    const MockKodiakRouter = await ethers.getContractFactory("MockKodiakRouter");
    KodiakRouter = await MockKodiakRouter.deploy();

    const MockKodiakVault = await ethers.getContractFactory("MockKodiakVault");
    KodiakVault = await MockKodiakVault.deploy();

    // Deploy Vault
    Vault = await ethers.getContractFactory("Vault");
    vault = await Vault.deploy(
      asset.address,
      rewardToken.address,
      Gauge.address,
      Plugin.address,
      SwapRouter.address,
      KodiakRouter.address,
      KodiakVault.address,
      tokenHoney.address,
      tokenNectar.address
    );

    // Approve vault for asset transfers
    await asset.connect(owner).approve(vault.address, ethers.utils.parseEther("1000000"));
    await asset.connect(user1).approve(vault.address, ethers.utils.parseEther("1000000"));
  });

  describe("Deposit", function () {
    it("should allow users to deposit assets and receive shares", async function () {
      const depositAmount = ethers.utils.parseEther("100");

      // User1 deposits assets
      await asset.connect(user1).transfer(user1.address, depositAmount);
      await asset.connect(user1).approve(vault.address, depositAmount);

      const shares = await vault.connect(user1).callStatic.deposit(depositAmount, user1.address);
      await vault.connect(user1).deposit(depositAmount, user1.address);

      // Check balances
      const userShares = await vault.balanceOf(user1.address);
      const vaultAssets = await asset.balanceOf(vault.address);

      expect(userShares).to.equal(shares);
      expect(vaultAssets).to.equal(depositAmount);
    });

    it("should revert if deposit exceeds maxDeposit", async function () {
      const depositAmount = ethers.utils.parseEther("10000000"); // Exceeds available asset balance

      await expect(
        vault.connect(user1).deposit(depositAmount, user1.address)
      ).to.be.revertedWith("ERC4626: deposit more than max");
    });
  });

  describe("Withdraw", function () {
    it("should allow users to withdraw assets", async function () {
      const depositAmount = ethers.utils.parseEther("100");

      // User1 deposits assets
      await asset.connect(user1).transfer(user1.address, depositAmount);
      await asset.connect(user1).approve(vault.address, depositAmount);
      await vault.connect(user1).deposit(depositAmount, user1.address);

      // User1 withdraws assets
      const shares = await vault.connect(user1).callStatic.withdraw(depositAmount, user1.address, user1.address);
      await vault.connect(user1).withdraw(depositAmount, user1.address, user1.address);

      // Check balances
      const userAssets = await asset.balanceOf(user1.address);
      const vaultAssets = await asset.balanceOf(vault.address);

      expect(userAssets).to.equal(depositAmount);
      expect(vaultAssets).to.equal(0);
    });

    it("should revert if withdraw exceeds maxWithdraw", async function () {
      const withdrawAmount = ethers.utils.parseEther("100");

      await expect(
        vault.connect(user1).withdraw(withdrawAmount, user1.address, user1.address)
      ).to.be.revertedWith("ERC4626: withdraw more than max");
    });
  });

  describe("HarvestYield", function () {
    it("should harvest rewards and compound them", async function () {
      const depositAmount = ethers.utils.parseEther("100");

      // User1 deposits assets
      await asset.connect(user1).transfer(user1.address, depositAmount);
      await asset.connect(user1).approve(vault.address, depositAmount);
      await vault.connect(user1).deposit(depositAmount, user1.address);

      // Simulate rewards
      await rewardToken.transfer(vault.address, ethers.utils.parseEther("50"));

      // Harvest rewards
      await vault.harvestYield(user1.address);

      // Check that rewards were compounded (mock logic)
      const vaultBalance = await asset.balanceOf(vault.address);
      expect(vaultBalance).to.be.gt(depositAmount);
    });
  });

  describe("Edge Cases", function () {
    it("should revert if harvestYield is called without rewards", async function () {
      await expect(vault.harvestYield(user1.address)).to.be.revertedWith("No rewards available");
    });
  });
});
