// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title NFTAuction
/// @notice NFT 拍卖市场，支持 ETH 和 ERC20 出价，使用 Chainlink 预言机换算 USD
contract NFTAuction is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // ============ 结构体 ============

    struct Auction {
        address seller;           // 卖家地址
        address nftContract;      // NFT 合约地址
        uint256 tokenId;          // NFT tokenId
        uint256 startPrice;       // 起拍价（USD，18 位小数）
        uint256 endTime;          // 拍卖结束时间
        bool ended;               // 是否已结束
        
        address highestBidder;    // 当前最高出价者
        uint256 highestBidInUSD;  // 最高出价（USD，用于比较）
        address highestBidToken;  // 最高出价使用的 token（address(0) = ETH）
        uint256 highestBidAmount; // 最高出价的原始 token 数量
    }

    // ============ 状态变量 ============

    uint256 public nextAuctionId;
    mapping(uint256 => Auction) public auctions;
    
    /// @notice token 地址 → Chainlink 喂价地址
    /// @dev address(0) 代表 ETH
    mapping(address => address) public tokenPriceFeeds;
    
    /// @notice 被超越的出价者的待退款余额
    mapping(address => mapping(address => uint256)) public pendingReturns;
    
    /// @notice 用户在某个拍卖中的累计出价：auctionId → user → token → amount
    mapping(uint256 => mapping(address => mapping(address => uint256))) public userBids;

    /// @dev 预留 45 个存储槽给未来升级版本使用（当前已用 5 个变量，共预留 50 个）
    uint256[45] private __gap;

    // ============ 事件 ============

    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address nftContract, uint256 tokenId);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, address token, uint256 amount, uint256 usdValue);
    event AuctionEnded(uint256 indexed auctionId, address winner, uint256 finalPrice);
    event TokenRegistered(address indexed token, address indexed priceFeed);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);

    // ============ 初始化（替代 constructor）============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public virtual initializer {
        __Ownable_init(msg.sender);
        nextAuctionId = 1;
    }

    // ============ 管理员函数 ============

    /// @notice 注册支持的 token 及其 Chainlink 喂价地址
    /// @param token token 地址（address(0) 代表 ETH）
    /// @param priceFeed Chainlink 喂价合约地址
    function registerToken(address token, address priceFeed) external virtual onlyOwner {
        require(priceFeed != address(0), "Invalid price feed address");
        tokenPriceFeeds[token] = priceFeed;
        emit TokenRegistered(token, priceFeed);
    }

    // ============ 拍卖功能 ============

    /// @notice 创建拍卖
    /// @param nftContract NFT 合约地址
    /// @param tokenId NFT tokenId
    /// @param startPriceUSD 起拍价（USD，18 位小数）
    /// @param duration 拍卖时长（秒）
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPriceUSD,
        uint256 duration
    ) external virtual returns (uint256 auctionId) {
        require(nftContract != address(0), "Invalid NFT contract");
        require(startPriceUSD > 0, "Start price must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        
        // 1. 检查 NFT 所有权
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        
        // 2. 转移 NFT 到合约（需要用户提前 approve）
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        
        // 3. 创建拍卖记录
        auctionId = nextAuctionId++;
        auctions[auctionId] = Auction({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            startPrice: startPriceUSD,
            endTime: block.timestamp + duration,
            ended: false,
            highestBidder: address(0),
            highestBidInUSD: 0,
            highestBidToken: address(0),
            highestBidAmount: 0
        });
        
        // 4. 触发事件
        emit AuctionCreated(auctionId, msg.sender, nftContract, tokenId);
    }

    /// @notice 出价
    /// @param auctionId 拍卖 ID
    /// @param token 出价使用的 token（address(0) = ETH）
    /// @param amount 出价数量（如果之前出过价，则为增量；否则为总金额）
    function bid(uint256 auctionId, address token, uint256 amount) external virtual payable {
        Auction storage auction = auctions[auctionId];
        
        // 1. 检查拍卖是否有效
        require(auction.seller != address(0), "Auction does not exist");
        require(!auction.ended, "Auction has ended");
        require(block.timestamp < auction.endTime, "Auction has expired");
        require(msg.sender != auction.seller, "Seller cannot bid");
        
        // 2. 获取用户之前的出价
        uint256 previousBid = userBids[auctionId][msg.sender][token];
        uint256 totalAmount;
        
        if (previousBid > 0) {
            // 用户之前出过价，amount 是增量
            require(amount > 0, "Increment must be greater than 0");
            totalAmount = previousBid + amount;
        } else {
            // 用户首次出价，amount 是总金额
            totalAmount = amount;
        }
        
        // 3. 计算 USD 价值
        uint256 bidInUSD = _getUSDValue(token, totalAmount);
        
        // 4. 检查是否高于起拍价和当前最高出价
        require(bidInUSD >= auction.startPrice, "Bid below start price");
        require(bidInUSD > auction.highestBidInUSD, "Bid not high enough");
        
        // 5. 转移 token 到合约（只转移增量）
        if (token == address(0)) {
            require(msg.value == amount, "Incorrect ETH amount");
        } else {
            require(msg.value == 0, "Do not send ETH for ERC20 bid");
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
        
        // 6. 处理出价者的 pendingReturns
        if (auction.highestBidder != address(0) && auction.highestBidder != msg.sender) {
            // 上一个最高出价者被超越，记录他的累计出价到 pendingReturns
            uint256 totalUserBid = userBids[auctionId][auction.highestBidder][auction.highestBidToken];
            pendingReturns[auction.highestBidder][auction.highestBidToken] = totalUserBid;
        }
        
        // 7. 更新用户的累计出价
        userBids[auctionId][msg.sender][token] = totalAmount;
        
        // 8. 如果当前出价者之前有待退款，清零（因为他现在是最高出价者）
        if (pendingReturns[msg.sender][token] > 0) {
            pendingReturns[msg.sender][token] = 0;
        }
        
        // 9. 更新最高出价记录
        auction.highestBidder = msg.sender;
        auction.highestBidInUSD = bidInUSD;
        auction.highestBidToken = token;
        auction.highestBidAmount = totalAmount;
        
        // 10. 触发事件
        emit BidPlaced(auctionId, msg.sender, token, totalAmount, bidInUSD);
    }

    /// @notice 结束拍卖
    function endAuction(uint256 auctionId) external virtual {
        Auction storage auction = auctions[auctionId];
        
        // 1. 检查拍卖是否有效和到期
        require(auction.seller != address(0), "Auction does not exist");
        require(!auction.ended, "Auction already ended");
        require(block.timestamp >= auction.endTime, "Auction not yet ended");
        
        // 2. 标记拍卖已结束
        auction.ended = true;
        
        // 3. 如果有出价者，转移 NFT 和资金
        if (auction.highestBidder != address(0)) {
            // 转移 NFT 给最高出价者
            IERC721(auction.nftContract).transferFrom(
                address(this),
                auction.highestBidder,
                auction.tokenId
            );
            
            // 转移资金给卖家
            if (auction.highestBidToken == address(0)) {
                // ETH
                payable(auction.seller).transfer(auction.highestBidAmount);
            } else {
                // ERC20
                IERC20(auction.highestBidToken).transfer(
                    auction.seller,
                    auction.highestBidAmount
                );
            }
            
            emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBidInUSD);
        } else {
            // 没有出价者，NFT 退还给卖家
            IERC721(auction.nftContract).transferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );
            
            emit AuctionEnded(auctionId, address(0), 0);
        }
    }

    /// @notice 提取待退款
    /// @param token 要提取的 token 地址（address(0) = ETH）
    function withdraw(address token) external virtual {
        uint256 amount = pendingReturns[msg.sender][token];
        require(amount > 0, "No funds to withdraw");
        
        // 先清零，防止重入攻击
        pendingReturns[msg.sender][token] = 0;
        
        // 转账
        if (token == address(0)) {
            // ETH
            payable(msg.sender).transfer(amount);
        } else {
            // ERC20
            IERC20(token).transfer(msg.sender, amount);
        }
        
        emit Withdrawn(msg.sender, token, amount);
    }

    // ============ 辅助函数 ============

    /// @notice 获取 token 的 USD 价格
    /// @param token token 地址（address(0) = ETH）
    /// @param amount token 数量
    /// @return usdValue USD 价值（18 位小数）
    function _getUSDValue(address token, uint256 amount) internal virtual view returns (uint256 usdValue) {
        // 1. 获取 priceFeed 地址
        address priceFeed = tokenPriceFeeds[token];
        require(priceFeed != address(0), "Token not supported");
        
        // 2. 调用 Chainlink 获取价格（8 位小数）
        (, int256 price, , ,) = AggregatorV3Interface(priceFeed).latestRoundData();
        require(price > 0, "Invalid price");
        
        // 3. 获取 token 的小数位数
        uint8 tokenDecimals;
        if (token == address(0)) {
            tokenDecimals = 18; // ETH 是 18 位小数
        } else {
            tokenDecimals = IERC20Metadata(token).decimals();
        }
        
        // 4. 换算成 USD（统一到 18 位小数）
        // 公式：(amount * price * 1e18) / (10^tokenDecimals) / 1e8
        usdValue = (amount * uint256(price) * 1e18) / (10 ** tokenDecimals) / 1e8;
    }

    // ============ UUPS 升级授权 ============

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}
