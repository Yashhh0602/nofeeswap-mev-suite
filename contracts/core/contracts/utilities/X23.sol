// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

// Type 'X23' is dedicated to pool growth ratios which determine the ratio of
// the accrued growth portions that belong to a pool owner. 'oneX23' represents
// 100%.
type X23 is uint256;

X23 constant zeroX23 = X23.wrap(0);
X23 constant oneX23 = X23.wrap(1 << 23);

using {add as +, sub as -} for X23 global;

// Overflow should be avoided externally.
function add(
  X23 value0,
  X23 value1
) pure returns (
  X23 result
) {
  assembly {
    result := add(value0, value1)
  }
}

// Underflow should be avoided externally.
function sub(
  X23 value0,
  X23 value1
) pure returns (
  X23 result
) {
  assembly {
    result := sub(value0, value1)
  }
}