// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICakeVault.sol";
import "./interfaces/ICakeStaker.sol";

contract CakeVault is Ownable, ICakeVault {

    IERC20 override immutable public cake;
    ICakeStaker override immutable public cakeStaker;
    uint256 public totalReward = 0;

    constructor(IERC20 _cake, ICakeStaker _cakeStaker) {
        cake = _cake;
        cakeStaker = _cakeStaker;
    }

    function deposit(uint256 amount) override external {
        cake.transferFrom(msg.sender, address(this), amount);
        cake.approve(address(cakeStaker), amount);
        cakeStaker.enterStaking(amount);
    }

    function withdraw(uint256 amount) override external {
        totalReward += cakeStaker.pendingCake(0, address(this));
        cakeStaker.leaveStaking(amount);
        cake.transfer(msg.sender, amount);
    }

    function claim() override external {
        cake.transfer(msg.sender, totalReward);
        totalReward = 0;
    }
}
