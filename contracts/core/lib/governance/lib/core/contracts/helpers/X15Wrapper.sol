// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/X15.sol';

/// @title This contract exposes the functions of 'X15.sol' for testing
/// purposes.
contract X15Wrapper {
  function equals(
    X15 value0,
    X15 value1
  ) public returns (
    bool result
  ) {
    return value0 == value1;
  }

  function notEqual(
    X15 value0,
    X15 value1
  ) public returns (
    bool result
  ) {
    return value0 != value1;
  }

  function lessThan(
    X15 value0,
    X15 value1
  ) public returns (
    bool result
  ) {
    return value0 < value1;
  }

  function greaterThan(
    X15 value0,
    X15 value1
  ) public returns (
    bool result
  ) {
    return value0 > value1;
  }

  function lessThanOrEqualTo(
    X15 value0,
    X15 value1
  ) public returns (
    bool result
  ) {
    return value0 <= value1;
  }

  function greaterThanOrEqualTo(
    X15 value0,
    X15 value1
  ) public returns (
    bool result
  ) {
    return value0 >= value1;
  }
  
  function add(
    X15 value0,
    X15 value1
  ) public returns (
    X15 result
  ) {
    return value0 + value1;
  }

  function sub(
    X15 value0,
    X15 value1
  ) public returns (
    X15 result
  ) {
    return value0 - value1;
  }
}