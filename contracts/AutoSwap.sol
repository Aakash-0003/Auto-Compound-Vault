// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract AutoSwap {
    ISwapRouter private immutable swapRouter;
    IERC20 public immutable rewardToken; //Reward token

    // Uniswap V3 pool fee (e.g., 0.3% = 3000)
    uint24 public constant poolFee = 3000;

    constructor(ISwapRouter _swapRouter, IERC20 _rewardToken) {
        swapRouter = _swapRouter;
        rewardToken = _rewardToken;
    }

    // Function to perform the swap
    function swapExactInputSingle(
        uint256 amountIn,
        IERC20 tokenB,
        address recipient
    ) internal returns (uint256 amountOut) {
        // Transfer the specified amount of Token A from the caller to this contract
        rewardToken.transferFrom(msg.sender, address(this), amountIn);

        // Approve the Uniswap router to spend Token A
        rewardToken.approve(address(swapRouter), amountIn);

        // Define the swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(rewardToken),
                tokenOut: address(tokenB),
                fee: poolFee,
                recipient: recipient, // Tokens will be sent to the user
                deadline: block.timestamp + 15, // 15 seconds deadline
                amountIn: amountIn,
                amountOutMinimum: 0, // Accept any amount of Token B (set this in production to manage slippage)
                sqrtPriceLimitX96: 0 // No price limit
            });

        // Execute the swap
        amountOut = swapRouter.exactInputSingle(params);
    }
}
