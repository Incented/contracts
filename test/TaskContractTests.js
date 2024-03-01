const { expect } = require("chai");
const { ethers } = require("hardhat");
require('dotenv').config()

describe("TaskContract", function () {
    let taskContract;
    let owner, addr1, addr2, token;

    beforeEach(async function () {
        // Deploy the contract and a mock ERC20 token for testing
        const TaskContract = await ethers.getContractFactory("TaskContract");
        const MockERC20 = await ethers.getContractFactory("MockERC20");

        [owner, addr1, addr2] = await ethers.getSigners();
        token = await MockERC20.deploy("MockToken", "MTK", 1000);
        taskContract = await TaskContract.deploy();

    });

    describe("initialize", function () {
        it("Should correctly initialize the contract", async function () {
            await taskContract.initialize(owner.address, 10000, addr1.address, token.address, 3600);

            expect(await taskContract.initialized()).to.equal(true);
        });
    });

});