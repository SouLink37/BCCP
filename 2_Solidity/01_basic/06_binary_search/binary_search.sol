// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BinarySearch {
    function binarySearch(int256[] calldata inputArray, int256 target) public pure returns(int256) {
        if (inputArray.length == 0) {
            return -1;
        }

        uint256 right = inputArray.length - 1;
        uint256 left = 0;

        if (target < inputArray[left] || target > inputArray[right]) {
            return -1;
        }

        while (left <= right) {
            uint256 mid = left + (right - left) / 2;
            
            if (inputArray[mid] == target) {
                return mid;
            } else if (inputArray[mid] < target) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }   

        return -1;
    }
}