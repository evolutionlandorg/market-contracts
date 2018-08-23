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
3. tokenVendor合约 (用于ETH和RING相互转换)
4. GenesisHolder合约 (即ClockAucion中的pangu)
5. LandData合约 (存储地块属性)


## 初始化相关
在合约的构造器中涉及到的参数，其意义分别是：
1. address _nftAddress: LAND合约地址
2. address _RING: RING合约地址
3. address _tokenVendor: ETH和RING相互转换的TokenVendor合约地址
4. uint256 _cut: 交易手续费，即拍卖完成后不返还给卖家的部分。范围[0, 10000]，对应着[0%, 100%]
5. uint245 _waitingMinutes: 每次竞拍等待的最长时间，填入分钟数
6. uint256 _claimBountyForRING: ring的claimBounty，建议设置成10-20个ring(记得*10^18)
7. address _pangu: 拍卖的分账合约，执行初代拍卖的合约
8. address _landData: 地块信息的合约地址


## 拍卖操作相关
### 1. 创建拍卖
使用LAND合约中的`approveAndCall`方法，传入参数为：
1. `_to`: 拍卖合约地址
2. `_tokenId`: 地块的tokenId
3. `_startingPriceInToken`: 起始价格（ring）
4. `_endingPriceInToken`: 终止价格(ring)，其实价格比终止价格高
5. `_duration`: 拍卖持续时间，以秒为单位
6. `_seller`: 卖方(或者地块拥有者指定的地块拍卖的受益人)
7. `_pangu`: 分账合约地址

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