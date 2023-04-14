// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../contracts/FlashSwap.sol";
import "./FlashSwapSetup.t.sol";

contract InitFlash is Test, FlashSwapSetup {
    function testFlashSwap() external {
        flashSwap.initFlash(
            FlashSwap.FlashParams({
                token0: address(UNI),
                token1: address(USDC),
                fee1: 3000,
                amount0: 2 ether,
                amount1: 0,
                fee2: 200,
                fee3: 300
            })
        );
    }
}
