pragma solidity =0.5.16;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/SafeMath.sol';

// uniswapV2 的核心合约之二

// 该合约为交易对合约的父合约
contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    // 定义了ERC20代币的三个对外状态变量（代币元数据）：名称，符号和精度
    string public constant name = 'Uniswap V2';
    string public constant symbol = 'UNI-V2';
    uint8 public constant decimals = 18;

    uint public totalSupply;
    mapping(address => uint) public balanceOf; // 记录地址对应的余额
    mapping(address => mapping(address => uint)) public allowance; // 记录每个地址的授权分布

    bytes32 public DOMAIN_SEPARATOR; // 用于在不同的Dapp之间区分相同结构和内容的签名信息

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // 根据事先约定使用`permit`函数的部分定义计算哈希值，重建消息签名时使用。

    mapping(address => uint) public nonces;
    // 记录合约中每个地址使用链下签名消息交易的数量，用来防止重放攻击。

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        // 根据EIP-712的介绍，该值通过`domainSeparator = hashStruct(eip712Domain)`计算。
        // 其中`eip712Domain`是一个名为`EIP712Domain`的 结构，它可以有以下一个或者多个字段：
        // - `string name` 可读的签名域的名称，例如Dapp的名称，在本例中为代币名称。
        // - `string version`当前签名域的版本，本例中为"1"。
        // - `uint256 chainId`。当前链的ID，注意因为Solidity不支持直接获取该值，所以使用了内嵌汇编来获取。
        // - `address verifyingContract`验证合约的地址，在本例中就是本合约地址了。
        // 结构体本身无法直接进行hash运算，所以构造器中先进行了转换，`hashStruct`就是指将结构体转换并计算最终hash的过程。
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        // 代币增发函数（内部函数）
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        // 代币销毁函数（内部函数）
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        // 授权操作（private函数）
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        // 代币转移函数（private函数）
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        // 授权操作（内部函数）
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            // 如果你的授权额度为最大值（几乎用不完，相当于永久授权），为了减小操作步数和gas，调用时授权余额是不扣除相应的转移代币数量的。这里如果没有授权（授权额度为0），那么会怎样呢？库函数`.sub(value)`调用时无法通过`SafeMath`的`require`检查，会导致整个交易会被重置。所以如果没有授权，第三方合约是无法转移你的代币的，你不用担心你的资产被别的合约随便偷走。
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        // 使用线下签名消息进行授权操作
        // 线下签名不需要花费任何gas，然后任何其它账号或者智能合约可以验证这个签名后的消息，然后再进行相应的操作（这一步可能是需要花费gas的，签名本身是不花费gas的）。线下签名还有一个好处是减少以太坊上交易的数量，UniswapV2中使用线下签名消息主要是为了消除代币授权转移时对授权交易的需求。
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s); // Solidity中的一个内置的函数`ecrecover`：获取消息的签名地址
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
