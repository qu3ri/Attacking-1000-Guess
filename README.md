# Attacking 1000 Guess

## Description
This project demonstrates an attack on the Ethereum lottery game 1000 Guess. 

Private variables in Ethereum are not truly private, while they are obscured from the public view, they still exist publicly on the blockchain. The lottery game 1000 Guess operated on Ethereum's decentralized infrastructure and players placed bets on their position in the sequence of players. For instance, if a player was the fifth to place a bet, their guess would be the number 5. After the 1000th player placed a bet, the winning number was chosen by a pseudo-random number generator (PRNG) and several private variables in the contract.

However, all variables used to determine the winning position were visible on the public blockchain, introducing a vulnerability where an attacker can determine if the 1000th bet placed will be the winner before the bet is made, and make a bet accordingly. 

This project contains a modern implementation of the original, vulnerable 1000 Guess game; a demonstration of the attack; and a secure version of 1000 Guess that is not vulnerable to the same attack. 

The original version of 1000 Guess in an older version of Solidity can be found at: https://etherscan.io/address/0x386771ba5705da638d889381471ec1025a824f53#readContract
The attack is based on CVE-2018-12454 and the blog post found at: https://medium.com/coinmonks/attack-on-pseudo-random-number-generator-prng-used-in-1000-guess-an-ethereum-lottery-game-7b76655f953d 


## Setup
This project was developed and tested in Hardhat and requires an installation of Node.js. 

To set up the Hardhat testing environment:

```shell
npm install --save-dev hardhat
npm add --dev @openzeppelin/contracts
npm add @chainlink/contracts
```

