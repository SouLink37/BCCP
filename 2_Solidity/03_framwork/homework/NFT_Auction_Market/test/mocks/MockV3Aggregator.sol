// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title MockV3Aggregator
/// @notice 模拟 Chainlink 价格预言机，用于测试
contract MockV3Aggregator is AggregatorV3Interface {
    uint8 private _decimals;
    int256 private _answer;

    constructor(uint8 decimals_, int256 initialAnswer) {
        _decimals = decimals_;
        _answer = initialAnswer;
    }

    /// @notice 返回小数位数（Chainlink 标准是 8）
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /// @notice 返回预言机描述
    function description() external pure override returns (string memory) {
        return "Mock Chainlink Price Feed";
    }

    /// @notice 返回版本号
    function version() external pure override returns (uint256) {
        return 1;
    }

    /// @notice 获取指定轮次的价格数据
    function getRoundData(uint80)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, _answer, block.timestamp, block.timestamp, 1);
    }

    /// @notice 获取最新价格数据
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, _answer, block.timestamp, block.timestamp, 1);
    }

    /// @notice 手动设置价格（测试用）
    function setPrice(int256 newAnswer) external {
        _answer = newAnswer;
    }
}
