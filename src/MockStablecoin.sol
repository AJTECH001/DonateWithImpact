// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockStablecoin is ERC20 {
    constructor() ERC20("Mock Stablecoin", "MST") {
        _mint(msg.sender, 1000000 * 10 ** 18); // Mint 1M tokens to deployer
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
