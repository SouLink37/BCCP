
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ============ Imports ============
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @title NFT
/// @notice 作业用最小 ERC721：mint 并绑定 tokenURI
contract NFT is ERC721, ERC721URIStorage {
    // ============ State ============

    /// @dev 自增 tokenId（本实现首次 mint 的 tokenId 为 1）
    uint256 private _nextTokenId;

    // ============ Constructor ============

    /// @notice 初始化 NFT 合约，设置集合名称和符号（会显示在钱包 / OpenSea 等）。
    /// @param name_ NFT 集合名称，例如 "My First NFT"
    /// @param symbol_ NFT 集合符号，例如 "MFN"
    /// @dev 这里一般只做初始化；更复杂的配置（owner/baseURI/maxSupply）你可自行添加。
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    // ============ Mint ============

    /// @notice Mint NFT to `recipient` and set its tokenURI
    /// @param recipient NFT 接收地址
    /// @param uri 元数据链接（tokenURI）
    /// @return tokenId 新铸造的 tokenId
    function mintNFT(address recipient, string memory uri) external returns (uint256 tokenId) {
        _nextTokenId++;
        tokenId = _nextTokenId;
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // ============ Overrides ============

    /// @notice Get tokenURI for tokenId
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory uri)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice ERC165 supportsInterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool supported)
    {
        return super.supportsInterface(interfaceId);
    }

}

