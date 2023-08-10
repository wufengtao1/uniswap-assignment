const { task } = require("hardhat/config");
const { readFile } = require("../scripts/tools");
const path = require("path");

// yarn hardhat verify-contract --network sepolia

const deploymentPath = path.resolve(
  __dirname,
  "../deployments/deployment.json"
);

task("verify-contract", "Verify contract").setAction(async (_, hre) => {
  const chainId = hre.network.config.chainId;
  if (!chainId || chainId == 31337) return;

  let development;
  try {
    const deploymentContent = readFile(deploymentPath);
    const developments = JSON.parse(deploymentContent);
    development = developments[chainId];
  } catch (error) {
    console.error(error);
    throw new Error("no deployment.");
  }
  if (!development) {
    throw new Error(`no deployment in chain [${chainId}]`);
  }

  console.log(development);

  await tryVerify(development.wethAddress, "contracts/WETH.sol:WETH", []);
  await tryVerify(
    development.factoryAddress,
    "contracts/core/UniswapV2Factory.sol:UniswapV2Factory",
    [development.deployerAddress]
  );
  await tryVerify(
    development.routerAddress,
    "contracts/periphery/UniswapV2Router02.sol:UniswapV2Router02",
    [development.factoryAddress, development.wethAddress]
  );
  await tryVerify(
    development.multicallAddress,
    "contracts/Multicall.sol:Multicall",
    []
  );
  await tryVerify(development.tok1Address, "contracts/Token.sol:Token", [
    "Token1",
    "TOK1"
  ]);
  await tryVerify(development.tok2Address, "contracts/Token.sol:Token", [
    "Token2",
    "TOK2"
  ]);
});

async function tryVerify(address, contract, constructorArguments) {
  try {
    console.log("Verifying... ", contract, address);
    await hre.run("verify:verify", {
      address,
      contract,
      constructorArguments
    });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already verified!");
    } else {
      console.log(e);
    }
  }
}
