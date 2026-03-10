// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CNHPriceFeed
 * @notice
 *  一个简化版的 CNH/USD 预言机实现，用于测试环境。
 *
 *  - 完全遵循 Chainlink 的 AggregatorV3Interface 接口签名
 *  - 价格单位为「USD，8 位小数」，含义为：1 CNH 等于多少 USD
 *  - 例如：_price = 14492754 表示 1 CNH = 0.14492754 USD，约等于 1 USD = 6.9 CNH
 *
 * @dev
 *  合约内部不做任何外部喂价拉取逻辑，仅存一份价格由 owner 手动更新：
 *  - 适合作为本项目 Auction 合约中 `tokenPriceFeeds[CNH]` 的数据源
 *  - 仅用于测试 / 演示，不适合作为生产级价格预言机
 */
contract CNHPriceFeed is AggregatorV3Interface, Ownable {
    /**
     * @dev 当前价格，单位为 USD，8 位小数。
     *
     * 示例：
     *  - _price = 1_00000000  => 1 CNH = 1.0  USD
     *  - _price =   14492754  => 1 CNH = 0.14492754 USD（约 1 USD = 6.9 CNH）
     */
    uint256 private _price;

    /**
     * @dev 价格轮次 ID。
     *
     * 每次调用 {setPrice} 时自增 1，用于模拟 Chainlink 中 price feed 的轮次概念，
     * 方便前端或调试脚本根据 roundId 判断是否拿到的是最新一轮价格。
     */
    uint80 private _roundId = 1;

    /**
     * @notice 构造函数
     * @param initialPriceUsd8 初始价格（8 位小数），含义为「1 CNH = ? USD」。
     *  例如：14492754 表示 1 CNH = 0.14492754 USD（约 1 USD = 6.9 CNH）。
     */
    constructor(uint256 initialPriceUsd8) Ownable(msg.sender) {
        require(initialPriceUsd8 > 0, "Invalid price");
        _price = initialPriceUsd8;
    }

    /**
     * @inheritdoc AggregatorV3Interface
     *
     * @dev
     *  - roundId / answeredInRound：统一返回当前 _roundId
     *  - startedAt / updatedAt：这里简化为当前 block.timestamp
     *  - answer：当前价格 _price，单位为 USD，8 位小数
     */
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, int256(_price), block.timestamp, block.timestamp, _roundId);
    }

    /**
     * @inheritdoc AggregatorV3Interface
     *
     * @dev
     *  为了保持接口兼容，这里实现了 getRoundData，但仅支持查询当前 _roundId：
     *  - 如果传入的 _rId 不是当前轮次，会直接 revert
     *  - 在测试场景下通常不会用到历史轮次数据
     */
    function getRoundData(uint80 _rId)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        require(_rId == _roundId, "Round not found");
        return (_roundId, int256(_price), block.timestamp, block.timestamp, _roundId);
    }

    /**
     * @notice 返回价格的小数位数
     * @dev 固定为 8，保持与 Chainlink 主网价格预言机一致
     */
    function decimals() external pure override returns (uint8) {
        return 8;
    }

    /**
     * @notice 返回该预言机的描述信息
     * @dev 这里固定为 "CNH/USD"
     */
    function description() external pure override returns (string memory) {
        return "CNH/USD";
    }

    /**
     * @notice 预言机版本号（自定义）
     * @dev 简单返回常量 1，便于将来有 breaking change 时升级为新版本
     */
    function version() external pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice 手动更新 CNH 价格（仅 owner，测试网用）
     * @param priceUsd8 新价格（8 位小数），含义同构造函数参数 initialPriceUsd8
     *
     * @dev
     *  - 该函数会同步自增 _roundId，用于模拟新的一轮喂价
     *  - 生产环境下应由 off-chain service 定期根据真实汇率调用该函数
     */
    function setPrice(uint256 priceUsd8) external onlyOwner {
        require(priceUsd8 > 0, "Invalid price");
        _price = priceUsd8;
        _roundId++;
    }
}
