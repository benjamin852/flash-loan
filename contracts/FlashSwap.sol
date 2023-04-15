// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";

import "@uniswap/v3-periphery/contracts/base/PeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/base/PeripheryImmutableState.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract FlashSwap is
    IUniswapV3FlashCallback,
    PeripheryImmutableState,
    PeripheryPayments
{
    /*** STORAGE ***/
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    ISwapRouter public immutable swapRouter;

    /*
     - token amounts and address pulled out of pool
     - fee tiers determine which pool we withdraw & swap with
    */
    struct FlashParams {
        address token0;
        address token1;
        uint24 fee1; //fee for initial borrow
        uint256 amount0;
        uint256 amount1;
        uint24 fee2; //fee for first pool to arb from
        uint24 fee3; //fee for the second pool to arb from
    }

    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address payer;
        PoolAddress.PoolKey poolKey; //sorted tokens with the matched fee tier
        uint24 poolFee2; //fee for second pool of token0 & token1
        uint24 poolFee3; //fee for second pool of token0 & token1
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
     * @notice create new flash loan on pool
     * @param _flashParams token addresses and fee
     */
    function initFlash(FlashParams memory _flashParams) external {
        //unique struct for each pool
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({
            token0: _flashParams.token0,
            token1: _flashParams.token1,
            fee: _flashParams.fee1
        });

        //get uniswap pool
        IUniswapV3Pool pool = IUniswapV3Pool(
            PoolAddress.computeAddress(factory, poolKey)
        );

        // call flash on our pool
        pool.flash(
            address(this),
            _flashParams.amount0,
            _flashParams.amount1,
            //will be decoded in the callback for part2 of tx
            abi.encode(
                FlashCallbackData({
                    amount0: _flashParams.amount0,
                    amount1: _flashParams.amount1,
                    payer: msg.sender,
                    poolKey: poolKey,
                    poolFee2: _flashParams.fee2,
                    poolFee3: _flashParams.fee3
                })
            )
        );
    }

    /**
     * @param _fee0 fee for the first pool
     * @param _fee1 fee for the second pool
     * @param _data encoded from call data
     */
    function uniswapV3FlashCallback(
        uint256 _fee0,
        uint256 _fee1,
        bytes calldata _data
    ) external override {
        FlashCallbackData memory decoded = abi.decode(
            _data,
            (FlashCallbackData)
        );

        //verify call coming from uniswap pool
        CallbackValidation.verifyCallback(factory, decoded.poolKey);

        address token0 = decoded.poolKey.token0;
        address token1 = decoded.poolKey.token1;

        //approve router to interact with token0
        TransferHelper.safeApprove(
            token0,
            address(swapRouter),
            decoded.amount0
        );

        // approve router to interact with token1
        TransferHelper.safeApprove(
            token1,
            address(swapRouter),
            decoded.amount1
        );

        // set min amount to revert if trade no profitable
        uint256 amount0Min = LowGasSafeMath.add(decoded.amount0, _fee0);
        uint256 amount1Min = LowGasSafeMath.add(decoded.amount1, _fee1);

        //swap out withdrawn token0 for token1 in pool with fee2
        // pool determined by token pair with next pool fee
        uint256 amountEarned0 = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token0,
                fee: decoded.poolFee2,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: decoded.amount1,
                amountOutMinimum: amount0Min,
                sqrtPriceLimitX96: 0
            })
        );

        //swap out token1 for token0 pool with fee3
        uint256 amountEarned1 = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token0,
                tokenOut: token1,
                fee: decoded.poolFee3,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: decoded.amount0,
                amountOutMinimum: amount1Min,
                sqrtPriceLimitX96: 0
            })
        );

        _paybackPool(
            decoded.amount0,
            decoded.amount1,
            _fee0,
            _fee1,
            token0,
            token1,
            amountEarned0,
            amountEarned1,
            decoded.payer
        );
    }

    /*** HELPERS ***/

    /**
     *
     * @param _swapAmount0 amount of tokenOne swapped in on dex1 (i think)
     * @param _swapAmount1 amount of tokenTwo swapped in on dex1 (i think)
     * @param _fee0 swap fee for tokenOne on dexOne
     * @param _fee1 swap fee for tokenTwo  on dexOne
     * @param _token0 address of tokenOne
     * @param _token1 address of tokenTwo
     * @param _amountEarnedToken0 amount of token0 earned on output of swap
     * @param _amountEarnedToken1 amount of token1 earned on output of swap
     * @param _payer user triggering the flash loan
     */
    function _paybackPool(
        uint256 _swapAmount0,
        uint256 _swapAmount1,
        uint256 _fee0,
        uint256 _fee1,
        address _token0,
        address _token1,
        uint256 _amountEarnedToken0,
        uint256 _amountEarnedToken1,
        address _payer
    ) public {
        //owed is howmuch i borrowed + the fee
        uint256 amountToken0Owed = LowGasSafeMath.add(_swapAmount0, _fee0);
        uint256 amountToken1Owed = LowGasSafeMath.add(_swapAmount1, _fee1);

        //enable swap to transfer token0 owed
        TransferHelper.safeApprove(_token0, address(this), amountToken0Owed);
        TransferHelper.safeApprove(_token1, address(this), amountToken1Owed);

        //pay back pool
        if (amountToken0Owed > 0) {
            //pay from address(this)
            //pay to to msg.sender (pool is calling this)
            pay(_token0, address(this), msg.sender, amountToken0Owed);
        }

        //pay back pool
        if (amountToken1Owed > 0) {
            pay(_token1, address(this), msg.sender, amountToken1Owed);
        }

        //pay remaining profits to flash loaner
        if (_amountEarnedToken0 > amountToken0Owed) {
            uint256 profitToken0 = LowGasSafeMath.sub(
                _amountEarnedToken0,
                amountToken0Owed
            );

            TransferHelper.safeApprove(_token0, address(this), profitToken0);

            pay(_token0, address(this), _payer, profitToken0);
        }

        if (_amountEarnedToken1 > amountToken1Owed) {
            uint256 profitToken1 = LowGasSafeMath.sub(
                _amountEarnedToken1,
                amountToken1Owed
            );

            TransferHelper.safeApprove(_token0, address(this), profitToken1);

            pay(_token0, address(this), _payer, profitToken1);
        }
    }
}
