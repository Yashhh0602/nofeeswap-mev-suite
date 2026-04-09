// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

// Type 'X15' is dedicated to the vertical coordinates of the kernel
// breakpoints. The distribution of liquidity within every interval is governed
// by a piecewise linear kernel function. The kernel function is characterized
// by a list of breakpoints given by the pool owner. The vertical coordinate of
// each breakpoint is a number within the interval [0, 1] which is stored in
// 'X15' format, with '2 ** 15' representing 1.
type X15 is uint256;

X15 constant zeroX15 = X15.wrap(0);
X15 constant oneX15 = X15.wrap(1 << 15);

using {equals as ==, notEqual as !=} for X15 global;
using {lessThan as <, greaterThan as >} for X15 global;
using {
  lessThanOrEqualTo as <=,
  greaterThanOrEqualTo as >=
} for X15 global;
using {add as +, sub as -} for X15 global;

function equals(
  X15 value0,
  X15 value1
) pure returns (
  bool result
) {
  assembly {
    result := eq(value0, value1)
  }
}

function notEqual(
  X15 value0,
  X15 value1
) pure returns (
  bool result
) {
  return !(value0 == value1);
}

function lessThan(
  X15 value0,
  X15 value1
) pure returns (
  bool result
) {
  assembly {
    result := lt(value0, value1)
  }
}

function greaterThan(
  X15 value0,
  X15 value1
) pure returns (
  bool result
) {
  assembly {
    result := gt(value0, value1)
  }
}

function lessThanOrEqualTo(
  X15 value0,
  X15 value1
) pure returns (
  bool result
) {
  return !(value0 > value1);
}

function greaterThanOrEqualTo(
  X15 value0,
  X15 value1
) pure returns (
  bool result
) {
  return !(value0 < value1);
}

// Overflow should be avoided externally.
function add(
  X15 value0,
  X15 value1
) pure returns (
  X15 result
) {
  assembly {
    result := add(value0, value1)
  }
}

// Underflow should be avoided externally.
function sub(
  X15 value0,
  X15 value1
) pure returns (
  X15 result
) {
  assembly {
    result := sub(value0, value1)
  }
}