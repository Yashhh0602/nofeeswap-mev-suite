// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/X208.sol';

/// @title This contract exposes the functions of 'X208.sol' for testing
/// purposes.
contract X208Wrapper {
  function equals(
    X208 value0,
    X208 value1
  ) public returns (
    bool result
  ) {
    return value0 == value1;
  }

  function notEqual(
    X208 value0,
    X208 value1
  ) public returns (
    bool result
  ) {
    return value0 != value1;
  }

  function lessThan(
    X208 value0,
    X208 value1
  ) public returns (
    bool result
  ) {
    return value0 < value1;
  }

  function greaterThan(
    X208 value0,
    X208 value1
  ) public returns (
    bool result
  ) {
    return value0 > value1;
  }

  function lessThanOrEqualTo(
    X208 value0,
    X208 value1
  ) public returns (
    bool result
  ) {
    return value0 <= value1;
  }

  function greaterThanOrEqualTo(
    X208 value0,
    X208 value1
  ) public returns (
    bool result
  ) {
    return value0 >= value1;
  }

  function add(
    X208 value0,
    X208 value1
  ) public returns (
    X208 result
  ) {
    return value0 + value1;
  }

  function sub(
    X208 value0,
    X208 value1
  ) public returns (
    X208 result
  ) {
    return value0 - value1;
  }

  function mulDiv(
    X208 value,
    X216 numerator,
    X216 denominator
  ) public returns (
    X208 result
  ) {
    return X208Library.mulDiv(
      value,
      numerator,
      denominator
    );
  }

  function mulDivByExpInv8(
    X208 value,
    X216 multiplier
  ) public returns (
    X111 product
  ) {
    return X208Library.mulDivByExpInv8(value, multiplier);
  }
}