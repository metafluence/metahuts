//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "./IMetahut.sol";

contract EventRoom is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable, IMetahut {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    string public baseTokenURI;
    mapping(address => bool) public admins;
    uint256 public MAX_ID;

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("EventRoom", "Er");
        setBaseURI("https://dcdn.metafluence.com/metahut/events/");
        MAX_ID = 3500;
    }

    function _baseURI() internal view  virtual override returns (string memory) {
         return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setAdmin(address _addr) public onlyOwner {
        admins[_addr] = true;
    }

    function removeAdmin(address _addr) public onlyOwner {
        delete admins[_addr];
    }

    function setMaxId(uint256 _v) public onlyOwner {
        MAX_ID = _v;
    }

    function mintNFT(address recipient) external override returns (uint256) {
        require(admins[msg.sender], "not admin");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(newItemId < MAX_ID, "reach max id");
        _mint(recipient, newItemId);

        return newItemId;
    }

  function myCollection(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }
}
