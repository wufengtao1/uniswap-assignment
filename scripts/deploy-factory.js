const { ethers, network } = require("hardhat");
const { writeFile, readFile } = require("./tools");
const path = require("path");

// Deploy function
async function deploy() {
  [account] = await ethers.getSigners();
  deployerAddress = account.address;
  console.log(`Deploying contracts using ${deployerAddress}`);

  //Deploy WETH
  const weth = await ethers.getContractFactory("WETH");
  const wethInstance = await weth.deploy();
  await wethInstance.deployed();

  console.log(`WETH deployed to : ${wethInstance.address}`);

  //Deploy Factory
  const factory = await ethers.getContractFactory("UniswapV2Factory");
  const factoryInstance = await factory.deploy(deployerAddress);
  await factoryInstance.deployed();

  console.log(`Factory deployed to : ${factoryInstance.address}`);

  //Deploy Router passing Factory Address and WETH Address
  const router = await ethers.getContractFactory("UniswapV2Router02");
  const routerInstance = await router.deploy(
    factoryInstance.address,
    wethInstance.address
  );
  await routerInstance.deployed();

  console.log(`Router V02 deployed to :  ${routerInstance.address}`);

  //Deploy Multicall (needed for Interface)
  const multicall = await ethers.getContractFactory("Multicall");
  const multicallInstance = await multicall.deploy();
  await multicallInstance.deployed();

  console.log(`Multicall deployed to : ${multicallInstance.address}`);

  //Deploy Tokens
  const tok1 = await ethers.getContractFactory("Token");
  const tok1Instance = await tok1.deploy("Token1", "TOK1");
  await tok1Instance.deployed();

  console.log(`Token1 deployed to : ${tok1Instance.address}`);

  const tok2 = await ethers.getContractFactory("Token");
  const tok2Instance = await tok2.deploy("Token2", "TOK2");
  await tok2Instance.deployed();

  console.log(`Token2 deployed to : ${tok2Instance.address}`);

  //Approve router on tokens
  console.log(`Approving Router on Token1`);
  const approveToken1Tx = await tok1Instance.approve(
    routerInstance.address,
    "1000000000000000000000"
  );
  await approveToken1Tx.wait(1);
  console.log(`Approving Router on Token2`);
  const approveToken2Tx = await tok2Instance.approve(
    routerInstance.address,
    "1000000000000000000000"
  );
  await approveToken2Tx.wait(1);

  //Create Pair with Factory and Get Address
  const createPairTx1 = await factoryInstance.createPair(
    tok1Instance.address,
    wethInstance.address
  );
  await createPairTx1.wait(1);

  //Get Block TimeStamp
  const blockTime1 = (await ethers.provider.getBlock()).timestamp;

  //Add Liquidity
  console.log(`Adding Liquidity...`);
  const addLiquidityTx1 = await routerInstance.addLiquidityETH(
    tok1Instance.address,
    "1000000000000000000000",
    "100000000000000000000",
    "10000000000000000",
    deployerAddress,
    blockTime1 + 1800,
    {value: "100000000000000000"}
  );
  await addLiquidityTx1.wait(1);

  // //Swap
  // console.log(`Swap...`);
  // const txResponse = await routerInstance.swapExactTokensForTokens(
  //    '100000',
  //    '10000',
  //    [tok2Instance.address,tok1Instance.address],
  //    deployerAddress,
  //    blockTime + 1800
  // );
  // console.log("Transaction Hash", txResponse.hash);

  const lpAddress1 = await factoryInstance.getPair(
    tok1Instance.address,
    wethInstance.address
  );

  console.log("Liquidity pool1 at address:", lpAddress1);

  //Create Pair with Factory and Get Address
  const createPairTx2 = await factoryInstance.createPair(
    tok2Instance.address,
    wethInstance.address
  );
  await createPairTx2.wait(1);

  //Get Block TimeStamp
  const blockTime2 = (await ethers.provider.getBlock()).timestamp;

  //Add Liquidity
  console.log(`Adding Liquidity...`);
  const addLiquidityTx2 = await routerInstance.addLiquidityETH(
    tok2Instance.address,
    "1000000000000000000000",
    "100000000000000000000",
    "10000000000000000",
    deployerAddress,
    blockTime2 + 1800,
    {value: "100000000000000000"}
  );
  await addLiquidityTx2.wait(1);

  // //Swap
  // console.log(`Swap...`);
  // const txResponse = await routerInstance.swapExactTokensForTokens(
  //    '100000',
  //    '10000',
  //    [tok2Instance.address,tok1Instance.address],
  //    deployerAddress,
  //    blockTime + 1800
  // );
  // console.log("Transaction Hash", txResponse.hash);

  const lpAddress2 = await factoryInstance.getPair(
    tok2Instance.address,
    wethInstance.address
  );

  console.log("Liquidity pool2 at address:", lpAddress2);


  const deployment = {
    deployerAddress,
    wethAddress: wethInstance.address,
    factoryAddress: factoryInstance.address,
    routerAddress: routerInstance.address,
    multicallAddress: multicallInstance.address,
    tok1Address: tok1Instance.address,
    tok2Address: tok2Instance.address,
    lpAddress1: lpAddress1,
    lpAddress2: lpAddress2,
  };

  overWriteSave(deployment);
}

deploy()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

const deploymentPath = path.resolve(
  __dirname,
  "../deployments/deployment.json"
);
function overWriteSave(deployment) {
  const chainId = network.config.chainId;

  let developments = {};
  try {
    developments = JSON.parse(readFile(deploymentPath));
  } catch (error) {}

  writeFile(
    deploymentPath,
    JSON.stringify({ ...developments, ...{ [chainId]: deployment } })
  );
}
