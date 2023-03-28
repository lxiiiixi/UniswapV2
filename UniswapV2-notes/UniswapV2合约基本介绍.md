## 合约概览和关系介绍

- UniswapV2-core/constract

  - interfaces

    - IERC20.sol

      ERC20 接口

    - IUniswapV2Callee.sol

    - IUniswapV2ERC20.sol

    - IUniswapV2Factory.sol

    - IUniswapV2Pair.sol

  - libraries

    - Math.sol
    - SafeMath.sol
    - UQ112x112.sol

  - UniswapV2ERC20.sol

    ERC20 合约，该合约为交易对合约的父合约，主要实现了ERC20代币功能并增加了对线下签名消息进行授权的支持。它除了标准的ERC20接口外还有自己的接口，因此取名为`UniswapV2ERC20`。

  - UniswapV2Factory.sol

    工厂合约

  - UniswapV2Pair.sol

    该合约是交易对合约，在其父合约`UniswapV2ERC20`的基础上增加了资产交易及流动性供给等功能。

  > - UniswapV2Pair 继承 UniswapV2ERC20（这两个可以看作是整体的一个合约）
  >
  > - UniswapV2Factory 是用来部署 UniswapV2Pair 合约的（UniswapV2Factory 引用了 UniswapV2Pair）（每一个交易对都有一个单独的 pair 合约）

- UniswapV2-periphery/constract





> 创建流动性：
>
> 1. 项目方通过 UniswapV2Router 创建流动性
> 2. UniswapV2Router 调用了 UniswapV2Factory 去创建交易对
> 3. 交易对的创建就需要部署 UniswapV2Pair
>
>  
>
> 交易：
>
> 1. 用户通过 UniswapV2Router 交易
> 2. UniswapV2Router 直接调用已经创建好的交易对



## Uniswap 运行逻辑

1. uniswap核心合约分为3个合约, 工厂合约，配对合约, ERC20合约

2. 核心合约布署时只需要布署工厂合约

3. 工厂合约布署时构造函数只需要设定一个手续费管理员

4. 在工厂合约布署之后，就可以进行创建配对的操作
5. 要在交易所中进行交易，操作顺序是:创建交易对添加流动性，交易
6. 添加配对时需要提供两个token的地址，随后工厂合约会为这个交易对布署一个新的配对合约
7. 配对合约的布署是通过create2的方法
8. 两个token地址按2进制大小排序后一起进行hash以这个hash值作为create2的salt进行布署
9. 所以配对合约的地址是可以通过两个token地址进行create2计算的
10. 用户可以将两个token存入到配对合约中，然后在配对合约中为用户生成一种兼容ERC20的token
11. 配对合约中生成的erc20Token可以成为流动性
12. 用户可以将自己的流动性余额兑换成配对合约中的任何一种token
13. 用户也可以取出流动性，配对合约将销毁流动性，并将两种token同时返还用户
14. 返还的数量将根据流动性数量和两种token的储备量重新计算，如果有手续费收益，用户也将得到收益
15. 用户可以通过一种token交换另一种token配对合约将扣除千分之3的手续费
16. 在uniswap核心合约基础上，还有一个路由合约用来更好的操作核心合约
17. 路由合约拥有3部分操作方法，添加流动性，移除流动性，交换
18. 虽然配对合约已经可以完成所有的交易操作，但路由合约将所有操作整合，配合前端更好的完成交易
19. 因为路由合约的代码量较多，布署时会超过gas限制，所以路由合约被分为两个版本，功能互相补充



































