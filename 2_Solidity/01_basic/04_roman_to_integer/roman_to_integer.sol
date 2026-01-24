// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RomanToInterger {
    function romanToInterger(string calldata s) public pure returns(uint256) {
        bytes memory input = bytes(s);
        uint256 result = 0;
        uint256 preValue = 0;

        for (uint256 i = uint256(input.length); i > 0; --i) {
            uint256 currentValue = charToValue(input[i - 1]);

            if (currentValue > preValue) {
                result += currentValue;
            } else {
                result -= currentValue;
            }

            preValue = currentValue;
        }

        return result;
    }

    function charToValue(bytes1 char) internal pure returns (uint256) {
        if (char == 'I') return 1;
        if (char == 'V') return 5;
        if (char == 'X') return 10;
        if (char == 'L') return 50;
        if (char == 'C') return 100;
        if (char == 'D') return 500;
        if (char == 'M') return 1000;
        return 0;
    }
}