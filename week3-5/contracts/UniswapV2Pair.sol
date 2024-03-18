// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {UniswapV2Factory} from "./UniswapV2Factory.sol";

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";

import {IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract UniswapV2Pair is ERC20, ReentrancyGuard, IERC3156FlashLender {
    using FixedPointMathLib for uint256;

    address public factory;
    address public token0;
    address public token1;

    uint256 private reserve0;
    uint256 private reserve1;
    uint256 private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;

    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);

    error INSUFFICIENT_OUTPUT_AMOUNT();
    error INSUFFICIENT_INPUT_AMOUNT();
    error INSUFFICIENT_LIQUIDITY();
    error FLASH_LOAN_FAILED();
    error INVALID_PAIR();
    error EXPIRED();
    error K();

    struct SwapArgs {
        address to;
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 amount0In;
        uint256 amount1In;
        uint256 amount0Out;
        uint256 amount1Out;
        uint256 balance0;
        uint256 balance1;
    }

    constructor(address _token0, address _token1) {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    modifier checkDeadline(uint256 deadline) {
        if (deadline < block.timestamp) revert EXPIRED();
        _;
    }

    modifier checkToken(address token) {
        if (token != token0 && token != token1) revert INVALID_PAIR();
        _;
    }

    function name() public view override returns (string memory) {
        return "test";
    }

    function symbol() public view override returns (string memory) {
        return "tst";
    }

    function maxFlashLoan(address token) external view checkToken(token) returns (uint256) {
        return token == token0 ? reserve0 : reserve1;
    }

    function flashFee(
        address token,
        uint256 amount
    ) external view checkToken(token) returns (uint256) {
        return _flashFee(amount);
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external checkToken(token) returns (bool) {
        SafeTransferLib.safeTransfer(token, msg.sender, amount);
        uint256 fee = _flashFee(amount);
        if (
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) !=
            keccak256("ERC3156FlashBorrower.onFlashLoan")
        ) revert FLASH_LOAN_FAILED();
        SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), amount + fee);
        return true;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        checkDeadline(deadline)
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        (amountA, amountB) = _addLiquidity(amountADesired, amountBDesired, amountAMin, amountBMin);
        SafeTransferLib.safeTransferFrom(tokenA, msg.sender, token0, amountA);
        SafeTransferLib.safeTransferFrom(tokenB, msg.sender, token1, amountB);
        liquidity = mint_(to);
    }

    function swapExactFrom(
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline,
        address fromToken
    ) external checkDeadline(deadline) nonReentrant returns (uint256) {
        if (amountIn == 0) revert INSUFFICIENT_INPUT_AMOUNT();
        SwapArgs memory args = SwapArgs(to, token0, token1, reserve0, reserve1, 0, 0, 0, 0, 0, 0);
        if (args.reserve0 == 0 || args.reserve1 == 0) revert INSUFFICIENT_LIQUIDITY();
        uint256 amountOut = fromToken == args.token0
            ? _getAmountOut(amountIn, args.reserve0, args.reserve1)
            : _getAmountOut(amountIn, args.reserve1, args.reserve0);
        if (amountOut < amountOutMin) revert INSUFFICIENT_OUTPUT_AMOUNT();
        SafeTransferLib.safeTransferFrom(fromToken, msg.sender, address(this), amountIn);
        if (fromToken == token0) {
            args.amount1Out = amountOut;
            SafeTransferLib.safeTransfer(args.token1, args.to, args.amount1Out);
        } else {
            args.amount0Out = amountOut;
            SafeTransferLib.safeTransfer(args.token0, args.to, args.amount0Out);
        }
        args.balance0 = ERC20(args.token0).balanceOf(address(this));
        args.balance1 = ERC20(args.token1).balanceOf(address(this));
        _validateSwap(args);
        _updateState(args.balance0, args.balance1, args.reserve0, args.reserve1);
        emit Swap(
            msg.sender,
            args.amount0In,
            args.amount1In,
            args.amount0Out,
            args.amount1Out,
            args.to
        );
        return amountOut;
    }

    // internal functions

    function _flashFee(uint256 amount) internal pure returns (uint256) {
        return (amount * 5) / 100;
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 tokenIn,
        uint256 tokenOut
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn.rawMul(997);
        uint256 numerator = amountInWithFee.rawMul(tokenIn);
        uint256 denominator = tokenOut.rawMul(1000).rawAdd(amountInWithFee);
        return numerator / denominator;
    }

    function _validateSwap(SwapArgs memory args) internal pure {
        args.amount0In = args.balance0 > args.reserve0 - args.amount0Out
            ? args.balance0 - (args.reserve0 - args.amount0Out)
            : 0;
        args.amount1In = args.balance1 > args.reserve1 - args.amount1Out
            ? args.balance1 - (args.reserve1 - args.amount1Out)
            : 0;
        uint256 balance0Adjusted = args.balance0.rawMul(1000).rawSub(args.amount0In.rawMul(3));
        uint256 balance1Adjusted = args.balance1.rawMul(1000).rawSub(args.amount1In.rawMul(3));
        if (
            balance0Adjusted.rawMul(balance1Adjusted) <
            uint256(args.reserve0).rawMul(args.reserve1).rawMul(1000 ** 2)
        ) revert K();
    }

    function _updateState(
        uint256 balance0,
        uint256 balance1,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal {
        uint256 timeElapsed = block.timestamp - blockTimestampLast;
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            unchecked {
                price0CumulativeLast += _reserve1.rawDiv(_reserve0) * timeElapsed;
                price1CumulativeLast += _reserve0.rawDiv(_reserve1) * timeElapsed;
            }
        }
        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = block.timestamp;
        emit Sync(reserve0, reserve1);
    }

    function _addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = (reserve0, reserve1);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = _quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) revert INSUFFICIENT_INPUT_AMOUNT();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = _quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                if (amountAOptimal < amountAMin) revert INSUFFICIENT_INPUT_AMOUNT();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        if (amountA == 0) revert INSUFFICIENT_INPUT_AMOUNT();
        if (reserveA == 0 || reserveB == 0) revert INSUFFICIENT_LIQUIDITY();
        amountB = amountA.rawMul(reserveB) / reserveA;
    }

    function mint_(address to) internal returns (uint liquidity) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.rawSub(_reserve0);
        uint amount1 = balance1.rawSub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = FixedPointMathLib.sqrt(amount0.rawMul(amount1)).rawSub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = FixedPointMathLib.min(
                amount0.rawMul(_totalSupply) / _reserve0,
                amount1.rawMul(_totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _updateState(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).rawMul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    function _mintFee(uint256 _reserve0, uint256 _reserve1) private returns (bool feeOn) {
        address feeTo = UniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = FixedPointMathLib.sqrt(uint(_reserve0).rawMul(_reserve1));
                uint rootKLast = FixedPointMathLib.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply().rawMul(rootK.rawSub(rootKLast));
                    uint denominator = rootK.rawMul(5).rawAdd(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }
}
