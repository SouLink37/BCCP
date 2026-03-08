// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTAuction.sol";

/// @title NFTAuctionV2
/// @notice NFTAuction 的升级版本，新增手续费功能
contract NFTAuctionV2 is NFTAuction {
    // ============ 新增状态变量（必须加在 V1 状态变量之后）============

    /// @notice 手续费率（基点，10000 = 100%，最高 1000 = 10%）
    uint256 public feeRate;

    /// @notice 累计手续费收入（token → 金额）
    mapping(address => uint256) public collectedFees;

    /// @dev 预留存储槽（V1 用了 45 个 gap，V2 新增 2 个变量，还剩 43 个）
    uint256[43] private __gap;

    // ============ 新增事件 ============

    event FeeRateUpdated(uint256 oldFeeRate, uint256 newFeeRate);
    event FeeCollected(uint256 indexed auctionId, address token, uint256 feeAmount);
    event FeesWithdrawn(address indexed token, uint256 amount);

    // ============ 新增函数 ============

    /// @notice 设置手续费率（只有 owner 可调用）
    /// @param newFeeRate 新手续费率（基点，如 250 = 2.5%）
    function setFeeRate(uint256 newFeeRate) external virtual onlyOwner {
        require(newFeeRate <= 1000, "Fee too high");
        uint256 oldFeeRate = feeRate;
        feeRate = newFeeRate;
        emit FeeRateUpdated(oldFeeRate, newFeeRate);
    }

    /// @notice 提取累计手续费（只有 owner 可调用）
    /// @param token 要提取的 token 地址（address(0) = ETH）
    function withdrawFees(address token) external virtual onlyOwner {
        uint256 amount = collectedFees[token];
        require(amount > 0, "No fees to withdraw");

        collectedFees[token] = 0;

        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).transfer(owner(), amount);
        }

        emit FeesWithdrawn(token, amount);
    }

    // ============ 重写 endAuction，加入手续费逻辑 ============

    /// @notice 结束拍卖（V2 版本，卖家收到扣除手续费后的金额）
    function endAuction(uint256 auctionId) external virtual override {
        Auction storage auction = auctions[auctionId];

        // 1. 检查拍卖是否有效和到期
        require(auction.seller != address(0), "Auction does not exist");
        require(!auction.ended, "Auction already ended");
        require(block.timestamp >= auction.endTime, "Auction not yet ended");

        // 2. 标记拍卖已结束
        auction.ended = true;

        // 3. 如果有出价者，转移 NFT 和资金（扣除手续费）
        if (auction.highestBidder != address(0)) {
            // 转移 NFT 给最高出价者
            IERC721(auction.nftContract).transferFrom(
                address(this),
                auction.highestBidder,
                auction.tokenId
            );

            // 计算手续费和卖家实收金额
            uint256 fee = auction.highestBidAmount * feeRate / 10000;
            uint256 sellerAmount = auction.highestBidAmount - fee;

            // 记录手续费
            if (fee > 0) {
                collectedFees[auction.highestBidToken] += fee;
                emit FeeCollected(auctionId, auction.highestBidToken, fee);
            }

            // 转移资金给卖家（扣除手续费后）
            if (auction.highestBidToken == address(0)) {
                // ETH
                payable(auction.seller).transfer(sellerAmount);
            } else {
                // ERC20
                IERC20(auction.highestBidToken).transfer(auction.seller, sellerAmount);
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
}
