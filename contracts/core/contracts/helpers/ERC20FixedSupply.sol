// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

contract ERC20FixedSupply is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply,
    address owner
  ) ERC20(name, symbol) {
      _mint(owner, initialSupply);
  }
}