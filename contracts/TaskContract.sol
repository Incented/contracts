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
// -

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
        ValidationEnded,
        Settled
    }
   
    struct ValidationPhase {
        uint256 startTime;
        uint256 endTime;
        mapping(address staker => uint256 ammount) forStakes;
        mapping(address staker => uint256 ammount) againstStakes;
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

    modifier isInitialized() {
        require(!initialized, "Contract is already initialized");
        _;
    }

    // this function needs to get protected so that it can only be called once.. will do soon.
    function initialize(address _project, uint256 _reward, address _creator, address _tokenAddress)
        external
        isInitialized
    {
        Task storage task = Task(_project, _creator, _reward, 0, 0, TaskStatus.Created, IERC20(_tokenAddress));
    }

    function submitContribution() external {}


    // Staking for validation
    function stakeForValidation(uint256 taskId, uint256 amount, bool validate) external {
       require(block.timestamp >= ValidationPhase.startTime && block.timestamp <= ValidationPhase.endTime, "Voting period inactive");
       require(amount > 0, "Amount must be greater than 0");
       require(Task.token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        if(validate){
            ValidationPhase.forStakes[msg.sender] += amount;
            ValidationPhase.totalForStakes += amount;
            ValidationPhase.stakersForKeys.push(msg.sender);
        } else {
            ValidationPhase.againstStakes[msg.sender] += amount;
            ValidationPhase.totalAgainstStakes += amount;
            ValidationPhase.stakersAgainstKeys.push(msg.sender);
        }
    }
   
    function calculateWinners() public {
        require(block.timestamp > ValidationPhase.endTime, "Validation period still active");
    
        if (ValidationPhase.totalFor > ValidationPhase.totalAgainst) {
            ValidationPhase.winnerTotalStake = ValidationPhase.totalFor;
            ValidationPhase.loserTotalStake = ValidationPhase.totalAgainst;
            ValidationPhase.forWon = true;
        } else {
            ValidationPhase.winnerTotalStake = ValidationPhase.totalAgainst;
            ValidationPhase.loserTotalStake = ValidationPhase.totalFor;
            ValidationPhase.forWon = false;
        }
    }

    

    function updateLosersStake() external {
        require(ValidationPhase.votingEnded, "Voting has not ended yet");
        require(ValidationPhase.winnerTotalStake > 0, "Winners must be determined");

        uint256 loserFee = ValidationPhase.loserTotalStake * 5 / 100; // Calculate 5% of the losing side's stake
        if(ValidationPhase.forWon){
            for(uint256 i = 0; i < ValidationPhase.stakersAgainstKeys.length; i++){
                address staker = ValidationPhase.stakersAgainstKeys[i];
                uint256 stake = ValidationPhase.againstStakes[staker];
                uint256 lostStake = stake - (stake * loserFee);
                ValidationPhase.againstStakes[staker] = stake - lostStake;
                ValidationPhase.poolPrize += lostStake;
            }
        }
        else{
            for(uint256 i = 0; i < ValidationPhase.stakersForKeys.length; i++){
                address staker = ValidationPhase.stakersForKeys[i];
                uint256 stake = ValidationPhase.forStakes[staker];
                uint256 lostStake = stake - (stake * loserFee);
                ValidationPhase.forStakes[staker] = stake - lostStake;
                ValidationPhase.poolPrize += lostStake;    
        }
        ValidationPhase.losersStakeUpdated = true;
    }

    function unstakeAndClaim() external {
        require(TaskStats.ValidationEnded, "Validation is not over");
        require(ValidationPhase.losersStakeUpdated, "Losers stake not updated");
        require(ValidationPhase.poolPrize > 0, "Pool prize must be greater than 0");

        if(ValidationPhase.forWon){
            require(ValidationPhase.forStakes[msg.sender] > 0);
            uint256 reward;
            reward = ValidationPhase.forStakes[msg.sender]; 
        }

    }

    // this needs logic to settle the funds. There are two outcomes. the contribuitor gets the funds or the task is not completed
    // and the funds get sent back to the project.
    function settle() external {
        
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
