// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/X47.sol';

/// @title This contract exposes the functions of 'X47.sol' for testing
/// purposes.
contract X47Wrapper {
  function equals(
    X47 value0,
    X47 value1
  ) public returns (
    bool result
  ) {
    return value0 == value1;
  }

  function notEqual(
    X47 value0,
    X47 value1
  ) public returns (
    bool result
  ) {
    return value0 != value1;
  }

  function lessThan(
    X47 value0,
    X47 value1
  ) public returns (
    bool result
  ) {
    return value0 < value1;
  }

  function greaterThan(
    X47 value0,
    X47 value1
  ) public returns (
    bool result
  ) {
    return value0 > value1;
  }

  function lessThanOrEqualTo(
    X47 value0,
    X47 value1
  ) public returns (
    bool result
  ) {
    return value0 <= value1;
  }

  function greaterThanOrEqualTo(
    X47 value0,
    X47 value1
  ) public returns (
    bool result
  ) {
    return value0 >= value1;
  }

  function minX47(
    X47 value0,
    X47 value1
  ) public returns (
    X47 result
  ) {
    return min(value0, value1);
  }

  function maxX47(
    X47 value0,
    X47 value1
  ) public returns (
    X47 result
  ) {
    return max(value0, value1);
  }
}