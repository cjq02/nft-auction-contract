# Sepolia 拍卖合约部署说明

## 一、核心概念：代理地址不变，只换“实现”

```
用户 / 前端永远只认一个地址 → 代理 (Proxy)
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              实现 V1          实现 V2          实现 V3  …
            (可被换掉)       (可被换掉)       (可被换掉)
```

- **代理 (Proxy)**：链上只有一个，地址**永远不变**，用户/前后端只配置这一个地址。
- **实现 (Implementation)**：V1、V2、V3… 是不同版本的**实现合约**，可以随时部署新的，然后让**代理指向新实现**（升级）。
- **以后有 V3**：部署一个 AuctionV3 实现合约，再跑一次**升级脚本**，让现有代理 `upgradeTo(V3)` 即可。**不需要新代理，不需要改前后端配置。**

---

## 二、V1 和 V2 怎么选

| 目标 | 需要执行的命令 | 说明 |
|------|----------------|------|
| **只要 V1** | 只执行 **①** | 固定手续费，逻辑简单 |
| **要 V2** | **二选一**：<br>• **方式 A**：先 ① 再 ②（部署 V1 代理 → 升级到 V2）<br>• **方式 B**：只执行 **③**（直接部署 V2 代理，一步到位） | V2 有分层手续费、修复 ERC20 手续费 bug |

**结论：不需要“部署 + 升级”两条都执行才能用。**  
- 只要 V1 → 只跑 ①。  
- 要 V2 → 要么 ①+②，要么只跑 ③（推荐 ③，少一步）。

---

## 三、部署前 .env

在 `nft-auction-contract/.env` 中确认：

```bash
PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/...
ETH_PRICE_FEED=0x694AA1769357215DE4FAC081bf1f309aDC325306
FEE_RECIPIENT=0x你的收款地址
```

若用 **方式 A（先 V1 再升级）**，执行 ② 前还要把 ① 得到的代理地址填进：

```bash
PROXY_ADDRESS=0x①打印的Proxy地址
```

---

## 四、命令（在 nft-auction-contract 目录下）

### ① 只部署 V1（代理 + 实现）

```bash
forge script script/deploy/DeployAuction.s.sol:DeployAuction --rpc-url sepolia --broadcast
```

得到 **Proxy 地址**。若只想要 V1，到这一步即可，把该地址写到前后端配置。

---

### ② 在已有 V1 代理上升级到 V2

**前提**：已经执行过 ①，且 `.env` 里 `PROXY_ADDRESS` 为该代理地址。

```bash
forge script script/upgrade/UpgradeAuctionToV2.s.sol:UpgradeAuctionToV2 --rpc-url sepolia --broadcast
```

代理地址不变，只是实现从 V1 换成 V2。

---

### ③ 直接部署 V2（代理 + 实现，一步到位）

```bash
forge script script/deploy/DeployAuctionV2.s.sol:DeployAuctionV2 --rpc-url sepolia --broadcast
```

得到 **Proxy 地址**，即为 V2 代理，无需再执行 ②。

---

## 五、部署后

把最终使用的 **Proxy 地址** 填到：

- `nft-auction-api/.env` → `AUCTION_CONTRACT_ADDRESS`
- `nft-auction-web/.env` → `VITE_AUCTION_CONTRACT_ADDRESS`

NFT 合约无需重部署，沿用现有地址即可。

---

## 六、以后有 V3（或 V4…）怎么办

**代理地址不用改**，按下面做即可：

1. 在 `src/auction/` 里写新实现合约（如 `AuctionV3.sol`），继承并扩展上一版。
2. 在 `script/upgrade/` 里加一个升级脚本（如 `UpgradeAuctionToV3.s.sol`）：
   - 部署新的 `AuctionV3` 实现合约；
   - 对**当前代理**调用 `upgradeTo(新实现地址)`。
3. `.env` 里 `PROXY_ADDRESS` 保持为**现在用的那个代理地址**（一直不变）。
4. 执行：`forge script script/upgrade/UpgradeAuctionToV3.s.sol:UpgradeAuctionToV3 --rpc-url sepolia --broadcast`。

升级后，代理地址不变，前后端配置不用改，只是链上逻辑变成了 V3。V4、V5… 同理，每次都是：新实现 + 新升级脚本 + 对**同一个代理**做 `upgradeTo`。
