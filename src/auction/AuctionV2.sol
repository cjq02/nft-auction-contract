// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Auction} from "./Auction.sol";
import {PriceConverter} from "../libraries/PriceConverter.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title AuctionV2
 * @dev NFT 拍卖合约升级版，添加动态手续费计算功能
 * @custom:security-contact security@example.com
 */
contract AuctionV2 is Auction {
    using PriceConverter for AggregatorV3Interface;
    // ========== V2 新增：动态手续费配置 ==========

    struct FeeTier {
        uint256 minAmount; // 最小金额（USD，18 位小数）
        uint256 feeRate; // 手续费率（基点）
    }

    FeeTier[] public feeTiers;

    // ========== V2 新增：动态手续费变更事件（便于链下追溯历史配置） ==========

    event FeeTierAdded(uint256 indexed index, uint256 minAmount, uint256 feeRate);
    event FeeTierUpdated(uint256 indexed index, uint256 minAmount, uint256 feeRate);
    event FeeTierRemoved(uint256 indexed index);

    // ========== V2 新增：动态手续费管理 ==========

    /**
     * @notice 添加手续费层级
     */
    function addFeeTier(uint256 minAmount, uint256 _feeRate) external onlyOwner {
        require(_feeRate <= 1000, "Fee rate too high");
        uint256 index = feeTiers.length;
        feeTiers.push(FeeTier({minAmount: minAmount, feeRate: _feeRate}));
        emit FeeTierAdded(index, minAmount, _feeRate);
    }

    /**
     * @notice 移除手续费层级
     */
    function removeFeeTier(uint256 index) external onlyOwner {
        require(index < feeTiers.length, "Invalid index");
        feeTiers[index] = feeTiers[feeTiers.length - 1];
        feeTiers.pop();
        emit FeeTierRemoved(index);
    }

    /**
     * @notice 更新手续费层级
     */
    function updateFeeTier(uint256 index, uint256 minAmount, uint256 _feeRate) external onlyOwner {
        require(index < feeTiers.length, "Invalid index");
        require(_feeRate <= 1000, "Fee rate too high");
        feeTiers[index] = FeeTier({minAmount: minAmount, feeRate: _feeRate});
        emit FeeTierUpdated(index, minAmount, _feeRate);
    }

    /**
     * @notice 获取所有手续费层级
     */
    function getFeeTiers() external view returns (FeeTier[] memory) {
        return feeTiers;
    }

    // ========== 重写初始化钩子 ==========

    /// @notice 初始化时添加默认手续费层级
    function _initializeHook() internal override {
        feeTiers.push(FeeTier({minAmount: 0, feeRate: feeRate}));
    }

    // ========== 重写手续费计算函数 ==========

    /**
     * @notice 计算手续费（支持动态手续费）
     * @dev V2 新增：修复了原版本 ERC20 手续费计算为 0 的 bug；返回 feeRateBps 便于事件追溯
     */
    function calculateFee(
        uint256 amount,
        bool isETH,
        address paymentToken
    ) public view override returns (uint256 fee, uint256 feeRateBps) {
        // 计算 USD 价值
        uint256 usdValue;
        if (isETH) {
            usdValue = ethPriceFeed.getETHAmountInUSD(amount);
        } else {
            // V2 修复：正确计算 ERC20 代币的 USD 价值
            require(address(tokenPriceFeeds[paymentToken]) != address(0), "Price feed not set");
            usdValue = tokenPriceFeeds[paymentToken].getTokenAmountInUSD(amount);
        }

        // 查找适用的手续费层级
        feeRateBps = feeRate;
        for (uint256 i = feeTiers.length; i > 0; i--) {
            if (usdValue >= feeTiers[i - 1].minAmount) {
                feeRateBps = feeTiers[i - 1].feeRate;
                break;
            }
        }

        fee = (amount * feeRateBps) / 10000;
    }
}
