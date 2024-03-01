// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TaskContract.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Considering using this implementation of the project contract as it is easier to understand and maintain given the
/// OpenZeppelin library Clones.sol handles all the implementation details of the minimal proxy pattern ERC1167

contract ProjectContract {
    using SafeERC20 for IERC20;
    mapping(uint256 => address) tasks;
    uint256 public taskCount;
    address public implementationContract;
    address ecosystem;

    struct Project {
        string ecosystem;
        address ecosystemToken;
    }

    function initialize(
        address _ecosystem,
        address _taskContract,
        address _ecosystemToken
    ) external {
        require(implementationContract == address(0), "Already initialized");
        implementationContract = _taskContract;
        ecosystem = _ecosystem;
    }

    function createTask(
        address _project,
        uint256 _reward,
        address _creator,
        address _tokenAddress,
        uint256 _endTime
    ) external {
        address clone = Clones.clone(implementationContract);
        TaskContract(clone).initialize(
            _project,
            _reward,
            _creator,
            _tokenAddress,
            _endTime
        );
    }
}
