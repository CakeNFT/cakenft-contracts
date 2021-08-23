// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./ICakeStaker.sol";

interface ICakeNFT is IERC721, IERC721Metadata, IERC721Enumerable {

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function PERMIT_ALL_TYPEHASH() external view returns (bytes32);

    function nonces(uint256 id) external view returns (uint256);
    function noncesForAll(address owner) external view returns (uint256);

    function nfts(uint256 id) external view returns (
        uint256 originPower,
        uint256 supportedLPTokenAmount,
        uint256 cakeRewardDebt
    );

    function cake() external view returns (IERC20);
    function cakeStaker() external view returns (ICakeStaker);

    function cakeLastRewardBlock() external view returns (uint256);
    function accCakePerShare() external view returns (uint256);

    function claimCakeReward(uint256 id) external;

    function pendingCakeReward(uint256 id) external view returns (uint256);

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
