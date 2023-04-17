// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title DESSERT TOKEN
 * @dev This is the ERC20 reward token which we'll use to give rewards in our staking contract
 */
contract DESSERT is ERC20 {
    constructor() ERC20("DESSERT", "DSRT") {
        _mint(address(msg.sender), 10000000 * 10 ** decimals());
    }
}