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


    // function updateLosersStake() external {
    //     require(
    //         block.timestamp > validationPhase.endTime,
    //         "Voting has not ended yet"
    //     );
    //     require(
    //         validationPhase.winnerTotalStake > 0,
    //         "Winners must be determined"
    //     );

    //     uint256 loserFee = (validationPhase.loserTotalStake * 5) / 100; // Calculate 5% of the losing side's stake
    //     if (validationPhase.forWon) {
    //         for (
    //             uint256 i = 0;
    //             i < validationPhase.stakersAgainstKeys.length;
    //             ++i
    //         ) {
    //             address staker = validationPhase.stakersAgainstKeys[i];
    //             uint256 stake = validationAgainstStakes[staker];
    //             uint256 lostStake = stake - (stake * loserFee);
    //             validationAgainstStakes[staker] = stake - lostStake;
    //             validationPhase.poolPrize += lostStake;
    //         }
    //     } else {
    //         for (
    //             uint256 i = 0;
    //             i < validationPhase.stakersForKeys.length;
    //             ++i
    //         ) {
    //             address staker = validationPhase.stakersForKeys[i];
    //             uint256 stake = validationForStakes[staker];
    //             uint256 lostStake = stake - (stake * loserFee);
    //             validationForStakes[staker] = stake - lostStake;
    //             validationPhase.poolPrize += lostStake;
    //         }
    //         validationPhase.losersStakeUpdated = true;
    //     }
    // }
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
            const loserTotalStake = await taskContract.getLoserTotalStake();
            expect(loserTotalStake).to.equal(950);
        });
    })

});
