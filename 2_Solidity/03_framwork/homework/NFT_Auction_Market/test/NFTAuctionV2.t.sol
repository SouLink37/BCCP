// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTAuction.sol";
import "../src/NFTAuctionV2.sol";
import "../src/NFT.sol";
import "../src/AuctionToken.sol";
import "./mocks/MockV3Aggregator.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NFTAuctionV2Test is Test {
    // ============ 合约实例 ============

    NFTAuction public auction;       // 指向代理，V1 接口
    NFTAuctionV2 public auctionV2;   // 升级后，V2 接口
    NFT public nft;
    AuctionToken public usdc;

    MockV3Aggregator public ethPriceFeed;
    MockV3Aggregator public usdcPriceFeed;

    // ============ 测试账户 ============

    // makeAddr() 生成哈希地址，不会和任何 EVM 预编译合约冲突
    address public owner   = makeAddr("owner");
    address public seller  = makeAddr("seller");
    address public bidder1 = makeAddr("bidder1");
    address public bidder2 = makeAddr("bidder2");

    // 代理地址（升级前后不变）
    address public proxyAddr;

    // ============ setUp ============

    function setUp() public {
        vm.startPrank(owner);

        nft  = new NFT("Auction NFT", "ANFT");
        usdc = new AuctionToken("Mock USDC", "USDC", 6);

        ethPriceFeed  = new MockV3Aggregator(8, 2800 * 1e8); // ETH = $2800
        usdcPriceFeed = new MockV3Aggregator(8, 1 * 1e8);    // USDC = $1

        // 部署 V1 实现 + 代理
        NFTAuction implV1 = new NFTAuction();
        bytes memory initData = abi.encodeCall(implV1.initialize, ());
        ERC1967Proxy proxy = new ERC1967Proxy(address(implV1), initData);
        proxyAddr = address(proxy);
        auction = NFTAuction(proxyAddr);

        auction.registerToken(address(0),    address(ethPriceFeed));
        auction.registerToken(address(usdc), address(usdcPriceFeed));

        vm.deal(bidder1, 10 ether);
        usdc.mint(bidder2, 10000 * 1e6);

        vm.stopPrank();
    }

    // ============ Helper ============

    function _createAuction(uint256 startPriceUSD, uint256 duration)
        internal
        returns (uint256 tokenId, uint256 auctionId)
    {
        vm.startPrank(seller);
        tokenId = nft.mintNFT(seller, "ipfs://test");
        nft.approve(proxyAddr, tokenId);
        auctionId = auction.createAuction(address(nft), tokenId, startPriceUSD, duration);
        vm.stopPrank();
    }

    /// @dev 升级到 V2，返回 V2 接口
    function _upgradeToV2() internal returns (NFTAuctionV2) {
        NFTAuctionV2 implV2 = new NFTAuctionV2();
        vm.prank(owner);
        auction.upgradeToAndCall(address(implV2), "");
        return NFTAuctionV2(proxyAddr);
    }

    // ============ 升级测试 ============

    /// @notice 升级后代理地址不变，V1 数据保留
    function testUpgradePreservesState() public {
        // V1 先创建一个拍卖
        (, uint256 auctionId) = _createAuction(100e18, 1 days);

        // 升级到 V2
        auctionV2 = _upgradeToV2();

        // 代理地址不变
        assertEq(address(auctionV2), proxyAddr, "proxy address should not change");

        // V1 的拍卖数据还在
        (address _seller, , , , , , , , , ) = auctionV2.auctions(auctionId);
        assertEq(_seller, seller, "auction state should be preserved after upgrade");
    }

    /// @notice 非 owner 不能升级
    function testUpgrade_RevertIfNotOwner() public {
        NFTAuctionV2 implV2 = new NFTAuctionV2();

        vm.prank(bidder1);
        vm.expectRevert();
        auction.upgradeToAndCall(address(implV2), "");
    }

    // ============ 手续费测试 ============

    /// @notice 设置手续费率
    function testSetFeeRate() public {
        auctionV2 = _upgradeToV2();

        vm.prank(owner);
        auctionV2.setFeeRate(250); // 2.5%

        assertEq(auctionV2.feeRate(), 250, "fee rate should be 250");
    }

    /// @notice 手续费率超过 1000 应 revert
    function testSetFeeRate_RevertIfTooHigh() public {
        auctionV2 = _upgradeToV2();

        vm.prank(owner);
        vm.expectRevert("Fee too high");
        auctionV2.setFeeRate(1001);
    }

    /// @notice 非 owner 不能设置手续费率
    function testSetFeeRate_RevertIfNotOwner() public {
        auctionV2 = _upgradeToV2();

        vm.prank(bidder1);
        vm.expectRevert();
        auctionV2.setFeeRate(250);
    }

    /// @notice 结束拍卖时正确扣除手续费，seller 收到扣费后的金额
    function testEndAuction_WithFee() public {
        auctionV2 = _upgradeToV2();

        // 设置 10% 手续费
        vm.prank(owner);
        auctionV2.setFeeRate(1000);

        // 创建拍卖，bidder1 出 1 ETH
        (, uint256 auctionId) = _createAuction(100e18, 1 days);
        vm.prank(bidder1);
        auctionV2.bid{value: 1 ether}(auctionId, address(0), 1 ether);

        uint256 sellerBalanceBefore = seller.balance;

        // 结束拍卖
        vm.warp(block.timestamp + 1 days + 1);
        auctionV2.endAuction(auctionId);

        // 手续费 10% of 1 ETH = 0.1 ETH，seller 收到 0.9 ETH
        assertEq(seller.balance, sellerBalanceBefore + 0.9 ether, "seller should receive 0.9 ETH after 10% fee");

        // 合约记录了 0.1 ETH 手续费
        assertEq(auctionV2.collectedFees(address(0)), 0.1 ether, "collected fee should be 0.1 ETH");
    }

    /// @notice owner 可以提取手续费
    function testWithdrawFees() public {
        auctionV2 = _upgradeToV2();

        vm.prank(owner);
        auctionV2.setFeeRate(1000); // 10%

        (, uint256 auctionId) = _createAuction(100e18, 1 days);
        vm.prank(bidder1);
        auctionV2.bid{value: 1 ether}(auctionId, address(0), 1 ether);

        vm.warp(block.timestamp + 1 days + 1);
        auctionV2.endAuction(auctionId);

        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        auctionV2.withdrawFees(address(0));

        assertEq(owner.balance, ownerBalanceBefore + 0.1 ether, "owner should receive collected fees");
        assertEq(auctionV2.collectedFees(address(0)), 0, "collected fees should be cleared");
    }

    /// @notice 无手续费时提取应 revert
    function testWithdrawFees_RevertIfEmpty() public {
        auctionV2 = _upgradeToV2();

        vm.prank(owner);
        vm.expectRevert("No fees to withdraw");
        auctionV2.withdrawFees(address(0));
    }

    /// @notice 非 owner 不能提取手续费
    function testWithdrawFees_RevertIfNotOwner() public {
        auctionV2 = _upgradeToV2();

        vm.prank(bidder1);
        vm.expectRevert();
        auctionV2.withdrawFees(address(0));
    }

    /// @notice feeRate = 0 时不收手续费，seller 收到全额
    function testEndAuction_ZeroFee() public {
        auctionV2 = _upgradeToV2();
        // feeRate 默认就是 0，不需要额外设置

        (, uint256 auctionId) = _createAuction(100e18, 1 days);
        vm.prank(bidder1);
        auctionV2.bid{value: 1 ether}(auctionId, address(0), 1 ether);

        uint256 sellerBalanceBefore = seller.balance;

        vm.warp(block.timestamp + 1 days + 1);
        auctionV2.endAuction(auctionId);

        assertEq(seller.balance, sellerBalanceBefore + 1 ether, "seller should receive full amount with zero fee");
        assertEq(auctionV2.collectedFees(address(0)), 0, "no fee should be collected");
    }
}
