// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";

import "../contracts/FlashSwap.sol";

contract Setup is Test, FlashSwap {
    ISwapRouter public swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IWETH9 public constant WETH =
        IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public flashSwap;

    function setUp() public {
        v3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

        flashSwap = new FlashSwap(swapRouter, v3Factory, IWETH9);
    }
}
