// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IntergerToRoman {
    function intergerToRoman(uint256 num) public pure returns (string memory) {
        uint256[] memory values = new uint256[](13);
        string[] memory symbols = new string[](13);

        values[0] = 1000; symbols[0] = "M";
        values[1] = 900;  symbols[1] = "CM";
        values[2] = 500;  symbols[2] = "D";
        values[3] = 400;  symbols[3] = "CD";
        values[4] = 100;  symbols[4] = "C";
        values[5] = 90;   symbols[5] = "XC";
        values[6] = 50;   symbols[6] = "L";
        values[7] = 40;   symbols[7] = "XL";
        values[8] = 10;   symbols[8] = "X";
        values[9] = 9;    symbols[9] = "IX";
        values[10] = 5;   symbols[10] = "V";
        values[11] = 4;   symbols[11] = "IV";
        values[12] = 1;   symbols[12] = "I";

        bytes memory result = new bytes(15);
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < 13; ++i){
            while (num > values[i]) {
                bytes memory symbolBytes = bytes(symbols[i]);
                for (uint256 j = 0; j < symbolBytes.length; ++j){
                    result[resultIndex++] = symbolBytes[j];
                }
                num -= values[i];
            }
        }

        bytes memory finalResult = new bytes(resultIndex);
        for (uint256 i = 0; i < resultIndex; ++i){
            finalResult[i] = result[i];
        }

        return string(finalResult);
    }
}
