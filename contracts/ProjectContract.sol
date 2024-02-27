// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract EcosystemContract is Ownable, ReentrancyGuard, Initializable {

    bool public isInitialized;
    
    string public _name;
    address _ecosystemToken;
    uint _prioritizerShare;
    uint _contributorShare;
    uint _validatorShare;

   
    event AddAdmin(address adminAddress);
    event RemoveAdmin(address adminAddress);
    
    event AddTask(uint taskId);
    event RemoveTask(uint taskId);



    function initialize(
        string memory name,
        uint prioritizerShare,
        uint contributorShare,
        uint validatorShare
    ) public initializer {
        isInitialized = true;

        _name = name;
        _ecosystemToken = ecosystemToken;

        _prioritizerShare = prioritizersShare;
        _contributorShare = contributorShare;
        _validatorShare = validatorShare;
    }

     function addTask() external nonReentrant {
        uint256 tokenId = totalSupply() + 1;
        // console.logBytes(_proof[0]);

        _safeMint(msg.sender, tokenId);

        emit Mint(tokenId, msg.sender);

        mintedTillNow++;
    }

     function removeTask() external nonReentrant {
        uint256 tokenId = totalSupply() + 1;
        // console.logBytes(_proof[0]);

        _safeMint(msg.sender, tokenId);

        emit Mint(tokenId, msg.sender);

        mintedTillNow++;
    }

    function mintNFT() external nonReentrant {
        uint256 tokenId = totalSupply() + 1;
        // console.logBytes(_proof[0]);

        _safeMint(msg.sender, tokenId);

        emit Mint(tokenId, msg.sender);

        mintedTillNow++;
    }



    function tokenExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return mintedTillNow;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(_tokenId);

        //Gives the token metadata according to NFT campaigns
        return
            bytes(_baseImage).length > 0
                ? string(abi.encodePacked(_baseImage))
                : "";
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
}
