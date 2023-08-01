# Deploy Uniswap V2 to Sepolia

This is a Hardhat setup to deploy the necessary contracts of Uniswap (vulnerable).

**Note:** The repository `./contracts/core/UniswapV2Pair.sol` contains vulnerabilities related to K-value and lock. It should not be used directly in a production environment; it is intended only for educational purposes and reference.

## Get Started

Install packages:

```
yarn
```

Modify the private key and RPC as you wish in the `hardhat.config.js` file.

### Deploy the contracts and Interact the contracts

```
yarn hardhat run --network sepolia scripts/deploy-factory.js
```

If encountered

```
Adding Liquidity...
Error: cannot estimate gas;
```

Because Uniswap uses an init_code hash that was changed in the UniswapV2Library contract, you need to obtain the bytecode from `./artifacts/contracts/core/UniswapV2Pair.sol/UniswapV2Pair.json` and calculate the init code using [Keccak-256 Online Tools](http://emn178.github.io/online-tools/keccak_256.html) with Input type Hex (Remove the leading "0x" from the input.). Afterward, replace the init code in `./contracts/periphery/libraries/UniswapV2Library.sol`.

```solidity
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'eecc85ed9fa5cd0e6b6a2b30ac81f809a51e9d22908fee474a8cd15c539b41cb' // init code hash
            ))));
    }
```

Run it again

```
yarn hardhat run --network sepolia scripts/deploy-factory.js
```

verify contract:

```
yarn hardhat verify-contract --network sepolia
```
