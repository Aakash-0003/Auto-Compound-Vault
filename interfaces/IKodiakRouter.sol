// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
interface IKodiakVaultV1 {}
interface IKodiakRouter {
    function addLiquidity(
        IKodiakVaultV1 pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    ) external returns (uint256 amount0, uint256 amount1, uint256 mintAmount);
}
