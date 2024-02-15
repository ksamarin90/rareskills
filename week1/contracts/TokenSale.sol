// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenSale is ERC20 {
    using SafeERC20 for IERC20;

    error InvalidIntegral();
    error FreezeTime();

    uint256 public constant SLOPE = 1;
    uint256 public constant Y_INTERCEPT = 0;
    uint256 public constant FREEZE_TIME = 1 minutes;

    IERC20 public baseToken;
    mapping(address => uint256) public lastAction;

    constructor(
        string memory name_,
        string memory symbol_,
        IERC20 baseToken_
    ) ERC20(name_, symbol_) {
        baseToken = baseToken_;
    }

    modifier freezeCheck() {
        address sender = _msgSender();
        if (block.timestamp - lastAction[sender] < FREEZE_TIME) revert FreezeTime();
        lastAction[sender] = block.timestamp;
        _;
    }

    function buy(uint256 amount) external freezeCheck {
        uint256 priceChange = onBuyPriceChange(amount);

        address minter = _msgSender();

        _mint(minter, amount);

        baseToken.safeTransferFrom(minter, address(this), priceChange);
    }

    function sell(uint256 amount) external freezeCheck {
        uint256 priceChange = onSellPriceChange(amount);

        address burner = _msgSender();

        _burn(burner, amount);

        baseToken.safeTransfer(burner, priceChange);
    }

    function onBuyPriceChange(uint256 amount) public view returns (uint256) {
        uint256 currentSupply = totalSupply();
        uint256 newSupply = currentSupply + amount;
        uint256 priceChange = _calculateLinearIntegral(currentSupply, newSupply);
        return priceChange;
    }

    function onSellPriceChange(uint256 amount) public view returns (uint256) {
        uint256 currentSupply = totalSupply();
        uint256 newSupply = currentSupply - amount;
        uint256 priceChange = _calculateLinearIntegral(newSupply, currentSupply);
        return priceChange;
    }

    function _calculateLinearIntegral(uint256 from, uint256 to) internal pure returns (uint256) {
        if (to <= from) revert InvalidIntegral();
        uint256 result = (SLOPE * (to ** 2 - from ** 2)) / 2 + Y_INTERCEPT * (to - from);
        return result;
    }
}
