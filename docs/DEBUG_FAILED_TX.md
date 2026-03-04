# 交易失败排查指南

## 一、在 Etherscan 上查看失败原因

1. **打开交易详情页**  
   例如：https://sepolia.etherscan.io/tx/0xd239e8e73c5725bb3927dcf8766fe402087287541aab4c1c70729db69d099532

2. **看状态与错误信息**
   - 页面上方有 **Status: Fail** 或 **Success**
   - 点击 **Click to see more** 或展开 **Transaction Details**，有时会看到 **Error Message** / **Revert reason**（例如 `execution reverted: Bid too low`）

3. **若无明文错误**
   - 点 **Internal Txns** 看内部调用链，最后一个 revert 的调用往往就是失败点
   - 用 **Tenderly** 或 **OpenChain** 等工具对同一笔 tx 做调试/模拟，会给出 revert 位置和原因

4. **用 cast 本地模拟（Foundry）**
   ```bash
   cd nft-auction-contract
   cast run 0xd239e8e73c5725bb3927dcf8766fe402087287541aab4c1c70729db69d099532 --rpc-url $SEPOLIA_RPC_URL
   ```
   会打印 revert 原因或 trace。

---

## 二、本合约 `placeBid` 可能 revert 的原因

### 1. 修饰符 `onlyActiveAuction(auctionId)`

- **"Auction not active"**  
  拍卖状态不是 Active（已结束或已取消）。

- **"Auction not started"**  
  `block.timestamp < startTime`，拍卖尚未开始。

- **"Auction ended"**  
  `block.timestamp >= endTime`，拍卖已结束。

### 2. ETH 出价 `placeBid(uint256 auctionId)`

- **"Bid amount must be greater than 0"**  
  `msg.value == 0`，未附带 ETH。

- **"This auction accepts tokens, not ETH"**  
  该拍卖配置为 ERC20 支付，不接受 ETH。

- **"Bid too low"**  
  当前 ETH 按 Chainlink 换算的 USD 价值 < 拍卖的 `minBid`（最低出价）。

- **"Bid must be higher than current highest"**  
  已有出价时，你的出价（按 USD）必须高于当前最高出价。

- **"Invalid price" / "Round not updated"**（来自 PriceConverter）  
  Chainlink 预言机返回价格 ≤ 0 或数据过旧，常见于 Sepolia 上预言机未更新或配置错误。

---

## 三、常见情况与处理

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| Bid too low | 前端传的 ETH 换算成 USD 低于 minBid，或汇率变了 | 提高出价；或确认当前 ETH/USD 与 minBid 单位一致 |
| Auction ended | 已过 endTime | 只能对未结束的拍卖出价 |
| Invalid price / Round not updated | Sepolia 上 Chainlink 数据过期或未配置 | 换 RPC、换时间再试；或检查合约里 ETH 价格源地址是否为 Sepolia 官方 feed |
| This auction accepts tokens, not ETH | 该拍卖是 ERC20 支付 | 前端应走 `placeBidWithToken` 并传对应 token 与 amount |

---

## 四、常见 trace：`call to non-contract address 0x0000...`

若 `cast run` 输出类似：

```text
[34621] 0x199A...::placeBid{value: 0.34 ETH}(1)
  ├─ [0] 0x0000000000000000000000000000000000000000::latestRoundData() [staticcall]
  └─ ← [Revert] call to non-contract address 0x0000000000000000000000000000000000000000
```

说明合约在出价时调用了 **ETH 价格预言机**（`ethPriceFeed.latestRoundData()`），但 **`ethPriceFeed` 当前为 `address(0)`**（未配置或部署时传错）。

**处理：**

1. **Sepolia 正确 ETH/USD 预言机地址**：`0x694AA1769357215DE4FAC081bf1f309aDC325306`（[Chainlink 文档](https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#sepolia-testnet)）。
2. **当前线上合约无法改存储**：合约里没有 `setEthPriceFeed`，已部署的代理不能事后改 `ethPriceFeed`。
3. **可行做法**：用正确的 `ETH_PRICE_FEED` **重新部署**拍卖合约（或新代理），并在前端/后端把新合约地址替换掉。部署时在 `.env` 中设置：
   ```bash
   ETH_PRICE_FEED=0x694AA1769357215DE4FAC081bf1f309aDC325306
   ```
   再执行 `DeployAuction.s.sol`。

---

## 五、针对你这笔交易的建议

1. 在 Etherscan 该笔 tx 页面确认是否有 **Error Message / Revert reason**。  
2. 若有 **Internal Txns**，点进去看最后失败的 internal call。  
3. 在项目里执行：
   ```bash
   cast run 0xd239e8e73c5725bb3927dcf8766fe402087287541aab4c1c70729db69d099532 --rpc-url <你的 Sepolia RPC>
   ```
   看终端输出的 revert 原因。  
4. 对照上面 **二、三** 检查：是否已结束、是否 ETH 不足/低于 minBid、是否预言机报错等。
