# market-contracts
this project implements the whole Dutch Auction.

此项目实现了完整的荷兰式拍卖

## 拍卖合约
(只需要部署`ClockAuction`)
`ClockAuction.sol`
### 前置准备
在部署`ClockAuction`之前需要部署的合约如下:
1. Land合约
2. RING合约
3. bancorExchange合约 (用于ETH和RING相互转换)
4. GenesisHolder合约 (即ClockAucion中的pangu)
5. LandData合约 (存储地块属性)


## 初始化相关
在合约的构造器中涉及到的参数，其意义分别是：
1. address _nftAddress: LAND合约地址
2. address _pangu: 拍卖的分账合约，执行初代拍卖的合约
3. address _registry: 注册各变量的合约地址


## 拍卖操作相关
### 1. 创建拍卖
使用LAND合约中的`approveAndCall`方法，传入参数为：
1. `_to`: 拍卖合约地址
2. `_tokenId`: 地块的tokenId
3. `_startingPriceInToken`: 起始价格（ring）
4. `_endingPriceInToken`: 终止价格(ring)，其实价格比终止价格高
5. `_duration`: 拍卖持续时间，以秒为单位
6. `_seller`: 卖方(或者地块拥有者指定的地块拍卖的受益人)
第3、4、5、6个变量拼成一个bytes，如下：（换行仅为了方便理解）
```bash
0x
000000000000000000000000000000000000000000084595161401484a000000
00000000000000000000000000000000000000000000152d02c7e14af6800000
000000000000000000000000000000000000000000000000000000000002cad8
000000000000000000000000da7fab79bfd0a27f04367f5b9b9348cb5d1b0023
```


### 2. 取消拍卖
使用`clockAunction.sol`中`cancelAuction`方法

**注意**：只允许此次拍卖的`_seller`取消，如果`_seller`不是该地块的拥有者的话，意味着地块拥有者也无法取消此次拍卖

### 3. 获得拍卖信息
使用`clockAunction.sol`中`getAuction`方法

### 4. 获得拍卖的现时价格
使用`clockAunction.sol`中`getCurrentPriceInToken`方法

### 5. 使用RING来竞拍地块
发送要竞拍某次拍卖使用的RING的数量，到`clockAunction`合约中，使用RING.transfer(address(BidAuctionRING),ringAmount,data)即可。
其中data的长度为bytes64,组成如下：
1. 第一个bytes32: tokenId(注意必须是64位原始格式，不要写十进制格式)
2. 第二个bytes32: 推荐人的address

data的例子如下（分行仅为显示清晰）：
```bash
0x
0000000000000000000000000000000100000000000000000000000000000001
000000000000000000000000375eae23b65feb1833072328647902f1fe9afa61

```

**注意**：需要把tokenId转换成bytes格式

### 6. 使用ETH来竞拍地块
使用`clockAunction.sol`中的`bidWithETH`方法


## 提币相关
使用`clockAunction.sol`中的`claimTokens`方法

### KOVAN测试网络地址
```js
KTONAuthority: 0xf67fb3c7bd4be47cf9698437b9a28e35230a2f6f
  
AuctionSettingIds: 0x6f03440bd319b156170da842cd3d0858e31b9474
LandBaseAuthority: 0x40dfe9d19cc29e188323b912a0a549f7555be00b
ClaimBountyCalculator: 0x16bf8cc18dd69b979a6a7783d4a4be3ae0a3744d

ClockAuction: 0xf66cf1ad16ee377520bf1085718f9b6b67bb71d8
ClockAuctionProxy: 0x3df5d3430e672483fca03db43b086db3177d64a3

MysteriousTreasure: 0x2346da344fa654b4b67ac324b88180c59539c9ec
MysteriousTreasureProxy: 0x8dce349bbd971475988ca788c2832a4378e3fec9

GenesisHolder: 0xc1b56e42106ce1bc9b769a9ee1350eced55e831a
GenesisHolderProxy: 0xd61a48741c4b461ad991ee807a09cebe31100181
 
RevenuePool: 0xce3d801a094673b8aa5fed02fd9c8e05fc6da68b
RevenuePoolProxy: 0x27e3fb52a5ae40e79543a78df74e48832f625419
```
