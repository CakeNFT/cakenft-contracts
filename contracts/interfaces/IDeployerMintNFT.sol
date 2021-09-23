// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ICakeNFT.sol";

interface IDeployerMintNFT is ICakeNFT {
    function mint() external returns (uint256 id);
    function massMint(uint256 count) external;
}
