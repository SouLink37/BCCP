// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BeggingContract {
    address public owner;
    address[] public donorList;
    mapping(address => bool) private isDonor;
    mapping(address => uint256) public donations;
    uint256 public totalDonations;
    
    uint256 public startTime;
    uint256 public endTime;

    event Donation(address indexed donor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier withinTimeLimit() {
        require(block.timestamp >= startTime, "Not started");
        require(block.timestamp <= endTime, "Campaign ended");
        _;
    }

    constructor(uint256 _duration) {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = block.timestamp + _duration;
    }

    function donate() public payable withinTimeLimit { 
        require(msg.value > 0, "Zero donation");

        if (!isDonor[msg.sender]) {
            donorList.push(msg.sender);
            isDonor[msg.sender] = true;
        }

        donations[msg.sender] += msg.value;
        totalDonations += msg.value;

        emit Donation(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getDonation(address donor) public view returns(uint256){
        return donations[donor];
    }

    // 前端可以获取所有捐赠者，然后排序
    function getDonorCount() public view returns (uint256) {
        return donorList.length;
    }

    function extendCampaign(uint256 additionalTime) public onlyOwner {
        endTime += additionalTime;
    }
}