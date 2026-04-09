// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X15} from "./X15.sol";
import {X74} from "./X74.sol";
import {X127} from "./X127.sol";
import {X216} from "./X216.sol";
import {FullMathLibrary} from "./FullMath.sol";

// Type 'X59' is dedicated to the natural logarithm of price.
type X59 is int256;

using X59Library for X59 global;

X59 constant zeroX59 = X59.wrap(0);
X59 constant epsilonX59 = X59.wrap(1);
X59 constant oneX59 = X59.wrap(1 << 59);
X59 constant twoX59 = X59.wrap(2 << 59);
X59 constant threeX59 = X59.wrap(3 << 59);
X59 constant fourX59 = X59.wrap(4 << 59);
X59 constant sixteenX59 = X59.wrap(16 << 59);
X59 constant thirtyTwoX59 = X59.wrap(32 << 59);
X59 constant minLogSpacing = X59.wrap((1 << 59) >> 19);
X59 constant minLogStep = X59.wrap((1 << 59) >> 27);
X59 constant minLogOffset = X59.wrap(0 - int256(90 << 59));
X59 constant maxLogOffset = X59.wrap(90 << 59);
X59 constant minX59 = X59.wrap(0 - type(int256).max);
X59 constant maxX59 = X59.wrap(type(int256).max);

using {equals as ==, notEqual as !=} for X59 global;
using {lessThan as <, greaterThan as >} for X59 global;
using {
  lessThanOrEqualTo as <=,
  greaterThanOrEqualTo as >=
} for X59 global;
using {add as +, sub as -} for X59 global;
using {mod as %} for X59 global;

function equals(
  X59 value0,
  X59 value1
) pure returns (
  bool result
) {
  assembly {
    result := eq(value0, value1)
  }
}

function notEqual(
  X59 value0,
  X59 value1
) pure returns (
  bool result
) {
  return !(value0 == value1);
}

function lessThan(
  X59 value0,
  X59 value1
) pure returns (
  bool result
) {
  assembly {
    result := slt(value0, value1)
  }
}

function greaterThan(
  X59 value0,
  X59 value1
) pure returns (
  bool result
) {
  assembly {
    result := sgt(value0, value1)
  }
}

function lessThanOrEqualTo(
  X59 value0,
  X59 value1
) pure returns (
  bool result
) {
  return !(value0 > value1);
}

function greaterThanOrEqualTo(
  X59 value0,
  X59 value1
) pure returns (
  bool result
) {
  return !(value0 < value1);
}

// Overflow/underflow should be avoided externally.
function add(
  X59 value0,
  X59 value1
) pure returns (
  X59 result
) {
  assembly {
    result := add(value0, value1)
  }
}

// Overflow/underflow should be avoided externally.
function sub(
  X59 value0,
  X59 value1
) pure returns (
  X59 result
) {
  assembly {
    result := sub(value0, value1)
  }
}

// 'value' should be non-negative.
// 'modulus' should be positive.
function mod(
  X59 value,
  X59 modulus
) pure returns (
  X59 result
) {
  assembly {
    result := mod(value, modulus)
  }
}

function min(
  X59 value0,
  X59 value1
) pure returns (
  X59 result
) {
  return (value0 < value1) ? value0 : value1;
}

function max(
  X59 value0,
  X59 value1
) pure returns (
  X59 result
) {
  return (value0 < value1) ? value1 : value0;
}

