// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/NFT.sol";
import "../src/AuctionToken.sol";
import "../src/NFTAuction.sol";
import "../test/mocks/MockV3Aggregator.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title DeployScript
/// @notice 部署到 Sepolia 测试网：
///   - ETH/USD 使用真实 Chainlink 喂价
///   - Mock USDC 使用 MockV3Aggregator 固定返回 $1（Sepolia 无 USDC 喂价）
contract DeployScript is Script {
    // Sepolia 真实 Chainlink 喂价地址
    // 来源：https://docs.chain.link/data-feeds/price-feeds/addresses
    address constant SEPOLIA_ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // ---- 1. 部署 NFT 合约 ----
        NFT nft = new NFT("Auction NFT", "ANFT");

        // ---- 2. 部署 Mock USDC（6 位小数） ----
        AuctionToken mockUsdc = new AuctionToken("Mock USDC", "mUSDC", 6);
        mockUsdc.mint(msg.sender, 100_000 * 10 ** 6); // 给部署者 mint 10 万枚测试用

        // ---- 3. 配置喂价地址 ----
        // ETH/USD: 使用真实 Chainlink 喂价
        address ethPriceFeed = SEPOLIA_ETH_USD_FEED;

        // mUSDC: Sepolia 上没有 USDC/USD 喂价，用 Mock 固定返回 $1
        MockV3Aggregator usdcMockFeed = new MockV3Aggregator(8, 1 * 1e8);
        address usdcPriceFeed = address(usdcMockFeed);

        // ---- 4. 部署 NFTAuction UUPS 代理 ----
        NFTAuction implementation = new NFTAuction();
        bytes memory initData = abi.encodeCall(NFTAuction.initialize, ());
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        NFTAuction auction = NFTAuction(address(proxy));

        // ---- 5. 注册支持的 Token 及其喂价 ----
        auction.registerToken(address(0),        ethPriceFeed);  // ETH
        auction.registerToken(address(mockUsdc), usdcPriceFeed); // Mock USDC

        // ---- 6. 输出部署结果 ----
        console.log("------------------------------------");
        console.log(unicode"NFT            :", address(nft));
        console.log(unicode"Mock USDC      :", address(mockUsdc));
        console.log(unicode"NFTAuction Impl:", address(implementation));
        console.log(unicode"NFTAuction Proxy:", address(proxy));
        console.log("------------------------------------");

        vm.stopBroadcast();
    }
}
