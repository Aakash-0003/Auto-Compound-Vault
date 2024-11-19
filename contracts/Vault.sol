// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AutoCompound.sol";

contract Vault is ERC4626, AutoCompound {
    //Constructor
    constructor(
        IERC20 _asset,
        IERC20 _rewardToken,
        IGauge _gauge,
        IPlugIn _plugin,
        ISwapRouter _swapRouter,
        IKodiakRouter _kodiakRouter,
        IKodiakVaultV1 _islandPool,
        IERC20 _tokenHoney,
        IERC20 _tokenNectar
    )
        ERC4626(_asset)
        ERC20("Vault AutoCompoundToken", "vACT")
        AutoCompound(
            _gauge,
            _plugin,
            _kodiakRouter,
            _islandPool,
            _tokenHoney,
            _tokenNectar
        )
        AutoSwap(_swapRouter, _rewardToken)
    {}

    /**
     * Function deposit for depositing Island LP Tokens as assets
     * assets - amount of assets,user wish to deposit
     * receiver- reciever e.g. vault address
     */
    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override returns (uint256) {
        require(
            assets <= maxDeposit(receiver),
            "ERC4626: deposit more than max"
        );

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        afterDeposit(assets);

        return shares;
    }

    /**
     * Function withdraw  for withdrawing Island LP Tokens
     * assets - amount of vault allocated shared ,user wish to deposit to withdraw deposited LP token
     * receiver- reciever who user wish to recieve underlying asset
     * owner- owner  of the underlying asset e.g. user address
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(
            assets <= maxWithdraw(owner),
            "ERC4626: withdraw more than max"
        );
        beforeWithdraw(msg.sender);
        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /**
     * Function afterDeposit for initiating auto compound on the asset recieved by the vault
     * assets - amount of assets,that vault just recieved
     */
    function afterDeposit(uint256 assets) private {
        depositToFarm(msg.sender, assets);
    }

    /**
     * Function harvestYield for harvest and get the Obero reward from beradrome farm and start auto compounding process
     * can be called externally, or maybe an off-chain bot to call it periodically
     * receiver- address whose assets has to be harvested
     */
    function harvestYield(address receiver) external {
        uint256 reward = harvestReward(receiver);
        (
            uint256 honeyAmountOut,
            uint256 nectarAmountOut
        ) = swapRewardToHoneyAndNectar(receiver, reward);
        (, , uint256 mintAmount) = addLiquidityToIsland(
            honeyAmountOut,
            nectarAmountOut,
            1,
            1,
            1,
            receiver
        );
        depositToFarm(msg.sender, mintAmount);
    }

    /**
     * Function beforeWithdraw for getting all the invested assets from the farm and the Kodiak DEX
     * receiver- address whose assets has to be withdrawn from vault
     */

    function beforeWithdraw(address receiver) private {
        uint256 amount = plugin.balanceOf(receiver);
        plugin.withdrawTo(receiver, amount);

        uint256 reward = harvestReward(receiver);
        (
            uint256 honeyAmountOut,
            uint256 nectarAmountOut
        ) = swapRewardToHoneyAndNectar(receiver, reward);
        (, , uint256 mintAmount) = addLiquidityToIsland(
            honeyAmountOut,
            nectarAmountOut,
            1,
            1,
            1,
            receiver
        );
        _deposit(_msgSender(), receiver, mintAmount, 0);
    }
}
