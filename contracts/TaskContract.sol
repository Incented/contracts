// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Add the openzeppelin intializable contract here too

contract TaskContract {
    bool public initialized;
    mapping(address staker => uint256 ammount) validationForStakes;
    mapping(address staker => uint256 ammount) validationAgainstStakes;

    struct Task {
        address project;
        address creator;
        uint256 reward;
        TaskStatus status;
        IERC20 token;
    }
    Task task;

    enum TaskStatus {
        Created,
        PriotizationInProgress,
        ContributionInProgress,
        ValidationInProgress,
        ValidationEnded,
        Settled
    }

    struct ValidationPhase {
        uint256 startTime;
        uint256 endTime;
        address[] stakersForKeys;
        address[] stakersAgainstKeys;
        uint256 totalForStakes;
        uint256 totalAgainstStakes;
        bool votingEnded;
        bool forWon;
        uint256 winnerTotalStake;
        uint256 loserTotalStake;
        uint256 poolPrize;
        bool losersStakeUpdated;
        address contributor;
    }
    ValidationPhase validationPhase;

    modifier isInitialized() {
        require(!initialized, "Contract is already initialized");
        _;
    }

    // this function needs to get protected so that it can only be called once.. will do soon. -- Done
    function initialize(
        address _project,
        string memory _taskName,
        uint256 _reward,
        address _creator,
        address _tokenAddress,
        uint256 _endTime
    ) external isInitialized {
        task = Task(
            _project,
            _creator,
            _reward,
            TaskStatus.Created,
            IERC20(_tokenAddress)
        );
        validationPhase.endTime = _endTime;

        initialized = true;
    }

    function submitContribution() external {
        validationPhase.contributor = msg.sender;
    }

    // Staking for validation
    function stakeForValidation(uint256 amount, bool validate) external {
        require(
            block.timestamp >= validationPhase.endTime,
            "voting period inactive"
        );
        require(
            block.timestamp <= validationPhase.endTime,
            "Voting period inactive"
        );
        require(amount > 0, "Amount must be greater than 0");
        require(
            task.token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        if (validate) {
            validationForStakes[msg.sender] += amount;
            validationPhase.totalForStakes += amount;
            validationPhase.stakersForKeys.push(msg.sender);
        } else {
            validationAgainstStakes[msg.sender] += amount;
            validationPhase.totalAgainstStakes += amount;
            validationPhase.stakersAgainstKeys.push(msg.sender);
        }
    }

    function calculateWinners() public {
        require(
            block.timestamp > validationPhase.endTime,
            "Validation period still active"
        );

        if (
            validationPhase.totalForStakes > validationPhase.totalAgainstStakes
        ) {
            validationPhase.winnerTotalStake = validationPhase.totalForStakes;
            validationPhase.loserTotalStake = validationPhase
                .totalAgainstStakes;
            validationPhase.forWon = true;
        } else {
            validationPhase.winnerTotalStake = validationPhase
                .totalAgainstStakes;
            validationPhase.loserTotalStake = validationPhase.totalForStakes;
            validationPhase.forWon = false;
        }
    }

    function updateLosersStake() external {
        require(validationPhase.votingEnded, "Voting has not ended yet");
        require(
            validationPhase.winnerTotalStake > 0,
            "Winners must be determined"
        );

        uint256 loserFee = (validationPhase.loserTotalStake * 5) / 100; // Calculate 5% of the losing side's stake
        if (validationPhase.forWon) {
            for (
                uint256 i = 0;
                i < validationPhase.stakersAgainstKeys.length;
                ++i
            ) {
                address staker = validationPhase.stakersAgainstKeys[i];
                uint256 stake = validationAgainstStakes[staker];
                uint256 lostStake = stake - (stake * loserFee);
                validationAgainstStakes[staker] = stake - lostStake;
                validationPhase.poolPrize += lostStake;
            }
        } else {
            for (
                uint256 i = 0;
                i < validationPhase.stakersForKeys.length;
                ++i
            ) {
                address staker = validationPhase.stakersForKeys[i];
                uint256 stake = validationForStakes[staker];
                uint256 lostStake = stake - (stake * loserFee);
                validationForStakes[staker] = stake - lostStake;
                validationPhase.poolPrize += lostStake;
            }
            validationPhase.losersStakeUpdated = true;
        }
    }

    // In this function we will also caluclate the pool prize and how it is split amongst the winners.
    function unstakeAndClaim() external {
        require(
            task.status != TaskStatus.ValidationEnded,
            "Validation is not over"
        );
        require(validationPhase.losersStakeUpdated, "Losers stake not updated");
        require(
            validationPhase.poolPrize > 0,
            "Pool prize must be greater than 0"
        );

        if (validationPhase.forWon) {
            require(validationForStakes[msg.sender] > 0);
            uint256 reward;

            uint256 ratioOfPrizepool = validationForStakes[msg.sender] /
                validationPhase.winnerTotalStake;
            reward = ratioOfPrizepool * validationPhase.poolPrize;

            reward += validationForStakes[msg.sender];
            validationForStakes[msg.sender] = 0;

            require(
                task.token.transfer(msg.sender, reward),
                "Reward transfer failed"
            );
        } else {
            require(validationAgainstStakes[msg.sender] > 0);
            uint256 reward;

            uint256 ratioOfPrizepool = validationAgainstStakes[msg.sender] /
                validationPhase.winnerTotalStake;
            reward = ratioOfPrizepool * validationPhase.poolPrize;

            reward += validationAgainstStakes[msg.sender];
            validationAgainstStakes[msg.sender] = 0;

            require(
                task.token.transfer(msg.sender, reward),
                "Reward transfer failed"
            );
        }
    }

    // this needs logic to settle the funds. There are two outcomes. the contribuitor gets the funds or the task is not completed
    // and the funds get sent back to the project.
    function settle() external {
        require(
            task.status == TaskStatus.ValidationEnded,
            "Validation is not over"
        );
        if (validationPhase.forWon) {
            require(
                task.token.transfer(validationPhase.contributor, task.reward),
                "Reward transfer failed"
            );
        } else {
            require(
                task.token.transfer(task.project, task.reward),
                "Reward transfer failed"
            );
        }
    }
}

/////// TASK MVP WORKFLOW ////
// 1. Task gets inialized from the Project contract
// 2. Someone can contribute to the task
// 3. People Stake to validate the task
// 4. Caluclate rewards of the tasks the rewards of the task
// 5. Claim reward/stake

///////// TASK WORKFLOW /////////

// Phase 1: Task Creation
//      Initialization: The contract must allow for task creation by specifying the task details, cost in ERC-20 tokens, and the task creator. This phase includes storing the task information and the associated cost.
//      Hash it on chain
// Phase 2: Prioritization
//      Stake for Prioritization: Enable stakeholders to stake ERC-20 tokens to prioritize or deprioritize tasks. This will require updating the task's priority based on the net staking (prioritization stakes minus deprioritization stakes).
// Phase 3: Contribution
//          Individuals would contribute to the task and submit their contribution.
// Phase 4: Validation
//      Task Validation: Implement a mechanism for stakeholders to validate the completion of tasks. Successful completion transfers the staked amount to the task completer, including the initial proposal cost.
// Phase 5: Settlement
//      Settlement: The contract must allow for the settlement of funds based on the task's completion status. This phase includes transferring the funds to the task completer or returning the funds to the project if the task is not completed.

// Started working on this but thought should just get the validation done and then come back to this since they are the same logic.
// struct PrioritizationPhase {
//     uint256 startTime;
//     uint256 endTime;
//     mapping(address staker => uint256 ammount) forStakes;
//     mapping(address staker => uint256 ammount) againstStakes;
//     uint256 totalForStakes;
//     uint256 totalAgainstStakes;
//     bool votingEnded;
// }

//Helper fuction to distribute the rewards. This should be called
// Decided not to use those because we shouldnt be sending rewards but rather having users claim them.
// We can do that in the settlement
// function distributeRewards() public {
//     require(ValidationPhase.votingEnded, "Voting has not ended yet");
//     require(ValidationPhase.winnerTotalStake > 0, "Winners must be determined");

//     uint256 loserFee = ValidationPhase.loserTotalStake * 5 / 100; // Calculate 5% of the losing side's stake

//     if (ValidationPhase.forWon) {
//         for (uint256 i = 0; i < ValidationPhase.stakersForKeys.length; i++) {
//             address staker = ValidationPhase.stakersForKeys[i];
//             uint256 stake = ValidationPhase.forStakes[staker];
//             require(Task.token.transfer(staker, reward), "Reward transfer failed");
//         }
//     } else {
//         for (uint256 i = 0; i < ValidationPhase.stakersAgainstKeys.length; i++) {
//             uint256 reward = (stake * loserFee) / Valid.winnerTotalStake;
//             require(Task.token.transfer(staker, reward), "Reward transfer failed");
//         }
//     }
//     require(Task.token.transfer(Task.contributor, Task.reward), "Reward transfer failed");
// }

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
