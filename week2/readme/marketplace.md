There are several solutions:

-   Write own blockchain parser. It listens to events on NFT mints and transfers, or periodically lookup
    blockchain for new events and updates the DB with corresponding ownership info. (No restrictions for new chains)
-   Use existing services like The Graph. It will do essentially the same but abstracts complexity and additional hassle. Moreover, for certain chains The Graph offers decentralized storage so that it could provide better data integrity. (Does not support all chains. If it is new L2 then probably one will need to stick to the previous solution)
-   Avoid any service and query for events on frontend. It could work fine if NFTs are traded frequently.
    Otherwise it will take a significant amount of time to find last event on chain, resulting in poor UX.
