const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TaskContract", function () {
    let owner, addr1, addr2, token, taskContract;

    beforeEach(async function () {
        // Deploy the contract and a mock ERC20 token for testing
        const TaskContract = await ethers.getContractFactory("TaskContract");
        taskContract = await TaskContract.deploy();
        await taskContract.waitForDeployment();

        const MockERC20 = await ethers.getContractFactory("MockERC20");
        token = await MockERC20.deploy("MockToken", "MTK");
        await token.waitForDeployment();

        [owner, addr1, addr2] = await ethers.getSigners();
        taskAdd = await taskContract.getAddress();
        tokenAdd = await token.getAddress();

    });

    describe("initialize", function () {
        it("Should correctly initialize the contract", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);

            expect(await taskContract.initialized()).to.equal(true);
        });
    });

    // function stakeForValidation(uint256 amount, bool validate) external {
    //     require(
    //         block.timestamp >= validationPhase.endTime,
    //         "voting period inactive"
    //     );
    //     require(
    //         block.timestamp <= validationPhase.endTime,
    //         "Voting period inactive"
    //     );
    //     require(amount > 0, "Amount must be greater than 0");
    //     require(
    //         task.token.transferFrom(msg.sender, address(this), amount),
    //         "Transfer failed"
    //     );

    //     if (validate) {
    //         validationForStakes[msg.sender] += amount;
    //         validationPhase.totalForStakes += amount;
    //         validationPhase.stakersForKeys.push(msg.sender);

    //         emit TaskValidation(msg.sender, true, amount);
    //     } else {
    //         validationAgainstStakes[msg.sender] += amount;
    //         validationPhase.totalAgainstStakes += amount;
    //         validationPhase.stakersAgainstKeys.push(msg.sender);

    //         emit TaskValidation(msg.sender, false, amount);
    //     }
    // }
    describe("stakeForValidation", function () {
        it("Should revert because voting period is not open", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            await token.approve(taskAdd, 1000);
            expect(taskContract.stakeForValidation(1000, true)).to.be.revertedWith("Voting period inactive");
        });
        it("Should revert because amount is 0", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, tokenAdd, 3600);
            console.log(taskContract.task.taskStatus)
            await taskContract.task.taskStatus = TaskStatus.ValidationInProgress
            await token.approve(taskAdd, 0);
            expect(taskContract.stakeForValidation(0, true)).to.be.revertedWith("Amount must be greater than 0");
        });
    });

});