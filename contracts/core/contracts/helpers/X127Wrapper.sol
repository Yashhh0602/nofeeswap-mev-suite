// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/X127.sol';
import '../utilities/X23.sol';

/// @title This contract exposes the functions of 'X127.sol' for testing
/// purposes.
contract X127Wrapper {
  function equals(
    X127 value0,
    X127 value1
  ) public returns (
    bool result
  ) {
    return value0 == value1;
  }

  function notEqual(
    X127 value0,
    X127 value1
  ) public returns (
    bool result
  ) {
    return value0 != value1;
  }

  function lessThan(
    X127 value0,
    X127 value1
  ) public returns (
    bool result
  ) {
    return value0 < value1;
  }

  function greaterThan(
    X127 value0,
    X127 value1
  ) public returns (
    bool result
  ) {
    return value0 > value1;
  }

  function lessThanOrEqualTo(
    X127 value0,
    X127 value1
  ) public returns (
    bool result
  ) {
    return value0 <= value1;
  }

  function greaterThanOrEqualTo(
    X127 value0,
    X127 value1
  ) public returns (
    bool result
  ) {
    return value0 >= value1;
  }

  function add(
    X127 value0,
    X127 value1
  ) public returns (
    X127 result
  ) {
    return value0 + value1;
  }

  function sub(
    X127 value0,
    X127 value1
  ) public returns (
    X127 result
  ) {
    return value0 - value1;
  }

  function safeAdd(
    X127 value0,
    X127 value1
  ) public returns (
    X127 result
  ) {
    return value0 & value1;
  }

  function minX127(
    X127 value0,
    X127 value1
  ) public returns (
    X127 result
  ) {
    return min(value0, value1);
  }

  function maxX127(
    X127 value0,
    X127 value1
  ) public returns (
    X127 result
  ) {
    return max(value0, value1);
  }

  function times(
    X127 value,
    X23 multiplier
  ) public returns (
    X127 product
  ) {
    return X127Library.times(value, multiplier);
  }

  function mulDiv(
    X127 value,
    X216 numerator,
    X216 denominator
  ) public returns (
    X127 result
  ) {
    return X127Library.mulDiv(
      value,
      numerator,
      denominator
    );
  }

  function toInteger(
    X127 value
  ) public returns (
    int256 result
  ) {
    return X127Library.toInteger(value);
  }

  function toIntegerRoundUp(
    X127 value
  ) public returns (
    int256 result
  ) {
    return X127Library.toIntegerRoundUp(value);
  }
}