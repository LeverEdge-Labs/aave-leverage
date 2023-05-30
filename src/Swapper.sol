// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// v3-core 0.8
import "@uniswap/v3-core/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

// v3-periphery 0.8
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

// openzeppelin safeTransfer
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "forge-std/console.sol";
import "forge-std/Test.sol";

contract Swapper {
    IUniswapV3Factory public constant v3Factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    // @dev gets price of token0 in terms of token1
    function getPrice(
        address token0,
        address token1
    ) public view returns (uint) {
        uint price = estimateAmountOut(token0, 1e18, 12, token1);
        return price;
    }

    // @dev gets price of tokenIn in terms of tokenOut
    function estimateAmountOut(
        address tokenIn,
        uint128 amountIn,
        uint32 secondsAgo,
        address tokenOut
    ) internal view returns (uint amountOut) {
        address pool = getPool(tokenIn, tokenOut, 3000);

        // Code copied from OracleLibrary.sol, consult()
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(
            secondsAgos
        );

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 tick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));

        if (
            tickCumulativesDelta < 0 &&
            (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)
        ) {
            tick--;
        }

        amountOut = OracleLibrary.getQuoteAtTick(
            tick,
            amountIn,
            tokenIn,
            tokenOut
        );
    }

    // @dev gets pool address of token pair on uniswap v3
    function getPool(
        address token0,
        address token1,
        uint24 fee
    ) internal view returns (address) {
        address pool = v3Factory.getPool(token0, token1, fee);

        require(pool != address(0), "Pool does not exist on Uniswap V3");
        return pool;
    }

    // @dev swaps a fixed amount of token0 for a maximum possible amount of token1
    function swapExactInputSingle(
        address token0,
        address token1,
        uint amountIn
    ) internal returns (uint amountOut) {
        SafeERC20.safeApprove(IERC20(token0), address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token0,
                tokenOut: token1,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
    }
}
