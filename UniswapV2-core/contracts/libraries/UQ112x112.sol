pragma solidity =0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

// 自定义的数据格式库
// 在UniswapV2中，价格为两种代币的数量比值，而在Solidity中，对非整数类型支持不好，通常两个无符号整数相除为地板除，会截断。为了提高价格精度，UniswapV2使用uint112来保存交易对中资产的数量，而比值（价格）使用UQ112x112表示，一个代表整数部分，一个代表小数部分。
library UQ112x112 {
    uint224 constant Q112 = 2 ** 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}
