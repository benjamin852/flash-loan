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

contract FlashSwap is IUniswapV3FlashCallback, PeripheryPayments {
    /*** STORAGE ***/
    ISwapRouter public immutable swapRouter;

    /*
     - token amounts and address pulled out of pool
     - fee tiers determine which pool we withdraw & swap with
    */
    struct FlashParams {
        address token0;
        address token1;
        uint24 fee1;
        uint256 amount0;
        uint256 amount1;
        uint24 fee2;
        uint24 fee3;
    }

    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address payer;
        PoolAddress.PoolKey poolKey; //sorted tokens with the matched fee tier
        uint24 poolFee2;
        uint24 poolFee3;
    }

    /*** MODIFIERS ***/
    modifier lock() {
        _;
    }

    modifier noDelegateCall() {
        _;
    }

    /*** CONSTRUCTOR ***/

    /**
     * @notice set needed contract addresses in local storage
     * @param _swapRouter swapRouter address
     * @param _factory factory address
     * @param _weth9 weth9 address
     */
    constructor(
        ISwapRouter _swapRouter,
        address _factory,
        address _weth9
    ) PeripheryImmutableState(_factory, _weth9) {
        swapRouter = _swapRouter;
    }

    /*** FUNCTIONS ***/

    /**
     *
     * @param _flashParams token addresses and fee
     */
    function initFlash(FlashParams memory _flashParams) external {
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({
            token0: _flashParams.token0,
            token1: _flashParams.token1,
            fee: _flashParams.fee1
        });
    }

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
