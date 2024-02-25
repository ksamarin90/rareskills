// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";

contract NFT is ERC721, ERC2981, Ownable2Step {
    using BitMaps for BitMaps.BitMap;

    event Minted(address indexed owner, uint256 tokenId, bool discounted);
    event Withdrawn(address indexed owner, uint256 amount);

    error InvalidProof();
    error DiscountAlreadyApplied();
    error MaxSupplyReached();
    error InvalidPrice();

    bytes32 public immutable merkleRoot;
    uint256 public constant maxSupply = 1000;
    uint256 public constant price = 1 ether;
    uint256 public constant discountPrice = 0.6 ether;

    uint256 public totalSupply;
    BitMaps.BitMap private _claimedDiscount;

    constructor(
        string memory name_,
        string memory symbol_,
        bytes32 merkleRoot_,
        address owner_
    ) ERC721(name_, symbol_) Ownable(owner_) {
        merkleRoot = merkleRoot_;
        // Set royalty to 2.5%
        _setDefaultRoyalty(owner_, 2_50);
    }

    modifier verifyMint(uint256 priceToPay) {
        totalSupply += 1;
        if (totalSupply > maxSupply + 1) revert MaxSupplyReached();
        if (msg.value < priceToPay) revert InvalidPrice();
        _;
    }

    modifier verifyDiscount(
        bytes32[] calldata proof,
        uint256 index,
        address buyer
    ) {
        if (_claimedDiscount.get(index)) revert DiscountAlreadyApplied();
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, buyer))));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert InvalidProof();
        _claimedDiscount.set(index);
        _;
    }

    receive() external payable {}

    function mint() external payable verifyMint(price) {
        _mint(msg.sender, totalSupply);
        emit Minted(msg.sender, totalSupply, false);
    }

    function mintWithDiscount(
        bytes32[] calldata proof,
        uint256 index
    ) external payable verifyMint(discountPrice) verifyDiscount(proof, index, msg.sender) {
        _mint(msg.sender, totalSupply);
        emit Minted(msg.sender, totalSupply, true);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
        emit Withdrawn(owner(), address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
