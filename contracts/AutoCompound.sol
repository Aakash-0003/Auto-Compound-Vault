// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPlugIn.sol";
import "../interfaces/IGauge.sol";
import "../interfaces/IKodiakRouter.sol";
import "./AutoSwap.sol";

abstract contract AutoCompound is AutoSwap {
    IGauge private immutable gauge;
    IPlugIn internal immutable plugin;
    IKodiakRouter private immutable kodiakRouter;
    IERC20 private immutable tokenHoney;
    IERC20 private immutable tokenNectar;
    IKodiakVaultV1 private immutable islandPool;

    constructor(
        IGauge _gauge,
        IPlugIn _plugin,
        IKodiakRouter _kodiakRouter,
        IKodiakVaultV1 _islandPool,
        IERC20 _tokenHoney,
        IERC20 _tokenNectar
    ) {
        gauge = _gauge;
        plugin = _plugin;
        kodiakRouter = _kodiakRouter;
        tokenHoney = _tokenHoney;
        tokenNectar = _tokenNectar;
        islandPool = _islandPool;
    }

    /**
     * Function depositToFarm for depositing Island LP Tokens as Liquidity provider to beradrom farm
     * assets - amount of assets to be deposited
     * receiver- reciever e.g.address who owns the LP tokens and reward tokens to be send to
     */
    function depositToFarm(address receiver, uint256 assets) internal {
        plugin.depositFor(receiver, assets);
    }

    /**
     * Function harvestReward for depositing Island LP Tokens as Liquidity provider to beradrom farm
     * receiver- reciever e.g.address who owns the LP tokens sent to farm
     */
    function harvestReward(
        address receiver
    ) internal returns (uint256 rewardHarvested) {
        gauge.getReward(receiver);
        return rewardToken.balanceOf(receiver);
    }

    /**
     * Function swapRewardToHoneyAndNectar for swapping oBero reward tokens to Honey and Nectar tokens
     * receiver- reciever e.g.address who owns oBero rewards
     * amountIn- the amount of oBeroReward tokens to be swapped
     */

    function swapRewardToHoneyAndNectar(
        address receiver,
        uint256 amountIn
    ) internal returns (uint256 honeyAmountOut, uint256 nectarAmountOut) {
        honeyAmountOut = swapExactInputSingle(
            amountIn / 2,
            tokenHoney,
            receiver
        );
        nectarAmountOut = swapExactInputSingle(
            amountIn / 2,
            tokenHoney,
            receiver
        );
    }

    /**
     * Function addLiquidityToIsland for depositing Honey and Nectar tokens as Liquidity to Honey-nectar Island
     * amount0Max- the maximum amount of  token0 e.g. Honey tokens to be deposited
     * amount1Max- the maximum amount of token1 e.g. Nectar tokens to be deposited
     * amount0Min- the minimum amount of token0 e.g. Honey tokens to be deposited
     * amoun1Min- the minimum amount of token1 e.g. Nectar tokens to be deposited
     * amountSharesMin- the minimum amount of LP Island Token that will be received
     * receiver- reciever e.g.address who owns honey and nectar tokens and gonna recieve Island Tokens
     */
    function addLiquidityToIsland(
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    ) internal returns (uint256 amount0, uint256 amount1, uint256 mintAmount) {
        (amount0, amount1, mintAmount) = kodiakRouter.addLiquidity(
            islandPool,
            amount0Max,
            amount1Max,
            amount0Min,
            amount1Min,
            amountSharesMin,
            receiver
        );
    }
}
