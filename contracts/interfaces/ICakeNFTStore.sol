// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ICakeNFT.sol";

interface ICakeNFTStore {
    
    function add(
        string memory name,
        string memory symbol,
        string memory version,
        string memory baseURI
    ) external;
}
