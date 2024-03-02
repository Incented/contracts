// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TaskContract.sol";
import "./ProjectContract.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EcosystemContact2 {
    using SafeERC20 for IERC20;

    mapping(string => address) projects;
    uint256 public projectCount;
    address public projectImplementationContract;

    struct Ecosystem {
        string name;
        address ecosystemToken;
    }
    Ecosystem ecosystem;

    function createProject(
        address _projectID,
        address projectAddress,
        uint256 _totalGrant,
        address _ecosystemToken,
        address _tokenAddress,
        uint256 _endTime
    ) external {
        address clone = Clones.clone(projectImplementationContract);
        TaskContract(clone).initialize(
            address(this),
            clone,
            _totalGrant,
            _ecosystemToken,
            _tokenAddress,
            _endTime
        );
    }
}
