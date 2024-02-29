// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ProjectContract.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract EcosystemContract is Initializable {
    mapping(string => address) projects;

    mapping(address => uint256) adminList;

    bool public isInitialized;
    string public _name;
    address _ecosystemToken;


    modifier onlyAdmin() {
        require(adminList[msg.sender] == 1);
        _;
    }

    event AddAdmin(address adminAddress);
    event RemoveAdmin(address adminAddress);
    event AddProject(string projectName, address projectAddress);

    function initialize(
        string memory name,
        address ecosystemToken
    ) public initializer {
        isInitialized = true;

        _name = name;
        _ecosystemToken = ecosystemToken;
    }

    function addAdmin() public onlyAdmin {
      
    }

    function removeAdmin() public onlyAdmin {
       
    }

    function deployProjectClone(
        address implementationContract,
        string memory name,
        string memory projectSlug,
        uint prioritizerShare,
        uint contributorShare,
        uint validatorShare
    ) external returns (address) {
        require(
            projects[projectSlug] ==
                0x0000000000000000000000000000000000000000,
            "Project exists already with the same name, use different identifier"
        );

        // convert the address to 20 bytes

        bytes20 implementationContractInBytes = bytes20(
            implementationContract
        );

        //address to assign a cloned proxy
        address proxy;

        // as stated earlier, the minimal proxy has this bytecode
        // <3d602d80600a3d3981f3363d3d373d3d3d363d73><address of implementation contract><5af43d82803e903d91602b57fd5bf3>

        // <3d602d80600a3d3981f3> == creation code which copies runtime code into memory and deploys it

        // <363d3d373d3d3d363d73> <address of implementation contract> <5af43d82803e903d91602b57fd5bf3> == runtime code that makes a delegatecall to the implentation contract

        assembly {
            /*
            reads the 32 bytes of memory starting at the pointer stored in 0x40
            In solidity, the 0x40 slot in memory is special: it contains the "free memory pointer"
            which points to the end of the currently allocated memory.
            */
            let clone := mload(0x40)
            // store 32 bytes to memory starting at "clone"

            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            /*
              |              20 bytes                |
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
                                                      ^
                                                      pointer
            */
            // store 32 bytes to memory starting at "clone" + 20 bytes
            // 0x14 = 20
            mstore(add(clone, 0x14), implementationContractInBytes)

            /*
              |               20 bytes               |                 20 bytes              |
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe
                                                                                              ^
                                                                                              pointer
            */
            // store 32 bytes to memory starting at "clone" + 40 bytes
            // 0x28 = 40

            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            /*
            |                 20 bytes                  |          20 bytes          |           15 bytes          |
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73b<implementationContractInBytes>5af43d82803e903d91602b57fd5bf3 == 45 bytes in total
            */

            // create a new contract
            // send 0 Ether
            // code starts at the pointer stored in "clone"
            // code size == 0x37 (55 bytes)
            proxy := create(0, clone, 0x37)
        }

       
        // Call initialization
        ProjectContract(proxy).initialize(
            name,
            projectSlug,
            _ecosystemToken,
            prioritizerShare,
            contributorShare,
            validatorShare
        );

        projects[projectSlug] = proxy;

        emit AddProject(name, proxy);

        return proxy;
    }

    function getProjects(
        string memory _projectSlug
    ) public view returns (address) {
        require(
            projects[_projectSlug] !=
                0x0000000000000000000000000000000000000000,
            "No Project exists with this name"
        );

        return projects[_projectSlug];
    }
}
