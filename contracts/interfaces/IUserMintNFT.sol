// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IUserMintNFT is IERC721, IERC721Metadata, IERC721Enumerable {
    
    function deployer() external view returns (address);
    function storeAddress() external view returns (address);
    function version() external view returns (string memory);
    function mintPrice() view external returns (uint256);
    function maxMintCount() view external returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(uint256 id) external view returns (uint256);

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint(address to) external returns (uint256 id);
    function burn(uint256 id) external;
}
