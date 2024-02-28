// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//This contract is created by a community. This is the tasks that communites generate. Not all functionality is built. Will add natspec comments later.

// Functionality still needed to be implemented:
// - Time locking for voting periods.
// - Validation staking
// - Adding what the quorum
// - settlement of funds at the end
// - slashing of staking for the negative outcome

contract TaskContract {
    bool public initialized;

    struct Task {
        address project;
        address creator;
        uint256 reward;
        mapping(address prioritizeStaker => mapping(bool prioritize => uint256 amount)) prioritizationStake;
        mapping(address validationStaker => mapping(bool validate => uint256 amount)) validationStake;
        TaskStatus status;
        IERC20 token;
    }

    enum TaskStatus {
        Created,
        PriotizationInProgress,
        ContributionInProgress,
        ValidationInProgress,
        Settled
    }

    struct PrioritizationPhase {
        uint256 startTime;
        uint256 endTime;
        mapping(address staker => uint256 ammount) forStakes;
        mapping(address staker => uint256 ammount) againstStakes;
        uint256 totalForStakes;
        uint256 totalAgainstStakes;
        bool votingEnded;
    }

    struct ValidationPhase {
        uint256 startTime;
        uint256 endTime;
        mapping(address staker => uint256 ammount) forStakes;
        mapping(address staker => uint256 ammount) againstStakes;
        uint256 totalForStakes;
        uint256 totalAgainstStakes;
        bool votingEnded;
    }

    modifier isInitialized() {
        require(!initialized, "Contract is already initialized");
        _;
    }

    // this function needs to get protected so that it can only be called once.. will do soon.
    function initialize(address _project, uint256 _reward, address _creator, address _tokenAddress)
        external
        isInitialized
    {
        Task task = Task(_project, _creator, _reward, 0, 0, TaskStatus.Created, IERC20(_tokenAddress));
    }

    function stakeForPriority(uint256 taskId, uint256 amount, bool prioritize) external {
       require(amount > 0, "Amount must be greater than 0");
       require()



        if (prioritize) {
            
    }

    function submitContribution() external {}

    /// @notice This function handles the staking of the validation of the task. Validators stake an amount towards
    ///         if the task was complete or not.
    /// @param taskId this is the idea of the task
    /// @param completed boolean value for if the task was completed.
    function stakeToValidateTask(uint256 taskId, bool completed) external {
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

    function settle() external {
        // this needs logic to settle the funds. There are two outcomes. the contribuitor gets the funds or the task is not completed
        // and the funds get sent back to the project.
    }
}
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
// Phase 5: Settlement
//      Settlement: The contract must allow for the settlement of funds based on the task's completion status. This phase includes transferring the funds to the task completer or returning the funds to the project if the task is not completed.

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
