// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {ERC6909} from "@openzeppelin/token/ERC6909/draft-ERC6909.sol";

contract ERC6909FixedSupply is ERC6909 {
  constructor(uint256 initialSupply, uint256 id, address owner) {
    _mint(owner, id, initialSupply);
  }
}