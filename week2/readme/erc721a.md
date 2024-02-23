ERC721a improves ERC721Enumerable primarily by reducing amount of storage variables
and write operations.

-   It utilizes compact bit packing storing multiple values in one slot.
    Thus allowing to batch minting of multiple nfts without linear gas cost increase.
-   It adds gas cost for read operations, since data should be parsed correctly.
    Means - contract which rely on functions like "balanceOf", "ownerOf" will incur more gas cost.
