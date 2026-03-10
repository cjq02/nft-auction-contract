// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CNH
 * @notice
 *  离岸人民币（CNH）测试代币，实现 ERC20 标准。
 *
 *  - 仅用于测试 / Demo 网络，owner 地址拥有铸造权限
 *  - 可以模拟「人民币稳定币」作为拍卖出价代币或资产计价单位
 *
 * @dev
 *  生产环境推荐直接接入已有的人民币相关稳定币（例如 Tether CNHt），
 *  本合约主要用于：
 *   - 本项目 Auction 合约的集成测试
 *   - 演示如何为任意 ERC20 配置 tokenPriceFeeds
 */
contract CNH is ERC20, Ownable {
    /**
     * @param initialOwner 初始 owner 地址，拥有铸造权限
     *
     * @dev
     *  - 代币名称：Offshore Yuan
     *  - 代币符号：CNH
     *  - owner 可通过 {mint} 向任意地址发放测试代币
     */
    constructor(address initialOwner) ERC20("Offshore Yuan", "CNH") Ownable(initialOwner) {}

    /**
     * @notice 返回代币小数位数
     * @dev 固定为 18 位，方便与大部分 DeFi 合约、预言机逻辑对齐
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @notice 铸造 CNH（仅 owner，测试网用）
     * @param to 接收地址
     * @param amount 铸造数量，单位为最小单位（18 位小数）
     *
     * @dev
     *  如果希望给用户发放 100 个 CNH，需要传入：100 * 10^18
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
