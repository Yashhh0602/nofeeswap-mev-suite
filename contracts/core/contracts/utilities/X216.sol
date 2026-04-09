// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {FullMathLibrary} from "./FullMath.sol";

// Type 'X216' is dedicated to integrals and sqrt of price values.
type X216 is int256;

using X216Library for X216 global;

X216 constant oneX216 = X216.wrap(1 << 216);
X216 constant zeroX216 = X216.wrap(0);
X216 constant epsilonX216 = X216.wrap(1);
// (2 ** 216) * exp(-8)
X216 constant expInverse8X216 = X216.wrap(
  0x00000000000015FC21041027ACBBFCD46780FEE71EAD23FBCB7F4A81E58767EF
);

using {equals as ==, notEquals as !=} for X216 global;
using {lessThan as <, greaterThan as >} for X216 global;
using {
  lessThanOrEqualTo as <=,
  greaterThanOrEqualTo as >=
} for X216 global;
using {add as +, sub as -} for X216 global;
using {mul as *, cheapMul as &} for X216 global;
using {mulDivByExpInv8 as %, mulDivByExpInv16 as ^} for X216 global;

function equals(
  X216 value0,
  X216 value1
) pure returns (
  bool result
) {
  assembly {
    result := eq(value0, value1)
  }
}

function notEquals(
  X216 value0,
  X216 value1
) pure returns (
  bool result
) {
  return !(value0 == value1);
}

function lessThan(
  X216 value0,
  X216 value1
) pure returns (
  bool result
) {
  assembly {
    result := slt(value0, value1)
  }
}

function greaterThan(
  X216 value0,
  X216 value1
) pure returns (
  bool result
) {
  assembly {
    result := sgt(value0, value1)
  }
}

function lessThanOrEqualTo(
  X216 value0,
  X216 value1
) pure returns (
  bool result
) {
  return !(value0 > value1);
}

function greaterThanOrEqualTo(
  X216 value0,
  X216 value1
) pure returns (
  bool result
) {
  return !(value0 < value1);
}

// Overflow/underflow should be avoided externally.
function add(
  X216 value0,
  X216 value1
) pure returns (
  X216 result
) {
  assembly {
    result := add(value0, value1)
  }
}

// Overflow/underflow should be avoided externally.
function sub(
  X216 value0,
  X216 value1
) pure returns (
  X216 result
) {
  assembly {
    result := sub(value0, value1)
  }
}

// Calculates '(value0 * value1) / (2 ** 216)'.
// Overflow/underflow should be avoided externally.
// Both values should be greater than '- 2 ** 255'.
function mul(
  X216 value0,
  X216 value1
) pure returns (
  X216 result
) {
  // Let 's := value0 * value1 - (2 ** 256 - 1) * p'
  // Let 'r := value0 * value1 - (2 ** 216) * q'
  // Then 's - r == (2 ** 216) * q' [modulo '2 ** 256 - 1']
  // Then 'q == (2 ** 40) * (s - r)' [modulo '2 ** 256 - 1']
  assembly {
    result := mulmod(
      addmod(
        // We account for the additional term '2 ** 256' in two's complement
        // representation by subtracting 'slt(value, 0)'. Because if a two's
        // complement representation 'value' correspond to a negative number,
        // we have:
        //
        // 'value - 2 ** 256 == value - 1' [modulo 2 ** 256 - 1]
        //
        // Both subtractions are safe due to the input requirement.
        mulmod(
          sub(value0, slt(value0, 0)),
          sub(value1, slt(value1, 0)),
          not(0)
        ), // s
        // Here, we do not need to account for the additional term '2 ** 256'
        // in two's complement representation because if a two's complement
        // representation 'value' is negative, we have:
        //
        // 'value - 2 ** 256 == value' [modulo 2 ** 216]
        //
        // The subtraction is safe because '2 ** 216 < 2 ** 256 - 1'.
        sub(not(0), mulmod(value0, value1, shl(216, 1))), // 0 - r
        not(0)
      ),
      shl(40, 1),
      not(0)
    )
  }
}

