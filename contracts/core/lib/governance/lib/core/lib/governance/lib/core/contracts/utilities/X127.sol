// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X23} from "./X23.sol";
import {X216} from "./X216.sol";
import {SafeAddFailed} from "./Errors.sol";
import {FullMathLibrary} from "./FullMath.sol";

// Type 'X127' is used for 'sqrtOffset', 'sqrtInverseOffset', and token
// amounts.
type X127 is int256;

using X127Library for X127 global;

X127 constant oneX127 = X127.wrap(1 << 127);
X127 constant zeroX127 = X127.wrap(0);
X127 constant epsilonX127 = X127.wrap(1);
// 104 = 231 - 127 digits of non-decimal
X127 constant accruedMax = X127.wrap((1 << 231) - 1);

using {equals as ==, notEquals as !=} for X127 global;
using {lessThan as <, greaterThan as >} for X127 global;
using {
  lessThanOrEqualTo as <=,
  greaterThanOrEqualTo as >=
} for X127 global;
using {add as +, sub as -, safeAdd as &} for X127 global;

function equals(
  X127 value0,
  X127 value1
) pure returns (
  bool result
) {
  assembly {
    result := eq(value0, value1)
  }
}

function notEquals(
  X127 value0,
  X127 value1
) pure returns (
  bool result
) {
  return !(value0 == value1);
}

function lessThan(
  X127 value0,
  X127 value1
) pure returns (
  bool result
) {
  assembly {
    result := slt(value0, value1)
  }
}

function greaterThan(
  X127 value0,
  X127 value1
) pure returns (
  bool result
) {
  assembly {
    result := sgt(value0, value1)
  }
}

function lessThanOrEqualTo(
  X127 value0,
  X127 value1
) pure returns (
  bool result
) {
  return !(value0 > value1);
}

function greaterThanOrEqualTo(
  X127 value0,
  X127 value1
) pure returns (
  bool result
) {
  return !(value0 < value1);
}

// Overflow/underflow should be avoided externally.
function add(
  X127 value0,
  X127 value1
) pure returns (
  X127 result
) {
  assembly {
    result := add(value0, value1)
  }
}

// Overflow/underflow should be avoided externally.
function sub(
  X127 value0,
  X127 value1
) pure returns (
  X127 result
) {
  assembly {
    result := sub(value0, value1)
  }
}

// Throws in case of overflow/underflow.
function safeAdd(
  X127 value0,
  X127 value1
) pure returns (
  X127 result
) {
  // We first add the two values unsafely and then examine the result.
  result = value0 + value1;
  
  // The following requirement is satisfied if and only if 'result' does not
  // overflow or underflow. Because,
  // - overflow implies that both 'value0' and 'value1' are positive but
  // 'result' is negative which contradicts the following requirement.
  // - underflow implies that both 'value0' and 'value1' are negative but
  // 'result' is positive which contradicts the following requirement as well.
  // - Lastly, in case of no overflow/underflow, the following requirement is
  // trivial.
  require(
    (value1 >= zeroX127) == (result >= value0),
    SafeAddFailed(value0, value1)
  );
}

function min(
  X127 value0,
  X127 value1
) pure returns (
  X127 result
) {
  return (value0 < value1) ? value0 : value1;
}

function max(
  X127 value0,
  X127 value1
) pure returns (
  X127 result
) {
  return (value0 < value1) ? value1 : value0;
}

library X127Library {
  /// @notice Calculates 'value * multiplier / (2 ** 23)'
  /// 'value' should be non-negative.
  /// 'value * multiplier' should be less than '2 ** 256'.
  function times(
    X127 value,
    X23 multiplier
  ) internal pure returns (
    X127 product
  ) {
    // The multiplication is safe because of the input requirement.
    assembly {
      product := shr(23, mul(value, multiplier))
    }
  }

  /// @notice Calculates '(value * numerator) / denominator'
  /// Overflow and division by zero should be avoided externally.
  /// All input values should be non-negative.
  function mulDiv(
    X127 value,
    X216 numerator,
    X216 denominator
  ) internal pure returns (
    X127 result
  ) {
    result = X127.wrap(
      // Casting to 'int256' is safe because overflow is handled externally.
      int256(
        // The three castings are safe because of the input requirement.
        // The requirements of 'mulDiv' are met because overflow is handled
        // externally.
        FullMathLibrary.mulDiv(
          uint256(X127.unwrap(value)),
          uint256(X216.unwrap(numerator)),
          uint256(X216.unwrap(denominator))
        )
      )
    );
  }

  /// @notice Transforms type X127 to the integer 'value / (2 ** 127)' while
  /// maintaining the sign. Rounds towards negative infinity.
  function toInteger(
    X127 value
  ) internal pure returns (
    int256 result
  ) {
    assembly {
      result := sar(127, value)
    }
  }

  /// @notice Transforms type X127 to the integer 'value / (2 ** 127)' while
  /// maintaining the sign.
  /// Rounds towards positive infinity.
  /// 'value' should be greater than '- 2 ** 255'.
  function toIntegerRoundUp(
    X127 value
  ) internal pure returns (
    int256 result
  ) {
    // The inner subtraction is safe because 'value > - 2 ** 255'.
    // The outer subtraction is safe because 
    // '- 2 ** 128 < (0 - value) / (2 ** 127) < 2 ** 128'
    assembly {
      result := sub(0, sar(127, sub(0, value)))
    }
  }
}