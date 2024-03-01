const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TaskContract", function () {
    let owner, addr1, addr2, token, taskContract;

    beforeEach(async function () {
        // Deploy the contract and a mock ERC20 token for testing
        const TaskContract = await ethers.getContractFactory("TaskContract");
        taskContract = await TaskContract.deploy();

        const MockERC20 = await ethers.getContractFactory("MockERC20");
        token = await MockERC20.deploy("MockToken", "MTK");

        [owner, addr1, addr2] = await ethers.getSigners();

        console.log(taskContract.address);
        console.log(token.address);
        console.log(owner.address);
        console.log(addr1.address);
        console.log(addr2.address);

    });

    describe("initialize", function () {
        it("Should correctly initialize the contract", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, token.address, 3600);

            expect(await taskContract.initialized()).to.equal(true);
        });
    });

});