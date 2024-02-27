// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//need to create a community
contract TaskContract {
    struct Task {
        address creator;
        uint256 cost;
        uint256 prioritize;
        uint256 deprioritize;
        uint256 highestBid;
        address highestBidder;
        bool isClaimed;
        bool isCompleted;
    }

    IERC20 public token;
    mapping(uint256 => Task) public tasks;
    uint256 public nextTaskId;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function createTask(uint256 cost) external {
        tasks[nextTaskId++] = Task(msg.sender, cost, 0, 0, 0, address(0), false, false);
    }

    function stakeForPriority(uint256 taskId, uint256 amount, bool prioritize) external {
        require(tasks[taskId].creator != address(0), "Task does not exist");
        token.transferFrom(msg.sender, address(this), amount);

        if (prioritize) {
            tasks[taskId].prioritize += amount;
        } else {
            tasks[taskId].deprioritize += amount;
        }
    }

    function bidForTask(uint256 taskId, uint256 amount) external {
        Task storage task = tasks[taskId];
        require(task.creator != address(0), "Task does not exist");
        require(!task.isClaimed, "Task already claimed");
        require(amount > task.highestBid, "Bid too low");

        if (task.highestBidder != address(0)) {
            // Refund the previous highest bidder
            token.transfer(task.highestBidder, task.highestBid);
        }
        task.highestBid = amount;
        task.highestBidder = msg.sender;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function validateTask(uint256 taskId, bool completed) external {
        // Simplified validation process; consider a more complex mechanism maybe using
        Task storage task = tasks[taskId];
        require(task.creator != address(0), "Task does not exist");
        require(task.isClaimed, "Task not claimed");

        if (completed) {
            task.isCompleted = true;
            // Transfer task cost and bid amount to the task completer
            token.transfer(task.highestBidder, task.cost + task.highestBid);
        } else {
            // Don't know what to do if the contributor finished the tasks but it doesn't meet the requirements or gets validated.
        }
    }

    function claimTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        require(msg.sender == task.highestBidder, "Not highest bidder");
        require(!task.isClaimed, "Task already claimed");

        task.isClaimed = true;
    }
}

// Phase 1: Task Creation
//      Initialization: The contract must allow for task creation by specifying the task details, cost in ERC-20 tokens, and the task creator. This phase includes storing the task information and the associated cost.
// Phase 2: Prioritization
//      Stake for Prioritization: Enable stakeholders to stake ERC-20 tokens to prioritize or deprioritize tasks. This will require updating the task's priority based on the net staking (prioritization stakes minus deprioritization stakes).
// Phase 3: Claiming
//       Bidding for Task: Allow individuals to bid on tasks by staking ERC-20 tokens. The contract should track the highest bid and the bidder.
// Phase 4: Validation
//      Task Validation: Implement a mechanism for stakeholders to validate the completion of tasks. Successful completion transfers the staked amount to the task completer, including the initial proposal cost.

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
