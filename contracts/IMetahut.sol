// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetahut {
    function mintNFT(address recipient) external returns(uint256);
}