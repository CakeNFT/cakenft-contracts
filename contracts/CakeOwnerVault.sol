// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICakeOwnerVault.sol";
import "./interfaces/ICakeStaker.sol";

contract CakeOwnerVault is Ownable, ICakeOwnerVault {

    IERC20 override immutable public cake;
    ICakeStaker override immutable public cakeStaker;

    constructor(IERC20 _cake, ICakeStaker _cakeStaker) {
        cake = _cake;
        cakeStaker = _cakeStaker;
    }

    function deposit(uint256 amount) override external {
        cake.transferFrom(msg.sender, address(this), amount);
        cake.approve(address(cakeStaker), amount);
        cakeStaker.enterStaking(amount);
    }

    function claim() override external {
        (uint256 staked,) = cakeStaker.userInfo(0, address(this));
        cakeStaker.leaveStaking(staked);
        cake.transfer(owner(), cake.balanceOf(address(this)));
    }
}
