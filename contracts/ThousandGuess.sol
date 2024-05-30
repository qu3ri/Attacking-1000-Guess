// SPDX-License-Identifier: MIT

// Author: Kyri Lea

// Modification of https://etherscan.io/address/0x386771ba5705da638d889381471ec1025a824f53#readContract
// Updated to modern Solidity, removed extra functions, changed to 10 players

pragma solidity ^0.8.24;


contract ThousandGuess {
    // Used as variables to select a winner
    bytes32 currentHash = "";
    uint256 startTime;
    uint256 maxGuess = 1000000;

    // Someone can only bet if the game is open
    enum State {Started, Ended}
    State public state;

    // Each Guess is stored here
    struct Guess {
        address addr;
    }
    Guess[10] guesses;
    uint256 arraySize = 10;
    uint256 numGuesses = 0;

    uint256 public bet = 1 ether;

    // Counts the number of games that have been played on this contract
    uint256 gameIndex;

    // Developer and most recent winner's addresses
    address developer;
    address winner;

    modifier isActive() {
        require(state == State.Started, "Game is not active");
        _;
    }

    modifier isEnded() {
        require(state == State.Ended, "Game is active");
        _;
    }

    constructor() {
        developer = msg.sender;
        startTime = block.timestamp;
        state = State.Started;
        gameIndex = 1;
    }

    // Developer can change amount of players or the betting price if they want
    function changeGameParameters(uint256 contenders, uint256 bettingPrice) public {
        require(msg.sender == developer);
        arraySize = contenders;
        if (arraySize > 10) {
            arraySize = 10;
        }
        bet = bettingPrice;
    }

    // When a game has finished, find the winner
    function findWinner(uint256 lotteryNum) private {
        uint256 win = lotteryNum % numGuesses;
        winner = guesses[win].addr;
    }

    // Get the most recent winner
    function getWinner() public view returns(address) {
        return winner;
    }

    // Return how many people have guessed
    function getNum() public view returns(uint256) {
        return numGuesses;
    }

    // Calculate the developer's fee when someone wins
    function getDeveloperFee() private view returns (uint256) {
        return address(this).balance / 100;
    }

    // Calculate how much money the winner gets
    function getLotteryWinnings() private view returns (uint256) {
        uint256 developerFee = getDeveloperFee();
        uint256 prize = address(this).balance - developerFee;
        return prize;
    }

    // Allow the developer to end the game early
    function developerEndGame() public {
        require(msg.sender == developer, "Not authorized to end the game");
        endGame();
    }

    // When game ends, calculate the winner, give them their winnings, give developer their 
    // fee, and start a new game.
    function endGame() private {
        state = State.Ended;
        uint256 blockTimestamp = block.timestamp;
        uint256 lotteryNum = (uint256(currentHash) + blockTimestamp) % (maxGuess + 1);
        findWinner(lotteryNum);

        uint256 prize = getLotteryWinnings();
        payable(winner).transfer(prize);
        payable(developer).transfer(address(this).balance);

        numGuesses = 0;
        gameIndex += 1;
        state = State.Started;
        startTime = block.timestamp;
    }

    // Players call this and send their bet in order to make a guess
    function addGuess() public payable isActive() {
        _addGuess();
    }

    // Private variables used to help calculate the winner
    function _addGuess() private {
        require(msg.value >= bet, "Place a bigger bet");
        currentHash = sha256(abi.encodePacked(block.timestamp, block.coinbase, block.difficulty, currentHash));
        if ((numGuesses + 1) <= arraySize) {
            guesses[numGuesses].addr = msg.sender;
            numGuesses = numGuesses + 1;
            if (numGuesses >= arraySize) {
                endGame();
            }
        }
    }
}