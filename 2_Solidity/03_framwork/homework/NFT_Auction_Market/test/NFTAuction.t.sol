// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTAuction.sol";
import "../src/NFT.sol";
import "../src/AuctionToken.sol";
import "./mocks/MockV3Aggregator.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NFTAuctionTest is Test {
    // ============ 合约实例 ============
    
    NFTAuction public auction;
    NFT public nft;
    AuctionToken public usdc;
    AuctionToken public usdt;
    
    MockV3Aggregator public ethPriceFeed;
    MockV3Aggregator public usdcPriceFeed;
    MockV3Aggregator public usdtPriceFeed;

    // ============ 测试账户 ============
    
    address public owner   = makeAddr("owner");
    address public seller  = makeAddr("seller");
    address public bidder1 = makeAddr("bidder1");
    address public bidder2 = makeAddr("bidder2");

    // ============ 设置 ============

    function setUp() public {
        vm.startPrank(owner);

        // TODO: 1. 部署 NFT 合约
        nft = new NFT("Auction NFT", "ANFT");

        // TODO: 2. 部署 ERC20 代币（USDC, USDT）
        usdc = new AuctionToken("Mock USDC", "USDC", 6);
        usdt = new AuctionToken("Mock USDT", "USDT", 6);

        // TODO: 3. 部署 Mock 喂价合约
        ethPriceFeed = new MockV3Aggregator(8, 2800 * 1e8);  // ETH = $2800
        usdcPriceFeed = new MockV3Aggregator(8, 1 * 1e8);    // USDC = $1
        usdtPriceFeed = new MockV3Aggregator(8, 1 * 1e8);    // USDT = $1

        // TODO: 4. 部署 NFTAuction 的 UUPS 代理
        NFTAuction implementation = new NFTAuction();
        bytes memory initData = abi.encodeCall(implementation.initialize, ());
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        auction = NFTAuction(address(proxy));

        // TODO: 5. 注册支持的 token 和喂价地址
        auction.registerToken(address(0), address(ethPriceFeed));
        auction.registerToken(address(usdc), address(usdcPriceFeed));
        auction.registerToken(address(usdt), address(usdtPriceFeed));

        // TODO: 6. 给测试账户分配代币和 ETH
        vm.deal(bidder1, 10 ether);
        usdc.mint(bidder2, 10000 * 1e6);

        vm.stopPrank();
    }

    // ============ 测试用例 ============

    /// @notice 测试创建拍卖
    function testCreateAuction() public {
        vm.startPrank(seller);

        // 1. seller mint 一个 NFT
        uint256 tokenId = nft.mintNFT(seller, "ipfs://test");

        // 2. seller approve 拍卖合约
        nft.approve(address(auction), tokenId);

        // 3. seller 创建拍卖
        uint256 startPrice = 100e18; // $100
        uint256 duration = 1 days;
        uint256 auctionId = auction.createAuction(address(nft), tokenId, startPrice, duration);

        vm.stopPrank();

        // 4. 验证拍卖数据
        (
            address _seller,
            address _nftContract,
            uint256 _tokenId,
            uint256 _startPrice,
            uint256 _endTime,
            bool _ended,
            address _highestBidder,
            ,
            ,
        ) = auction.auctions(auctionId);

        assertEq(_seller, seller,                        "seller mismatch");
        assertEq(_nftContract, address(nft),             "nftContract mismatch");
        assertEq(_tokenId, tokenId,                      "tokenId mismatch");
        assertEq(_startPrice, startPrice,                "startPrice mismatch");
        assertEq(_endTime, block.timestamp + duration,   "endTime mismatch");
        assertFalse(_ended,                              "auction should not be ended");
        assertEq(_highestBidder, address(0),             "no bidder yet");

        // NFT should be transferred to auction contract
        assertEq(nft.ownerOf(tokenId), address(auction), "NFT not transferred to auction");
    }

    // ============ Helper ============

    function _createAuction(uint256 startPriceUSD, uint256 duration)
        internal
        returns (uint256 tokenId, uint256 auctionId)
    {
        vm.startPrank(seller);
        tokenId = nft.mintNFT(seller, "ipfs://test");
        nft.approve(address(auction), tokenId);
        auctionId = auction.createAuction(address(nft), tokenId, startPriceUSD, duration);
        vm.stopPrank();
    }

    // ============ testBidWithETH ============

    /// @notice 测试 ETH 出价
    function testBidWithETH() public {
        // 1. 创建拍卖，起拍价 $100，持续 1 天
        (, uint256 auctionId) = _createAuction(100e18, 1 days);

        // 2. bidder1 用 1 ETH 出价（= $2800）
        // bid{value: 1 ether} 是 Foundry 发送 ETH 的语法
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(auctionId, address(0), 1 ether);

        // 3. 验证最高出价更新
        (
            , , , , , ,
            address _highestBidder,
            uint256 _highestBidInUSD,
            address _highestBidToken,
            uint256 _highestBidAmount
        ) = auction.auctions(auctionId);

        assertEq(_highestBidder, bidder1,    "highest bidder should be bidder1");
        assertEq(_highestBidToken, address(0), "bid token should be ETH");
        assertEq(_highestBidAmount, 1 ether,   "bid amount should be 1 ether");
        // 1 ETH * $2800 = $2800，18位小数
        assertEq(_highestBidInUSD, 2800e18,    "USD value should be $2800");
    }

    /// @notice 测试 ERC20 出价
    function testBidWithERC20() public {
        // 1. 创建拍卖，起拍价 $100
        (, uint256 auctionId) = _createAuction(100e18, 1 days);

        // 2. bidder2 approve USDC 给拍卖合约，再出价 3000 USDC
        uint256 bidAmount = 3000 * 1e6; // 3000 USDC，6位小数
        vm.startPrank(bidder2);
        usdc.approve(address(auction), bidAmount);
        auction.bid(auctionId, address(usdc), bidAmount);
        vm.stopPrank();

        // 3. 验证最高出价更新
        (
            , , , , , ,
            address _highestBidder,
            uint256 _highestBidInUSD,
            address _highestBidToken,
            uint256 _highestBidAmount
        ) = auction.auctions(auctionId);

        assertEq(_highestBidder, bidder2,          "highest bidder should be bidder2");
        assertEq(_highestBidToken, address(usdc),  "bid token should be USDC");
        assertEq(_highestBidAmount, bidAmount,     "bid amount should be 3000 USDC");
        // 3000 USDC * $1 = $3000
        assertEq(_highestBidInUSD, 3000e18,        "USD value should be $3000");
    }

    /// @notice 测试混合出价（ETH vs USDC），USD 价值高的胜出
    function testMixedBids() public {
        (, uint256 auctionId) = _createAuction(100e18, 1 days);

        // bidder1 用 1 ETH 出价（= $2800）
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(auctionId, address(0), 1 ether);

        // bidder2 用 3000 USDC 出价（= $3000，更高）
        uint256 bidAmount = 3000 * 1e6;
        vm.startPrank(bidder2);
        usdc.approve(address(auction), bidAmount);
        auction.bid(auctionId, address(usdc), bidAmount);
        vm.stopPrank();

        // 验证 bidder2 是最高出价者
        ( , , , , , , address _highestBidder, , , ) = auction.auctions(auctionId);
        assertEq(_highestBidder, bidder2, "bidder2 should win with higher USD value");

        // bidder1 应该有待退款（1 ETH）
        assertEq(pendingReturns(bidder1, address(0)), 1 ether, "bidder1 should have pending return");
    }

    /// @notice 测试结束拍卖：NFT 转给 winner，资金转给 seller
    function testEndAuction() public {
        (, uint256 auctionId) = _createAuction(100e18, 1 days);

        // bidder1 出价 1 ETH
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(auctionId, address(0), 1 ether);

        // 记录 seller 出价前余额
        uint256 sellerBalanceBefore = seller.balance;

        // 时间快进到拍卖结束后
        vm.warp(block.timestamp + 1 days + 1);

        // 任何人都可以调用 endAuction
        auction.endAuction(auctionId);

        // 验证 NFT 转移给 bidder1
        (, uint256 tokenId) = _getAuctionTokenId(auctionId);
        assertEq(nft.ownerOf(tokenId), bidder1, "NFT should go to winner");

        // 验证 seller 收到 ETH
        assertEq(seller.balance, sellerBalanceBefore + 1 ether, "seller should receive ETH");

        // 验证拍卖已标记结束
        ( , , , , , bool _ended, , , , ) = auction.auctions(auctionId);
        assertTrue(_ended, "auction should be marked ended");
    }

    /// @notice 测试退款：被超越的出价者可以取回资金
    function testWithdraw() public {
        (, uint256 auctionId) = _createAuction(100e18, 1 days);

        // bidder1 先出价 1 ETH
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(auctionId, address(0), 1 ether);

        // bidder2 出更高价 3000 USDC，bidder1 被超越
        uint256 bidAmount = 3000 * 1e6;
        vm.startPrank(bidder2);
        usdc.approve(address(auction), bidAmount);
        auction.bid(auctionId, address(usdc), bidAmount);
        vm.stopPrank();

        // bidder1 取回 ETH
        uint256 balanceBefore = bidder1.balance;
        vm.prank(bidder1);
        auction.withdraw(address(0));

        assertEq(bidder1.balance, balanceBefore + 1 ether, "bidder1 should get ETH refund");
        assertEq(pendingReturns(bidder1, address(0)), 0,   "pending return should be cleared");
    }

    /// @notice 测试未注册的 token 出价应 revert
    function testUnsupportedToken() public {
        (, uint256 auctionId) = _createAuction(100e18, 1 days);

        address fakeToken = address(999);

        vm.prank(bidder1);
        vm.expectRevert("Token not supported");
        auction.bid(auctionId, fakeToken, 100e18);
    }

    // ============ 内部工具 ============

    /// @dev 读取 pendingReturns（封装一下避免重复解构）
    function pendingReturns(address user, address token) internal view returns (uint256) {
        return auction.pendingReturns(user, token);
    }

    /// @dev 从拍卖数据里取 tokenId
    function _getAuctionTokenId(uint256 auctionId) internal view returns (uint256, uint256) {
        ( , , uint256 tokenId, , , , , , , ) = auction.auctions(auctionId);
        return (auctionId, tokenId);
    }
}
