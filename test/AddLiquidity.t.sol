// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "./BaseTest.sol";
import {console2} from "forge-std/console2.sol";
import {IMaverickV2PoolLens} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2PoolLens.sol";

contract AddLiquidityTest is BaseTest {
    function setUp() public {
        startFork();
    }

    function testAddLiquidity() public {
        pool.tokenA().approve(address(manager), 1e30);
        pool.tokenB().approve(address(manager), 1e30);

        // get ticks and relative liquidity as they're done in Maverick tests
        (int32[] memory ticks, uint128[] memory relativeLiquidityAmounts) = _getTickAndRelativeLiquidity(1e18, pool);

        // get addSpec for params also as done in Maverick tests
        uint256 maxAmountA = 1e14;
        console2.log("Amount tokenA Target", maxAmountA);

        uint256 slippageFactor = 0.01e18;
        IMaverickV2PoolLens.AddParamsSpecification memory addSpec = IMaverickV2PoolLens.AddParamsSpecification({
            slippageFactorD18: slippageFactor,
            numberOfPriceBreaksPerSide: 0,
            targetAmount: maxAmountA,
            targetIsA: true
        });

        // get addParamsViewInputs as done in Maverick tests
        IMaverickV2PoolLens.AddParamsViewInputs memory addParamsViewInputs = IMaverickV2PoolLens.AddParamsViewInputs({
            pool: pool,
            kind: 0,
            ticks: ticks,
            relativeLiquidityAmounts: relativeLiquidityAmounts,
            addSpec: addSpec
        });

        (bytes memory packedSqrtPriceBreaks, bytes[] memory packedArgs, , , ) = lens.getAddLiquidityParams(
            addParamsViewInputs
        );

        (uint256 amountA, uint256 amountB, , ) = manager.mintPositionNftToSender(
            pool,
            packedSqrtPriceBreaks,
            packedArgs
        );
        console2.log("Amount tokenA Added ", amountA);
        console2.log("Amount tokenB Added ", amountB);
    }
}
