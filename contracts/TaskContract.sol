// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//This contract is created by a community. This is the tasks that communites generate. Not all functionality is built. Will add natspec comments later.

// Functionality still needed to be implemented:
// - Time locking for voting periods.
// - Validation staking
// - Adding what the quorum 
// - 
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
    // move to project contract
    mapping(uint256 => Task) public tasks;
    uint256 public nextTaskId;

    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 cost);
    event TaskPrioritized(uint256 indexed taskId, address indexed staker, uint256 amount, uint256 newPrioritize);
    event TaskDeprioritized(uint256 indexed taskId, address indexed staker, uint256 amount, uint256 newDeprioritize);
    event TaskBid(uint256 indexed taskId, address indexed bidder, uint256 bidAmount, uint256 highestBid);
    event TaskClaimed(uint256 indexed taskId, address indexed claimer);
    event TaskCompleted(uint256 indexed taskId, address indexed validator, address completer, bool status);
    // need to add the other stuff 
    constructor(address _tokenAddress, time, quorm, IERC20 ) {
        token = IERC20(_tokenAddress);
    }
    // This probably should be tracked in the Project contract
    function createTask(uint256 cost) external {
        tasks[++nextTaskId] = Task(msg.sender, cost, 0, 0, 0, address(0), false, false);
        emit TaskCreated(nextTaskId, msg.sender, cost);
    }
    // need to track balances of the stakers in a mapping 
    function stakeForPriority(uint256 taskId, uint256 amount, bool prioritize) external {
        require(tasks[taskId].creator != address(0), "Task does not exist");
        token.transferFrom(msg.sender, address(this), amount);

        if (prioritize) {
            tasks[taskId].prioritize += amount;
            emit TaskPrioritized(taskId, msg.sender, amount, tasks[taskId].prioritize);
        } else {
            tasks[taskId].deprioritize += amount;
            emit TaskDeprioritized(taskId, msg.sender, amount, tasks[taskId].deprioritize);
        }
    }

    // function bidForTask(uint256 taskId, uint256 amount) external {
    //     Task storage task = tasks[taskId];
    //     require(task.creator != address(0), "Task does not exist");
    //     require(!task.isClaimed, "Task already claimed");
    //     require(amount > task.highestBid, "Bid too low"); // might change this
    //     // this needs some more thought about how to handle the bidding
    //     if (task.highestBidder != address(0)) {
    //         token.transfer(task.highestBidder, task.highestBid);
    //     }
    //     task.highestBid = amount;
    //     task.highestBidder = msg.sender;
    //     token.transferFrom(msg.sender, address(this), amount);
    //     emit TaskBid(taskId, msg.sender, amount, task.highestBid);
    // }
    
    // function claimTask(uint256 taskId) external {
    //     Task storage task = tasks[taskId];
    //     require(msg.sender == task.highestBidder, "Not highest bidder");
    //     require(!task.isClaimed, "Task already claimed");

    //     task.isClaimed = true;

    //     emit TaskClaimed(taskId, msg.sender);
    // }

    // this is a simple way to validate tasks, maybe consider using EIP-712 to sign
    function validateTask(uint256 taskId, bool completed) external {
        Task storage task = tasks[taskId];
        require(task.creator != address(0), "Task does not exist");
        require(task.isClaimed, "Task not claimed");

        if (completed) {
            task.isCompleted = true;
            // Transfer task cost and bid amount to the task completer
            token.transfer(task.highestBidder, task.cost + task.highestBid);
            emit TaskCompleted(taskId, msg.sender, task.highestBidder, true);
        } else {
            // Don't know what to do if the contributor finished the tasks but it doesn't meet the requirements or gets validated.
        }
    }
    function settle
}

///////// TASK WORKFLOW /////////

// Phase 1: Task Creation
//      Initialization: The contract must allow for task creation by specifying the task details, cost in ERC-20 tokens, and the task creator. This phase includes storing the task information and the associated cost.
//      Hash it on chain 
// Phase 2: Prioritization
//      Stake for Prioritization: Enable stakeholders to stake ERC-20 tokens to prioritize or deprioritize tasks. This will require updating the task's priority based on the net staking (prioritization stakes minus deprioritization stakes).
// Phase 3: Contribution
// 
// Phase 4: Validation
//      Task Validation: Implement a mechanism for stakeholders to validate the completion of tasks. Successful completion transfers the staked amount to the task completer, including the initial proposal cost.

// Functionality that still needed to be implemented:
// - Time locking for voting periods.

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
