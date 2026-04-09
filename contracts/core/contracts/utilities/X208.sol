// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X111} from "./X111.sol";
import {X216} from "./X216.sol";
import {FullMathLibrary} from "./FullMath.sol";

// Type 'X208' is dedicated to growth multipliers.
type X208 is uint256;

using X208Library for X208 global;

X208 constant zeroX208 = X208.wrap(0);
// (2 ** 208) * exp(+8)
X208 constant exp8X208 = X208.wrap(
  0x000000000BA4F53EA38636F85F007042540AE8EF33225E9A7AB4F4473A86D4A8
);

using {equals as ==, notEquals as !=} for X208 global;
using {lessThan as <, greaterThan as >} for X208 global;
using {
  lessThanOrEqualTo as <=,
  greaterThanOrEqualTo as >=
} for X208 global;
using {add as +, sub as -} for X208 global;

function equals(
  X208 value0,
  X208 value1
) pure returns (
  bool result
) {
  assembly {
    result := eq(value0, value1)
  }
}

function notEquals(
  X208 value0,
  X208 value1
) pure returns (
  bool result
) {
  return !(value0 == value1);
}

function lessThan(
  X208 value0,
  X208 value1
) pure returns (
  bool result
) {
  assembly {
    result := lt(value0, value1)
  }
}

function greaterThan(
  X208 value0,
  X208 value1
) pure returns (
  bool result
) {
  assembly {
    result := gt(value0, value1)
  }
}

function lessThanOrEqualTo(
  X208 value0,
  X208 value1
) pure returns (
  bool result
) {
  return !(value0 > value1);
}

function greaterThanOrEqualTo(
  X208 value0,
  X208 value1
) pure returns (
  bool result
) {
  return !(value0 < value1);
}

// Overflow should be avoided externally.
function add(
  X208 value0,
  X208 value1
) pure returns (
  X208 result
) {
  assembly {
    result := add(value0, value1)
  }
}

// Underflow should be avoided externally.
function sub(
  X208 value0,
  X208 value1
) pure returns (
  X208 result
) {
  assembly {
    result := sub(value0, value1)
  }
}

library X208Library {
  /// @notice Calculates '(value * numerator) / denominator'
  /// Overflow and division by zero should be avoided externally.
  /// 'numerator' and 'denominator' values should be non-negative.
  function mulDiv(
    X208 value,
    X216 numerator,
    X216 denominator
  ) internal pure returns (
    X208 result
  ) {
    // Both castings are safe because of the non-negative requirement on both
    // 'numerator' and 'denominator'.
    result = X208.wrap(
      FullMathLibrary.mulDiv(
        X208.unwrap(value),
        uint256(X216.unwrap(numerator)),
        uint256(X216.unwrap(denominator))
      )
    );
  }

  /// @notice Calculates
  /// '(value * multiplier) / ((2 ** 313) * exp(-8))'
  /// 'multiplier' should be non-negative.
  function mulDivByExpInv8(
    X208 value,
    X216 multiplier
  ) internal pure returns (
    X111 product
  ) {
    ( ,  , uint256 q2) = FullMathLibrary.mul768(
      // (2 ** 244) * exp(8)
      0xBA4F53EA38636F85F007042540AE8EF33225E9A7AB4F4473A86D4A8FDD1A5B82,
      X208.unwrap(value),
      // Casting is safe because of the non-negative requirement on
      // 'multiplier'.
      uint256(X216.unwrap(multiplier))
    );
    unchecked {
      // Casting is safe because 'q2 >> 45' never exceeds 'type(int256).max'.
      // '45 == 244 + 208 + 216 - 512 - 111'
      product = X111.wrap(int256(q2 >> 45));
    }
  }
}