library X59Library {
  // Overflow should be avoided externally.
  // 'value0' should be non-negative.
  function times(
    X59 value0,
    X15 value1
  ) internal pure returns (
    X74 result
  ) {
    assembly {
      result := mul(value0, value1)
    }
  }

  /// @notice Calculates '(value * numerator) / denominator' when 
  /// 'value * numerator < denominator * (denominator - 1)'.
  /// The three inputs should be non-negative.
  function cheapMulDiv(
    X59 value,
    X216 numerator,
    X216 denominator
  ) internal pure returns (
    X59 result
  ) {
    // The three castings to 'uint256' are safe because of the 'non-negative'
    // requirement on input values.
    //
    // The casting to 'int256' is safe because
    // 'value * numerator / denominator < denominator - 1 <= 2 ** 255 - 2'.
    //
    // The requirement of 'cheapMulDiv' are met because of the above input
    // requirement.
    result = X59.wrap(int256(FullMathLibrary.cheapMulDiv(
      uint256(X59.unwrap(value)),
      uint256(X216.unwrap(numerator)),
      uint256(X216.unwrap(denominator))
    )));
  }

  /// @notice Calculates
  /// '(value * multiplier0 * multiplier1) / ((2 ** (216 + 59)) * exp(-16))'
  /// Overflow should be avoided externally.
  /// All three inputs should be non-negative.
  function mulDivByExpInv16(
    X59 value,
    X216 multiplier0,
    X216 multiplier1
  ) internal pure returns (
    X216 product
  ) {
    assembly {
      // Let 'r := value * multiplier0 * multiplier1 
      //         - floor((2 ** 275) * exp(-16)) * q'.
      //
      // Let 's := value * multiplier0 * multiplier1 - (2 ** 256) * p'.
      //
      // Then 's - r == floor((2 ** 275) * exp(-16)) * q' [modulo '2 ** 256']
      product := mul(
        sub(
          // s
          mul(mul(value, multiplier0), multiplier1),
          // r
          mulmod(
            mulmod(
              value,
              multiplier0,
              // floor((2 ** 275) * exp(-16))
              0xF1AADDD7742E56D32FB9F997447D9E6314DB84884FABAB26BF059AF9BC20B61
            ),
            multiplier1,
            // floor((2 ** 275) * exp(-16))
            0xF1AADDD7742E56D32FB9F997447D9E6314DB84884FABAB26BF059AF9BC20B61
          )
        ),
        // modularInverse(floor((2 ** 275) * exp(-16)), 2 ** 256)
        0xD49C04AF80AF1EA5F98F85886B450A4B264FC14874F9F64143836145A37DD8A1
      )
    }
  }

  /// @notice Calculates '(2 ** 256) * exp(- x / (2 ** 60))'.
  /// "Pade Approximant" is employed for this purpose:
  /// 'exp(- x / (2 ** 60)) ~= ((u(x) - v(x)) / (u(x) + v(x))) ** (2 ** 14)'
  /// where
  ///                x ** 2      x ** 4       x ** 6          x ** 8
  /// 'u(x) = 1 + 7 --------- + --------- + ----------- + --------------'
  ///                15<<150     39<<300     6435<<449     2027025<<600
  /// and
  ///            x       x ** 3       x ** 5        x ** 7
  /// 'v(x) = ------- + --------- + ---------- + -------------'.
  ///          1<<75     15<<224     585<<374     225225<<523
  ///
  /// This formula can be reproduced via the following Mathematica command:
  /// 'PadeApproximant[Exp[- x / (2 ^ 74)], {x, 0, 8}]'.
  ///
  /// Input should be greater than '0' and less than '2 ** 64'.
  function expInverse(
    X59 value
  ) internal pure returns (
    uint256 exponentialInverse
  ) {
    unchecked {
      // Casting is safe because 'value' is between '0' and '2 ** 64'.
      uint256 x = uint256(X59.unwrap(value));
      
      // x ** 2
      uint256 x2 = x * x;
      
      // x ** 4
      uint256 x4 = x2 * x2;

      // (x ** 6) / (2 ** 128)
      uint256 x6;
      assembly {
        // Let 'r := x2 * x4 - (2 ** 128) * q'
        // Let 's := x2 * x4 - (2 ** 256 - 1) * p'
        // Then 's - r == (2 ** 128) * q' [modulo '2 ** 256 - 1']
        // And 'q == (2 ** 128) * (s - r)' [modulo '2 ** 256 - 1']
        // Calculation modulo '2 ** 256 - 1' is safe because:
        // '((2 ** 64 - 1) ** 6) / (2 ** 128) < 2 ** 256 - 1'
        x6 := mulmod(
          // The subtraction is safe because the remainder is greater than or
          // equal to the second one.
          sub(mulmod(x2, x4, not(0)), mulmod(x2, x4, shl(128, 1))),
          shl(128, 1),
          not(0)
        )
      }

      // (x ** 8) / (2 ** 256)
      uint256 x8;
      assembly {
        // Let 'r := x4 * x4 - (2 ** 256) * q'
        // Let 's := x4 * x4 - (2 ** 256 - 1) * p'
        // Then 's - r == q' [modulo '2 ** 256 - 1']
        // Calculation modulo '2 ** 256 - 1' is safe because:
        // '((2 ** 64 - 1) ** 8) / (2 ** 256) < 2 ** 256 - 1'
        x8 := sub(mulmod(x4, x4, not(0)), mul(x4, x4))
      }

      // (2 ** 254) * u(x)
      // The additions are safe because the first term is '1 << 254' and none
      // of the other terms exceed '1 << 250'.
      uint256 a = 
        ((x2 * (7 << 104)) / 15) + 
        (x4 / (39 << 46)) + 
        (x6 / (6435 << 67)) + 
        (x8 / (2027025 << 90)) + 
        (1 << 254);

      // (2 ** 254) * v(x)
      // The additions are safe because the first term is '1 << 255' and none
      // of the other terms exceed '1 << 250'.
      uint256 b = 
        ((x2 << 106) / 15) + 
        (x4 / (585 << 44)) + 
        (x6 / (225225 << 65)) + 
        (1 << 255);
        
      assembly {
        // Here we multiply the result by (x / (2 ** 76)).
        // Let 'r := x * b - (2 ** 76) * q'
        // Let 's := x * b - (2 ** 256 - 1) * p'
        // Then 's - r == (2 ** 76) * q' [modulo '2 ** 256 - 1']
        // And 'q == (2 ** 180) * (s - r)' [modulo '2 ** 256 - 1']
        // Calculation modulo '2 ** 256 - 1' is safe because:
        // 'b < 2 ** 256 - 1'
        b := mulmod(
          // The subtraction is safe because the remainder is greater than or
          // equal to the second one.
          sub(mulmod(x, b, not(0)), mulmod(x, b, shl(76, 1))),
          shl(180, 1),
          not(0)
        )
      }

      // (2 ** 256) * (u(x) - v(x)) / (u(x) + v(x))
      // Since '(2 ** 254) * (a - b) - (a + b) * (a + b - 1)' is a
      // decreasing function with respect to 'x', it suffices to verify
      // that '(2 ** 254) * (a - b) - (a + b) * (a + b - 1) < 0' only for
      // 'x == 1' which is true. Hence, the requirement of 'cheapMulDiv' is
      // satisfied.
      a = FullMathLibrary.cheapMulDiv(a - b, 1 << 254, a + b) << 2;

      // Next, we compute 'f(f(f(f(f(f(f(f(f(f(f(f(f(f(a))))))))))))))'
      // where 'f(y) = (y ** 2) / (2 ** 256 - 1) ~ (y ** 2) / (2 ** 256)'
      // This is because of the '2 ** 14' term which was discussed before.
      assembly {
        a := sub(
          mulmod(a, a, not(0)), // s := a * a - q * not(0)
          mul(a, a) // r := a * a
        ) // s - r == - q * not(0) == q
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
      }

      return a;
    }
  }

  /// @notice Transforms natural logarithm of price to square root of price.
  /// @param value The input whose exponential to be calculated.
  /// @return exponentialInverse is '(2 ** 216) * exp(- x / (2 ** 60))'
  /// @return exponentialOverExp16 is '(2 ** 216) * exp(- 16 + x / (2 ** 60))'
  /// Input should be greater than 0 and less than (2 ** 64).
  function exp(
    X59 value
  ) internal pure returns (
    X216 exponentialInverse,
    X216 exponentialOverExp16
  ) {
    // The requirements of 'expInverse' are the same as the requirements here.
    uint256 a = expInverse(value);

    // Since '0 < value < 2 ** 64', we have
    // '(2 ** 256) * exp(-16) < a < (2 ** 256)', hence
    // '(2 ** 472) * exp(-16) < a * (a - 1)' and the requirements of
    // 'cheapMulDiv' are satisfied.
    //
    // Casting to 'int256' is safe because the output of 'cheapMulDiv' is
    // non-negative and it is less than 'oneX216'.
    //
    // So, we can calculate '(2 ** 472) * exp(-16) / a' as follows:
    exponentialOverExp16 = X216.wrap(int256(FullMathLibrary.cheapMulDiv(
      // (2 ** 279) * exp(-16)
      0xF1AADDD7742E56D32FB9F997447D9E6314DB84884FABAB26BF059AF9BC20B609,
      1 << 193,
      a
    )));

    // Casting to 'int256' is safe because 'a >> 40' is non-negative and it is
    // less than 'oneX216'.
    exponentialInverse = X216.wrap(int256(a >> 40));
  }

  /// @notice Transforms natural logarithm of price to square root of price.
  /// "Pade Approximant" is employed for this purpose:
  /// 'exp(- x / (2 ** 60)) ~= ((u(x) - v(x)) / (u(x) + v(x))) ** (2 ** 48)'
  /// where
  ///              x ** 2
  /// 'u(x) = 1 + --------'
  ///              3<<218
  /// and
  ///             x
  /// 'v(x) = --------'.
  ///          1<<109
  ///
  /// This formula can be reproduced via the following Mathematica command:
  /// 'PadeApproximant[Exp[- x / (2 ^ 108)], {x, 0, 2}]'.
  ///
  /// @param value The input whose exponential to be calculated.
  /// @return exponentialInverse is '(2 ** 256) * exp(- x / (2 ** 60))'
  /// Input should be positive and less than '2 * maxLogOffset'.
  function expOffset(
    X59 value
  ) internal pure returns (
    uint256 exponentialInverse
  ) {
    unchecked {
      // Casting is safe because 'value' is between '0' and '2 ** 64'.
      uint256 x = uint256(X59.unwrap(value));

      // (2 ** 255) * u(x)
      // The multiplication and addition are safe because 'x < 2 ** 64'.
      uint256 a = (((x * x) << 37) / 3) + (1 << 255);

      // (2 ** 255) * v(x)
      // The shift is safe because 'x < 2 ** 64'.
      x <<= 146;

      // The requirements of 'cheapMulDiv' are satisfied because
      // (a - x) * (2 ** 254) - (a + x) (a + x - 1) is a decreasing function
      // with respect to 'x'. Hence, we just need to verify that it is negative
      // for 'x == 1' which is true.
      a = FullMathLibrary.cheapMulDiv(a - x, 1 << 254, a + x) << 2;

      // Next, we apply the function 
      // 'f(y) = (y ** 2) / (2 ** 256 - 1) ~ (y ** 2) / (2 ** 256)', 48 times.
      // This is because of the '2 ** 48' term which was discussed before.
      assembly {
        a := sub(
          mulmod(a, a, not(0)), // s := a * a - q * not(0)
          mul(a, a) // r := a * a
        ) // s - r == - q * not(0) == q
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
        a := sub(mulmod(a, a, not(0)), mul(a, a))
      }

      return a;
    }
  }

  /// @notice Transforms natural logarithm of price in two's complement to
  /// square root of price.
  /// Input should be between 'minLogOffset' and 'maxLogOffset'.
  /// @param logOffset The input whose exponential to be calculated.
  /// @return sqrtOffset is '(2 ** 127) * exp(logOffset / (2 ** 60))'
  function logToSqrtOffset(
    X59 logOffset
  ) internal pure returns (
    X127 sqrtOffset
  ) {
    // '(2 ** 256) * exp(- (maxLogOffset - logOffset) / (2 ** 60))'
    // The requirements of 'expOffset' are satisfied here because:
    // 'minLogOffset < logOffset < maxLogOffset'
    // '0 < maxLogOffset - logOffset < 
    //      maxLogOffset - minLogOffset == 2 * maxLogOffset'.
    uint256 exponential = (maxLogOffset - logOffset).expOffset();
    // (2 ** (256 + 191)) * exp(- (maxLogOffset - logOffset) / (2 ** 60)) / 
    // ((2 ** 320) * exp(-45))
    assembly {
      // Let 's := exponential * (2 ** 191) - (2 ** 256) * p'
      // Let 'r := exponential * (2 ** 191) - floor((2 ** 320) * exp(-45)) * q'
      // Then 's - r == floor((2 ** 320) * exp(-45)) * q' [modulo '2 ** 256']
      sqrtOffset := mul(
        // s - r
        sub(
          // s
          mul(exponential, shl(191, 1)), // Because '256 + 191 - 320 == 127'
          // r
          mulmod(
            exponential,
            shl(191, 1),
            // floor((2 ** 320) * exp(-45))
            0x872DB9E8FFA9E7D41F2AAF39897B91E4002E70FCEED391471FAD73D51503772D
          )
        ),
        // modularInverse(floor((2 ** 320) * exp(-45)), 2 ** 256)
        0xCF8E41E6C4D4AA5E9CC597C10CD32EACD30C44F750A8FFDB1A8863DD8F72F0A5
      )
    }
  }
}