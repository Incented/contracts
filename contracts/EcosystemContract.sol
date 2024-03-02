// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TaskContract.sol";
import "./ProjectContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EcosystemContact {
    event ProjectCreated(
        address indexed project,
        uint256 reward,
        address creator,
        address tokenAddress,
        uint256 endTime
    );

    using SafeERC20 for IERC20;
    uint256 totalGrant;
    uint256 rewardPool;

    mapping(uint256 => address) projects;
    uint256 public projectCount;

    string name;
    IERC20 _ecosystemToken = IERC20(0x466710434DBc9278887A64FD5759210167Cd26CE);

    constructor(string memory _name, uint256 _totalGrant, uint256 _rewardPool) {
        name = _name;
        totalGrant = _totalGrant;
        rewardPool = _rewardPool;
    }

    function createProject(
        uint256 _requestAmount,
        address _ecoSystemToken,
        address _ecosystemAddress,
        uint256 _endTime
    ) external {
        ProjectContract project = new ProjectContract(
            _requestAmount,
            _ecosystemAddress,
            _ecoSystemToken,
            _endTime
        );
        emit ProjectCreated(
            address(project),
            _requestAmount,
            msg.sender,
            _ecoSystemToken,
            _endTime
        );
        projects[projectCount] = address(project);
        projectCount++;
    }

    function recieveGrantMoney(uint256 _amount) external {
        require(
            _ecosystemToken.balanceOf(msg.sender) >= _amount,
            "Insufficient balance"
        );
        _ecosystemToken.safeTransferFrom(msg.sender, address(this), _amount);
        totalGrant += _amount;
    }
}
