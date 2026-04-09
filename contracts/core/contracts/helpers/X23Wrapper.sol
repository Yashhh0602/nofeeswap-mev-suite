// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/X23.sol';

/// @title This contract exposes the functions of 'X23.sol' for testing
/// purposes.
contract X23Wrapper {
  function add(
    X23 value0,
    X23 value1
  ) public returns (
    X23 result
  ) {
    return value0 + value1;
  }

  function sub(
    X23 value0,
    X23 value1
  ) public returns (
    X23 result
  ) {
    return value0 - value1;
  }
}