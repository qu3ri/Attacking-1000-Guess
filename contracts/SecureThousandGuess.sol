// SPDX-License-Identifier: MIT
//Author: Domenic Lo Iacono

pragma solidity ^0.8.24;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

contract Lottery is VRFConsumerBaseV2, ConfirmedOwner {
    enum LotteryState { Open, Drawing, Closed }

    event RequestSent(uint256 requestId);
    event RequestFulfilled(uint256 requestId, uint256 randomWord);
    event WinnerPaid(address winner, uint256 amount);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256 randomWord;
    }

    VRFCoordinatorV2Interface COORDINATOR;
    mapping(uint256 => RequestStatus) public s_requests;
    address payable[] public players;
    uint public lotteryId;
    mapping(uint => address payable) public lotteryHistory;
    mapping(uint => uint256) public lotteryPayouts;
    uint public randomResult;
    LotteryState public state;

    uint64 s_subscriptionId;
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625) ConfirmedOwner(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625);
        s_subscriptionId = subscriptionId;
        lotteryId = 1;
        state = LotteryState.Open;
    }

    /// Allows entry into the lottery; requires a minimum ETH sent and lottery to be open.
    function enter() public payable {
        require(msg.value > 1 gwei, "Insufficient ETH sent");
        require(state == LotteryState.Open, "Lottery not accepting entries");
        players.push(payable(msg.sender));
    }

    /// Initiates a request for random words; only callable by the owner and requires at least two players.
    function requestRandomWords() external onlyOwner {
        require(players.length > 1, "Not enough players");
        require(state == LotteryState.Open, "Lottery draw in progress or not ready");

        uint256 requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, 1);
        s_requests[requestId] = RequestStatus({randomWord: 0, exists: true, fulfilled: false});
        state = LotteryState.Drawing;
        emit RequestSent(requestId);
    }

    /// Callback function for the VRF coordinator to deliver random words; internal use only.
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "Request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWord = _randomWords[0];

        emit RequestFulfilled(_requestId, _randomWords[0]);
        randomResult = _randomWords[0];
        payWinner();
    }

    /// Pays out to the lottery winner; requires a drawing in progress.
    function payWinner() public  {
        require(state == LotteryState.Drawing, "No draw in progress");
        uint index = randomResult % players.length;
        address payable winner = players[index];
        uint256 payout = address(this).balance;
        winner.transfer(payout);

        lotteryHistory[lotteryId] = winner;
        lotteryPayouts[lotteryId] = payout;
        lotteryId++;

        players = new address payable[](0);
        state = LotteryState.Closed;
        emit WinnerPaid(winner, payout);
    }

    /// Reopens the lottery for new entries; only callable by the owner and if the lottery has ended.
    function restartLottery() public onlyOwner {
        require(state == LotteryState.Closed, "Lottery not ended");
        state = LotteryState.Open;
        lotteryId++;
    }

    /// Closes the open lottery and triggers the draw for a winner; only callable by the owner.
    function closeLotteryAndDrawWinner() public onlyOwner {
        require(state == LotteryState.Open, "Lottery not open or already drawing");
        //require(players.length > 1, "Not enough players to draw a winner");

        // Request random number to select winner
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1  // Request only one random word
        );
        
        s_requests[requestId] = RequestStatus({
            randomWord: 0,
            exists: true,
            fulfilled: false
        });

        state = LotteryState.Drawing;
        emit RequestSent(requestId);
    }

    /// Provides details of a specific lottery by ID, including the winner and payout.
    function getLotteryDetails(uint _lotteryId) public view returns (address payable winner, uint256 payout) {
        return (lotteryHistory[_lotteryId], lotteryPayouts[_lotteryId]);
    }
}
