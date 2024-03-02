// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TaskContract.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ProjectContract {
    using SafeERC20 for IERC20;
    uint256 public projectID;
    bool public initialized;
    address ecosystem;
    IERC20 token;
    uint256 endTime;
    uint256 requestedAmount;
    mapping(address staker => uint256 ammount) prioritzationForStakes;
    mapping(address staker => uint256 ammount) priotizationAgainstStakes;
    uint256 totalForStakes;
    uint256 totalAgainstStakes;
    address[] stakersForKeys;
    address[] stakersAgainstKeys;
    bool isSelected;
    uint256 public taskCount;
    address public taskImplementationContract;
    mapping(uint256 => address) tasks;

    modifier isInitialized() {
        require(!initialized, "Contract is already initialized");
        _;
    }
    modifier onlyEcosystem() {
        require(
            msg.sender == ecosystem,
            "Only ecosystem can call this function"
        );
        _;
    }

    function initialize(
        uint256 _projectID,
        uint256 _requestAmount,
        address _ecoSystemToken,
        address _ecosystemAddress,
        uint256 _endTime,
        address _taskImplementationContract
    ) external isInitialized {
        projectID = _projectID;
        requestedAmount = _requestAmount;
        token = IERC20(_ecoSystemToken);
        ecosystem = _ecosystemAddress;
        endTime = _endTime;
        taskImplementationContract = _taskImplementationContract;

        initialized = true;
    }

    function createTask(
        address _project,
        uint256 _reward,
        address _creator,
        address _tokenAddress,
        uint256 _endTime
    ) external {
        address clone = Clones.clone(taskImplementationContract);
        TaskContract(clone).initialize(
            _project,
            _reward,
            _creator,
            _tokenAddress,
            _endTime
        );
        tasks[taskCount] = clone;
        taskCount++;
    }

    function stakeForPrioritization(uint256 amount, bool priotitize) external {
        require(block.timestamp >= endTime, "voting period inactive");
        require(amount > 0, "Amount must be greater than 0");
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        if (priotitize) {
            prioritzationForStakes[msg.sender] += amount;
            totalForStakes += amount;
            stakersForKeys.push(msg.sender);
        } else {
            priotizationAgainstStakes[msg.sender] += amount;
            totalAgainstStakes += amount;
            stakersAgainstKeys.push(msg.sender);
        }
    }

    function selected() external onlyEcosystem {
        require(block.timestamp >= endTime, "voting period inactive");
        require(!isSelected, "Project is already selected");
        isSelected = true;
    }

    function withdraw() external {
        require(block.timestamp >= endTime, "voting period inactive");
        require(!isSelected, "Project is not selected");
        require(
            prioritzationForStakes[msg.sender] > 0 ||
                priotizationAgainstStakes[msg.sender] > 0,
            "No stakes"
        );
        uint256 amount = prioritzationForStakes[msg.sender];
        prioritzationForStakes[msg.sender] = 0;
        totalForStakes -= amount;
        token.safeTransfer(msg.sender, amount);
    }

    function getStakedForAmmount(
        address staker
    ) external view returns (uint256) {
        return prioritzationForStakes[staker];
    }

    function getStakedAgainstAmmount(
        address staker
    ) external view returns (uint256) {
        return priotizationAgainstStakes[staker];
    }

    function getRequestedAmount() external view returns (uint256) {
        return requestedAmount;
    }

    function getIsSelected() external view returns (bool) {
        return isSelected;
    }

    function getEcosystem() external view returns (address) {
        return ecosystem;
    }

    function getEndTime() external view returns (uint256) {
        return endTime;
    }

    function getTotalForStakes() external view returns (uint256) {
        return totalForStakes;
    }

    function getToalAgainstStakes() external view returns (uint256) {
        return totalAgainstStakes;
    }

    function getTaskCount() external view returns (uint256) {
        return taskCount;
    }

    function getProjectID() external view returns (uint256) {
        return projectID;
    }

    function getTaskImplementationContract() external view returns (address) {
        return taskImplementationContract;
    }
}
