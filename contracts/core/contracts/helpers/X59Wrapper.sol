// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/X59.sol';

/// @title This contract exposes the functions of 'X59.sol' for testing
/// purposes.
contract X59Wrapper {
  function equals(
    X59 value0,
    X59 value1
  ) public returns (
    bool result
  ) {
    return value0 == value1;
  }

  function notEqual(
    X59 value0,
    X59 value1
  ) public returns (
    bool result
  ) {
    return value0 != value1;
  }

  function lessThan(
    X59 value0,
    X59 value1
  ) public returns (
    bool result
  ) {
    return value0 < value1;
  }

  function greaterThan(
    X59 value0,
    X59 value1
  ) public returns (
    bool result
  ) {
    return value0 > value1;
  }

  function lessThanOrEqualTo(
    X59 value0,
    X59 value1
  ) public returns (
    bool result
  ) {
    return value0 <= value1;
  }

  function greaterThanOrEqualTo(
    X59 value0,
    X59 value1
  ) public returns (
    bool result
  ) {
    return value0 >= value1;
  }

  function add(
    X59 value0,
    X59 value1
  ) public returns (
    X59 result
  ) {
    return value0 + value1;
  }

  function sub(
    X59 value0,
    X59 value1
  ) public returns (
    X59 result
  ) {
    return value0 - value1;
  }

  function mod(
    X59 value0,
    X59 value1
  ) public returns (
    X59 result
  ) {
    return value0 % value1;
  }

  function minX59(
    X59 value0,
    X59 value1
  ) public returns (
    X59 result
  ) {
    return min(value0, value1);
  }

  function maxX59(
    X59 value0,
    X59 value1
  ) public returns (
    X59 result
  ) {
    return max(value0, value1);
  }

  function times(
    X59 value0,
    X15 value1
  ) public returns (
    X74 result
  ) {
    return X59Library.times(value0, value1);
  }

  function cheapMulDiv(
    X59 value,
    X216 numerator,
    X216 denominator
  ) public returns (
    X59 result
  ) {
    return X59Library.cheapMulDiv(value, numerator, denominator);
  }

  function mulDivByExpInv16(
    X59 value,
    X216 multiplier0,
    X216 multiplier1
  ) public returns (
    X216 product
  ) {
    return X59Library.mulDivByExpInv16(value, multiplier0, multiplier1);
  }

  function exp(
    X59 value
  ) public returns (
    X216 exponentialInverse,
    X216 exponentialOverExp16
  ) {
    return X59Library.exp(value);
  }

  function expOffset(
    X59 value
  ) public returns (
    uint256 exponentialInverse
  ) {
    return X59Library.expOffset(value);
  }

  function logToSqrtOffset(
    X59 value
  ) public returns (
    X127 sqrtOffset
  ) {
    return X59Library.logToSqrtOffset(value);
  }
}