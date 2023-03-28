pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

// uniswapV2 的核心合约之一 工厂合约
// uniswapV2 只需要部署工厂合约 pair合约是通过工厂合约创建的

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    // feeTo：这个状态变量主要是用来切换开发团队手续费开关，收税地址。在UniswapV2中，用户在交易代币时，会被收取交易额的千分之三的手续费分配给所有流动性供给者。如果`feeTo`不为零地址，则代表开关打开，此时会在手续费中分1/6给开发团队。`feeTo`设置为零地址（默认值），则开关关闭，不从流动性供给者中分走1/6手续费。它的访问权限设置为public后编译器会默认构建一个同名public函数，正好用来实现`IUniswapV2Factory.sol`中定义的相关接口。
    address public feeToSetter;
    // feeToSetter：这个状态变量是用来记录谁是`feeTo`设置者，收税权限控制地址。其读取权限设置为public的主要目的同上。

    mapping(address => mapping(address => address)) public getPair;
    // getPair：`mapping(address => mapping(address => address)) public getPair;`这个状态变量是一个map(其key为地址类型，其value也是一个map)，它用来记录所有的交易对地址。注意，它的名称为`getPair`并且为`public`的，这样的目的也是让默认构建的同名函数来实现相应的接口。注意这行代码中出现了三个`address`，前两个分别为交易对中两种ERC20代币合约的地址，最后一个是交易对合约本身的地址，也就是根据两个代币地址得到其交易对地址。
    address[] public allPairs;
    // allPairs：记录所有交易对地址的数组。虽然交易对址前面已经使用map记录了，但map无法遍历。如果想遍历和索引，必须使用数组。注意它的名称和权限，同样是为了实现接口。

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    // PairCreated：交易对地址的创建事件。注意参数中的`indexed`表明该参数可以被监听端（轻客户端）过滤。

    constructor(address _feeToSetter) public {
        // 构造器，参数提供了一个初始`feeToSetter`地址作为`feeTo`的设置者地址，不过此时`feeTo`仍然为默认值零地址，开发团队手续费未打开。
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        // allPairsLength()：返回所有交易对的数量，这样在合约外部可以方便使用类似`for`这样的形式遍历该数组。
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        // createPair()：接受任意两个代币地址为参数，用来创建一个新的交易对合约并返回新合约的地址
        // external 意味着合约外部的任何账号（或者合约）都可以调用该函数来创建一个新的ERC20/ERC20交易对（前提是该ERC20/ERC20交易对并未创建）

        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        // 相同代币不能创建 pair

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // 对两种代币的合约地址从小到大排序，因为地址类型底层其实是uint160，所以也是有大小可以排序的，具体来说是按照字典顺序（即按照每个地址的十六进制表示进行比较）来排序。
        // 对于 Uniswap 这样的去中心化交易所来说，流动性池子的创建和管理需要对代币的地址进行排序，以确保每个代币对应的交易对只有一个。因此，对于每个交易对，必须按照相同的顺序来排列代币地址，这样才能确保交易对的唯一性和正确性。

        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        // 验证两个地址不能为零地址。为什么只验证了`token0`呢，因为`token1`比它大，它不为零地址，`token1`肯定也就不为零地址。
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS');
        // 验证交易对并未创建（不能重复创建相同的交易对）

        // => 完成所有验证操作之后开始创建交易对合约并初始化

        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        // 获取交易对模板合约`UniswapV2Pair`编译后的节码`creationCode`
        // type() 关键字用于获取某个合约的编译时类型（即编译时类型信息），其中 type(UniswapV2Pair) 返回了 UniswapV2Pair 合约的编译时类型信息，其中包括了合约的代码以及其他元数据信息。然后，通过 .creationCode 属性来获取 UniswapV2Pair 合约的创建字节码（creation bytecode），并将其赋值给了 bytecode 变量。
        // 创建字节码是一种特殊的字节码，用于在以太坊网络上部署智能合约。它包含了智能合约的代码、构造函数参数以及其他元数据信息，可以通过以太坊网络发送一笔交易来将智能合约部署到区块链上。
        // 需要注意的是，这段代码中获取的合约创建字节码是一个静态的值，在编译时就已经确定。如果合约代码发生了修改，合约创建字节码也会发生变化。
        // 注意，它返回的结果是包含了创建字节码的字节数组，类型为`bytes`。类似的，还有运行时的字节码`runtimeCode`。`creationCode`主要用来在内嵌汇编中自定义合约创建流程，特别是应用于`create2`操作码中，这里`create2`是相对于`create`操作码来讲的。注意该值无法在合约本身或者继承合约中获取，因为这样会导致自循环引用。

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // 计算一个`salt`。注意，它使用了两个代币地址作为计算源，这就意味着，对于任意交易对，该`salt`是固定值并且可以线下计算出来。

        assembly {
            // 这是一段内嵌汇编代码，Solidity中内嵌汇编语言为Yul语言。在Yul中，使用同名的内置函数来代替直接使用操作码
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
            // 在Yul代码中使用了`create2`函数（该函数名表明使用了create2操作码）来创建新合约，并且加盐，返回地址到 pair 变量。
            // create2(v, p, n, s)：`v`代表发送到新合约的eth数量（以`wei`为单位），`p`代表代码的起始内存地址，`n`代表代码的长度，`s`代表`salt`。
        }

        IUniswapV2Pair(pair).initialize(token0, token1);
        // 调用新创建的交易对合约的一个初始化方法，将排序后的代币地址传递过去。为什么要这样做呢，因为使用`create2`函数创建合约时无法提供构造器参数。

        // => 接下来开始记录新创建的交易对地址并触发交易对创建事件

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        // 将交易对地址记录到map中去
        // A/B交易对同时也是B/A交易对，在查询交易对时，用户提供的两个代币地址并没有排序，所以需要记录两次
        allPairs.push(pair);
        // 第13行将交易对地址记录到数组中去，便于合约外部索引和遍历。
        emit PairCreated(token0, token1, pair, allPairs.length);
        // 触发交易对创建事件
    }

    function setFeeTo(address _feeTo) external {
        // setFeeTo()：设置新的`feeTo`以切换开发团队手续费开关（可以为开发团队接收手续费的地址，也可以为零地址）
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN'); // 调用者必须为`feeTo`的设置者`feeToSetter`，如果不是则会重置整个交易。
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        // setFeeToSetter()：转让`feeToSetter`。它首先判定调用者必须是原`feeToSetter`，否则重置整个交易。
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
