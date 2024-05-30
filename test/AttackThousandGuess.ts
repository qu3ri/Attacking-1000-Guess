// Author: Sierra Kennedy

// Tests that the game attack functions

import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers"
import { expect } from "chai"
import { ethers } from "hardhat"

describe("Attack Thousand Guess", function () {
    async function deployFixture() {
        const [developer, p1, p2, p3, p4, p5, attacker] = await ethers.getSigners()
        const game = await ethers.deployContract("ThousandGuess")
        const attackContract = await ethers.deployContract("Attack")
    
        return {developer, p1, p2, p3, p4, p5, attacker, game, attackContract}
    }

    it("Attacker Wins", async function () {
        const {developer, p1, p2, p3, p4, p5, attacker, game, attackContract} = await loadFixture(deployFixture)
        // 9 people bet
        await game.connect(p1).addGuess({value: ethers.parseEther("1")})
        await game.connect(p2).addGuess({value: ethers.parseEther("1")})
        await game.connect(p3).addGuess({value: ethers.parseEther("1")})
        await game.connect(p4).addGuess({value: ethers.parseEther("1")})
        await game.connect(p5).addGuess({value: ethers.parseEther("1")})
        await game.connect(p1).addGuess({value: ethers.parseEther("1")})
        await game.connect(p2).addGuess({value: ethers.parseEther("1")})
        await game.connect(p3).addGuess({value: ethers.parseEther("1")})
        await game.connect(p4).addGuess({value: ethers.parseEther("1")})

        // (address target, bytes32 curhash, uint256 arraySize, uint attackerInd)
        const curhash = ethers.provider.getStorage(game, 0);
        // Will revert with a string if the attacker will not win, and attacker does not place bet
        // If attacker will win they will bet 
        await attackContract.connect(attacker).attack(game.getAddress(), ethers.encodeBytes32String(String(curhash)), 10, 9, {value: ethers.parseEther("1")})

        console.log("Attacker: ", attacker)
        
        // Winner is random so we do not know who will win. Should be different every time
        const winner = await game.getWinner()
        console.log(winner)
    })
})