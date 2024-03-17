**Why does the price0CumulativeLast and price1CumulativeLast never decrement?**

There is no need for them to decrement. Uniswap heavily relies on modular arithmetic and overflows are desired.
It means internally calculations will be always correct at any point of time, therefore those storage variables will be simply aggregated.

**How do you write a contract that uses the oracle?**

The contract should take snapshots of Uniswap pair price. After certain period of time TWAP can be calculated using previously saved price0CumulativeLast and price1CumulativeLast and current values.
In this way it is possible to highly customize time frames which are needed by your own contract.

**Why are price0CumulativeLast and price1CumulativeLast stored separately? Why not just calculate `price1CumulativeLast = 1/price0CumulativeLast?**

Is it much simpler to track both values and do not rely on ratio, since ratio in case of changing denominator
would not reflect the actual price change - 1 / (2 + 3) != 1/2 + 1/3.
