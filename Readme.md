# Deploy Uniswap V2 to Sepolia

This is a Hardhat setup to deploy the necessary contracts of Uniswap.

## Get Started

Install packages:

```
npm i
```

Modify the private keys and RPC as you wish in the `hardhat.config.js` file.

### Deploy the contracts and Interact the contracts

```
npx hardhat run --network sepolia scripts/deploy-factory.js
```
