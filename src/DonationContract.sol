// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ImpactPassNFT.sol";

contract DonationContract is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public stablecoin;
    ImpactPassNFT public impactPassNFT;

    // Donor stats: total donated + last donation timestamp
    struct Donor {
        uint256 totalDonated;
        uint256 lastDonationTime;
        bool hasImpactPass;
    }

    mapping(address => Donor) public donors;
    uint256 public totalRaised;

    // Events
    event DonationReceived(address indexed donor, uint256 amount, uint256 totalDonated);
    event ImpactPassMinted(address indexed donor, uint256 tokenId);
    event FundsWithdrawn(address indexed to, uint256 amount);

    constructor(address _stablecoin, address _impactPassNFT) Ownable(msg.sender) {
        stablecoin = IERC20(_stablecoin);
        impactPassNFT = ImpactPassNFT(_impactPassNFT);
    }

    /**
     * @dev Donate stablecoins to the contract.
     *      Mints an ImpactPass NFT on the donor's first contribution.
     * @param amount The amount of stablecoin to donate.
     */
    function donate(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");

        // Safely transfer tokens from donor to this contract
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        Donor storage donor = donors[msg.sender];
        donor.totalDonated += amount;
        donor.lastDonationTime = block.timestamp;

        // Mint ImpactPass on first donation
        if (!donor.hasImpactPass) {
            uint256 tokenId = impactPassNFT.mintImpactPass(msg.sender);
            donor.hasImpactPass = true;
            emit ImpactPassMinted(msg.sender, tokenId);
        }

        totalRaised += amount;
        emit DonationReceived(msg.sender, amount, donor.totalDonated);
    }

    /**
     * @dev Withdraw funds from the contract (pull-over-push pattern).
     *      Only callable by the owner (e.g., NGO).
     * @param to The recipient address.
     * @param amount The amount of stablecoin to withdraw.
     */
    function withdrawFunds(address to, uint256 amount) external onlyOwner {
        require(amount <= stablecoin.balanceOf(address(this)), "Insufficient funds");
        stablecoin.safeTransfer(to, amount);
        emit FundsWithdrawn(to, amount);
    }

    /**
     * @dev Returns the total amount donated by a specific donor.
     */
    function getDonorTotalDonated(address donor) external view returns (uint256) {
        return donors[donor].totalDonated;
    }

    /**
     * @dev Get contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return stablecoin.balanceOf(address(this));
    }
}
