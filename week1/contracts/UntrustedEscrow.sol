// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract UntrustedEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct PriceDetail {
        IERC20 token;
        uint256 amount;
    }

    struct Payment {
        uint256 amount;
        IERC20 token;
        uint96 createdAt;
    }

    error InvalidPrice();
    error Locked();
    error AlreadyPayed();
    error NonExistentPayment();

    event SellerPrice(address indexed seller, IERC20 indexed token, uint256 amount);
    event BuyerPayment(
        address indexed buyer,
        address indexed seller,
        IERC20 indexed token,
        uint256 amount
    );
    event SellerWithdraw(
        address indexed buyer,
        address indexed seller,
        IERC20 indexed token,
        uint256 amount
    );

    uint256 public constant LOCKUP_PERIOD = 3 days;

    mapping(address => mapping(IERC20 => uint256)) public sellerPriceDetails;
    mapping(address => mapping(address => Payment)) public buyerToSellerPayment;

    constructor() {}

    function setSellerPriceDetails(PriceDetail[] calldata priceDetails) external {
        for (uint256 i = 0; i < priceDetails.length; i++) {
            sellerPriceDetails[msg.sender][priceDetails[i].token] = priceDetails[i].amount;
            emit SellerPrice(msg.sender, priceDetails[i].token, priceDetails[i].amount);
        }
    }

    function buy(address seller, PriceDetail memory payment) external nonReentrant {
        if (buyerToSellerPayment[msg.sender][seller].amount != 0) revert AlreadyPayed();

        uint256 received = _transferFromWithBalanceCheck(
            payment.token,
            msg.sender,
            address(this),
            payment.amount
        );
        if (received != sellerPriceDetails[seller][payment.token]) revert InvalidPrice();

        buyerToSellerPayment[msg.sender][seller] = Payment({
            amount: received,
            token: payment.token,
            createdAt: uint96(block.timestamp)
        });

        emit BuyerPayment(msg.sender, seller, payment.token, payment.amount);
    }

    function withdraw(address[] calldata buyers) external nonReentrant {
        for (uint256 i = 0; i < buyers.length; i++) {
            Payment memory payment = buyerToSellerPayment[buyers[i]][msg.sender];
            if (payment.amount == 0) revert NonExistentPayment();
            if (payment.createdAt + LOCKUP_PERIOD > block.timestamp) revert Locked();
            delete buyerToSellerPayment[buyers[i]][msg.sender];

            payment.token.safeTransfer(msg.sender, payment.amount);

            emit SellerWithdraw(buyers[i], msg.sender, payment.token, payment.amount);
        }
    }

    function _transferFromWithBalanceCheck(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        uint256 balanceBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, amount);
        uint256 balanceAfter = token.balanceOf(to);
        return balanceAfter - balanceBefore;
    }
}
