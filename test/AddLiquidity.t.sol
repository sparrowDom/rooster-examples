// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "./BaseTest.sol";
import {console2} from "forge-std/console2.sol";
import {IMaverickV2PoolLens} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2PoolLens.sol";
import {IMaverickV2Pool} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Pool.sol";

contract AddLiquidityTest is BaseTest {
    function setUp() public {
        startFork();
    }

    function testAddLiquidity() public {
        pool.tokenA().approve(address(manager), 1e45);
        pool.tokenB().approve(address(manager), 1e45);

        addLiquidity(1e18, true);
        swapToPool(1e17, true);
    }

    function addLiquidity(uint256 amount, bool isTokenA) public {
        // get ticks and liquidity params assuming flat distribution
        (int32[] memory ticks, uint128[] memory relativeLiquidityAmounts) = _getTickAndRelativeLiquidity(1e18, pool);

        IMaverickV2PoolLens.AddParamsSpecification memory addSpec = IMaverickV2PoolLens.AddParamsSpecification({
            slippageFactorD18: 0,
            numberOfPriceBreaksPerSide: 0,
            targetAmount: amount,
            targetIsA: isTokenA
        });

        IMaverickV2PoolLens.AddParamsViewInputs memory addParamsViewInputs = IMaverickV2PoolLens.AddParamsViewInputs({
            pool: pool,
            kind: 0,
            ticks: ticks,
            relativeLiquidityAmounts: relativeLiquidityAmounts,
            addSpec: addSpec
        });

        (bytes memory packedSqrtPriceBreaks, bytes[] memory packedArgs, , ,IMaverickV2PoolLens.TickDeltas[] memory tickDeltas) = lens.getAddLiquidityParams(
            addParamsViewInputs
        );

        console2.log("WETH deltaOut", tickDeltas[0].deltaAOut);
        console2.log("OETHp deltaOut", tickDeltas[0].deltaBOut);

        (uint256 amountA, uint256 amountB, , uint256 tokenId) = manager.mintPositionNftToSender(
            pool,
            packedSqrtPriceBreaks,
            packedArgs
        );

        int256 tokenADiff = int256(tickDeltas[0].deltaAOut) - int256(amountA);
        int256 tokenBDiff = int256(tickDeltas[0].deltaBOut) - int256(amountB);

        if (tokenADiff < 0) {
            console2.log("Add liquiduty transfered more WETH than anticipated: ", tokenADiff);
        }
        if (tokenBDiff < 0) {
            console2.log("Add liquiduty transfered more OETHp than anticipated: ", tokenBDiff);
        }
    }

    function swapToPool(uint256 amount, bool tokenAIn) public {
        pool.tokenA().approve(address(manager), 1e30);
        pool.tokenB().approve(address(manager), 1e30);

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
        //console2.log("Pool swap", amountOut);
    }
}
