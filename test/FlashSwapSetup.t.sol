// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";

import "../contracts/FlashSwap.sol";

contract FlashSwapSetup is Test {
    ISwapRouter public swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IWETH9 public constant WETH9 =
        IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    FlashSwap public flashSwap;

    address public v3Factory;

    function setUp() public {
        v3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

        flashSwap = new FlashSwap(swapRouter, v3Factory, address(WETH9));

        vm.deal(address(flashSwap), 20 ether);
        vm.deal(vm.addr(1), 20 ether);

        vm.prank(vm.addr(1));
        WETH9.deposit{value: 20 ether}();

        vm.prank(address(flashSwap));
        WETH9.deposit{value: 20 ether}();

        vm.prank(0x756D64Dc5eDb56740fC617628dC832DDBCfd373c);
        USDC.transfer(address(flashSwap), 0.0002 ether);

        ISwapRouter actualSwapRouter = flashSwap.swapRouter();
        assertEq(address(swapRouter), address(actualSwapRouter));
    }
}
