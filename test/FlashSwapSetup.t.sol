// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";

import "../contracts/FlashSwap.sol";

contract FlashSwapSetup is Test {
    ISwapRouter public swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IWETH9 public constant WETH =
        IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    FlashSwap public flashSwap;

    address public v3Factory;

    function setUp() public {
        v3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

        flashSwap = new FlashSwap(swapRouter, v3Factory, address(WETH));

        vm.deal(vm.addr(1), 10 ether);

        vm.prank(vm.addr(1));
        WETH.deposit{value: 10 ether}();

        ISwapRouter actualSwapRouter = flashSwap.swapRouter();
        assertEq(address(swapRouter), address(actualSwapRouter));
    }
}
