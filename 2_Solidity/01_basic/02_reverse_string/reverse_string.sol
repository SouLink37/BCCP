// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReverseString {
    function reverseString(string memory input) public pure returns(string memory) {
        bytes memory inputBytes = bytes(input);
        uint256 len = inputBytes.length;

        bytes memory reverseBytes = new bytes(len);

        for (uint i = 0; i < len; ++i){
            reverseBytes[i] = inputBytes[len - i - 1];
        } 

        return string(reverseBytes);
    }
}