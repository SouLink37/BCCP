// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title AuctionToken
/// @notice 用于拍卖市场的 ERC20 代币（模拟 USDC/USDT）
contract AuctionToken is ERC20 {
    uint8 private _decimals;

    /// @param name_ 代币名称，如 "Mock USDC"
    /// @param symbol_ 代币符号，如 "USDC"
    /// @param decimals_ 小数位数（USDC/USDT 都是 6）
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _mint(msg.sender, 1000000 * (10 ** decimals_));
    }

    /// @notice 重写 decimals 函数
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @notice Mint 代币（测试用）
    /// @param to 接收地址
    /// @param amount 数量（注意小数位）
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
