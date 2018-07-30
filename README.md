# market-contracts

## 初始化相关
在各合约的构造器中涉及到下列参数的一个或多个，其意义分别是：
1. address _nftAddress: LAND合约地址
2. address _RING: RING合约地址
3. address _tokenVendor: ETH和RING相互转换的TokenVendor合约地址
4. uint256 _cut: 交易手续费，即拍卖完成后不返还给卖家的部分。范围[0, 10000]，对应着[0%, 100%]


## 拍卖操作相关
### 1. 创建拍卖
使用`clockAuction.sol`中的`createAuction`方法，传入参数为：
1. `_tokenId`: 地块的tokenId
2. `_startingPriceInRING`: 起始价格（ring）
3. `_endingPriceInRING`: 终止价格(ring)，其实价格比终止价格高
4. `_duration`: 拍卖持续时间，以秒为单位
5. `_seller`: 卖方(或者地块拥有者指定的地块拍卖的受益人)

### 2. 取消拍卖
使用`clockAunction.sol`中`cancelAuction`方法

**注意**：只允许此次拍卖的`_seller`取消，如果`_seller`不是该地块的拥有者的话，意味着地块拥有者也无法取消此次拍卖

### 3. 获得拍卖信息
使用`clockAunction.sol`中`getAuction`方法

### 4. 获得拍卖的现时价格
使用`clockAunction.sol`中`getCurrentPriceInRING`方法

### 5. 使用RING来竞拍地块
发送要竞拍某次拍卖使用的RING的数量，到`BidAuctionRING`合约中，使用RING.transfer(address(BidAuctionRING),ringAmount,bytes(tokenId))即可

**注意**：需要把tokenId转换成bytes格式

### 6. 使用ETH来竞拍地块
使用`BidAuctionETH.sol`中的`bid`方法


## 提币相关
使用`BidAuctionETH.sol`和`BidAuctionRING.sol`中的`claimTokens`方法