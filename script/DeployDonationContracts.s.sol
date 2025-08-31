// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/DonationContract.sol";
import "../src/ImpactPassNFT.sol";
import "../src/MockStablecoin.sol";

contract DeployDonationContracts is Script {
    address public admin = 0xa4280dd3f9E1f6Bf1778837AC12447615E1d0317; // Default deployer account in Remix JavaScript VM

    function run() external {
        vm.startBroadcast();
        // Deploy MockStablecoin
        MockStablecoin mockStablecoin = new MockStablecoin();
        console.log("MockStablecoin deployed at:", address(mockStablecoin));
        // Deploy ImpactPassNFT with deployer as temporary owner
        ImpactPassNFT impactPassNFT = new ImpactPassNFT(admin);
        console.log("ImpactPassNFT deployed at:", address(impactPassNFT));
        // Deploy DonationContract with MockStablecoin and ImpactPassNFT addresses
        DonationContract donationContract = new DonationContract(address(mockStablecoin), address(impactPassNFT));
        console.log("DonationContract deployed at:", address(donationContract));
        // Transfer ownership of ImpactPassNFT to DonationContract
        impactPassNFT.transferOwnership(address(donationContract));
        console.log("Ownership of ImpactPassNFT transferred to DonationContract at:", address(donationContract));
        vm.stopBroadcast();
    }
}
