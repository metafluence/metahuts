// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IMetahut.sol";


contract Metahut is Initializable, OwnableUpgradeable {
    IERC20Upgradeable meto;
    IERC20Upgradeable busd;
    IMetahut shoppingRoom;
    IMetahut nftRoom;
    IMetahut eventRoom;

    struct hut {
        uint256 shopping_room;
        uint256 nft_room;
        uint256 event_room;
    }

    mapping(address => hut[]) public metahuts;
    
    enum ASSET {METO, BUSD}

    struct OptionLaunchpadLand{
        uint ClaimableCount;
        uint ClaimedCount;
    }

    uint256[] public disabledLands;
    mapping(address => bool) public whiteListAddresses;
    mapping(address => OptionLaunchpadLand) public launchpadLands;
    // use as the index if item not found in array
    uint256 private ID_NOT_FOUND;
    //block transaction or  set new land price if argument = ID_SKIP_PRICE_VALUE
    uint256 private ID_SKIP_PRICE_VALUE;
    uint256 public METAHUT_PUBLIC_PRICE_METO;
    uint256 public METAHUT_PUBLIC_PRICE_BUSD;
    uint256 public METAHUT_WHITELIST_PRICE_METO;
    uint256 public METAHUT_WHITELIST_PRICE_BUSD;
    uint256 public BUSD_METO_PAIR; //1 busd value by meto
    uint METAHUT_MAX_COUNT_PER_TRANSACTION;
    bool public launchpadSaleStatus;
    bool public whiteListSaleStatus;
    bool public privateSaleStatus;
    bool public publicSaleStatus;
    address public PRICE_UPDATER;

    function initialize() public initializer {
        __Ownable_init();
        meto = IERC20Upgradeable(0xa78775bba7a542F291e5ef7f13C6204E704A90Ba);
        busd = IERC20Upgradeable(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        // meto = IERC20Upgradeable(0xc39A5f634CC86a84147f29a68253FE3a34CDEc57);
        // busd = IERC20Upgradeable(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee);
        shoppingRoom = IMetahut(0x5d217023db033E606eA7294D33a89119c1e952d9);
        nftRoom = IMetahut(0x59f967894B9185C8a4b6f8FcE51584547F63cf71);
        eventRoom = IMetahut(0x7B5046D4Ac1Da36d8E134fb214fB4B918036AFB6);

        //set inital values
        ID_NOT_FOUND = 99999999999999999999;
        ID_SKIP_PRICE_VALUE = 99999999999999999999;
        METAHUT_PUBLIC_PRICE_METO = 3900;
        METAHUT_PUBLIC_PRICE_BUSD = 4150;
        METAHUT_WHITELIST_PRICE_METO = 3500;
        METAHUT_WHITELIST_PRICE_BUSD = 3700;
        BUSD_METO_PAIR = 369 * decimals();
    }

    event BoughtMetahut(address indexed _from, uint256 _price);
    event Claim(address indexed _from, uint256 _tid, uint256 claimableCount, uint256 claimedCount);

    modifier Claimable () {
        require(launchpadSaleStatus, "Launchad sale not opened yet.");
        _;
    }

    /* Start of Administrative Functions */
    function setMetahutPriceWithMeto(uint256 _price, uint256 _whiteListPrice) public onlyOwner {   
        if (_price != ID_SKIP_PRICE_VALUE) {
            METAHUT_PUBLIC_PRICE_METO = _price;
        }
        if ( _whiteListPrice != ID_SKIP_PRICE_VALUE) {
            METAHUT_WHITELIST_PRICE_METO = _whiteListPrice;
        }
    }

    function setMetahutPriceWithBusd(uint256 _price, uint256 _whiteListPrice) public onlyOwner {   
        if (_price != ID_SKIP_PRICE_VALUE) {
            METAHUT_PUBLIC_PRICE_BUSD = _price;
        }
        if ( _whiteListPrice != ID_SKIP_PRICE_VALUE) {
            METAHUT_WHITELIST_PRICE_BUSD = _whiteListPrice;
        }
    }
    
    function setBusdMetoPair(uint256 _price) public {
        require(msg.sender == PRICE_UPDATER || msg.sender == owner(), "price updater is not valid.");
        BUSD_METO_PAIR = _price;
    }

    function setPriceUpdater(address _v) public onlyOwner {
        PRICE_UPDATER = _v;
    }

    function withdrawMeto(address payable addr, uint256 _amount) external onlyOwner {
        SafeERC20Upgradeable.safeTransfer(meto, addr, _amount);
    }

    function withdrawBusd(address payable addr, uint256 _amount) external onlyOwner {
        SafeERC20Upgradeable.safeTransfer(busd, addr, _amount);
    }

    //todo allow multiple launchad address insertation
    function setLaunchpadAddresses(address[] memory  _addrs, OptionLaunchpadLand[] memory _options) public onlyOwner {
        require(_addrs.length == _options.length, "addresses and launchpad options count is not equal.");

        for (uint256 i = 0; i < _addrs.length; i++) {
            launchpadLands[_addrs[i]] = _options[i];
        }
    }

    function setWhitelistAddresses(address[] memory _addrs, bool[] memory _values) public onlyOwner {
        require(_addrs.length == _values.length,  "address counts dont match with values");
        for (uint i = 0; i < _addrs.length; i++) {
            whiteListAddresses[_addrs[i]] = _values[i]; 
        }
    }
    
    function setSaleStatus(bool _launchpadSaleStatus, bool _publicSaleStatus, bool _whiteListSaleStatus) public onlyOwner {
        launchpadSaleStatus = _launchpadSaleStatus;
        publicSaleStatus = _publicSaleStatus;
        whiteListSaleStatus = _whiteListSaleStatus;
    }

    function adminMint(address _addr, uint _cnt) public onlyOwner {
        for (uint i = 0; i < _cnt; i++) {
            _mint(_addr);
        }
    }

    /* End of Administrative Functions */

    // return user nft collection 
    function myCollection() public view returns(hut[] memory) {
        return metahuts[msg.sender];
    }

    function _mint(address _owner) internal {
        uint256 r1 = shoppingRoom.mintNFT(_owner);
        uint256 r2 = nftRoom.mintNFT(_owner);
        uint256 r3 = eventRoom.mintNFT(_owner);

        uint256[] memory minted = new uint256[](3);
        minted[0] = r1;
        minted[1] = r2;
        minted[2] = r3;
        
        hut memory metahut = hut(r1, r2, r3);
        metahuts[_owner].push(metahut);
    }


    function mintWithMeto(uint _count) public {
        require(whiteListSaleStatus || publicSaleStatus,  "sale not started.");
        
        uint256 totalPrice = calculateTotalPrice(ASSET.METO) * _count;
        require(meto.balanceOf(msg.sender) > totalPrice,  "User has not enough balance.");

        SafeERC20Upgradeable.safeTransferFrom(meto, msg.sender, address(this), totalPrice);

        for (uint i = 0; i < _count; i++) {
            _mint(msg.sender);
        }

        emit BoughtMetahut(msg.sender, totalPrice);
    }

    function mintWithBusd(uint _count) public {
        require(whiteListSaleStatus || publicSaleStatus,  "sale not started.");
        uint256 totalPrice = calculateTotalPrice(ASSET.BUSD) * _count;
        require(busd.balanceOf(msg.sender) > totalPrice,  "User has not enough balance.");

        SafeERC20Upgradeable.safeTransferFrom(busd, msg.sender, address(this), totalPrice);
    
        for (uint i = 0; i < _count; i++) {
            _mint(msg.sender);
        }

        emit BoughtMetahut(msg.sender, totalPrice);
    }

    // claim mint single nft without payment and available from launchpad
    function claim(uint256 _id)
        public Claimable
        returns(uint256[] memory) {
        require(launchpadSaleStatus && launchpadLands[msg.sender].ClaimedCount < launchpadLands[msg.sender].ClaimableCount, "reach calimable limit.");
        uint256 r1 = shoppingRoom.mintNFT(msg.sender);
        uint256 r2 = nftRoom.mintNFT(msg.sender);
        uint256 r3 = eventRoom.mintNFT(msg.sender);

        uint256[] memory minted;
        minted[0] = r1;
        minted[1] = r2;
        minted[2] = r3;
        emit Claim(msg.sender, _id, launchpadLands[msg.sender].ClaimableCount, launchpadLands[msg.sender].ClaimedCount);
        return minted;
    }

    
    function decimals() internal pure returns(uint256) {
        return 10 ** 18;
    }

    function calculateTotalPrice(ASSET _asset) internal view returns(uint256) {
        uint256 _price = 0;

        if (whiteListAddresses[msg.sender] && whiteListSaleStatus) {
            if (_asset == ASSET.METO) {
                _price = METAHUT_WHITELIST_PRICE_METO * BUSD_METO_PAIR;
            } else if (_asset == ASSET.BUSD) {
                _price = METAHUT_WHITELIST_PRICE_BUSD * decimals();
            }
        } else {
            require(publicSaleStatus, "public sale not opened.");
            if (_asset == ASSET.METO) {
                _price = METAHUT_PUBLIC_PRICE_METO * BUSD_METO_PAIR ;
            } else if (_asset == ASSET.BUSD) {
                _price = METAHUT_PUBLIC_PRICE_BUSD * decimals();
            }
        }

        return _price;
    }
}