// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {ERC1155} from "@openzeppelin/token/ERC1155/ERC1155.sol";

contract ERC1155FixedSupply is ERC1155 {
  constructor(
    string memory uri,
    uint256 initialSupply,
    uint256 id,
    address owner
  ) ERC1155(uri) {
    _mint(owner, id, initialSupply, "");
  }
}