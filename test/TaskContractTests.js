const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TaskContract", function () {
    let owner, addr1, addr2, addr3, addr4, addr5, taskContract;

    beforeEach(async function () {
        // Deploy the contract and a mock ERC20 token for testing
        const TaskContract = await ethers.getContractFactory("TaskContract");
        taskContract = await TaskContract.deploy();
        await taskContract.waitForDeployment();

        const MockERC20 = await ethers.getContractFactory("MockERC20");
        token = await MockERC20.deploy("MockToken", "MTK");
        await token.waitForDeployment();
        token.mint(addr1, 100000);
        token.mint(addr2, 100000);
        token.mint(addr3, 100000);
        token.mint(addr4, 100000);
        token.mint(addr5, 100000);




        [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
        taskAdd = await taskContract.getAddress();
        tokenAdd = await token.getAddress();


    });

    describe("initialize", function () {
        it("Should correctly initialize the contract", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);

            expect(await taskContract.initialized()).to.equal(true);
        });
    });

    describe("stakeForValidation", function () {
        it("Should revert because voting period is not open", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.approve(taskAdd, 1000);
            expect(taskContract.stakeForValidation(1000, true)).to.be.revertedWith("Voting period inactive");
        });
        it("Should revert because amount is 0", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.approve(taskAdd, 0);
            expect(taskContract.stakeForValidation(0, true)).to.be.revertedWith("Amount must be greater than 0");
        });
        it("should revert because time period is over", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            await token.approve(taskAdd, 10);
            expect(taskContract.stakeForValidation(10, true)).to.be.revertedWith("voting period inactive");
        });
        it("Should stake for validation", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.connect(addr1).approve(taskAdd, 1000);
            await taskContract.connect(addr1).stakeForValidation(1000, true);
            const stakeAmount = await taskContract.getStakeFor(addr1.address);
            expect(stakeAmount).to.equal(1000);
        });
        it("Should stake against validation", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.connect(addr1).approve(taskAdd, 1000);
            await taskContract.connect(addr1).stakeForValidation(1000, false);
            const stakeAmount = await taskContract.getStakeAgainst(addr1.address);
            expect(stakeAmount).to.equal(1000);
        });

    });

    describe("calculateWinners", function () {
        it("Should revert because voting period is still active", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            expect(taskContract.calculateWinners()).to.be.revertedWith("Validation period still active");
        });
        it("Should lose the validation in a situation of a tie also asign losers and winners stake", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.connect(addr1).approve(taskAdd, 1000);
            await taskContract.connect(addr1).stakeForValidation(1000, true);
            await token.connect(addr2).approve(taskAdd, 1000);
            await taskContract.connect(addr2).stakeForValidation(1000, false);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            const forvotes = await taskContract.getTotalForStakes();
            const againstvotes = await taskContract.getTotalAgainstStakes();
            console.log(forvotes, againstvotes);
            await taskContract.calculateWinners();
            const winnerTotalStake = await taskContract.getWinnerTotalStake();
            const loserTotalStake = await taskContract.getLoserTotalStake();
            const forWon = await taskContract.getForWon();
            expect(winnerTotalStake).to.equal(1000);
            expect(loserTotalStake).to.equal(1000);
            expect(forWon).to.equal(false);
        });
        it("Should lose the validation and also asign losers and winners stake", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.connect(addr1).approve(taskAdd, 1000);
            await taskContract.connect(addr1).stakeForValidation(1000, true);
            await token.connect(addr2).approve(taskAdd, 1000);
            await taskContract.connect(addr2).stakeForValidation(1000, false);
            await token.connect(addr3).approve(taskAdd, 1000);
            await taskContract.connect(addr3).stakeForValidation(1000, false);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            const forvotes = await taskContract.getTotalForStakes();
            const againstvotes = await taskContract.getTotalAgainstStakes();
            console.log(forvotes, againstvotes);
            await taskContract.calculateWinners();
            const winnerTotalStake = await taskContract.getWinnerTotalStake();
            const loserTotalStake = await taskContract.getLoserTotalStake();
            const forWon = await taskContract.getForWon();
            expect(winnerTotalStake).to.equal(2000);
            expect(loserTotalStake).to.equal(1000);
            expect(forWon).to.equal(false);
        });
        it("Should win the validation and also asign losers and winners stake", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.connect(addr1).approve(taskAdd, 1000);
            await taskContract.connect(addr1).stakeForValidation(1000, true);
            await token.connect(addr2).approve(taskAdd, 1000);
            await taskContract.connect(addr2).stakeForValidation(1000, false);
            await token.connect(addr3).approve(taskAdd, 1000);
            await taskContract.connect(addr3).stakeForValidation(1000, true);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            const forvotes = await taskContract.getTotalForStakes();
            const againstvotes = await taskContract.getTotalAgainstStakes();
            console.log(forvotes, againstvotes);
            await taskContract.calculateWinners();
            const winnerTotalStake = await taskContract.getWinnerTotalStake();
            const loserTotalStake = await taskContract.getLoserTotalStake();
            const forWon = await taskContract.getForWon();
            expect(winnerTotalStake).to.equal(2000);
            expect(loserTotalStake).to.equal(1000);
            expect(forWon).to.equal(true);
        });
    })

    describe("updateLosersStake", function () {
        it("Should revert because voting period is still active", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            expect(taskContract.updateLosersStake()).to.be.revertedWith("Voting has not ended yet");
        });
        it("Should revert because winners must be determined", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            expect(taskContract.updateLosersStake()).to.be.revertedWith("Winners must be determined");
        });
        it("Should update losers stake", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.connect(addr1).approve(taskAdd, 1000);
            await taskContract.connect(addr1).stakeForValidation(1000, true);
            await token.connect(addr2).approve(taskAdd, 1000);
            await taskContract.connect(addr2).stakeForValidation(1000, false);
            await token.connect(addr3).approve(taskAdd, 1000);
            await taskContract.connect(addr3).stakeForValidation(1000, true);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            await taskContract.calculateWinners();
            await taskContract.updateLosersStake();
            const loserTotalStake = await taskContract.getStakeAgainst(addr2.address);
            expect(loserTotalStake).to.equal(950);
        });
        it("Should update losers stake and pool prize", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.connect(addr1).approve(taskAdd, 1000);
            await taskContract.connect(addr1).stakeForValidation(1000, false);
            await token.connect(addr2).approve(taskAdd, 1000);
            await taskContract.connect(addr2).stakeForValidation(1000, true);
            await token.connect(addr3).approve(taskAdd, 1000);
            await taskContract.connect(addr3).stakeForValidation(1000, false);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            await taskContract.calculateWinners();
            await taskContract.updateLosersStake();
            const loserTotalStake = await taskContract.getStakeFor(addr2.address);
            expect(loserTotalStake).to.equal(950);
            expect(await taskContract.getPoolPrize()).to.equal(50);
        });
    });

    // function unstakeAndClaim() external {
    //     require(
    //         task.status != TaskStatus.ValidationEnded,
    //         "Validation is not over"
    //     );
    //     require(validationPhase.losersStakeUpdated, "Losers stake not updated");
    //     require(
    //         validationPhase.poolPrize > 0,
    //         "Pool prize must be greater than 0"
    //     );

    //     if (validationPhase.forWon) {
    //         require(validationForStakes[msg.sender] > 0);
    //         uint256 reward;

    //         uint256 ratioOfPrizepool = validationForStakes[msg.sender] /
    //             validationPhase.winnerTotalStake;
    //         reward = ratioOfPrizepool * validationPhase.poolPrize;

    //         reward += validationForStakes[msg.sender];
    //         validationForStakes[msg.sender] = 0;

    //         require(
    //             task.token.transfer(msg.sender, reward),
    //             "Reward transfer failed"
    //         );
    //     } else {
    //         require(validationAgainstStakes[msg.sender] > 0);
    //         uint256 reward;

    //         uint256 ratioOfPrizepool = validationAgainstStakes[msg.sender] /
    //             validationPhase.winnerTotalStake;
    //         reward = ratioOfPrizepool * validationPhase.poolPrize;

    //         reward += validationAgainstStakes[msg.sender];
    //         validationAgainstStakes[msg.sender] = 0;

    //         require(
    //             task.token.transfer(msg.sender, reward),
    //             "Reward transfer failed"
    //         );
    //     }
    // }
    describe("unstakeAndClaim", function () {
        it("Should revert because validation is not over", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            expect(taskContract.unstakeAndClaim()).to.be.revertedWith("Validation is not over");
        });
        it("Should revert because losers stake not updated", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            expect(taskContract.unstakeAndClaim()).to.be.revertedWith("Losers stake not updated");
        });
        it("Should revert because pool prize must be greater than 0", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.connect(addr1).approve(taskAdd, 1000);
            await taskContract.connect(addr1).stakeForValidation(1000, true);
            await token.connect(addr2).approve(taskAdd, 1000);
            await taskContract.connect(addr2).stakeForValidation(1000, false);
            await token.connect(addr3).approve(taskAdd, 1000);
            await taskContract.connect(addr3).stakeForValidation(1000, true);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            await taskContract.calculateWinners();
            await taskContract.updateLosersStake();
            const prizePool = await taskContract.getPoolPrize()
            expect(taskContract.unstakeAndClaim()).to.be.revertedWith("Pool prize must be greater than 0");
            expect(prizePool).to.equal(50);
        });
        it("Should unstake and claim reward for winner", async function () {
            console.log(`TaskContract deployed to: ${taskAdd}`);
            console.log(`MockERC20 deployed to: ${tokenAdd}`);
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            const bal1Before = await token.balanceOf(addr1.address);
            const bal2Before = await token.balanceOf(addr2.address);
            const bal3before = await token.balanceOf(addr3.address);
            await token.connect(addr1).approve(taskAdd, 1000);
            await taskContract.connect(addr1).stakeForValidation(1000, true);
            await token.connect(addr2).approve(taskAdd, 1000);
            await taskContract.connect(addr2).stakeForValidation(1000, false);
            await token.connect(addr3).approve(taskAdd, 1000);
            await taskContract.connect(addr3).stakeForValidation(1000, true);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            await taskContract.calculateWinners();
            await taskContract.updateLosersStake();
            await token.connect(addr1).approve(taskAdd, 1000000);
            await taskContract.connect(addr1).unstakeAndClaim();
            const bal1After = await token.balanceOf(addr1.address);
            expect(bal1After).to.equal(100025);
        }
        );
        it("Should unstake and claim reward for loser", async function () {
            console.log(`TaskContract deployed to: ${taskAdd}`);
            console.log(`MockERC20 deployed to: ${tokenAdd}`);
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            const bal1Before = await token.balanceOf(addr1.address);
            const bal2Before = await token.balanceOf(addr2.address);
            const bal3before = await token.balanceOf(addr3.address);
            await token.connect(addr1).approve(taskAdd, 1000);
            await taskContract.connect(addr1).stakeForValidation(1000, false);
            await token.connect(addr2).approve(taskAdd, 1000);
            await taskContract.connect(addr2).stakeForValidation(1000, false);
            await token.connect(addr3).approve(taskAdd, 1000);
            await taskContract.connect(addr3).stakeForValidation(1000, true);
            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");
            await taskContract.calculateWinners();
            await taskContract.updateLosersStake();
            await token.connect(addr1).approve(taskAdd, 1000000);
            await taskContract.connect(addr1).unstakeAndClaim();
            const bal1After = await token.balanceOf(addr1.address);
            expect(bal1After).to.equal(100025);
        }
        );
    });
});