// Calculates '(value0 * value1) / (2 ** 216)'.
// 'value0' and 'value1' should be non-negative and less than 'oneX216'.
function cheapMul(
  X216 value0,
  X216 value1
) pure returns (
  X216 result
) {
  // Let 's := value0 * value1 - (2 ** 216 - 1) * p'
  // Let 'r := value0 * value1 - (2 ** 216) * q'
  // Then 's - r == q' [modulo '2 ** 216 - 1']
  // Because of the input requirements, 'q' does not exceed '2 ** 216 - 1'
  // which concludes that: 's - r == q'.
  assembly {
    result := addmod(
      mulmod(value0, value1, sub(shl(216, 1), 1)), // s
      // The subtraction is safe because the output of 'mulmod' does not exceed
      // '2 ** 216 - 1'.
      sub(sub(shl(216, 1), 1), mulmod(value0, value1, shl(216, 1))), // 0 - r
      sub(shl(216, 1), 1)
    )
  }
}

// Calculates '(value0 * value1) / ((2 ** 216) * exp(-8))'.
//
// The following approximation is used: '(2 ** 216) * exp(-8) ~= b / a' where
// 'a = 0xF8F6376C44' and 
// 'b = 0x1561650620DABB6A84B684E2A7E5A47CAA0A0905210083F0E3B551AABF84E9'
//
// Overflow should be avoided externally.
// Both values should be non-negative.
// 'value0' should be less than 'oneX216'.
function mulDivByExpInv8(
  X216 value0,
  X216 value1
) pure returns (
  X216 result
) {
  // Let 's := value0 * value1 * a - (2 ** 256) * p'
  // Let 'r := value0 * value1 * a - b * q'
  // Then 's - r == b * q' [modulo '2 ** 256']
  assembly {
    // Multiplication is safe because of the input requirement:
    // '0 <= value0 < oneX216'.
    result := mul(value0, 0xF8F6376C44)
    result := mul(
      // s - r
      sub(
        // s
        mul(result, value1),
        // r
        mulmod(
          result,
          value1,
          0x1561650620DABB6A84B684E2A7E5A47CAA0A0905210083F0E3B551AABF84E9 // b
        )
      ),
      // modular inverse of 'b' modulo '2 ** 256'
      0x28256938C4923FF15AB260970AA81F81C15E6F5EF3AF38DC210569E77DB19359
    )
  }
}

// Calculates '(value0 * value1) / ((2 ** 216) * exp(-16))'.
//
// The following approximation is used: '(2 ** 216) * exp(-16) ~= b / a' where
// 'a = 0x27D117D7B * 0x2EC3A856' and 
// 'b = 0xDBB82F7041B890FE67970A62A3568CC34DF9DCB17CC3A2A6A027850E7E3724F9'
//
// Overflow should be avoided externally.
// Both values should be non-negative.
// 'value0' and 'value1' should be less than 'oneX216'.
function mulDivByExpInv16(
  X216 value0,
  X216 value1
) pure returns (
  X216 result
) {
  // Let 's := value0 * value1 * a - (2 ** 256) * p'
  // Let 'r := value0 * value1 * a - b * q'
  // Then 's - r == b * q' [modulo '2 ** 256']
  assembly {
    // Both of the following multiplications are safe because of the input
    // requirements:
    // '0 <= value0 < oneX216'.
    // '0 <= value1 < oneX216'.
    value0 := mul(value0, 0x27D117D7B)
    value1 := mul(value1, 0x2EC3A856)
    result := mul(
      // s - r
      sub(
        // s
        mul(value0, value1),
        // r
        mulmod(
          value0,
          value1,
          // b
          0xDBB82F7041B890FE67970A62A3568CC34DF9DCB17CC3A2A6A027850E7E3724F9
        )
      ),
      // modular inverse of 'b' modulo '2 ** 256'
      0x7F6AF8233BADA11DD406B4458454ED9904D7AF796BE7AA4885B23E25B6985D49
    )
  }
}

function min(
  X216 value0,
  X216 value1
) pure returns (
  X216 result
) {
  return (value0 < value1) ? value0 : value1;
}

function max(
  X216 value0,
  X216 value1
) pure returns (
  X216 result
) {
  return (value0 < value1) ? value1 : value0;
}

