// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X208} from "./X208.sol";
import {X216} from "./X216.sol";
import {FullMathLibrary} from "./FullMath.sol";

// Type 'X111' is dedicated to growth and liquidity values.
type X111 is int256;

using X111Library for X111 global;

X111 constant zeroX111 = X111.wrap(0);
X111 constant oneX111 = X111.wrap(1 << 111);
X111 constant maxGrowth = X111.wrap(1 << 127);

using {equals as ==, notEqual as !=} for X111 global;
using {lessThan as <, greaterThan as >} for X111 global;
using {
  lessThanOrEqualTo as <=,
  greaterThanOrEqualTo as >=
} for X111 global;
using {add as +, sub as -} for X111 global;

function equals(
  X111 value0,
  X111 value1
) pure returns (
  bool result
) {
  assembly {
    result := eq(value0, value1)
  }
}

function notEqual(
  X111 value0,
  X111 value1
) pure returns (
  bool result
) {
  return !(value0 == value1);
}

function lessThan(
  X111 value0,
  X111 value1
) pure returns (
  bool result
) {
  assembly {
    result := slt(value0, value1)
  }
}

function greaterThan(
  X111 value0,
  X111 value1
) pure returns (
  bool result
) {
  assembly {
    result := sgt(value0, value1)
  }
}

function lessThanOrEqualTo(
  X111 value0,
  X111 value1
) pure returns (
  bool result
) {
  return !(value0 > value1);
}

function greaterThanOrEqualTo(
  X111 value0,
  X111 value1
) pure returns (
  bool result
) {
  return !(value0 < value1);
}

// Overflow/underflow should be avoided externally.
function add(
  X111 value0,
  X111 value1
) pure returns (
  X111 result
) {
  assembly {
    result := add(value0, value1)
  }
}

// Overflow/underflow should be avoided externally.
function sub(
  X111 value0,
  X111 value1
) pure returns (
  X111 result
) {
  assembly {
    result := sub(value0, value1)
  }
}

function min(
  X111 value0,
  X111 value1
) pure returns (
  X111 result
) {
  return (value0 < value1) ? value0 : value1;
}

function max(
  X111 value0,
  X111 value1
) pure returns (
  X111 result
) {
  return (value0 < value1) ? value1 : value0;
}

library X111Library {
  /// @notice Calculates 'liquidity == growth * shares'.
  /// 'growth' should not be less than 'oneX111'.
  /// 'growth' should be less than or equal to '1 << 127'.
  /// 'shares' should be less than '1 << 127'
  function times(
    X111 growth,
    uint256 shares
  ) internal pure returns (
    X111 liquidity
  ) {
    assembly {
      // Multiplication is safe because of the input requirements.
      liquidity := mul(growth, shares)
    }
  }

  /// @notice Calculates 'liquidity == growth * shares'.
  /// 'growth' should not be less than 'oneX111'.
  /// 'growth' should be less than or equal to '1 << 127'.
  /// 'shares' should be greater than '- (1 << 127)'.
  /// 'shares' should be less than '1 << 127'.
  function times(
    X111 growth,
    int256 shares
  ) internal pure returns (
    X111 liquidity
  ) {
    assembly {
      // Multiplication is safe because of the input requirements.
      liquidity := mul(growth, shares)
    }
  }

  /// @notice Calculates
  /// '(value * multiplier) / ((2 ** 119) * exp(-8))'
  /// 'growth' should not be less than 'oneX111'.
  /// 'growth' should be less than or equal to '1 << 127'.
  /// 'multiplier' should be non-negative and less than 'oneX216'.
  function mulDivByExpInv8(
    X111 growth,
    X216 multiplier
  ) internal pure returns (
    X208 product
  ) {
    // Both castings are safe because
    // 'growth >= oneX111' and 'multiplier >= zeroX216'
    ( ,  , uint256 q2) = FullMathLibrary.mul768(
      // (2 ** 244) * exp(8)
      0xBA4F53EA38636F85F007042540AE8EF33225E9A7AB4F4473A86D4A8FDD1A5B82,
      // The shift is safe because 'oneX111 <= growth <= (1 << 127)'
      uint256(X111.unwrap(growth)) << 110,
      // The shift is safe because '0 <= multiplier <= oneX216'
      uint256(X216.unwrap(multiplier)) << 39
    );
    product = X208.wrap(q2);
  }
}