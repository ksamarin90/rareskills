Both ERC-777 and ERC-1363 aim to extend limited functionality of ERC-20 standard.

ERC-777 was introduced first and proposed following functionality above ERC-20:

-   Operators. Those are actors which are allowed to send tokens on behalf of actual token holder.
-   There are two hooks: "tokensToSend" (called before tokens are sent) and "tokensReceived" (called after tokens were sent)
-   Hooks are called only if token holder registered it in ERC-1820 Registry contract
-   Both token holder and operator can provide their own data payload which will be executed
-   There can be blocks on which tokens holder can receive and send

ERC-777 is prone to reentrancy attack and is considered "over-engineered".
It requires significantly more precautions to devise secure contract implementing this standard.

ERC-1363 aims to solve similar pain-points like ERC-777 (e.g. approve/transferFrom pattern).

-   Allows to execute recipient code after "transfer" or "transferFrom"
-   Spender call can be executed after "approve"
-   "transferAndCall" as well as "transferFromAndCall" call "onTransferReceived" on ERC1363Receiver contract
-   "approveAndCall" calls "onApprovalReceived" on ERC1363Spender contract
