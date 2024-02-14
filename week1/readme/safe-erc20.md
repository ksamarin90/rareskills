The first problem with "transfer" and "transferFrom" is that they do not revert
but return boolean - whether operation was successful or not.

Thus, it is a responsibility of a smart contract developer to check for success and handle possible failures.

Moreover, some "ERC-20" tokens do not follow the specification strictly and instead of returning boolean - revert.

For that reason there is a library from OpenZeppelin - SafeERC20.
It provides 'safe' operations like: "safeTransfer", "safeTransferFrom", "safeIncreaseAllowance", "safeDecreaseAllowance" and others.
So it unifies behavior across various ERC-20 tokens by reverting transaction if it was unsuccessful.

There is an alternative to SafeERC20 - Solmate's SafeTransferLib.
It is generally more gas efficient, but does not check whether the called 'token' is really a token.
It might be an issue if smart contract developer relies on the fact that SafeTransferLib will revert
in case of calling EOA address by mistake instead of ERC-20 contract.
