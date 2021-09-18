// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ICakeStaker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICakeDividend {

    event DistributeCake(address indexed by, uint256 distributed);
    event ClaimCake(IERC721 indexed nft, uint256 indexed nftId, address indexed to, uint256 claimed);

    function cake() external returns (IERC20);
    function cakeStaker() external returns (ICakeStaker);
    function totalStakedCakeBalance() view external returns (uint256);
    function stakedCakeBalances(IERC721 nft, uint256 nftId) external view returns (uint256);
    
    function accumulativeCakeOf(IERC721 nft, uint256 nftId) external view returns (uint256);
    function claimedCakeOf(IERC721 nft, uint256 nftId) external view returns (uint256);
    function claimableCakeOf(IERC721 nft, uint256 nftId) external view returns (uint256);
    function claimCake(IERC721 nft, uint256 nftId) external;
}
