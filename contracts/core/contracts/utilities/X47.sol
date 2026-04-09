// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

// Type 'X47' is dedicated to growth portions. Interval liquidity can grow as a
// result of a swap or a donation. A portion of this growth goes to the
// protocol. A portion of the remaining growth goes to the pool owner. These
// portions are stored as 'X47' type with 'oneX47' representing 100%.
type X47 is uint256;

X47 constant zeroX47 = X47.wrap(0);
// Largest valid value for growth portions:
X47 constant oneX47 = X47.wrap(1 << 47);
// An invalid value for growth portions which is used as an indicator:
X47 constant maxX47 = X47.wrap(type(uint48).max);

using {equals as ==, notEqual as !=} for X47 global;
using {lessThan as <, greaterThan as >} for X47 global;
using {
  lessThanOrEqualTo as <=,
  greaterThanOrEqualTo as >=
} for X47 global;

function equals(
  X47 value0,
  X47 value1
) pure returns (
  bool result
) {
  assembly {
    result := eq(value0, value1)
  }
}

function notEqual(
  X47 value0,
  X47 value1
) pure returns (
  bool result
) {
  return !(value0 == value1);
}

function lessThan(
  X47 value0,
  X47 value1
) pure returns (
  bool result
) {
  assembly {
    result := lt(value0, value1)
  }
}

function greaterThan(
  X47 value0,
  X47 value1
) pure returns (
  bool result
) {
  assembly {
    result := gt(value0, value1)
  }
}

function lessThanOrEqualTo(
  X47 value0,
  X47 value1
) pure returns (
  bool result
) {
  return !(value0 > value1);
}

function greaterThanOrEqualTo(
  X47 value0,
  X47 value1
) pure returns (
  bool result
) {
  return !(value0 < value1);
}

function min(
  X47 value0,
  X47 value1
) pure returns (
  X47 result
) {
  return (value0 < value1) ? value0 : value1;
}

function max(
  X47 value0,
  X47 value1
) pure returns (
  X47 result
) {
  return (value0 < value1) ? value1 : value0;
}