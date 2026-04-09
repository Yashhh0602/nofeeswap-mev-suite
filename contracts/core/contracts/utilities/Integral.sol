// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {zeroX15, X15} from "./X15.sol";
import {twoX59, X59} from "./X59.sol";
import {X74} from "./X74.sol";
import {zeroX216, X216} from "./X216.sol";
import {PriceLibrary} from "./Price.sol";

// (2 ** 240) * exp(-8)
uint256 constant EXP_INV_8_X240 = 
  0x00000015FC21041027ACBBFCD46780FEE71EAD23FBCB7F4A81E58767EF801A32;

library IntegralLibrary {
  using PriceLibrary for uint256;

  /// @notice Let 'l' and 'u' denote the logarithmic prices whose offset binary
  /// 'X59' representation is stored in the pointers 'price0' and 'price1',
  /// respectively. In other words, define:
  ///
  ///               price0.log()                         price1.log()
  ///  l := - 16 + --------------    and    u := - 16 + --------------
  ///                 2 ** 59                              2 ** 59
  /// -------------------------------------------------------------------------
  /// If 'left == false' this function transforms the given integral
  ///
  ///             / u
  ///            |      -h/2
  ///  input :=  |     e     f(h - l) dh
  ///            |
  ///           / l
  ///
  /// to the following:
  ///
  ///     / u                                     / u
  ///    |      +h/2                 +(l + u)/2  |      -h/2
  ///    |     e     f(u - h) dh == e            |     e     f(h - l) dh ==
  ///    |                                       |
  ///   / l                                     / l
  ///
  ///  exp(+ l / 2) * exp(+ u / 2) * input ==
  ///
  ///  (2**216) * exp(-8+l/2) * (2**216) * exp(-8+u/2) * input
  /// --------------------------------------------------------- == 
  ///                     (2 ** 432) * exp(-16)
  ///
  ///  (2**216) * exp(-16+(l+16)/2) * (2**216) * exp(-16+(u+16)/2) * input
  /// --------------------------------------------------------------------- == 
  ///                       (2 ** 432) * exp(-16)
  ///
  ///  price0.sqrt(true) * price1.sqrt(true) * input
  /// -----------------------------------------------
  ///             (2 ** 432) * exp(-16)
  ///
  /// -------------------------------------------------------------------------
  /// If 'left == true' the integral
  ///
  ///             / u
  ///            |      +h/2
  ///  input :=  |     e     f(u - h) dh
  ///            |
  ///           / l
  ///
  /// is transformed to 
  ///
  ///     / u                                     / u
  ///    |      -h/2                 -(l + u)/2  |      +h/2
  ///    |     e     f(h - l) dh == e            |     e     f(u - h) dh == 
  ///    |                                       |
  ///   / l                                     / l
  ///
  ///  exp(- l / 2) * exp(- u / 2) * input ==
  ///
  ///  (2**216) * exp(-8-l/2) * (2**216) * exp(-8-u/2) * input
  /// --------------------------------------------------------- == 
  ///                     (2 ** 432) * exp(-16)
  ///
  ///  (2**216) * exp(-(l+16)/2) * (2**216) * exp(-(u+16)/2) * input
  /// --------------------------------------------------------------- == 
  ///                      (2 ** 432) * exp(-16)
  ///
  ///  price0.sqrt(false) * price1.sqrt(false) * input
  /// -------------------------------------------------
  ///              (2 ** 432) * exp(-16)
  ///
  /// -------------------------------------------------------------------------
  /// The following approximation is used:
  ///
  ///            1                   b * c * d
  /// ----------------------- ~ --------------------
  ///  (2 ** 432) * exp(-16)     (2 ** 256 - 1) * a
  ///
  /// where
  ///
  /// 'a == 0x5BC2A24E50A66D39C35A9132C33F2FC50A1B99389D5455E78A7CF7EF8894E4CD'
  /// 'b == 0x4BC3287B', 'c == 0xCEF6AE8685', 'd == 0xCB21E499'.
  ///
  /// 'integralInput' should be non-negative and less than 'oneX216'.
  function shift(
    X216 integralInput,
    uint256 price0,
    uint256 price1,
    bool left
  ) internal pure returns (
    X216 shiftedIntegral
  ) {
    // This boolean determines whether 'sqrt' or 'sqrtInverse' is returned by
    // 'PriceLibrary'.
    bool right = !left;
    X216 p0 = price0.sqrt(right);
    X216 p1 = price1.sqrt(right);
    assembly {
      // All three multiplications are safe because 'integralInput', 'p0' and
      // 'p1' are read from 216 bits of memory and the outputs fit within 256
      // bits.
      integralInput := mul(0x4BC3287B, integralInput) // b * integralInput
      p0 := mul(0xCEF6AE8685, p0) // c * price0.sqrt(right)
      p1 := mul(0xCB21E499, p1) // d * price1.sqrt(right)

      // Next, we calculate
      // 'p0 * p1 / a == c * d * price0.sqrt(right) * price1.sqrt(right) / a'.
      // Let 's := p0 * p1 - (2 ** 256) * q'.
      // Let 'r := p0 * p1 - a * p'.
      // Then 's - r == a * p' [mod 2 ** 256]
      //
      // The output does not exceed 249 bits because both 'price0.sqrt(right)'
      // and 'price1.sqrt(right)' are less than 'oneX216' and:
      // 'c * d * (1 << 216) * (1 << 216) / a < 2 ** 249'.
      shiftedIntegral := mul(
        // s - r
        sub(
          // s
          mul(p0, p1),
          // r
          mulmod(
            p0,
            p1,
            // a
            0x5BC2A24E50A66D39C35A9132C33F2FC50A1B99389D5455E78A7CF7EF8894E4CD
          )
        ),
        // modularInverse(a, 2 ** 256)
        0x7082326D62B7EF4D06861F13C21DD192C8044B19A121205B7DC63C2642B5A805
      )

      // Multiplication by 'integralInput / (2 ** 256 - 1)'
      shiftedIntegral := sub(
        // r == x * y - (2 ** 256 - 1) * q
        mulmod(shiftedIntegral, integralInput, not(0)),
        // s == x * y - (2 ** 256) * p
        mul(shiftedIntegral, integralInput)
      )
    }
    return shiftedIntegral;
  }

  /// @notice Returns an integral value given its memory pointer.
  /// Notice that due to an 'exp(-8) / 2' factor, integral values are always
  /// less than 'oneX216'. This is because:
  ///
  ///               / +16                         / +16
  ///   exp(-8)    |      +h/2        exp(-8)    |      -h/2
  ///  --------- x |     e     dh == --------- x |     e     dh < 1
  ///      2       |                     2       |
  ///             / -16                         / -16
  ///
  function integral(
    uint256 pointer
  ) internal pure returns (
    X216 value
  ) {
    assembly {
      // The slot whose most significant 160 bits host the integral value is
      // loaded and then the least significant 40 bits are discarded via a 40
      // bit shift to the right.
      value := shr(40, mload(pointer))
    }
  }

  /// @notice Writes an integral value in a memory pointer.
  /// 'pointer' should not be less than '32'.
  /// 'integralValue' should be less than 'oneX216'.
  function setIntegral(
    uint256 pointer,
    X216 integralValue
  ) internal pure {
    assembly {
      // The preceding slot is cached so that it can be restored after we place
      // the integral value in the appropriate memory location.
      // The subtraction is safe because of the input requirement on 'pointer'.
      let precedingPointer := sub(pointer, 32)
      let precedingSlot := mload(precedingPointer)

      // We move 5 bytes backward (40 bits) to point to the slot whose least
      // significant 216 bits are supposed to host 'integralValue'.
      // '216 - 256' bits == '-40' bits == '-5' bytes.
      mstore(sub(pointer, 5), integralValue)

      // The preceding slot is restored.
      mstore(precedingPointer, precedingSlot)
    }
  }

  /// @notice Adds a given increment to an integral stored in the given memory 
  /// pointer.
  /// Overflow should be avoided externally.
  function incrementIntegral(
    uint256 pointer,
    X216 increment
  ) internal pure {
    assembly {
      // The increment is shifted to the left by 40 bits to be added to the
      // integral value in memory. In other words, the following slot is
      // loaded:
      //
      //   +-------------------+----------------------------------------------+
      //   | 216 bit integral  | 40 additional bits that should remain intact |
      //   +-------------------+----------------------------------------------+
      //   |
      // pointer
      //
      // and added to:
      //
      //   +-------------------+----------------------------------------------+
      //   | 216 bit increment |          40 additional zero bits             |
      //   +-------------------+----------------------------------------------+
      //
      // The result is then stored in memory using the same pointer.
      // The addition is safe because overflow is handled externally.
      mstore(pointer, add(mload(pointer), shl(40, increment)))
    }
  }

  /// @notice Subtracts a given decrement from an integral stored in the given
  /// memory pointer.
  /// Underflow should be avoided externally.
  function decrementIntegral(
    uint256 pointer,
    X216 decrement
  ) internal pure {
    assembly {
      // The decrement is shifted to the left by 40 bits to be subtracted from
      // the integral value in memory. In other words, the following slot is
      // loaded:
      //
      //   --------------------------------------------------------------------
      //   | 216 bit integral  | 40 additional bits that should remain intact |
      //   +-------------------------------------------------------------------
      //   |
      // pointer
      //
      // and the following value is subtracted from the loaded slot:
      //
      //   --------------------------------------------------------------------
      //   | 216 bit increment |          40 additional zero bits             |
      //   --------------------------------------------------------------------
      //
      // The result is then stored in memory using the same pointer.
      // The subtraction is safe because underflow is handled externally.
      mstore(pointer, sub(mload(pointer), shl(40, decrement)))
    }
  }

  /// @notice Let 'q' denote the logarithmic price whose offset binary 'X59'
  /// representation is stored in the pointer 'targetPrice'. In other words,
  /// define:
  ///
  ///               targetPrice.log()
  ///  q := - 16 + -------------------
  ///                   2 ** 59
  ///
  /// Additionally, let '(b0, c0)' and '(b1, c1)' represent the segment
  /// coordinates to be loaded from the memory via the pointers
  /// 'coordinates0 := segmentCoordinates' and
  /// 'coordinates1 := segmentCoordinates + 64', respectively. More precisely:
  ///
  ///                coordinates0.log()           coordinates0.height()
  ///  b0 := - 16 + --------------------,  c0 := -----------------------
  ///                     2 ** 59                        2 ** 15
  ///
  ///                coordinates1.log()           coordinates1.height()
  ///  b1 := - 16 + --------------------,  c1 := -----------------------
  ///                     2 ** 59                        2 ** 15
  ///
  /// -------------------------------------------------------------------------
  /// This function evaluates the following and returns the resulting
  /// value in 'X216' representation:
  ///
  ///                                      c1 - c0
  ///  (2 ** 216) * (exp(-8) / 2) * (c0 + --------- (q - b0))
  ///                                      b1 - b0
  ///
  /// We should have: 'c0 <= c1 <= oneX15'.
  /// We should have: 'min(b0, b1) <= q <= max(b0, b1) < thirtyTwoX59'.
  /// We should have: 'b0 != b1'.
  function evaluate(
    uint256 segmentCoordinates,
    uint256 targetPrice
  ) internal pure returns (
    X216 value
  ) {
    // Loads the segment coordinates from the memory. '(b0, c0)' are loaded
    // using 'pointer = segmentCoordinates' and '(b1, c1)' are loaded using
    // 'pointer = segmentCoordinates + 64'.
    (X59 b0, X59 b1, X15 c0, X15 c1) = segmentCoordinates.segment();

    // In this case, because of the input requirement 'c0 <= c1', we have 
    // 'c0 == c1 == zeroX15' and the output should be 'zeroX216'.
    if (c1 == zeroX15) return value;

    // If 'c1 == c0', we multiply 'c0' by 'exp(-8) / 2' and return.
    // The multiplication is safe because 'c0' is a 16 bit (read from memory) 
    // non-negative value and 'EXP_INV_8_X240' is 229 bits.
    if (c1 == c0) {
      assembly {
        // The last '40' bits are discarded because
        // '216 - 240 - 15 - 1 == - 40', where '216' appears because the output
        // should follow the 'X216' representation, '240' cancels the 
        // '1 << 240' factor in 'EXP_INV_8_X240', '15' cancels the 'X15'
        // representation of 'c0', and '1' accounts for the denominator of
        // 'exp(-8) / 2'.
        value := shr(40, mul(c0, EXP_INV_8_X240))
      }
      return value;
    }

    // If 'b1 == q', the solution is equal to:
    //
    //                                      c1 - c0
    //  (2 ** 216) * (exp(-8) / 2) * (c0 + --------- (b1 - b0)) ==
    //                                      b1 - b0
    //
    //  (2 ** 216) * (exp(-8) / 2) * c1
    //
    // Hence, we just multiply 'c1' by 'exp(-8) / 2' and return.
    // The multiplication is safe because 'c1' is a 16 bit (read from memory) 
    // non-negative value and 'EXP_INV_8_X240' is 229 bits.
    if (b1 == targetPrice.log()) {
      assembly {
        // As argued above, the last '40' bits are discarded because
        // '216 - 240 - 15 - 1 == - 40', where '216' appears because the output
        // should follow the 'X216' representation, '240' cancels the 
        // '1 << 240' factor in 'EXP_INV_8_X240', '15' cancels the 'X15'
        // representation of 'c1', and '1' accounts for the denominator of
        // 'exp(-8) / 2'.
        value := shr(40, mul(c1, EXP_INV_8_X240))
      }
      return value;
    }

    // If 'b1 < b0', the subtraction 'b0 - b1' is safe and the subtraction
    // 'b0 - targetPrice.log()' is also safe due to the input requirement:
    // 'q <= max(b0, b1)'.
    //
    // If 'b1 >= b0', the subtraction 'b1 - b0' is safe and the subtraction
    // 'targetPrice.log() - b0' is also safe due to the input requirement:
    // 'min(b0, b1) <= q'.
    //
    // The subtraction 'c1 - c0' is safe because of the input requirement
    // 'c0 <= c1'. The multiplication is also safe because '|q - b0|' and
    // 'c1 - c0' are both non-negative and occupy up to '64' and '16' bits,
    // respectively.
    //
    // The signed comparison of 'b0' and 'b1' is valid because both are 64 bit
    // (read from memory) non-negative values.
    (X59 db, X74 numerator) = (b1 < b0) ? 
      (b0 - b1, (b0 - targetPrice.log()).times(c1 - c0)) : 
      (b1 - b0, (targetPrice.log() - b0).times(c1 - c0));

    // Next, we calculate 
    // '(exp(-8) / 2) * (c0 + |q - b0| * (c1 - c0) / db)'
    // where 'db = |b1 - b0|'.
    assembly {
      // The 320 bit product 'EXP_INV_8_X240 * numerator' is calculated first, 
      // where 'numerator = |q - b0| * (c1 - c0)'.

      // The least significant 192-bits of the product 
      // 'EXP_INV_8_X240 * numerator'. This multiplication is in 'X314'
      // representation because '240 + 74 == 314'.
      let lsbitsX314 := mulmod(EXP_INV_8_X240, numerator, shl(192, 1))

      // The most significant 128-bits of the product 
      // 'EXP_INV_8_X240 * numerator'.
      // 'r == EXP_INV_8_X240 * numerator - (2 ** 192 - 1) * q'
      // 'lsbitsX314 == EXP_INV_8_X240 * numerator - (2 ** 192) * p'
      // 'r - lsbitsX314 == p' [mod 2 ** 192 - 1]
      let msbitsX314 := addmod(
        // r
        mulmod(EXP_INV_8_X240, numerator, sub(shl(192, 1), 1)),
        // 0 - lsbitsX314 [mod 2 ** 192 - 1]
        // The subtraction is safe because 'lsbitsX314' does not exceed 192
        // bits.
        sub(sub(shl(192, 1), 1), lsbitsX314),
        sub(shl(192, 1), 1)
      )

      // Here, we perform the division by 'db' via the simple long division
      // algorithm, i.e., '(2 ** 192) * msbitsX314 + lsbitsX314' divided by
      // 'db' becomes:
      //
      //                 q1X255         q0X255
      //      ---------------------------------
      // db   |      msbitsX314     lsbitsX314
      //      |
      //            q1X255 * db 
      //        -------------------------------
      //        msbitsX314 % db     lsbitsX314
      //
      //                           q0X255 * db
      //        -------------------------------
      //                                     r
      //
      // where 
      // 'r := (msbitsX314 * (2 ** 192) + lsbitsX314) % db'
      // 'q1X255 := msbitsX314 / db'
      // 'q0X255 := ((msbits % db) * (2 ** 192) + lsbitsX314) / db'
      let quotientX255 := add(
        // First, we calculate 'q1X255 << 192' which the more significant part
        // of the quotient.
        //
        // The division 'msbitsX314 / db' is safe because 'db != 0' due to an
        // input requirement.
        //
        // The 192-bit shift does not overflow because '|q - b0| <= db' and
        // therefore:
        // 
        // 'msbitsX314 / db =
        //  ((EXP_INV_8_X240 * |q - b0| * (c1 - c0)) >> 192) / db <= 
        //  ((EXP_INV_8_X240 * db * (c1 - c0)) >> 192) / db == 
        //  ((EXP_INV_8_X240 * (c1 - c0)) >> 192) <
        //  (2 ** (229 + 16)) >> 192 == 2 ** 53'
        //
        // Hence, 'msbitsX314 / db' does not exceed '53' bits.
        shl(192, div(msbitsX314, db)),
        // Then, we calculate 'q0X255' which the least significant 192 bits of
        // the quotientX255.
        //
        // The division by 'db' is safe because 'db != 0' due to an input
        // requirement.
        div(
          // The addition is safe because 'lsbitsX314' and 'db' do not exceed
          // '192' and '64 'bits, respectively.
          add(
            // The shift does not overflow because 
            // 'msbitsX314 % db < db < 2 ** 64'.
            shl(192, mod(msbitsX314, db)),
            lsbitsX314
          ),
          db
        )
      )

      // Lastly, we need to add '(exp(-8) / 2) * c0'.
      //
      // This addition is also safe because:
      //
      //        c1 - c0                    c1 - c0
      //  c0 + --------- (q - b0) <= c0 + --------- (b1 - b0) <= c1
      //        b1 - b0                    b1 - b0
      //
      // Hence the output of 'add' is bounded by 'mul(c1, EXP_INV_8_X240)'
      // which does not overflow because 'c1 <= oneX15' and 'EXP_INV_8_X240'
      // has 229 bits.
      //
      // As argued above, the last '40' bits are discarded because
      // '216 - 240 - 15 - 1 == - 40', where '216' appears because the output
      // should follow the 'X216' representation, '240' cancels the 
      // '1 << 240' factor in 'EXP_INV_8_X240', '15' cancels the 'X15'
      // representation of 'c0' and 'c1', and '1' accounts for the denominator
      // of 'exp(-8) / 2'.
      value := shr(40, add(mul(c0, EXP_INV_8_X240), quotientX255))
    }
  }

  /// @notice Let 'f' and 't' denote the logPrice values whose offset binary
  /// 'X59' representation is stored in the pointers 'from' and 'to',
  /// respectively. In other words, define:
  ///
  ///               from.log()                          to.log()
  ///  f := - 16 + ------------    and    t := - 16 + ------------
  ///                2 ** 59                            2 ** 59
  ///
  /// Additionally, let '(b0, c0)' and '(b1, c1)' represent the segment
  /// coordinates to be loaded from the memory via the pointers
  /// 'coordinates0' and 'coordinates1 := coordinates0 + 64', respectively.
  /// More precisely:
  ///
  ///               coordinates0.log()           coordinates0.height()
  /// b0 := - 16 + --------------------,  c0 := -----------------------
  ///                    2 ** 59                        2 ** 15
  ///
  ///               coordinates1.log()           coordinates1.height()
  /// b1 := - 16 + --------------------,  c1 := -----------------------
  ///                    2 ** 59                        2 ** 15
  ///
  /// -------------------------------------------------------------------------
  /// If 'f < t' this function calculates:
  ///
  ///                                / t
  ///                               |     -h/2         c1 - c0
  ///  (2 ** 216) * (exp(-8) / 2) * |    e      (c0 + --------- (h - b0)) dh
  ///                               |                  b1 - b0
  ///                              / f
  ///
  /// In this case, the following closed-form formula is used:
  ///
  ///  (2 ** 216) * exp(-8) * (
  ///                                          c1 - c0
  ///    c0 * (exp(- f / 2) - exp(- t / 2)) + --------- * 
  ///                                          b1 - b0
  ///
  ///    ((f - b0 + 2) * exp(- f / 2) - (t - b0 + 2) * exp(- t / 2))
  ///  )
  ///
  ///  == c0 * ((2 ** 216) * exp(- 8 - f / 2) - (2 ** 216) * exp(- 8 - t / 2))
  ///
  ///       c1 - c0
  ///    + --------- * ((f - b0 + 2) * (2 ** 216) * exp(- 8 - f / 2) - 
  ///       b1 - b0
  ///                   (t - b0 + 2) * (2 ** 216) * exp(- 8 - t / 2))
  ///
  ///  == c0 * (from.sqrt(false) - to.sqrt(false))
  ///
  ///       c1 - c0
  ///    + --------- * ((f - b0 + 2) * from.sqrt(false) - 
  ///       b1 - b0
  ///                   (t - b0 + 2) * to.sqrt(false))
  ///
  /// -------------------------------------------------------------------------
  /// If 't < f' this function calculates:
  ///
  ///                                / f
  ///                               |     +h/2         c1 - c0
  ///  (2 ** 216) * (exp(-8) / 2) * |    e      (c0 + --------- (b0 - h)) dh
  ///                               |                  b0 - b1
  ///                              / t
  ///
  /// In this case, the following closed-form formula is used:
  ///
  ///  (2 ** 216) * exp(-8) * (
  ///                                          c1 - c0
  ///    c0 * (exp(+ f / 2) - exp(+ t / 2)) + --------- * 
  ///                                          b0 - b1
  ///
  ///    ((b0 - f + 2) * exp(+ f / 2) - (b0 - t + 2) * exp(+ t / 2))
  ///  )
  ///
  ///  == c0 * ((2 ** 216) * exp(- 8 + f / 2) - (2 ** 216) * exp(- 8 + t / 2))
  ///
  ///       c1 - c0
  ///    + --------- * ((b0 - f + 2) * (2 ** 216) * exp(- 8 + f / 2) - 
  ///       b0 - b1
  ///                   (b0 - t + 2) * (2 ** 216) * exp(- 8 + t / 2))
  ///
  ///  == c0 * (from.sqrt(true) - to.sqrt(true))
  ///
  ///       c1 - c0
  ///    + --------- * ((b0 - f + 2) * from.sqrt(true) - 
  ///       b0 - b1
  ///                   (b0 - t + 2) * to.sqrt(true))
  ///
  /// -------------------------------------------------------------------------
  /// We should have: 'c0 <= c1 <= oneX15'.
  ///
  /// If 't < f' then we should have: 'b1 <= t < f <= b0 < thirtyTwoX59'
  ///
  /// If 'f < t' then we should have: 'b0 <= f < t <= b1 < thirtyTwoX59'
  ///
  function outgoing(
    uint256 coordinate0,
    uint256 from,
    uint256 to
  ) internal pure returns (
    X216 result
  ) {
    // The following values will be defined and loaded from the memory.
    X15 c0;
    X216 sqrtFrom;
    X216 sqrtTo;
    X59 db;
    X74 from_times_dc;
    X74 to_times_dc;
    {
      // First, we load the two integral boundaries.
      X59 logFrom = from.log();
      X59 logTo = to.log();

      // The special case of 'logFrom == logTo' is handled here. In this case
      // the result is equal to 'zeroX216'.
      if (logFrom == logTo) return zeroX216;

      // The pointer to the second price is derived.
      uint256 coordinate1;
      unchecked {
        coordinate1 = coordinate0 + 64;
      }

      // 'c0' is loaded from the memory.
      c0 = coordinate0.height();

      // 'c1' is loaded from the memory and temporarily placed in 'dc'.
      X15 dc = coordinate1.height();

      // In this case, because of the input requirement 'c0 <= c1', we have 
      // 'c0 == c1 == zeroX15' and the output should be 'zeroX216'.
      if (dc == zeroX15) return zeroX216;

      // 'dc' represents the vertical length of the segment that characterizes
      // the function that we are integrating. The subtraction is safe due to
      // the input requirement 'c0 <= c1'.
      dc = dc - c0;

      // As explained above, depending on the value of 'left', we either use
      // '(from.sqrt(false), to.sqrt(false))' or
      // '(from.sqrt(true), to.sqrt(true))'.
      bool left = logTo < logFrom;
      sqrtFrom = from.sqrt(left);
      sqrtTo = to.sqrt(left);

      // If 'c1 == c0' we simply return
      // 'c0 * (from.sqrt(false) - to.sqrt(false)) / (2 ** 15)'
      // for 'left == false' or 
      // 'c0 * (from.sqrt(true) - to.sqrt(true)) / (2 ** 15)'
      // for 'left == true'.
      //
      // The subtraction is safe, because if 'f <= t' then
      // 'left == false' and we have 'exp(- 8 - t / 2) <= exp(-8 - f / 2)'
      // which concludes 'to.sqrt(left) <= from.sqrt(left)'.
      //
      // On the other hand, if 't < f' then 'left == true' and we have
      // 'exp(- 8 + t / 2) < exp(- 8 + f / 2)' which concludes
      // 'to.sqrt(left) < from.sqrt(left)'.
      //
      // The multiplication is safe because 'c0' and 'sqrtFrom - sqrtTo' are
      // nonnegative values which do not exceed '16' and '216' bits, 
      // respectively.
      //
      // We shift the result by 15 bits to the right to cancel the 'X15'
      // representation of 'c0'.
      if (dc == zeroX15) {
        assembly {
          result := shr(15, mul(c0, sub(sqrtFrom, sqrtTo)))
        }
        return result;
      }

      // 'b0' is loaded from memory and temporarily placed in 'db'.
      db = coordinate0.log();

      // Next, if 'left == true', we calculate 
      // '(b0 - logFrom + 2) * dc' and '(b0 - logTo + 2) * dc'. 
      // If 'left == false', we calculate 
      // '(logFrom - b0 + 2) * dc' and '(logTo - b0 + 2) * dc'.
      //
      // The subtractions are safe due to the input requirements. Because if
      // 'left == false', we have 'b0 <= logFrom' and 'b0 <= logTo'.
      // Additionally, if 'left == true', we have 'logFrom <= b0' and
      // 'logTo <= b0'.
      //
      // The additions with 'twoX59' are safe, because in all cases the two
      // terms that are being added are less than '2 ** 64'.
      //
      // The multiplications are safe, because in all cases the inputs are
      // non-negative and the output does not exceed 81 bits.
      (from_times_dc, to_times_dc) = left ? 
        ((db - logFrom + twoX59).times(dc), (db - logTo + twoX59).times(dc)) : 
        ((logFrom - db + twoX59).times(dc), (logTo - db + twoX59).times(dc));
      
      // 'db' represents the horizontal length of the segment that
      // characterizes the function that we are integrating. The subtractions
      // are safe due to the input requirements. Because if 'left == false',
      // we have 'b0 <= b1' and if 'left == true', we have 'b0 >= b1'.
      db = left ? db - coordinate1.log() : coordinate1.log() - db;
    }

    assembly {
      // The least significant 192-bits of the product 
      // 'from_times_dc * sqrtFrom' which is in 'X290' representation because
      // 'from_times_dc' is 'X74' and 'sqrtFrom' is 'X216'.
      let lsbits0X290 := mulmod(from_times_dc, sqrtFrom, shl(192, 1))

      // The least significant 192-bits of the product 
      // 'to_times_dc * sqrtTo' which is in 'X290' representation because
      // 'to_times_dc' is 'X74' and 'sqrtTo' is 'X216'.
      let lsbits1X290 := mulmod(to_times_dc, sqrtTo, shl(192, 1))

      // Next, we calculate 
      // 'sqrtFrom * from_times_dc - sqrtTo * to_times_dc'.
      //
      // Next, we are going to prove that the subtraction is safe:
      //
      // If 'f < t', We are calculating
      //
      // y := ((f - b0 + 2) * exp(- f / 2) - (t - b0 + 2) * exp(- t / 2)) * dc
      //
      // In this case, because '(q + 2) * exp(-q / 2)' is a decreasing function
      // within the interval '(0, +oo)', the expression
      // 
      // (f - b0 + 2) * exp(-(f - b0) / 2) - (t - b0 + 2) * exp(-(t - b0) / 2)
      //
      // is non-negative which concludes that 'y' is also non-negative. Hence,
      // the subtraction is safe.
      //
      // If 't < f', We are calculating
      //
      // y := ((b0 - f + 2) * exp(+ f / 2) - (b0 - t + 2) * exp(+ t / 2)) * dc
      //
      // In this case, because '(q + 2) * exp(-q / 2)' is a decreasing function
      // within the interval '(0, +oo)', the expression
      // 
      // (b0 - f + 2) * exp(-(b0 - f) / 2) - (b0 - t + 2) * exp(-(b0 - t) / 2)
      //
      // is non-negative which concludes that 'y' is also non-negative. Hence,
      // the subtraction is safe.

      // The least significant 192-bits of 
      // 'sqrtFrom * from_times_dc - sqrtTo * to_times_dc' which may underflow
      // in which case '1' will be subtracted from 'msbitsX290'.
      // The subtraction is safe because 'lsbits1X290' is less than '1 << 192'.
      let lsbitsX290 := addmod(
        lsbits0X290,
        sub(shl(192, 1), lsbits1X290),
        shl(192, 1)
      )

      // The most significant 128-bits of 
      // 'sqrtFrom * from_times_dc - sqrtTo * to_times_dc'
      let msbitsX290 := sub(
        // 'x == to_times_dc * sqrtTo - (2 ** 192) * a'
        // 'y == from_times_dc * sqrtFrom - (2 ** 192 - 1) * b'
        // 'z == from_times_dc * sqrtFrom - (2 ** 192) * c'
        // 'w == to_times_dc * sqrtTo - (2 ** 192 - 1) * d'
        //
        // 'x + y - z - w == b - d' [mod 2 ** 192]
        sub(
          add(
            lsbits1X290,
            mulmod(from_times_dc, sqrtFrom, sub(shl(192, 1), 1))
          ),
          add(
            lsbits0X290,
            mulmod(to_times_dc, sqrtTo, sub(shl(192, 1), 1))
          )
        ),
        // 'lsbits0X290 < lsbits1X290' indicates that 'lsbits' has underflowed.
        // In this case, we need to subtract 'msbitsX290' by '1'.
        lt(lsbits0X290, lsbits1X290)
      )

      // Next, we calculate:
      //
      // '(from_times_dc * sqrtFrom - to_times_dc * sqrtTo) / db'
      //
      // Here, we perform the division by 'db' via the simple long division
      //                   _____________________
      // algorithm, i.e., 'msbitsX290 lsbitsX290' divided by 'db' becomes:
      //
      //                 q1X231           q0X231
      //      -----------------------------------
      // db   |      msbitsX290       lsbitsX290
      //      |
      //            q1X231 * db 
      //        ---------------------------------
      //        msbitsX290 % db       lsbitsX290
      //
      //                             q0X231 * db
      //        ---------------------------------
      //                                       r
      //
      // where
      // 'r := (msbitsX290 * (2 ** 192) + lsbitsX290) % db'
      // 'q1X231 := msbitsX290 / db'
      // 'q0X231 := ((msbitsX290 % db) * (2 ** 192) + lsbitsX290) / db'
      //
      // Next, we will prove that 'msbitsX290 / db < 2 ** 50' which will be
      // useful later. If 'f < t' (the other side can be argued similarly), we
      // have:
      //
      //  (2 ** 192) * msbitsX290 + lsbitsX290
      // -------------------------------------- ==
      //      (2 ** (290 - 59)) * (b1 - b0)
      //
      //   (2 ** 192) * msbitsX290 + lsbitsX290
      //  --------------------------------------
      //                2 ** 290
      // ---------------------------------------- ==
      //                b1 - b0
      //               ---------
      //                2 ** 59
      //
      //  ((f - b0 + 2) * exp(- f / 2) - (t - b0 + 2) * exp(- t / 2)) * dc
      // ------------------------------------------------------------------ <=
      //                              b1 - b0
      //
      //  ((f - b0 + 2) * exp(- f / 2) - (t - b0 + 2) * exp(- t / 2)) * dc
      // ------------------------------------------------------------------ ==
      //                               t - f
      //
      //  g(t - b0) - g(f - b0)
      // ----------------------- * exp(- b0 / 2) * dc ==
      //   (t - b0) - (f - b0)
      //
      //  g'(z) * exp(- b0 / 2) * dc <= exp(-1) * exp(- b0 / 2) * dc < 
      //  exp(7) < 2 ** 11
      //
      // where 'g(q) := - (q + 2) * exp(-q / 2)' and 'z' is some arbitrary 
      // point within the interval '(0, +oo)' whose existence is guaranteed
      // thanks to the mean value theorem.
      //
      // Due to the above argument, we have 'msbitsX290 / db <= 2 ** 50'.
      let quotientX231 := add(
        // First, we calculate 'q1X231 << 192' which the more significant part
        // of the quotientX231.
        //
        // The division 'msbits / db' is safe because 'db != 0' due to an input
        // requirement.
        //
        // The 192 bit shift to the left is safe because we have proven that
        // 'msbitsX290 / db <= 2 ** 50'.
        shl(192, div(msbitsX290, db)),
        // Then, we calculate 'q0X231' which is the least significant 192 bits
        // of 'quotientX231'.
        //
        // The division by 'db' is safe because 'db != 0' due to an input
        // requirement.
        div(
          add(
            // The shift does not overflow because 
            // 'msbitsX290 % db < db < 2 ** 64'.
            shl(192, mod(msbitsX290, db)),
            lsbitsX290
          ),
          db
        )
      )

      // Lastly, the following value is calculated:
      //
      // 'c0 * (from.sqrt(left) - to.sqrt(left)) + quotient'
      //
      // The addition does not overflow and does not exceed '216' bits because
      // the output integral is equal to:
      //
      //                                / t
      //                               |     -h/2         c1 - c0
      //  (2 ** 216) * (exp(-8) / 2) * |    e      (c0 + --------- (h - b0)) dh
      //                               |                  b1 - b0
      //                              / f
      //
      //                                   / 16
      //                                  |     -h/2
      //  <= (2 ** 216) * (exp(-8) / 2) * |    e      dh < (2 ** 216) - 1
      //                                  |
      //                                 / -16
      //
      // The subtraction is safe, because if 'f <= t' then
      // 'left == false' and we have 'exp(- 8 - t / 2) <= exp(-8 - f / 2)'
      // which concludes 'to.sqrt(left) <= from.sqrt(left)'
      //
      // On the other hand, if 't < f' then 'left == true' and we have
      // 'exp(- 8 + t / 2) < exp(- 8 + f / 2)' which concludes
      // 'to.sqrt(left) < from.sqrt(left)'.
      //
      // The multiplication is safe because 'c0' and 'sqrtFrom - sqrtTo' are
      // nonnegative values which do not exceed '16' and '216' bits, 
      // respectively.
      //
      // We shift the result by 15 bits to the right to cancel the 'X15'
      // representation of 'c0' and 'dc'.
      result := shr(15, add(mul(c0, sub(sqrtFrom, sqrtTo)), quotientX231))
    }
  }

  /// @notice Let 'f' and 't' denote the logPrice values whose offset binary
  /// 'X59' representation is stored in the pointers 'from' and 'to',
  /// respectively. In other words, define:
  ///
  ///               from.log()                          to.log()
  ///  f := - 16 + ------------    and    t := - 16 + ------------
  ///                2 ** 59                            2 ** 59
  ///
  /// Let '(b0, c0)' and '(b1, c1)' represent the segment coordinates to be
  /// loaded from the memory using 'coordinate0' and 'coordinate0 + 64',
  /// respectively.
  ///
  /// Additionally, let '(b0, c0)' and '(b1, c1)' represent the segment
  /// coordinates to be loaded from the memory via the pointers
  /// 'coordinates0' and 'coordinates1 := coordinates0 + 64', respectively.
  /// More precisely:
  ///
  ///               coordinates0.log()           coordinates0.height()
  /// b0 := - 16 + --------------------,  c0 := -----------------------
  ///                    2 ** 59                        2 ** 15
  ///
  ///               coordinates1.log()           coordinates1.height()
  /// b1 := - 16 + --------------------,  c1 := -----------------------
  ///                    2 ** 59                        2 ** 15
  ///
  /// -------------------------------------------------------------------------
  /// If 'f < t' this function calculates:
  ///
  ///                                / t
  ///                               |     +h/2         c1 - c0
  ///  (2 ** 216) * (exp(-8) / 2) * |    e      (c0 + --------- (h - b0)) dh
  ///                               |                  b1 - b0
  ///                              / f
  ///
  /// In this case, the following closed-form formula is used:
  ///
  ///  (2 ** 216) * exp(-8) * (
  ///                                          c1 - c0
  ///    c1 * (exp(+ t / 2) - exp(+ f / 2)) - --------- * 
  ///                                          b1 - b0
  ///
  ///    ((b1 - t + 2) * exp(+ t / 2) - (b1 - f + 2) * exp(+ f / 2))
  ///  )
  ///
  ///  == c1 * ((2 ** 216) * exp(- 8 + t / 2) - (2 ** 216) * exp(- 8 + f / 2))
  ///
  ///       c1 - c0
  ///    - --------- * ((b1 - t + 2) * (2 ** 216) * exp(- 8 + t / 2) - 
  ///       b1 - b0
  ///                   (b1 - f + 2) * (2 ** 216) * exp(- 8 + f / 2))
  ///
  ///  == c1 * (to.sqrt(true) - from.sqrt(true))
  ///
  ///       c1 - c0
  ///    - --------- * ((b1 - t + 2) * to.sqrt(true) - 
  ///       b1 - b0
  ///                   (b1 - f + 2) * from.sqrt(true))
  ///
  /// -------------------------------------------------------------------------
  /// If 't < f' this function calculates:
  ///
  ///                                / f
  ///                               |     -h/2         c1 - c0
  ///  (2 ** 216) * (exp(-8) / 2) * |    e      (c0 + --------- (b0 - h)) dh
  ///                               |                  b0 - b1
  ///                              / t
  ///
  /// In this case, the following closed-form formula is used:
  ///
  ///  (2 ** 216) * exp(-8) * (
  ///                                          c1 - c0
  ///    c1 * (exp(- t / 2) - exp(- f / 2)) - --------- * 
  ///                                          b0 - b1
  ///
  ///    ((t - b1 + 2) * exp(- t / 2) - (f - b1 + 2) * exp(- f / 2))
  ///  )
  ///
  ///  == c1 * ((2 ** 216) * exp(- 8 - t / 2) - (2 ** 216) * exp(- 8 - f / 2))
  ///
  ///       c1 - c0
  ///    - --------- * ((t - b1 + 2) * (2 ** 216) * exp(- 8 - t / 2) - 
  ///       b0 - b1
  ///                   (f - b1 + 2) * (2 ** 216) * exp(- 8 - f / 2))
  ///
  ///  == c1 * (to.sqrt(false) - from.sqrt(false))
  ///
  ///       c1 - c0
  ///    - --------- * ((t - b1 + 2) * to.sqrt(false) - 
  ///       b0 - b1
  ///                   (f - b1 + 2) * from.sqrt(false))
  ///
  /// -------------------------------------------------------------------------
  /// We should have: 'c0 <= c1 <= oneX15'.
  ///
  /// If 't < f' then we should have: 'b1 <= t < f <= b0 < thirtyTwoX59'
  ///
  /// If 'f < t' then we should have: 'b0 <= f < t <= b1 < thirtyTwoX59'
  ///
  function incoming(
    uint256 coordinate0,
    uint256 from,
    uint256 to
  ) internal pure returns (
    X216 result
  ) {
    // The following values will be defined and loaded from the memory.
    X15 c1;
    X216 sqrtFrom;
    X216 sqrtTo;
    X59 db;
    X74 from_times_dc;
    X74 to_times_dc;
    {
      // First, we load the integral boundaries.
      X59 logFrom = from.log();
      X59 logTo = to.log();

      // The special case of 'logFrom == logTo' is handled here. In this case
      // the result is equal to 'zeroX216'.
      if (logFrom == logTo) return zeroX216;

      {
        // The pointer to the second price is derived.
        uint256 coordinate1;
        unchecked {
          coordinate1 = coordinate0 + 64;
        }

        // 'c1' is loaded from the memory.
        c1 = coordinate1.height();

        // In this case, because of the input requirement 'c0 <= c1', we have 
        // 'c0 == c1 == zeroX15' and the output should be 'zeroX216'.
        if (c1 == zeroX15) return result;

        // 'b1' is loaded from the memory and temporarily placed in 'db'.
        db = coordinate1.log();
      }

      // As explained above, depending on the value of 'left', we either use
      // '(from.sqrt(false), to.sqrt(false))' or
      // '(from.sqrt(true), to.sqrt(true))'.
      bool left = logTo < logFrom;
      sqrtFrom = from.sqrt(!left);
      sqrtTo = to.sqrt(!left);

      {
        // 'c0' is loaded from the memory and temporarily placed in 'dc'.
        X15 dc = coordinate0.height();

        // If 'c1 == c0' we simply return
        // 'c1 * (to.sqrt(true) - from.sqrt(true)) / (2 ** 15)'
        // for 'left == false' or 
        // 'c1 * (to.sqrt(false) - from.sqrt(false)) / (2 ** 15)'
        // for 'left == true'.
        //
        // The subtraction is safe, because if 'f <= t' then
        // 'left == false' and we have 'exp(- 8 + f / 2) <= exp(-8 + t / 2)'
        // which concludes 'from.sqrt(!left) <= to.sqrt(!left)'
        //
        // On the other hand, if 't < f' then 'left == true' and we have
        // 'exp(- 8 - f / 2) < exp(- 8 - t / 2)' which concludes
        // 'from.sqrt(!left) < to.sqrt(!left)'.
        //
        // The multiplication is safe because 'c1' and 'sqrtTo - sqrtFrom' are
        // nonnegative values which do not exceed '16' and '216' bits, 
        // respectively.
        //
        // We shift the result by 15 bits to the right to cancel the 'X15'
        // representation of 'c1'.
        if (c1 == dc) {
          assembly {
            result := shr(15, mul(c1, sub(sqrtTo, sqrtFrom)))
          }
          return result;
        }

        // 'dc' represents the vertical length of the segment that
        // characterizes the function that we are integrating. The subtraction
        // is safe due to the input requirement 'c0 <= c1'.
        dc = c1 - dc;

        // Next, if 'left == true', we calculate 
        // '(logFrom - b1 + 2) * dc' and '(logTo - b1 + 2) * dc'. 
        // If 'left == false', we calculate 
        // '(b1 - logFrom + 2) * dc' and '(b1 - logTo + 2) * dc'.
        //
        // The subtractions are safe due to the input requirements. Because if
        // 'left == false', we have 'logFrom <= b1' and 'logTo <= b1'.
        // Additionally, if 'left == true', we have 'b1 <= logFrom' and
        // 'b1 <= logTo'.
        //
        // The additions with 'twoX59' are safe, because in all cases the two
        // terms that are being added are less than '2 ** 64'.
        //
        // The multiplications are safe, because in all cases the inputs are
        // non-negative and the output does not exceed 81 bits.
        (from_times_dc, to_times_dc) = left ? (
          (logFrom - db + twoX59).times(dc),
          (logTo - db + twoX59).times(dc)
        ) : (
          (db - logFrom + twoX59).times(dc),
          (db - logTo + twoX59).times(dc)
        );
      }

      // 'db' represents the horizontal length of the segment that
      // characterizes the function that we are integrating. The subtractions
      // are safe due to the input requirements. Because if 'left == false',
      // we have 'b0 <= b1' and if 'left == true', we have 'b0 >= b1'.
      db = left ? coordinate0.log() - db : db - coordinate0.log();
    }

    assembly {
      // The least significant 192-bits of the product 
      // 'from_times_dc * sqrtFrom' which is in 'X290' representation because
      // 'from_times_dc' is 'X74' and 'sqrtFrom' is 'X216'.
      let lsbits0X290 := mulmod(from_times_dc, sqrtFrom, shl(192, 1))

      // The least significant 192-bits of the product 
      // 'to_times_dc * sqrtTo' which is in 'X290' representation because
      // 'to_times_dc' is 'X74' and 'sqrtTo' is 'X216'.
      let lsbits1X290 := mulmod(to_times_dc, sqrtTo, shl(192, 1))

      // Next, we calculate 
      // 'sqrtTo * to_times_dc - sqrtFrom * from_times_dc'.
      //
      // Next, we are going to prove that the subtraction is safe:
      //
      // If 'f < t', We are calculating
      //
      // y := ((b1 - t + 2) * exp(+ t / 2) - (b1 - f + 2) * exp(+ f / 2)) * dc
      //
      // In this case, because '(q + 2) * exp(-q / 2)' is a decreasing function
      // within the interval '(0, +oo)', the expression
      // 
      // (b1 - t + 2) * exp(-(b1 - t) / 2) - (b1 - f + 2) * exp(-(b1 - f) / 2)
      //
      // is non-negative which concludes that 'y' is also non-negative. Hence,
      // the subtraction is safe.
      //
      // If 't < f', We are calculating
      //
      // y := ((t - b1 + 2) * exp(- t / 2) - (f - b1 + 2) * exp(- f / 2)) * dc
      //
      // In this case, because '(q + 2) * exp(-q / 2)' is a decreasing function
      // within the interval '(0, +oo)', the expression
      // 
      // (t - b1 + 2) * exp(-(t - b1) / 2) - (f - b1 + 2) * exp(-(f - b1) / 2)
      //
      // is non-negative which concludes that 'y' is also non-negative. Hence,
      // the subtraction is safe.

      // The least significant 192-bits of 
      // 'sqrtTo * to_times_dc - sqrtFrom * from_times_dc' which may underflow
      // in which case '1' will be subtracted from 'msbitsX290'.
      // The subtraction is safe because 'lsbits0X290' is less than '1 << 192'.
      let lsbitsX290 := addmod(
        lsbits1X290,
        sub(shl(192, 1), lsbits0X290),
        shl(192, 1)
      )

      // The most significant 128-bits of 
      // 'sqrtTo * to_times_dc - sqrtFrom * from_times_dc'.
      let msbitsX290 := sub(
        // 'x == from_times_dc * sqrtFrom - (2 ** 192) * a'
        // 'y == to_times_dc * sqrtTo - (2 ** 192 - 1) * b'
        // 'z == to_times_dc * sqrtTo - (2 ** 192) * c'
        // 'w == from_times_dc * sqrtFrom - (2 ** 192 - 1) * d'
        //
        // 'x + y - z - w == b - d (mod 2 ** 192)'
        sub(
          add(
            lsbits0X290,
            mulmod(to_times_dc, sqrtTo, sub(shl(192, 1), 1))
          ),
          add(
            lsbits1X290,
            mulmod(from_times_dc, sqrtFrom, sub(shl(192, 1), 1))
          )
        ),
        // 'lsbits1X290 < lsbits0X290' indicates that 'lsbits' has underflowed.
        // In this case, we need to subtract 'msbitsX290' by '1'.
        lt(lsbits1X290, lsbits0X290)
      )

      // Next, we calculate:
      //
      // '(sqrtTo * to_times_dc - sqrtFrom * from_times_dc) / db'
      //
      // Here, we perform the division by 'db' via the simple long division
      //                   _____________________
      // algorithm, i.e., 'msbitsX290 lsbitsX290' divided by 'db' becomes:
      //
      //                 q1X231           q0X231
      //      -----------------------------------
      // db   |      msbitsX290       lsbitsX290
      //      |
      //            q1X231 * db 
      //        ---------------------------------
      //        msbitsX290 % db       lsbitsX290
      //
      //                             q0X231 * db
      //        ---------------------------------
      //                                       r
      //
      // where
      // 'r := (msbitsX290 * (2 ** 192) + lsbitsX290) % db'
      // 'q1X231 := msbitsX290 / db'
      // 'q0X231 := ((msbitsX290 % db) * (2 ** 192) + lsbitsX290) / db'
      //
      // Next, we will prove that 'msbitsX290 / db < 2 ** 50' which will be
      // useful later. If 'f < t' (the other side can be argued similarly), we
      // have:
      //
      //  (2 ** 192) * msbitsX290 + lsbitsX290
      // -------------------------------------- ==
      //      (2 ** (290 - 59)) * (b1 - b0)
      //
      //   (2 ** 192) * msbitsX290 + lsbitsX290
      //  --------------------------------------
      //                2 ** 290
      // ---------------------------------------- ==
      //                b1 - b0
      //               ---------
      //                2 ** 59
      //
      //  ((b1 - t + 2) * exp(+ t / 2) - (b1 - f + 2) * exp(+ f / 2)) * dc
      // ------------------------------------------------------------------ <=
      //                              b1 - b0
      //
      //  ((b1 - t + 2) * exp(+ t / 2) - (b1 - f + 2) * exp(+ f / 2)) * dc
      // ------------------------------------------------------------------ ==
      //                               t - f
      //
      //  g(b1 - t) - g(b1 - f)
      // ----------------------- * exp(+ b1 / 2) * dc ==
      //   (b1 - t) - (b1 - f)
      //
      //  g'(z) * exp(+ b1 / 2) * dc <= exp(-1) * exp(8) * dc < exp(7)
      //  < 2 ** 11
      //
      // where 'g(q) := - (q + 2) * exp(-q / 2)' and 'z' is some arbitrary 
      // point within the interval '(0, +oo)' whose existence is guaranteed
      // thanks to the mean value theorem.
      //
      // Due to the above argument, we have 'msbitsX290 / db <= 2 ** 50'.
      let quotientX231 := add(
        // First, we calculate 'q1X231 << 192' which the more significant part
        // of the quotientX231.
        //
        // The division 'msbits / db' is safe because 'db != 0' due to an input
        // requirement.
        //
        // The 192 bit shift to the left is safe because we have proven that
        // 'msbitsX290 / db <= 2 ** 50'.
        shl(192, div(msbitsX290, db)),
        // Then, we calculate 'q0X231' which is the least significant 192 bits
        // of 'quotientX231'.
        //
        // The division by 'db' is safe because 'db != 0' due to an input
        // requirement.
        div(
          add(
            // The shift does not overflow because 
            // 'msbitsX290 % db < db < 2 ** 64'.
            shl(192, mod(msbitsX290, db)),
            lsbitsX290
          ),
          db
        )
      )

      // Lastly, the following value is calculated:
      //
      // 'c1 * (to.sqrt(!left) - from.sqrt(!left)) - quotient'
      //
      // The inner subtraction is safe, because if 'f <= t' then
      // 'left == false' and we have 'exp(- 8 + f / 2) <= exp(- 8 + t / 2)'
      // which concludes 'from.sqrt(!left) <= to.sqrt(!left)'
      //
      // On the other hand, if 't < f' then 'left == true' and we have
      // 'exp(- 8 - f / 2) < exp(- 8 - t / 2)' which concludes
      // 'from.sqrt(!left) < to.sqrt(!left)'.
      //
      // The multiplication is safe because 'c1' and 'sqrtTo - sqrtFrom' are
      // nonnegative values which do not exceed '16' and '216' bits, 
      // respectively.
      //
      // The outer subtraction is safe because the output integral is
      // non-negative. Underflow due to rounding error is also impossible
      // because the lowest possible value for an incoming integral
      // corresponds to 
      //
      // 'c0 := 0'
      // 'c1 := 1 / (2 ** 15)'
      // 'b0 := - 16 + 1 / (2 ** 59)'
      // 'b1 := + 16 - 1 / (2 ** 59)'
      // 'f := - 16 + 1 / (2 ** 59)'
      // 't := - 16 + 2 / (2 ** 59)'
      //
      // leading to
      //                               / t
      //                              |     +h/2         c1 - c0
      // (2 ** 216) * (exp(-8) / 2) * |    e      (c0 + --------- (h - b0)) dh
      //                              |                  b1 - b0
      //                             / f
      //
      // ~= 8502917395809738
      //
      // which does not underflow.
      //
      // We shift the result by 15 bits to the right to cancel the 'X15'
      // representation of 'c1' and 'dc'.
      result := shr(15, sub(mul(c1, sub(sqrtTo, sqrtFrom)), quotientX231))
    }
  }
}