/// @notice Returns the minimum of two unsigned fractions. '0 / 0' is 
/// interpreted as infinity. 'which == false' and 'which == true' indicate
/// '(numerator0, denominator0)' and '(numerator1, denominator1)',
/// respectively.
/// All four values should be non-negative.
/// At least one 'denominator' should be non-zero.
function minFractions(
  X216 numerator0,
  X216 denominator0,
  X216 numerator1,
  X216 denominator1
) pure returns (
  X216 numerator,
  X216 denominator,
  bool which
) {
  if (numerator0 == zeroX216) {
    if (denominator0 == zeroX216) {
      return (numerator1, denominator1, true);
    }
  }
  // Castings are safe because all four values are non-negative.
  (uint256 lsb0, uint256 msb0) = FullMathLibrary.mul512(
    uint256(X216.unwrap(numerator0)),
    uint256(X216.unwrap(denominator1))
  );
  (uint256 lsb1, uint256 msb1) = FullMathLibrary.mul512(
    uint256(X216.unwrap(numerator1)),
    uint256(X216.unwrap(denominator0))
  );
  (numerator, denominator, which) = 
    ((msb1 > msb0) || ((msb1 == msb0) && (lsb1 >= lsb0))) ? 
    (numerator0, denominator0, false) : 
    (numerator1, denominator1, true);
}

library X216Library {
  /// @notice Calculates 'value * exp(1 / (2 ** 60))'.
  /// Overflow should be avoided externally.
  /// 'value' should be non-negative.
  function multiplyByExpEpsilon(
    X216 value
  ) internal pure returns (
    X216 result
  ) {
    // Let 'a := floor((2 ** 256) * exp(-1 / (2 ** 60)))'
    // Let 'r := (2 ** 256) * value - a * q'
    // Let 'b := modularInverse(- a, 2 ** 256)'
    // Then 'q == b * r' [modulo '2 ** 256']
    assembly {
      result := mul(
        // r
        mulmod(
          value,
          // We are subtracting by 'a' because '2 ** 256' does not fit, which
          // is okay because the multiplication is done modulo 'a'.
          // 2 ** 256 - a
          0xFFFFFFFFFFFFFFF8000000000000002AAAAAAAAAAAAAAA001,
          // a
          0xFFFFFFFFFFFFFFF0000000000000007FFFFFFFFFFFFFFD555555555555555FFF
        ),
        // b
        0xAA3ED2381A8B1241D16168FD77EF989ED2B13BE12B716AA23F35ED0E39556001
      )
    }
  }

  /// @notice Calculates 'value / exp(1 / (2 ** 60))'.
  /// 'value' should be non-negative.
  function divideByExpEpsilon(
    X216 value
  ) internal pure returns (
    X216 result
  ) {
    assembly {
      // Let 'a := floor((2 ** 256 - 1) * exp(-1 / (2 ** 60)))'.
      // Let 's := value * a - q * not(0)'.
      // Let 'r := value * a'.
      // Then 's - r == - q * not(0) == q'.
      result := sub(
        // s
        mulmod(
          value,
          // a
          0xFFFFFFFFFFFFFFF0000000000000007FFFFFFFFFFFFFFD555555555555555FFE,
          not(0)
        ),
        // r
        mul(
          value,
          // a
          0xFFFFFFFFFFFFFFF0000000000000007FFFFFFFFFFFFFFD555555555555555FFE
        )
      )
    }
  }

  /// @notice Calculates '(value * numerator) / denominator'
  /// Overflow and division by zero should be avoided externally.
  /// All input values should be non-negative.
  function mulDiv(
    X216 value,
    X216 numerator,
    X216 denominator
  ) internal pure returns (
    X216 result
  ) {
    result = X216.wrap(
      // Casting is safe because overflow is handled externally.
      int256(
        // All three castings are safe due to the input requirements.
        FullMathLibrary.mulDiv(
          uint256(X216.unwrap(value)),
          uint256(X216.unwrap(numerator)),
          uint256(X216.unwrap(denominator))
        )
      )
    );
  }

  /// @notice Calculates '(value * numerator) / denominator' when 
  /// 'value * numerator < denominator * (denominator - 1)'.
  /// value should be non-negative
  function cheapMulDiv(
    X216 value,
    uint256 numerator,
    uint256 denominator
  ) internal pure returns (
    X216 result
  ) {
    result = X216.wrap(
      // Casting is safe because overflow is handled externally.
      int256(
        // The requirement of 'cheapMulDiv' is met because of the above input
        // requirement.
        FullMathLibrary.cheapMulDiv(
          // Casting is safe due to the input requirement in 'value'.
          uint256(X216.unwrap(value)),
          numerator,
          denominator
        )
      )
    );
  }
}