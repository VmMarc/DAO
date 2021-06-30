// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title 
/// @author 

contract DAOToken is ERC20, Ownable {
    uint256 private _totalSupply;
    constructor() ERC20("DAOToken", "DTN") { 
        _totalSupply = 1000000;
        _mint(msg.sender, _totalSupply * 10**decimals());
    }
}
