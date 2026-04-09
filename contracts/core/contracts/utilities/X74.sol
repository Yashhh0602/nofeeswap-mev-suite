// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X216} from "./X216.sol";

// Type 'X74' is used as an intermediate type when searching for precise log
// price movement corresponding to the specified outgoing/incoming token 
// amounts.
type X74 is int256;

X74 constant zeroX74 = X74.wrap(0);

using {equals as ==, notEqual as !=} for X74 global;
using {add as +, sub as -} for X74 global;

using X74Library for X74 global;

function equals(
  X74 value0,
  X74 value1
) pure returns (
  bool result
) {
  assembly {
    result := eq(value0, value1)
  }
}

function notEqual(
  X74 value0,
  X74 value1
) pure returns (
  bool result
) {
  return !(value0 == value1);
}

// Overflow/underflow should be avoided externally.
function add(
  X74 value0,
  X74 value1
) pure returns (
  X74 result
) {
  assembly {
    result := add(value0, value1)
  }
}

// Overflow/underflow should be avoided externally.
function sub(
  X74 value0,
  X74 value1
) pure returns (
  X74 result
) {
  assembly {
    result := sub(value0, value1)
  }
}

library X74Library {
  // Converts type 'X74' to 'X216'.
  // Overflow should be avoided externally.
  function toX216(
    X74 value
  ) internal pure returns (
    X216 result
  ) {
    assembly {
      // Multiplication is safe because overflow is avoided externally.
      result := mul(shl(142, 1), value)
    }
  }
}