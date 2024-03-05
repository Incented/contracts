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

    //Mapp through all the projcts and see which ones had the highest staking for them. The projects with the most staking will win until the grant pool is over, then the rest of the projects will be not selected. The
    // ones that get selected will be given the grant money and the rest will be given back their staking money.

    // This function is still in the works. Need to figure out some more on the prioritization stage.

    function calculcateWinngingProjects() external {
        uint256 totalStaking;
        for (uint256 i = 0; i < projectCount; i++) {
            ProjectContract project = ProjectContract(projects[i]);
            totalStaking += project.getTotalForStakes();
        }
        for (uint256 i = 0; i < projectCount; i++) {
            ProjectContract project = ProjectContract(projects[i]);
            if (project.getTotalForStakes() > totalStaking / 2) {
                project.selected();
                rewardPool -= project.getRequestedAmount();
                _ecosystemToken.safeTransfer(
                    address(project),
                    project.getRequestedAmount()
                );
            } else {
                address[] memory stakersForKeys = project.getStakersForKeys();
                for (uint256 j = 0; j < stakersForKeys.length; j++) {
                    _ecosystemToken.safeTransfer(
                        stakersForKeys[j],
                        project.prioritzationForStakes[
                            project.stakersForKeys[j]
                        ]
                    );
                }
            }
        }
    }
}
