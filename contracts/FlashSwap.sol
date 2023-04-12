// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";

import "@uniswap/v3-periphery/contracts/base/PeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/base/PeripheryImmutableState.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract FlashSwap {
    /*** STORAGE ***/

    /*** MODIFIERS ***/
    modifier lock() {
        _;
    }

    modifier noDelegateCall() {
        _;
    }

    /*** FUNCTIONS ***/

    /**
     * @notice borrow and payback funds in one tx
     * @param _recipient recipient of the loan
     * @param _token0Amount amount of token0 being withdrawn
     * @param _token1Amount  amount of token1 being withdrawn
     * @param _data encoded data to be used during swap
     */
    function flash(
        address _recipient,
        uint256 _token0Amount,
        uint256 _token1Amount,
        bytes calldata _data
    ) external override lock noDelegateCall {}
}
