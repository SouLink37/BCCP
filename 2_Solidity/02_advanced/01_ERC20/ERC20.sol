// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    // ========== 状态变量 ==========
    string public name;
    string public symbol;
    uint256 public decimals;
    address public owner;
    uint256 public totalSupply;

    /// @dev 账户余额映射
    mapping(address => uint256) public balanceOf;

    /// @dev 授权额度映射: owner => (spender => amount)
    mapping(address => mapping(address => uint256)) public allowance;


    /// @dev 只有 owner 可以调用的 modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // ========== 构造函数 ==========
    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _initialSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10 ** decimals;
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    // ========== 实现接口方法 ==========
    /// @dev 转账：转移 amount 个代币到 recipient
    function transfer(address to, uint256 value) external returns (bool){
        require(to != address(0), "Invalid recipient address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /// @dev 授权：允许 spender 花费调用者的 amount 个代币
    function approve(address spender, uint256 value) external returns (bool){
        require(spender != address(0), "Invalid spender address");

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    /// @dev 代扣转账：从 sender 转移 amount 个代币到 recipient
    function transferFrom(address from, address to, uint256 value) external returns (bool){
        require(from != address(0), "Invalid sender address");
        require(to != address(0), "Invalid recipient address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        balanceOf[from] -= value
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);

        return true;
    }

    // ========== 额外功能 ==========
    /// @dev Mint 函数：只有合约所有者可以增发代币
    function mint(address to, uint256 value) public onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        
        totalSupply += value;
        balanceOf[to] += value;
        
        emit Transfer(address(0), to, value);
    } 

    /// @dev Burn 函数：销毁代币
    function burn(uint256 value) public {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        
        totalSupply -= value;
        balanceOf[msg.sender] -= value;
        
        emit Transfer(msg.sender, address(0), value);
    }
}