// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TaskContract.sol";
import "./ProjectContract.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EcosystemContact2 {
    event ProjectCreated(
        address indexed project,
        uint256 reward,
        address creator,
        address tokenAddress,
        uint256 endTime
    );

    using SafeERC20 for IERC20;
    uint256 totalGrant;

    mapping(uint256 => address) projects;
    uint256 public projectCount;
    address public projectImplementationContract;
    address public taskImplementationContract;

    string name;
    IERC20 _ecosystemToken = IERC20(0x466710434DBc9278887A64FD5759210167Cd26CE);

    constructor(
        string memory _name,
        uint256 _totalGrant,
        address _projectImplementationContract,
        address _taskImplementationContract
    ) {
        name = _name;
        totalGrant = _totalGrant;
        projectImplementationContract = _projectImplementationContract;
        taskImplementationContract = _taskImplementationContract;
    }

    function createProject(
        uint256 _requestAmount,
        address _ecoSystemToken,
        address _ecosystemAddress,
        uint256 _endTime,
        address _taskImplementationContract
    ) external {
        address clone = Clones.clone(projectImplementationContract);
        ProjectContract(clone).initialize(
            projectCount,
            _requestAmount,
            _ecosystemAddress,
            address(this),
            _endTime,
            _taskImplementationContract
        );
        emit ProjectCreated(
            clone,
            _requestAmount,
            msg.sender,
            _ecoSystemToken,
            _endTime
        );
        projects[projectCount] = clone;
        projectCount++;
    }
}
