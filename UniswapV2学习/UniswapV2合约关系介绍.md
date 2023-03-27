- UniSwapV2-core/constract

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

  > UniswapV2Pair 继承 UniswapV2ERC20
  >
  > UniswapV2Factory 使用来部署 UniswapV2Pair 合约的
  >
  > （每一个交易对都有一个单独的 pair 合约）