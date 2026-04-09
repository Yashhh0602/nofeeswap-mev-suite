// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/X111.sol';

/// @title This contract exposes the functions of 'X111.sol' for testing
/// purposes.
contract X111Wrapper {
  function equals(
    X111 value0,
    X111 value1
  ) public returns (
    bool result
  ) {
    return value0 == value1;
  }

  function notEqual(
    X111 value0,
    X111 value1
  ) public returns (
    bool result
  ) {
    return value0 != value1;
  }

  function lessThan(
    X111 value0,
    X111 value1
  ) public returns (
    bool result
  ) {
    return value0 < value1;
  }

  function greaterThan(
    X111 value0,
    X111 value1
  ) public returns (
    bool result
  ) {
    return value0 > value1;
  }

  function lessThanOrEqualTo(
    X111 value0,
    X111 value1
  ) public returns (
    bool result
  ) {
    return value0 <= value1;
  }

  function greaterThanOrEqualTo(
    X111 value0,
    X111 value1
  ) public returns (
    bool result
  ) {
    return value0 >= value1;
  }

  function add(
    X111 value0,
    X111 value1
  ) public returns (
    X111 result
  ) {
    return value0 + value1;
  }

  function sub(
    X111 value0,
    X111 value1
  ) public returns (
    X111 result
  ) {
    return value0 - value1;
  }

  function minX111(
    X111 value0,
    X111 value1
  ) public returns (
    X111 result
  ) {
    return min(value0, value1);
  }

  function maxX111(
    X111 value0,
    X111 value1
  ) public returns (
    X111 result
  ) {
    return max(value0, value1);
  }

  function timesUnsigned(
    X111 _growth,
    uint256 _shares
  ) public returns (
    X111 result
  ) {
    return X111Library.times(_growth, _shares);
  }

  function timesSigned(
    X111 _growth,
    int256 _shares
  ) public returns (
    X111 result
  ) {
    return X111Library.times(_growth, _shares);
  }

  function mulDivByExpInv8(
    X111 value,
    X216 multiplier
  ) public returns (
    X208 result
  ) {
    return X111Library.mulDivByExpInv8(value, multiplier);
  }
}