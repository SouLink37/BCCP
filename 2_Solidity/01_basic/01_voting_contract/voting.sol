// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting{
    address public owner;
    address[] public candidateList;
    mapping(address => uint256) public totalVotes;
    mapping(address => bool) public isUser;
    mapping(address => bool) public isCandidate;

    error InvalidCandidate(address);
    error InvalidAddress(address);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyUser(){
        require(isUser[msg.sender]);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function registerUser(address user) public {
        if (user == address(0)){
            revert InvalidAddress(user);
        }

        require(isUser[user] == false);
        isUser[user] = true;
    }

    function registerCandidate(address candidate) public onlyOwner {
        if (candidate == address(0)){
            revert InvalidAddress(candidate);
        }

        require(isCandidate[candidate] == false);
        isCandidate[candidate] = true;
        candidateList.push(candidate);
        totalVotes[candidate] = 0;
    }

    function vote(address candidate) public onlyUser {
        if (!isCandidate[candidate]){
            revert InvalidCandidate(candidate);
        }
        
        totalVotes[candidate] += 1;
    }

    function getVotes(address candidate) public view returns (uint256) {
        if (!isCandidate[candidate]){
            revert InvalidCandidate(candidate);
        }

        return totalVotes[candidate];
    }

    function resetVotes() public {
        uint256 len = candidateList.length;

        for (uint256 i = 0; i < len; ++i){
            totalVotes[candidateList[i]] = 0;
        } 
    }
}

