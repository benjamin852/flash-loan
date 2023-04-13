// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../contracts/FlashSwap.sol";
import "./FlashSwapSetup.t.sol";

contract Constructor is Test, FlashSwapSetup {
    // function setUp() public {}

    function testShouldSetSwapRouter() external {}
}
