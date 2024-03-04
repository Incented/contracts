// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Add the openzeppelin intializable contract here too

contract TaskContract {
    using SafeERC20 for IERC20;
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
        bool forWon;
        uint256 winnerTotalStake;
        uint256 loserTotalStake;
        uint256 poolPrize;
        bool losersStakeUpdated;
        address contributor;
        bool validationIsOver;
    }
    ValidationPhase validationPhase;

    /////////// EVENTS /////////////
    event TaskCreated(address project, address creator, uint256 reward);
    event TaskValidation(address contributor, bool validated, uint256 amount);
    event TaskContribution(address contributor);
    event TaskSettled(address contributor, uint256 amount);
    event TaskUnstake(address staker, uint256 amount);

    constructor(
        address _project,
        uint256 _reward,
        address _creator,
        address _tokenAddress,
        uint256 _endTime
    ) {
        task = Task(
            _project,
            _creator,
            _reward,
            TaskStatus.ValidationInProgress,
            IERC20(_tokenAddress)
        );
        validationPhase.endTime = _endTime;
        validationPhase.validationIsOver = false;
    }

    function submitContribution() external {
        validationPhase.contributor = msg.sender;
        emit TaskContribution(msg.sender);
    }

    // Staking for validation
    // This should probably check for if a person wants to stake more than 1 in a task.
    function stakeForValidation(uint256 amount, bool validate) external {
        require(
            block.timestamp >= validationPhase.endTime,
            "voting period inactive"
        );
        require(amount > 0, "Amount must be greater than 0");
        require(task.token.approve(address(this), amount), "Approval failed");

        if (validate) {
            validationForStakes[msg.sender] += amount;
            validationPhase.totalForStakes += amount;
            validationPhase.stakersForKeys.push(msg.sender);

            emit TaskValidation(msg.sender, true, amount);
        } else {
            validationAgainstStakes[msg.sender] += amount;
            validationPhase.totalAgainstStakes += amount;
            validationPhase.stakersAgainstKeys.push(msg.sender);

            emit TaskValidation(msg.sender, false, amount);
        }

        task.token.safeTransferFrom(msg.sender, address(this), amount);
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
        validationPhase.validationIsOver = true;
    }

    function updateLosersStake() external {
        require(
            block.timestamp > validationPhase.endTime,
            "Voting has not ended yet"
        );
        require(
            validationPhase.winnerTotalStake > 0,
            "Winners must be determined"
        );
        if (validationPhase.forWon) {
            for (
                uint256 i = 0;
                i < validationPhase.stakersAgainstKeys.length;
                ++i
            ) {
                address staker = validationPhase.stakersAgainstKeys[i];
                uint256 stake = validationAgainstStakes[staker];
                uint256 lostStake = (stake * 5) / 100;
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
                uint256 lostStake = (stake * 5) / 100;
                validationForStakes[staker] = stake - lostStake;
                validationPhase.poolPrize += lostStake;
            }
        }
        validationPhase.losersStakeUpdated = true;
    }

    // In this function we will also caluclate the pool prize and how it is split amongst the winners.
    function unstakeAndClaim() external {
        require(validationPhase.losersStakeUpdated, "Losers stake not updated");
        require(
            validationPhase.poolPrize > 0,
            "Pool prize must be greater than 0"
        );

        uint256 reward = 0;

        if (validationPhase.forWon) {
            if (validationForStakes[msg.sender] > 0) {
                reward =
                    (validationForStakes[msg.sender] *
                        validationPhase.poolPrize) /
                    validationPhase.winnerTotalStake;

                reward += validationForStakes[msg.sender];
                validationForStakes[msg.sender] = 0;
            } else {
                reward = validationAgainstStakes[msg.sender];
                validationAgainstStakes[msg.sender] = 0;
            }
        } else {
            if (validationAgainstStakes[msg.sender] > 0) {
                reward =
                    (validationAgainstStakes[msg.sender] *
                        validationPhase.poolPrize) /
                    validationPhase.winnerTotalStake;

                reward += validationAgainstStakes[msg.sender];
                validationAgainstStakes[msg.sender] = 0;
            } else {
                reward = validationForStakes[msg.sender];
                validationForStakes[msg.sender] = 0;
            }
        }

        task.token.safeTransfer(msg.sender, reward);
        emit TaskUnstake(msg.sender, reward);
    }

    // this needs logic to settle the funds. There are two outcomes. the contribuitor gets the funds or the task is not completed
    // and the funds get sent back to the project.
    function settle() external {
        require(
            validationPhase.validationIsOver == true,
            "Validation is not over"
        );
        if (validationPhase.forWon) {
            task.token.safeTransfer(validationPhase.contributor, task.reward);
        } else {
            task.token.safeTransfer(task.project, task.reward);
        }
        task.status = TaskStatus.Settled;
        emit TaskSettled(validationPhase.contributor, task.reward);
    }

    function getStakeFor(address staker) public view returns (uint256) {
        return validationForStakes[staker];
    }

    function getStakeAgainst(address staker) public view returns (uint256) {
        return validationAgainstStakes[staker];
    }

    function getTotalForStakes() public view returns (uint256) {
        return validationPhase.totalForStakes;
    }

    function getTotalAgainstStakes() public view returns (uint256) {
        return validationPhase.totalAgainstStakes;
    }

    function getWinnerTotalStake() public view returns (uint256) {
        return validationPhase.winnerTotalStake;
    }

    function getLoserTotalStake() public view returns (uint256) {
        return validationPhase.loserTotalStake;
    }

    function getForWon() public view returns (bool) {
        return validationPhase.forWon;
    }

    function getPoolPrize() public view returns (uint256) {
        return validationPhase.poolPrize;
    }

    function getProject() public view returns (address) {
        return task.project;
    }

    function getReward() public view returns (uint256) {
        return task.reward;
    }

    function getCreator() public view returns (address) {
        return task.creator;
    }

    function getToken() public view returns (IERC20) {
        return task.token;
    }

    function getEndTime() public view returns (uint256) {
        return validationPhase.endTime;
    }

    function getContributor() public view returns (address) {
        return validationPhase.contributor;
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

// Helper fuction to distribute the rewards. This should be called
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
