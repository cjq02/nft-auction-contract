# IPFS 元数据上传指南

## 目录

1. [Pinata 快速上手](#pinata-快速上手)
2. [完整操作流程](#完整操作流程)
3. [详细步骤说明](#详细步骤说明)
4. [在铸造中使用 CID](#在铸造中使用-cid)
5. [验证元数据](#验证元数据)
6. [批量操作脚本](#批量操作脚本)
7. [常见问题](#常见问题)

---

## Pinata 快速上手

### 注册账户

1. 访问 [Pinata](https://app.pinata.cloud/)
2. 点击 **Sign Up** 注册
3. 验证邮箱后登录

### 获取 API Key（可选，用于自动化）

1. 点击右上角头像 → **API Keys**
2. 点击 **New Key**
3. 选择权限：**Admin**
4. 复制生成的 JWT Token

---

## 完整操作流程

**重要**：请按照以下顺序操作，每一步都依赖前一步的结果。

```
1. 准备图片文件（.jpg, .png 等）
   ↓
2. 上传图片到 Pinata，获得图片 CID
   ↓
3. 创建元数据 JSON 文件，引用图片 CID
   ↓
4. 上传元数据到 Pinata，获得元数据 CID
   ↓
5. 使用元数据 CID 进行 NFT 铸造
```

---

## 详细步骤说明

### 步骤 1：上传图片到 Pinata

首先需要准备你的 NFT 图片文件（推荐格式：JPG、PNG，大小建议 < 10MB）。

#### 方法 1：网页上传（推荐新手）

1. 登录 [Pinata](https://app.pinata.cloud/)
2. 点击 **Upload** → **Upload File**
3. 选择你的图片文件（如 `nft-image-1.jpg`）
4. 等待上传完成
5. **复制图片的 CID**（类似 `QmAbCd123...`），保存备用

#### 方法 2：使用 Pinata API

```bash
# 设置环境变量
export PINATA_JWT="your_pinata_jwt_token"

# 上传图片
curl --request POST \
  --url 'https://api.pinata.cloud/pinning/pinFileToIPFS' \
  --header "Authorization: Bearer $PINATA_JWT" \
  --form 'file=@images/nft-image-1.jpg'

# 响应示例：
# {
#   "IpfsHash": "QmImageCID123...",  # 这是图片 CID，保存下来
#   "PinSize": 123456,
#   "Timestamp": "2024-01-15T10:30:00.000Z"
# }
```

#### 方法 3：使用 Pinata CLI

```bash
# 安装
npm install -g @pinata/sdk

# 上传图片（需要配置 API Key）
pinata upload images/nft-image-1.jpg
# 输出会显示 CID，复制保存
```

**重要**：记录下图片的 CID，下一步创建元数据时需要用到。

---

### 步骤 2：创建 NFT 元数据

使用上一步获得的图片 CID 创建元数据文件。

#### 标准元数据格式

创建 `metadata/auction-nft-1.json`：

```json
{
  "name": "Auction NFT #1",
  "description": "NFT for auction marketplace testing on Sepolia",
  "image": "ipfs://QmImageCID123...",
  "external_url": "https://your-project.com",
  "attributes": [
    {
      "trait_type": "Collection",
      "value": "Auction Market"
    },
    {
      "trait_type": "Rarity",
      "value": "Common"
    },
    {
      "trait_type": "Type",
      "value": "Testing"
    }
  ]
}
```

**注意**：
- 将 `QmImageCID123...` 替换为你在步骤 1 中获得的实际图片 CID
- `external_url` 是可选的，如果没有项目网站可以省略该字段

#### 字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| `name` | ✅ | NFT 名称 |
| `description` | ✅ | NFT 描述 |
| `image` | ✅ | 图片 URI（使用步骤 1 获得的图片 CID，格式：`ipfs://Qm...`） |
| `external_url` | ❌ | 指向 NFT 详情页或项目主页的链接（可选，如果项目没有网站可以省略） |
| `attributes` | ❌ | NFT 属性数组（可选，用于描述 NFT 的特征和属性） |

#### attributes 说明

`attributes` 是一个可选字段，用于描述 NFT 的特征和属性。这些属性会在 OpenSea 等市场平台上显示，帮助用户了解 NFT 的特点。

**用途**：
- 描述 NFT 的特征（如稀有度、类型、颜色等）
- 在交易平台上显示属性标签
- 帮助用户筛选和搜索 NFT

**基本格式**：
```json
"attributes": [
  {
    "trait_type": "属性名称",
    "value": "属性值"
  }
]
```

**常见属性类型**：

1. **文本属性**（最常用）：
   ```json
   {
     "trait_type": "Rarity",
     "value": "Legendary"
   },
   {
     "trait_type": "Collection",
     "value": "Auction Market"
   },
   {
     "trait_type": "Type",
     "value": "Testing"
   }
   ```

2. **数字属性**（需要指定 display_type）：
   ```json
   {
     "display_type": "number",
     "trait_type": "Generation",
     "value": 1
   },
   {
     "display_type": "number",
     "trait_type": "Level",
     "value": 5
   }
   ```

3. **日期属性**：
   ```json
   {
     "display_type": "date",
     "trait_type": "Birthday",
     "value": 1609459200
   }
   ```

4. **百分比属性**：
   ```json
   {
     "display_type": "boost_percentage",
     "trait_type": "Power",
     "value": 75
   }
   ```

**完整示例**：
```json
"attributes": [
  {
    "trait_type": "Collection",
    "value": "Auction Market"
  },
  {
    "trait_type": "Rarity",
    "value": "Common"
  },
  {
    "trait_type": "Type",
    "value": "Testing"
  },
  {
    "display_type": "number",
    "trait_type": "Token ID",
    "value": 1
  }
]
```

**注意**：
- `attributes` 是完全可选的，如果不需要可以省略该字段
- `trait_type` 是属性名称（如"稀有度"、"类型"等）
- `value` 是属性值（可以是字符串或数字）
- `display_type` 是可选的，用于指定显示方式（"number"、"date"、"boost_percentage" 等）
- 对于测试项目，可以只包含基本的属性，或者完全省略

#### external_url 说明

`external_url` 是一个可选字段，用于指向该 NFT 的详情页面或项目主页。常见用法：

1. **项目主页**（推荐）：
   ```json
   "external_url": "https://your-project.com"
   ```

2. **NFT 详情页**（如果有）：
   ```json
   "external_url": "https://your-project.com/nft/1"
   ```

3. **市场平台链接**（如 OpenSea）：
   ```json
   "external_url": "https://opensea.io/collection/your-collection"
   ```

4. **如果项目没有网站**：
   - 可以省略该字段（不包含在 JSON 中）
   - 或者留空字符串：`"external_url": ""`
   - 或者使用 IPFS 网关查看元数据：`"external_url": "https://gateway.pinata.cloud/ipfs/QmMetadataCID"`

**注意**：对于测试项目，如果没有实际网站，可以省略该字段。

#### 属性（Attributes）格式示例

**简单文本属性**：
```json
"attributes": [
  {
    "trait_type": "Collection",
    "value": "Auction Market"
  },
  {
    "trait_type": "Rarity",
    "value": "Common"
  },
  {
    "trait_type": "Type",
    "value": "Testing"
  }
]
```

**包含数字属性**：
```json
"attributes": [
  {
    "trait_type": "Rarity",
    "value": "Legendary"
  },
  {
    "display_type": "number",
    "trait_type": "Generation",
    "value": 1
  },
  {
    "trait_type": "Color",
    "value": "Blue"
  }
]
```

**无属性（可选）**：
如果不需要属性，可以完全省略 `attributes` 字段：
```json
{
  "name": "Auction NFT #1",
  "description": "NFT for auction marketplace testing",
  "image": "ipfs://QmImageCID123..."
}
```

---

### 步骤 3：上传元数据到 Pinata

将创建好的元数据 JSON 文件上传到 Pinata。

#### 方法 1：网页上传（推荐新手）

1. 登录 [Pinata](https://app.pinata.cloud/)
2. 点击 **Upload** → **Upload File**
3. 选择创建的 JSON 文件（如 `metadata/auction-nft-1.json`）
4. 等待上传完成
5. **复制元数据的 CID**（类似 `QmXyZ789...`），这是用于铸造的 CID

#### 方法 2：使用 Pinata API

```bash
# 设置环境变量（如果还没设置）
export PINATA_JWT="your_pinata_jwt_token"

# 上传元数据文件
curl --request POST \
  --url 'https://api.pinata.cloud/pinning/pinFileToIPFS' \
  --header "Authorization: Bearer $PINATA_JWT" \
  --form 'file=@metadata/auction-nft-1.json'

# 响应示例：
# {
#   "IpfsHash": "QmMetadataCID789...",  # 这是元数据 CID，用于铸造
#   "PinSize": 1234,
#   "Timestamp": "2024-01-15T10:30:00.000Z"
# }
```

#### 方法 3：使用 Pinata CLI

```bash
# 上传元数据文件
pinata upload metadata/auction-nft-1.json
# 输出会显示 CID，这是用于铸造的 CID
```

**重要**：记录下元数据的 CID，下一步铸造 NFT 时需要用到。

---

## 在铸造中使用 CID

**重要**：铸造时使用的是**元数据 CID**（步骤 3 获得的），而不是图片 CID。

### 格式说明

| 格式 | 说明 |
|------|------|
| `ipfs://Qm...` | 标准 IPFS 协议（推荐） |
| `https://gateway.pinata.cloud/ipfs/Qm...` | Pinata 网关 |
| `https://ipfs.io/ipfs/Qm...` | 公共 IPFS 网关 |

### 使用 cast 铸造

```bash
# 导出环境变量
export $(grep -v '^#' .env | xargs)

# 使用 IPFS URI 格式（使用步骤 3 获得的元数据 CID）
cast send $NFT_CONTRACT_ADDRESS \
  "mint(address,string)" \
  $ACCOUNT_B \
  "ipfs://QmMetadataCID789..." \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# 或使用网关 URL
cast send $NFT_CONTRACT_ADDRESS \
  "mint(address,string)" \
  $ACCOUNT_B \
  "https://gateway.pinata.cloud/ipfs/QmMetadataCID789..." \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

**注意**：将 `QmMetadataCID789...` 替换为你在步骤 3 中获得的实际元数据 CID。

---

## 验证元数据

### 验证元数据 CID

在上传元数据后，验证元数据 CID 是否可以正常访问：

```bash
# 通过 IPFS 网关查看元数据（使用步骤 3 获得的元数据 CID）
curl https://gateway.pinata.cloud/ipfs/QmMetadataCID789...

# 或使用公共网关
curl https://ipfs.io/ipfs/QmMetadataCID789...

# 应该返回 JSON 格式的元数据内容
```

### 验证图片 CID

验证元数据中引用的图片是否可以正常访问：

```bash
# 从元数据中提取图片 CID（假设图片 CID 是 QmImageCID123...）
curl https://gateway.pinata.cloud/ipfs/QmImageCID123...

# 或在浏览器中直接访问查看图片
# https://gateway.pinata.cloud/ipfs/QmImageCID123...
```

### 验证 JSON 格式

在上传前验证元数据 JSON 文件格式是否正确：

```bash
# 使用 jq 验证 JSON 格式
cat metadata/auction-nft-1.json | jq .

# 或在线验证
# https://jsonlint.com/
```

### 完整验证流程

```bash
# 1. 验证元数据 JSON 格式
cat metadata/auction-nft-1.json | jq .

# 2. 验证元数据 CID 可访问
curl https://gateway.pinata.cloud/ipfs/QmMetadataCID789... | jq .

# 3. 验证图片 CID 可访问（从元数据中获取图片 CID）
METADATA=$(curl -s https://gateway.pinata.cloud/ipfs/QmMetadataCID789...)
IMAGE_CID=$(echo $METADATA | jq -r '.image' | sed 's/ipfs:\/\///')
curl -I https://gateway.pinata.cloud/ipfs/$IMAGE_CID
```

---

## 批量操作脚本

### 完整批量流程脚本

按照正确顺序：先上传图片 → 创建元数据 → 上传元数据

```bash
#!/bin/bash

PINATA_JWT="your_jwt_token"
IMAGES_DIR="images"
METADATA_DIR="metadata"

# 步骤 1：批量上传图片，保存 CID
echo "=== 步骤 1: 上传图片 ==="
declare -A image_cids

for image_file in $IMAGES_DIR/*.{jpg,png,jpeg}; do
  if [ -f "$image_file" ]; then
    filename=$(basename "$image_file" | cut -d. -f1)
    echo "上传图片: $image_file"
    
    cid=$(curl --request POST \
      --url 'https://api.pinata.cloud/pinning/pinFileToIPFS' \
      --header "Authorization: Bearer $PINATA_JWT" \
      --form "file=@$image_file" \
      --silent | jq -r '.IpfsHash')
    
    image_cids["$filename"]=$cid
    echo "$filename -> $cid"
    echo "$cid" > "${image_file}.cid"
  fi
done

# 步骤 2：创建元数据文件（引用图片 CID）
echo -e "\n=== 步骤 2: 创建元数据 ==="
mkdir -p $METADATA_DIR

for image_file in $IMAGES_DIR/*.{jpg,png,jpeg}; do
  if [ -f "$image_file" ]; then
    filename=$(basename "$image_file" | cut -d. -f1)
    image_cid=${image_cids["$filename"]}
    
    if [ -n "$image_cid" ]; then
      cat > "$METADATA_DIR/${filename}.json" << EOF
{
  "name": "Auction NFT ${filename}",
  "description": "NFT ${filename} for auction marketplace",
  "image": "ipfs://${image_cid}",
  "attributes": [
    {
      "trait_type": "ID",
      "value": "${filename}"
    }
  ]
}
EOF
      echo "创建元数据: $METADATA_DIR/${filename}.json"
    fi
  fi
done

# 步骤 3：批量上传元数据文件
echo -e "\n=== 步骤 3: 上传元数据 ==="
for metadata_file in $METADATA_DIR/*.json; do
  if [ -f "$metadata_file" ]; then
    filename=$(basename "$metadata_file")
    echo "上传元数据: $filename"
    
    cid=$(curl --request POST \
      --url 'https://api.pinata.cloud/pinning/pinFileToIPFS' \
      --header "Authorization: Bearer $PINATA_JWT" \
      --form "file=@$metadata_file" \
      --silent | jq -r '.IpfsHash')
    
    echo "$filename -> $cid (用于铸造)"
    echo "$cid" > "${metadata_file}.cid"
  fi
done

echo -e "\n=== 完成 ==="
echo "所有 CID 已保存到对应的 .cid 文件中"
```

### 仅生成元数据脚本（需要先手动上传图片）

如果你已经上传了图片并获得了 CID，可以使用此脚本生成元数据：

```bash
#!/bin/bash

# 配置：图片 CID 映射（需要手动填写）
declare -A image_cids=(
  ["nft-1"]="QmImageCID1..."
  ["nft-2"]="QmImageCID2..."
  ["nft-3"]="QmImageCID3..."
)

METADATA_DIR="metadata"
mkdir -p $METADATA_DIR

# 生成元数据文件
for nft_name in "${!image_cids[@]}"; do
  image_cid=${image_cids["$nft_name"]}
  
  cat > "$METADATA_DIR/${nft_name}.json" << EOF
{
  "name": "Auction NFT ${nft_name}",
  "description": "NFT ${nft_name} for auction marketplace",
  "image": "ipfs://${image_cid}",
  "attributes": [
    {
      "trait_type": "ID",
      "value": "${nft_name}"
    }
  ]
}
EOF
  
  echo "创建元数据: $METADATA_DIR/${nft_name}.json (图片 CID: ${image_cid})"
done
```

---

## 常见问题

### Q1: 为什么我的 CID 和别人的不一样？

**A**: IPFS 是内容寻址（Content Addressing），相同内容才有相同 CID。即使只有一个字符不同，CID 也会完全不同。

### Q2: 可以上传文件夹吗？

**A**: 可以，但更推荐使用 **IPFS 目录**格式：

```bash
# 上传文件夹
pinata upload-folder ./metadata

# 得到文件夹 CID，访问文件时：
# ipfs://QmFolderCID/nft-1.json
```

### Q3: 如何永久保存文件？

**A**: Pinata 免费版会定期清理文件。解决方案：

1. **付费 Pinata** - 永久存储
2. **Filebase** - 免费永久存储
3. **NFT.Storage** - 基于.Filecoin，免费永久存储
4. **自建 IPFS 节点** - `ipfs pin add`

### Q4: 网关访问慢怎么办？

**A**: 使用公共网关或自建网关：

```
# 公共网关列表
https://ipfs.io/ipfs/Qm...
https://dweb.link/ipfs/Qm...
https://gateway.pinata.cloud/ipfs/Qm...
https://cloudflare-ipfs.com/ipfs/Qm...
```

### Q5: 可以复用其他项目的图片或元数据吗？

**A**: **不建议**。每个 NFT 项目应该使用独立的内容：

- ✅ **应该**：为每个 NFT 准备新的图片和元数据
- ✅ **应该**：按照标准流程：上传新图片 → 创建新元数据 → 上传新元数据 → 铸造
- ❌ **不应该**：复用其他项目或已铸造 NFT 的图片 CID
- ❌ **不应该**：直接使用示例中的占位符 CID

这样可以确保每个 NFT 的独特性和独立性。

### Q6: external_url 应该填什么？

**A**: `external_url` 是可选字段，用于指向 NFT 的详情页或项目主页。常见情况：

- **有项目网站**：填写项目主页 URL，如 `"https://your-project.com"`
- **有 NFT 详情页**：填写详情页 URL，如 `"https://your-project.com/nft/1"`
- **没有网站**：可以省略该字段（不包含在 JSON 中），或者留空 `"external_url": ""`
- **测试项目**：通常可以省略，不影响 NFT 的正常显示

**注意**：该字段主要用于 OpenSea 等市场平台显示"查看详情"链接，对于测试项目不是必需的。

### Q7: attributes 是什么？必须填写吗？

**A**: `attributes` 是可选字段，用于描述 NFT 的特征和属性。这些属性会在 OpenSea 等市场平台上显示。

**作用**：
- 描述 NFT 的特征（如稀有度、类型、颜色等）
- 在交易平台上显示属性标签
- 帮助用户筛选和搜索 NFT

**基本格式**：
```json
"attributes": [
  {
    "trait_type": "属性名称",
    "value": "属性值"
  }
]
```

**示例**：
```json
"attributes": [
  {
    "trait_type": "Collection",
    "value": "Auction Market"
  },
  {
    "trait_type": "Rarity",
    "value": "Common"
  },
  {
    "display_type": "number",
    "trait_type": "Token ID",
    "value": 1
  }
]
```

**重要提示**：
- ✅ **完全可选**：如果不需要属性，可以完全省略 `attributes` 字段
- ✅ **测试项目**：可以只包含基本属性，或者完全省略
- ✅ **不影响铸造**：没有 `attributes` 字段不影响 NFT 的正常铸造和显示
- ✅ **可以留空数组**：也可以使用空数组 `"attributes": []`

**常见属性类型**：
- 文本属性：`{"trait_type": "Rarity", "value": "Legendary"}`
- 数字属性：`{"display_type": "number", "trait_type": "Level", "value": 5}`
- 日期属性：`{"display_type": "date", "trait_type": "Birthday", "value": 1609459200}`

### Q8: 如何更新元数据？

**A**: IPFS 内容不可变，已上传的内容无法修改。如果需要"更新"：

1. **创建新的元数据文件**（不要修改已上传的文件）
2. 如果需要新图片，先上传新图片获得新的图片 CID
3. 在新元数据中引用新的图片 CID
4. 上传新的元数据到 Pinata，获得新的元数据 CID
5. 使用新的元数据 CID 铸造新的 NFT

**注意**：每个 NFT 应该使用独立的、新创建的元数据和图片。

---

## 最佳实践

### 1. 文件组织规范

建议的目录结构：

```
project/
├── images/                 # 存放原始图片文件
│   ├── nft-1.jpg
│   ├── nft-2.jpg
│   └── nft-3.png
├── metadata/               # 存放元数据 JSON 文件
│   ├── nft-1.json
│   ├── nft-2.json
│   └── nft-3.json
└── cids/                   # 存放 CID 记录（可选）
    ├── nft-1.jpg.cid       # 图片 CID
    ├── nft-1.json.cid      # 元数据 CID
    └── ...
```

### 2. 操作顺序（重要）

**严格按照以下顺序操作**：

```
1. 准备新的图片文件
   ↓
2. 上传图片 → 获得图片 CID
   ↓
3. 创建元数据（引用图片 CID）
   ↓
4. 上传元数据 → 获得元数据 CID
   ↓
5. 使用元数据 CID 铸造
```

**不要**：
- ❌ 复用其他项目的图片 CID
- ❌ 先创建元数据再上传图片
- ❌ 使用占位符 CID

**应该**：
- ✅ 为每个 NFT 准备新的图片
- ✅ 先上传图片获得真实 CID
- ✅ 在元数据中使用真实的图片 CID

### 3. 图片和元数据分离

```
# 步骤 1: 上传图片
image.jpg → QmImageCID

# 步骤 2: 在元数据中引用图片 CID
{
  "image": "ipfs://QmImageCID"
}

# 步骤 3: 上传元数据
metadata.json → QmMetadataCID

# 步骤 4: 铸造时使用元数据 CID
mint(address, "ipfs://QmMetadataCID")
```

### 4. 添加版本控制

```json
{
  "name": "NFT #1",
  "description": "...",
  "image": "ipfs://Qm...",
  "version": "1.0.0",
  "external_url": "https://example.com/token/1"
}
```

---

## 相关链接

| 资源 | 链接 |
|------|------|
| Pinata | https://app.pinata.cloud/ |
| Pinata API 文档 | https://docs.pinata.cloud/ |
| IPFS 文档 | https://docs.ipfs.tech/ |
| NFT.Storage | https://nft.storage/ |
| OpenSea 元数据标准 | https://docs.opensea.io/docs/metadata-standards |
| ERC-721 标准 | https://eips.ethereum.org/EIPS/eip-721 |
