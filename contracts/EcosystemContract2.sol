// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./TaskContract.sol";
import "./ProjectContract2.sol";
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
}
