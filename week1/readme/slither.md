-   Reentrancy in UntrustedEscrow.buy(address,UntrustedEscrow.PriceDetail) (contracts/UntrustedEscrow.sol#55-73):

False. There is a formal reentrancy, nonReentrant modifier is used.

-   Reentrancy in UntrustedEscrow.withdraw(address[]) (contracts/UntrustedEscrow.sol#75-86):
    External calls:
    payment.token.safeTransfer(msg.sender,payment.amount) (contracts/UntrustedEscrow.sol#82)
    State variables written after the call(s):
    delete buyerToSellerPayment[buyers[i]][msg.sender] (contracts/UntrustedEscrow.sol#80)

False. nNot correct at all.

-   Ownable.transferOwnership(address) (contracts/test/TetherToken.sol#68-72) should emit an event for: - owner = newOwner (contracts/test/TetherToken.sol#70)

True. Event should be emitted here.

-   TetherToken.deprecate(address).\_upgradedAddress (contracts/test/TetherToken.sol#397) lacks a zero-check on : - upgradedAddress = \_upgradedAddress (contracts/test/TetherToken.sol#399)

True. But from my perspective non zero check is not that obligatory.

-   UntrustedEscrow.withdraw(address[]) (contracts/UntrustedEscrow.sol#75-86) uses timestamp for comparisons
    Dangerous comparisons: - payment.createdAt + LOCKUP_PERIOD > block.timestamp (contracts/UntrustedEscrow.sol#79)

True, but it feels rather outdated especially with PoS.

-   solc-0.8.20 is not recommended for deployment

False. 0.8.24 is the latest version. Updated my slither to the latest version.

-   Variable ERC20Basic.\_totalSupply (contracts/test/TetherToken.sol#81) is not in mixedCase

False. Complete BS.

-   BasicToken.basisPointsRate (contracts/test/TetherToken.sol#116) should be constant / TokenSale.baseToken (contracts/TokenSale.sol#19) should be immutable

True.
