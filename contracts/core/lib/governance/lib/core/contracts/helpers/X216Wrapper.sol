// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/X216.sol';

/// @title This contract exposes the functions of 'X216.sol' for testing
/// purposes.
contract X216Wrapper {
  function equals(
    X216 value0,
    X216 value1
  ) public returns (
    bool result
  ) {
    return value0 == value1;
  }

  function notEqual(
    X216 value0,
    X216 value1
  ) public returns (
    bool result
  ) {
    return value0 != value1;
  }

  function lessThan(
    X216 value0,
    X216 value1
  ) public returns (
    bool result
  ) {
    return value0 < value1;
  }

  function greaterThan(
    X216 value0,
    X216 value1
  ) public returns (
    bool result
  ) {
    return value0 > value1;
  }

  function lessThanOrEqualTo(
    X216 value0,
    X216 value1
  ) public returns (
    bool result
  ) {
    return value0 <= value1;
  }

  function greaterThanOrEqualTo(
    X216 value0,
    X216 value1
  ) public returns (
    bool result
  ) {
    return value0 >= value1;
  }

  function add(
    X216 value0,
    X216 value1
  ) public returns (
    X216 result
  ) {
    return value0 + value1;
  }

  function sub(
    X216 value0,
    X216 value1
  ) public returns (
    X216 result
  ) {
    return value0 - value1;
  }

  function mul(
    X216 value0,
    X216 value1
  ) public returns (
    X216 result
  ) {
    return value0 * value1;
  }

  function cheapMul(
    X216 value0,
    X216 value1
  ) public returns (
    X216 result
  ) {
    return value0 & value1;
  }

  function mulDivByExpInv8(
    X216 value0,
    X216 value1
  ) public returns (
    X216 result
  ) {
    return value0 % value1;
  }

  function mulDivByExpInv16(
    X216 value0,
    X216 value1
  ) public returns (
    X216 result
  ) {
    return value0 ^ value1;
  }

  function minX216(
    X216 value0,
    X216 value1
  ) public returns (
    X216 result
  ) {
    return min(value0, value1);
  }

  function maxX216(
    X216 value0,
    X216 value1
  ) public returns (
    X216 result
  ) {
    return max(value0, value1);
  }

  function minFractionsX216(
    X216 numerator0,
    X216 denominator0,
    X216 numerator1,
    X216 denominator1
  ) public returns (
    X216 numerator,
    X216 denominator,
    bool which
  ) {
    return minFractions(
      numerator0,
      denominator0,
      numerator1,
      denominator1
    );
  }

  function multiplyByExpEpsilonX216(
    X216 value
  ) public returns (
    X216 product
  ) {
    return X216Library.multiplyByExpEpsilon(value);
  }

  function divideByExpEpsilonX216(
    X216 value
  ) public returns (
    X216 product
  ) {
    return X216Library.divideByExpEpsilon(value);
  }

  function mulDiv(
    X216 value,
    X216 numerator,
    X216 denominator
  ) public returns (
    X216 result
  ) {
    return X216Library.mulDiv(
      value,
      numerator,
      denominator
    );
  }

  function cheapMulDiv(
    X216 value,
    uint256 numerator,
    uint256 denominator
  ) public returns (
    X216 result
  ) {
    return X216Library.cheapMulDiv(
      value,
      numerator,
      denominator
    );
  }
}