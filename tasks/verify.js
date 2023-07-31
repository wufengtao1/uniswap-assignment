import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment, TaskArguments } from "hardhat/types";

import { networkConfig } from "../helper-hardhat-config";
import { utils } from "ethers";

// yarn hardhat verify-contract --network sepolia

task("verify-contract", "Verify contract").setAction(async (_, hre) => {
  const chainId = hre.network.config.chainId;
  if (!chainId || chainId == 31337) return;

  const Token = await hre.deployments.get("Token");
  const contract = Token.address;
  console.log("Verifying Token... ", contract);
  try {
    await hre.run("verify:verify", {
      address: contract,
      contract: "contracts/token/Token.sol:Token",
      constructorArguments: []
    });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already verified!");
    } else {
      console.log(e);
    }
  }
});
