// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IMaverickV2Pool} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Pool.sol";
import {IMaverickV2Factory} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Factory.sol";
import {IMaverickV2LiquidityManager} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2LiquidityManager.sol";
import {IMaverickV2PoolLens} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2PoolLens.sol";
import {IMaverickV2Quoter} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Quoter.sol";
import {IMaverickV2Router} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Router.sol";
import {IMaverickV2Position} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Position.sol";
import {IVault} from "../interfaces/IVault.sol";

abstract contract BaseTest is Test {
    IMaverickV2Factory internal factory;

    IMaverickV2Pool public pool;
    IERC20 public weth;
    IERC20 public oethp;

    IMaverickV2LiquidityManager public manager =
        IMaverickV2LiquidityManager(payable(0x28d79eddBF5B215cAccBD809B967032C1E753af7));
    IMaverickV2PoolLens public lens = IMaverickV2PoolLens(0x15B4a8cc116313b50C19BCfcE4e5fc6EC8C65793);
    IMaverickV2Quoter public quoter = IMaverickV2Quoter(0xf245948e9cf892C351361d298cc7c5b217C36D82);
    IMaverickV2Router public router = IMaverickV2Router(payable(0x35e44dc4702Fd51744001E248B49CBf9fcc51f0C));
    IMaverickV2Position public position = IMaverickV2Position(0x0b452E8378B65FD16C0281cfe48Ed9723b8A1950);
    IVault public oethVault = IVault(0xc8c8F8bEA5631A8AF26440AF32a55002138cB76a);

    address public this_;

    function startFork() internal {
        vm.selectFork(vm.createFork("https://phoenix-rpc.plumenetwork.xyz", 1231568));
        factory = IMaverickV2Factory(0x056A588AfdC0cdaa4Cab50d8a4D2940C5D04172E);
        pool = IMaverickV2Pool(0xcA26a025eD16c5becD100C0165136aA1E34f7E58);
        weth = pool.tokenA();
        oethp = pool.tokenB();
        this_ = address(this);

        deal(address(weth), this_, 1e50);
        //deal(address(oethp), this_, 1e50);
        weth.approve(address(oethVault), 1e22);
        oethVault.mint(address(weth), 1e22, 0);

        deal(address(weth), this_, 1e50);
    }

    // returns flat liquidity distribution +/- 2 ticks from the active tick
    function _getTickAndRelativeLiquidity(
        uint128 liquidityAmount,
        IMaverickV2Pool _pool
    ) internal view returns (int32[] memory ticks, uint128[] memory relativeLiquidityAmounts) {
        int32 activeTick = _pool.getState().activeTick;
        ticks = new int32[](5);
        (ticks[0], ticks[1], ticks[2], ticks[3], ticks[4]) = (
            activeTick - 2,
            activeTick - 1,
            activeTick,
            activeTick + 1,
            activeTick + 2
        );

        // relative liquidity amounts are in the liquidity domain, not the LP
        // balance domain. i.e. these are the values a user might input into
        // the addLiquidity bar-graph screen in the app.mav.xyz app.  the scale
        // is relative, but larger numbers are better as they allow more
        // precision in the deltaLPBalance calculation.
        relativeLiquidityAmounts = new uint128[](5);
        (
            relativeLiquidityAmounts[0],
            relativeLiquidityAmounts[1],
            relativeLiquidityAmounts[2],
            relativeLiquidityAmounts[3],
            relativeLiquidityAmounts[4]
        ) = (liquidityAmount, liquidityAmount, liquidityAmount, liquidityAmount, liquidityAmount);
    }
}
