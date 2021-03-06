// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ICakeNFT.sol";

interface ICakeSimpleNFTV1 is ICakeNFT {
    function mint() external returns (uint256 id);
}
