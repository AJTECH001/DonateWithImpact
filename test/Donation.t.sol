// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/DonationContract.sol";
import "../src/ImpactPassNFT.sol";
import "../src/MockStablecoin.sol";

contract DonationContractTest is Test {
    DonationContract public donationContract;
    ImpactPassNFT public impactPassNFT;
    MockStablecoin public mockStablecoin;
    address public admin = 0xa4280dd3f9E1f6Bf1778837AC12447615E1d0317;
    address public donor = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    uint256 public constant INITIAL_TOKENS = 1000 * 10**18;
    uint256 public constant DONATION_AMOUNT = 100 * 10**18;

    function setUp() public {
        // Deploy MockStablecoin
        mockStablecoin = new MockStablecoin();
        mockStablecoin.mint(donor, INITIAL_TOKENS);

        // Deploy ImpactPassNFT with admin as temporary owner
        impactPassNFT = new ImpactPassNFT(admin);

        // Deploy DonationContract
        donationContract = new DonationContract(address(mockStablecoin), address(impactPassNFT));

        // Transfer ownership of ImpactPassNFT to DonationContract
        vm.prank(admin);
        impactPassNFT.transferOwnership(address(donationContract));

        // Approve DonationContract to spend donor's tokens
        vm.prank(donor);
        mockStablecoin.approve(address(donationContract), INITIAL_TOKENS);
    }

    function testDeployment() public {
        assertTrue(address(donationContract) != address(0), "DonationContract deployment failed");
        assertTrue(address(impactPassNFT) != address(0), "ImpactPassNFT deployment failed");
        assertTrue(address(mockStablecoin) != address(0), "MockStablecoin deployment failed");
        assertEq(impactPassNFT.owner(), address(donationContract), "Ownership transfer failed");
    }

    function testDonateInitial() public {
        // Record initial state
        uint256 initialBalance = mockStablecoin.balanceOf(donor);
        uint256 initialContractBalance = mockStablecoin.balanceOf(address(donationContract));
        uint256 initialTotalRaised = donationContract.totalRaised();
        uint256 initialTokenId = impactPassNFT.getDonorTokenId(donor);

        // Perform donation
        vm.prank(donor);
        donationContract.donate(DONATION_AMOUNT);

        // Verify state changes
        uint256 newBalance = mockStablecoin.balanceOf(donor);
        uint256 newContractBalance = mockStablecoin.balanceOf(address(donationContract));
        uint256 newTotalRaised = donationContract.totalRaised();
        uint256 newTokenId = impactPassNFT.getDonorTokenId(donor);
        bool hasMinted = impactPassNFT.hasDonorMinted(donor);
        uint256 donorTotalDonated = donationContract.getDonorTotalDonated(donor);

        assertEq(newBalance, initialBalance - DONATION_AMOUNT, "Donor balance not reduced");
        assertEq(newContractBalance, initialContractBalance + DONATION_AMOUNT, "Contract balance not increased");
        assertEq(newTotalRaised, initialTotalRaised + DONATION_AMOUNT, "Total raised not updated");
        assertEq(newTokenId, 1, "Incorrect tokenId minted");
        assertTrue(hasMinted, "Donor should have minted NFT");
        assertEq(donorTotalDonated, DONATION_AMOUNT, "Donor total donated not updated");

        // Verify events (assuming event logs are accessible via vm.expectEmit)
        vm.expectEmit(true, true, true, true);
        emit DonationReceived(donor, DONATION_AMOUNT, DONATION_AMOUNT);
        vm.expectEmit(true, true, true, true);
        emit ImpactPassMinted(donor, 1);

        vm.prank(donor);
        donationContract.donate(DONATION_AMOUNT); // Trigger events
    }

    function testDonateSubsequent() public {
        // First donation to mint NFT
        vm.prank(donor);
        donationContract.donate(DONATION_AMOUNT);

        // Record state before second donation
        uint256 initialTotalDonated = donationContract.getDonorTotalDonated(donor);
        uint256 initialContractBalance = mockStablecoin.balanceOf(address(donationContract));
        uint256 initialTotalRaised = donationContract.totalRaised();

        // Perform second donation
        vm.prank(donor);
        donationContract.donate(DONATION_AMOUNT);

        // Verify state changes
        uint256 newTotalDonated = donationContract.getDonorTotalDonated(donor);
        uint256 newContractBalance = mockStablecoin.balanceOf(address(donationContract));
        uint256 newTotalRaised = donationContract.totalRaised();
        bool hasMinted = impactPassNFT.hasDonorMinted(donor);

        assertEq(newTotalDonated, initialTotalDonated + DONATION_AMOUNT, "Donor total donated not updated");
        assertEq(newContractBalance, initialContractBalance + DONATION_AMOUNT, "Contract balance not increased");
        assertEq(newTotalRaised, initialTotalRaised + DONATION_AMOUNT, "Total raised not updated");
        assertTrue(hasMinted, "Donor should still have minted NFT");

        // Verify no new NFT is minted (only DonationReceived event)
        vm.expectEmit(true, true, true, true);
        emit DonationReceived(donor, DONATION_AMOUNT, newTotalDonated);

        vm.prank(donor);
        donationContract.donate(DONATION_AMOUNT); // Trigger event
    }

    function testWithdrawFunds() public {
        // Donate first to fund the contract
        vm.prank(donor);
        donationContract.donate(DONATION_AMOUNT);

        // Record initial state
        uint256 initialContractBalance = mockStablecoin.balanceOf(address(donationContract));
        uint256 initialAdminBalance = mockStablecoin.balanceOf(admin);

        // Withdraw funds as admin
        vm.prank(admin);
        donationContract.withdrawFunds(admin, DONATION_AMOUNT);

        // Verify state changes
        uint256 newContractBalance = mockStablecoin.balanceOf(address(donationContract));
        uint256 newAdminBalance = mockStablecoin.balanceOf(admin);

        assertEq(newContractBalance, initialContractBalance - DONATION_AMOUNT, "Contract balance not reduced");
        assertEq(newAdminBalance, initialAdminBalance + DONATION_AMOUNT, "Admin balance not increased");

        // Verify event
        vm.expectEmit(true, true, true, true);
        emit FundsWithdrawn(admin, DONATION_AMOUNT);

        vm.prank(admin);
        donationContract.withdrawFunds(admin, DONATION_AMOUNT); // Trigger event
    }

    function testFailDonateZeroAmount() public {
        vm.prank(donor);
        vm.expectRevert("Amount must be > 0");
        donationContract.donate(0);
    }

    function testFailWithdrawInsufficientFunds() public {
        vm.prank(admin);
        vm.expectRevert("Insufficient funds");
        donationContract.withdrawFunds(admin, DONATION_AMOUNT + 1); // Attempt to withdraw more than donated
    }
}

// Events for testing (defined here for clarity, should match contract)
event DonationReceived(address indexed donor, uint256 amount, uint256 totalDonated);
event ImpactPassMinted(address indexed donor, uint256 tokenId);
event FundsWithdrawn(address indexed to, uint256 amount);