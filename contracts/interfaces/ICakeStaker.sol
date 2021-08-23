// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface ICakeStaker {
    function enterStaking(uint256 amount) external;
    function leaveStaking(uint256 amount) external;
}
