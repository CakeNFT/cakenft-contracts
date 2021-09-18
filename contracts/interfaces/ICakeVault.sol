// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICakeStaker.sol";

interface ICakeVault {
    function cake() external returns (IERC20);
    function cakeStaker() external returns (ICakeStaker);
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function claim() external;
}
