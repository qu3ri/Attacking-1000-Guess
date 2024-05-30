// Author: Kyri Lea

// Tests that the game functions as intended in the absence of malicious players

import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers"
import { ethers } from "hardhat"

describe("Thousand Guess", function () {
    async function deployFixture() {
        const [developer, p1, p2, p3, p4, p5] = await ethers.getSigners()
        const game = await ethers.deployContract("ThousandGuess")
    
        return {developer, p1, p2, p3, p4, p5, game}
    }

    it("A Winner is chosen", async function () {
        const {developer, p1, p2, p3, p4, p5, game} = await loadFixture(deployFixture)
        // After 10 guesses, a winner will be chosen
        await game.connect(p1).addGuess({value: ethers.parseEther("1")})
        await game.connect(p2).addGuess({value: ethers.parseEther("1")})
        await game.connect(p3).addGuess({value: ethers.parseEther("1")})
        await game.connect(p4).addGuess({value: ethers.parseEther("1")})
        await game.connect(p5).addGuess({value: ethers.parseEther("1")})
        await game.connect(p1).addGuess({value: ethers.parseEther("1")})
        await game.connect(p2).addGuess({value: ethers.parseEther("1")})
        await game.connect(p3).addGuess({value: ethers.parseEther("1")})
        await game.connect(p4).addGuess({value: ethers.parseEther("1")})
        await game.connect(p5).addGuess({value: ethers.parseEther("1")})
        
        // Winner is random so we do not know who will win. Should be different every time
        const winner = await game.getWinner()
        console.log(winner)
    })
})