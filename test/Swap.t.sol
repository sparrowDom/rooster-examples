// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "./BaseTest.sol";
import {console2} from "forge-std/console2.sol";
import {IMaverickV2PoolLens} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2PoolLens.sol";
import {IMaverickV2Pool} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Pool.sol";

contract SwapTest is BaseTest {
    function setUp() public {
        startFork();
    }

    function testSwapToPool() public {
        pool.tokenA().approve(address(manager), 1e30);
        pool.tokenB().approve(address(manager), 1e30);

        bool tokenAIn = false;
        uint256 amount = 1e5;
        if (tokenAIn) {
            pool.tokenA().transfer(address(pool), amount);
        } else {
            pool.tokenB().transfer(address(pool), amount);
        }
        IMaverickV2Pool.SwapParams memory swapParams = IMaverickV2Pool.SwapParams({
            amount: amount,
            tokenAIn: tokenAIn,
            exactOutput: false,
            tickLimit: tokenAIn ? type(int32).max : type(int32).min
        });

        // swaps without a callback as the assets are already sent to the pool
        (, uint256 amountOut) = pool.swap(this_, swapParams, bytes(""));
        console2.log("Pool swap", amountOut);
    }

    function testSwapViaRouter() public {
        pool.tokenA().approve(address(router), 1e30);
        pool.tokenB().approve(address(router), 1e30);

        bool tokenAIn = false;
        uint256 amount = 1e5;

        uint256 amountOut = router.exactInputSingle(this_, pool, tokenAIn, amount, 0);
        console2.log("Router swap", amountOut);
    }

    function testSwapQuote() public {
        bool tokenAIn = false;
        uint128 amount = 1e5;
        int32 tickLimit = tokenAIn ? type(int32).max : type(int32).min;

        // this can run out of gas if there isn't enough liquidity in the pool to swap
        (, uint256 amountOut, ) = quoter.calculateSwap(pool, amount, tokenAIn, false, tickLimit);
        console2.log("quoter swap", amountOut);
    }
}
