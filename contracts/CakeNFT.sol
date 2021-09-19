// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./libraries/ERC721.sol";
import "./libraries/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/ICakeNFT.sol";
import "./interfaces/IERC1271.sol";

contract CakeNFT is ERC721, ERC721Enumerable, ICakeNFT {
    
    address override public deployer;
    modifier onlyDeployer {
        require(msg.sender == deployer);
        _;
    }

    string public override version;
    string public baseURI;
    uint256 public count = 0;
    
    bytes32 public override DOMAIN_SEPARATOR;

    // keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    mapping(uint256 => uint256) public override nonces;

    constructor(
        string memory name,
        string memory symbol,
        string memory _version,
        string memory baseURI_
    ) ERC721(name, symbol) {

        deployer = msg.sender;
        version = _version;
        baseURI = baseURI_;

        uint256 chainId; assembly { chainId := chainid() }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(_version)),
                chainId,
                address(this)
            )
        );
    }

    function set(
        string memory name,
        string memory symbol,
        string memory _version,
        string memory baseURI_
    ) onlyDeployer external {
        _name = name;
        _symbol = symbol;
        version = _version;
        baseURI = baseURI_;

        uint256 chainId; assembly { chainId := chainid() }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(_version)),
                chainId,
                address(this)
            )
        );
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(block.timestamp <= deadline);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, spender, id, nonces[id], deadline))
            )
        );
        nonces[id] += 1;

        address owner = ownerOf(id);
        require(spender != owner);

        if (Address.isContract(owner)) {
            require(IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e);
        } else {
            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0));
            require(recoveredAddress == owner);
        }

        _approve(spender, id);
    }

    function mint() onlyDeployer public override returns (uint256 id) {
        id = count;
        count += 1;
        _mint(msg.sender, id);
    }

    function massMint(uint256 _count) onlyDeployer external override {
        for (uint256 i = 0; i < _count; i += 1) {
            mint();
        }
    }

    function burn(uint256 id) external override {
        require(msg.sender == ownerOf(id));
        _burn(id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
