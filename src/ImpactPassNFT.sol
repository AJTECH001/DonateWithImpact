// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ImpactPassNFT is ERC721, Ownable {
    mapping(address => uint256) private _donorToTokenId;
    uint256 private _tokenIdCounter;

    constructor(address initialOwner) ERC721("ImpactPass", "IMPACT") Ownable(initialOwner) {}

    /**
     * @dev Mint an ImpactPass NFT for a donor
     * @param to Donor address
     */
    function mintImpactPass(address to) external onlyOwner returns (uint256) {
        require(_donorToTokenId[to] == 0, "ImpactPass already minted");
        _tokenIdCounter++;
        _safeMint(to, _tokenIdCounter);
        _donorToTokenId[to] = _tokenIdCounter;
        return _tokenIdCounter;
    }

    /**
     * @dev Get donor's token ID
     */
    function getDonorTokenId(address donor) external view returns (uint256) {
        return _donorToTokenId[donor];
    }

    /**
     * @dev Check if donor has an ImpactPass
     */
    function hasDonorMinted(address donor) external view returns (bool) {
        return _donorToTokenId[donor] > 0;
    }

    /**
     * @dev Get total supply of minted ImpactPasses
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }
}
