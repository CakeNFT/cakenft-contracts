// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ICakeNFT.sol";

interface IUserMintNFT is ICakeNFT {
    function storeAddress() external view returns (address);
    function mintPrice() view external returns (uint256);
    function maxMintCount() view external returns (uint256);
    function mint(address to) external returns (uint256 id);
}
