// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/X74.sol';

/// @title This contract exposes the functions of 'X74.sol' for testing
/// purposes.
contract X74Wrapper {
  function equals(
    X74 value0,
    X74 value1
  ) public returns (
    bool result
  ) {
    return value0 == value1;
  }

  function notEqual(
    X74 value0,
    X74 value1
  ) public returns (
    bool result
  ) {
    return value0 != value1;
  }

  function add(
    X74 value0,
    X74 value1
  ) public returns (
    X74 result
  ) {
    return value0 + value1;
  }

  function sub(
    X74 value0,
    X74 value1
  ) public returns (
    X74 result
  ) {
    return value0 - value1;
  }

  function toX216(
    X74 value
  ) public returns (
    X216 result
  ) {
    return X74Library.toX216(value);
  }
}