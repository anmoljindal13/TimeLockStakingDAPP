// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title STAKING TOKEN
 * @dev This is the ERC20 staking token which we'll use to demonstrate in our staking contract
 */
contract STAKINGTOKEN is ERC20 {
    constructor() ERC20("STAKINGTOKEN", "STKTKN") {
        _mint(address(msg.sender), 10000000 * 10 ** decimals());
    }
}