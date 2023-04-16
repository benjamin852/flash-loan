// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../contracts/FlashSwap.sol";
import "./FlashSwapSetup.t.sol";

contract InitFlash is Test, FlashSwapSetup {
    function testFlashSwap() external {
        console.logAddress(address(WETH9));
        console.logAddress(address(USDC));

        console.logAddress(address(flashSwap));

        vm.prank(vm.addr(1));

        flashSwap.initFlash(
            FlashSwap.FlashParams({
                token0: address(USDC),
                token1: address(WETH9),
                fee1: 500,
                amount0: 0.000001 ether,
                amount1: 0.000001 ether,
                fee2: 200,
                fee3: 300
            })
        );
    }
}
