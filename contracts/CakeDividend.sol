// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./interfaces/ICakeDividend.sol";

contract CakeDividend is ICakeDividend {

    IERC20 override immutable public cake;
    ICakeStaker override immutable public cakeStaker;

    constructor(IERC20 _cake, ICakeStaker _cakeStaker) {
        cake = _cake;
        cakeStaker = _cakeStaker;
    }

    uint256 internal currentBalance = 0;
    uint256 internal totalTokenBalance = 0;
    mapping(IERC721 => mapping(uint256 => uint256)) public tokenBalances;

    uint256 constant internal pointsMultiplier = 2**128;
    uint256 internal pointsPerShare = 0;
    mapping(IERC721 => mapping(uint256 => int256)) public pointsCorrection;
    mapping(IERC721 => mapping(uint256 => uint256)) public claimed;

    function updateBalance() internal {
        if (totalTokenBalance > 0) {
            cakeStaker.leaveStaking(0);
            uint256 balance = cake.balanceOf(address(this));
            uint256 value = balance - currentBalance;
            if (value > 0) {
                pointsPerShare += value * pointsMultiplier / totalTokenBalance;
                emit DistributeCake(msg.sender, value);
            }
            currentBalance = balance;
        }
    }

    function claimedCakeOf(IERC721 nft, uint256 nftId) override public view returns (uint256) {
        return claimed[nft][nftId];
    }

    function accumulativeCakeOf(IERC721 nft, uint256 nftId) override public view returns (uint256) {
        uint256 _pointsPerShare = pointsPerShare;
        if (totalTokenBalance > 0) {
            uint256 balance = cakeStaker.pendingCake(0, address(this)) + cake.balanceOf(address(this));
            uint256 value = balance - currentBalance;
            if (value > 0) {
                _pointsPerShare += value * pointsMultiplier / totalTokenBalance;
            }
            return uint256(int256(_pointsPerShare * tokenBalances[nft][nftId]) + pointsCorrection[nft][nftId]) / pointsMultiplier;
        }
        return 0;
    }

    function claimableCakeOf(IERC721 nft, uint256 nftId) override external view returns (uint256) {
        return accumulativeCakeOf(nft, nftId) - claimed[nft][nftId];
    }

    function _accumulativeCakeOf(IERC721 nft, uint256 nftId) internal view returns (uint256) {
        return uint256(int256(pointsPerShare * tokenBalances[nft][nftId]) + pointsCorrection[nft][nftId]) / pointsMultiplier;
    }

    function _claimableCakeOf(IERC721 nft, uint256 nftId) internal view returns (uint256) {
        return _accumulativeCakeOf(nft, nftId) - claimed[nft][nftId];
    }

    function claimCake(IERC721 nft, uint256 nftId) override external {
        updateBalance();
        uint256 claimable = _claimableCakeOf(nft, nftId);
        if (claimable > 0) {
            claimed[nft][nftId] += claimable;
            emit ClaimCake(nft, nftId, msg.sender, claimable);
            cake.transfer(nft.ownerOf(nftId), claimable);
            currentBalance -= claimable;
        }
    }

    function _stakeCake(IERC721 nft, uint256 nftId, uint256 amount) internal {
        updateBalance();
        cake.approve(address(cakeStaker), amount);
        cakeStaker.enterStaking(amount);
        totalTokenBalance += amount;
        tokenBalances[nft][nftId] += amount;
        pointsCorrection[nft][nftId] -= int256(pointsPerShare * amount);
    }
}
