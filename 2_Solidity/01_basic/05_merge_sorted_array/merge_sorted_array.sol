// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MergeSortedArray {
    function mergeSortedArray(uint256[] calldata array1, uint256[] calldata array2) public pure returns(uint256[] memory){
        uint256 len1 = array1.length;
        uint256 len2 = array2.length;

        uint256 p1 = 0;
        uint256 p2 = 0;

        uint256[] memory result = new uint256[](len1 + len2);
        uint256 index = 0;

        while (p1 < len1 && p2 < len2) {
            if (array1[p1] <= array2[p2]) {
                result[index++] = array1[p1];
                ++p1;
            } else {
                result[index++] = array2[p2];
                ++p2;
            }
        }

        while (p1 < len1) {
            result[index++] = array1[p1++];
        }
        while (p2 < len2) {
            result[index++] = array2[p2++];
        }

        return result;
    }
}