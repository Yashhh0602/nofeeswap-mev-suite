// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {MulDivOverflow} from "./Errors.sol";

/// @title Contains 512-bit multiplication and division functions
/// Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
/// for several functions in this library.
library FullMathLibrary {
  ///                           _____   _____   _____
  /// @notice 512-bit addition 'r1 r0 = a1 a0 + b1 b0'.
  /// Overflow should be avoided externally.
  /// @param a0 Least significant 256 bits of the first number.
  /// @param a1 Most significant 256 bits of the first number.
  /// @param b0 Least significant 256 bits of the second number.
  /// @param b1 Most significant 256 bits of the second number.
  /// @return r0 Least significant 256 bits of the addition.
  /// @return r1 Most significant 256 bits of the addition.
  function add512(
    uint256 a0,
    uint256 a1,
    uint256 b0,
    uint256 b1
  ) internal pure returns (
    uint256 r0,
    uint256 r1
  ) {
    //      s0
    //      a1 a0
    // +    b1 b0
    // -----------
    //      r1 r0
    //
    // where 's0 := lt(r0, a0)'.
    assembly {
      r0 := add(a0, b0)
      r1 := add(
        add(a1, b1),
        // 'r0 < a0' indicates that the addition 'a0 + b0' has overflowed. In
        // this case '1' needs to be added to the most significant 256 bits of
        // the output.
        lt(r0, a0)
      )
    }
  }

  ///                              _____   _____   _____
  /// @notice 512-bit subtraction 'r1 r0 = a1 a0 - b1 b0'.
  /// Underflow should be avoided externally.
  /// @param a0 Least significant 256 bits of the minuend.
  /// @param a1 Most significant 256 bits of the minuend.
  /// @param b0 Least significant 256 bits of the subtrahend.
  /// @param b1 Most significant 256 bits of the subtrahend.
  /// @return r0 Least significant 256 bits of the subtraction.
  /// @return r1 Most significant 256 bits of the subtraction.
  function sub512(
    uint256 a0,
    uint256 a1,
    uint256 b0,
    uint256 b1
  ) internal pure returns (
    uint256 r0,
    uint256 r1
  ) {
    //      a1 a0
    // -    b1 b0
    // -----------
    //      s1 r0
    // -    s0
    // -----------
    //      r1 r0
    //
    // where 's0 := lt(a0, b0)' and 's1 := (a1 - b1) % (2 ** 256)'.
    assembly {
      r0 := sub(a0, b0)
      r1 := sub(
        sub(a1, b1),
        // 'a0 < b0' indicates that the subtraction 'a0 - b0' has underflowed.
        // In this case '1' needs to be subtracted from the most significant
        // 256 bits of the output.
        lt(a0, b0)
      )
    }
  }

  ///                           ___________
  /// @notice 512-bit multiply 'prod1 prod0 = a * b'.
  /// @param a The multiplicand.
  /// @param b The multiplier.
  /// @return prod0 Least significant 256 bits of the product.
  /// @return prod1 Most significant 256 bits of the product.
  function mul512(
    uint256 a,
    uint256 b
  ) internal pure returns (
    uint256 prod0, 
    uint256 prod1
  ) {
    assembly {
      // 'mm := a * b - (2 ** 256 - 1) * q'
      let mm := mulmod(a, b, not(0))

      // 'prod0 := a * b - (2 ** 256) * p'
      prod0 := mul(a, b)

      prod1 := sub(
        // 'mm - prod0 == q'.
        sub(mm, prod0),
        //               a * b                 a * b
        // p == floor(----------) <= floor(--------------) == q
        //             2 ** 256             2 ** 256 - 1
        //
        // On the other hand, since
        //
        //      a * b          a * b                  a * b
        // -------------- - ---------- == ----------------------------- < 1
        //  2 ** 256 - 1     2 ** 256      (2 ** 256) * (2 ** 256 - 1)
        //
        // we have 'q - p <= 1'.
        //
        // Hence, either 'p == q' or 'p == q - 1'.
        //
        // If 'p == q', then 'mm - prod0 == q >= 0'.
        // If 'p == q - 1', then 'prod0 - mm == (2 ** 256) - q > 0'.
        //
        // Since 'p == q' and 'p == q - 1' are mutually exclusive, we can argue
        // that:
        //
        // 'p == q' if and only if 'mm >= prod0'.
        // 'p == q - 1' if and only if 'mm < prod0'.
        //
        // Hence, in the latter case, we should subtract by '1'.
        lt(mm, prod0)
      )
    }
  }

  /// @notice Calculates (a * b) / denominator when 
  /// 'a * b < denominator * (denominator - 1)'.
  /// @param a The multiplicand.
  /// @param b The multiplier.
  /// @param denominator The divisor.
  /// @return result '(a * b) / denominator'.
  function cheapMulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (
    uint256 result
  ) {
    assembly {
      result := sub(denominator, 1)

      // 's := a * b - q * (denominator - 1)'
      // 'r := a * b - p * denominator'
      // 's - r == p * denominator == p' [mod (denominator - 1)]
      result := addmod(
        mulmod(a, b, result),
        // This subtraction is safe because 
        // '(a * b) % denominator <= denominator - 1'.
        sub(result, mulmod(a, b, denominator)),
        result
      )
      // Notice that 'result <= denominator - 1' and because of the input
      // requirement, we have 'p = (a * b) / denominator <= denominator - 1'.
      // Hence, 'result == s - r == p'.
    }
  }

  /// @notice Calculates the modular inverse of an odd number modulo '2 ** 256'
  /// Input should be odd.
  /// @param value The number whose modular inverse to be calculated.
  /// @return inverse A 256-bit inverse satisfying
  /// 'value * inverse == 1' [mod 2 ** 256].
  function modularInverse(
    uint256 value
  ) internal pure returns (
    uint256 inverse
  ) {
    unchecked {
      // Compute the inverse by starting with a seed that is correct for four
      // bits. That is, 'value * inverse = 1' [mod 2 ** 4].
      inverse = 3 * value ^ 2;
      // Now use Newton-Raphson iterations to improve the precision. Thanks to
      // Hensel's lifting lemma, this also works in modular arithmetic,
      // doubling the correct bits in each step.
      inverse *= 2 - value * inverse;
      inverse *= 2 - value * inverse;
      inverse *= 2 - value * inverse;
      inverse *= 2 - value * inverse;
      inverse *= 2 - value * inverse;
      inverse *= 2 - value * inverse;
    }
  }

  ///                          ________
  /// @notice 768-bit multiply q2 q1 q0 = a * b * c
  /// @param a The multiplicand.
  /// @param b The first multiplier.
  /// @param c The second multiplier.
  /// @return q0 Least significant 256 bits of the product.
  /// @return q1 Middle 256 bits of the product.
  /// @return q2 Most significant 256 bits of the product.
  function mul768(
    uint256 a,
    uint256 b,
    uint256 c
  ) internal pure returns (
    uint256 q0,
    uint256 q1,
    uint256 q2
  ) {
    //          a
    // x        b
    // -----------
    //      q1 q0
    // x        c
    // -----------
    //   ss 
    //      mm q0
    // + q2 q1  0
    // -----------
    //   q2 q1 q0
    //
    uint256 mm;
    (q0, q1) = mul512(a, b);
    (q1, q2) = mul512(q1, c);
    (q0, mm) = mul512(q0, c);
    assembly {
      q1 := add(q1, mm)
      // 'q1 < mm' indicates that the above addition has overflowed (i.e.,
      // 'ss == 1') and hence, '1' needs to be added to the most significant
      // 256 bits of the product.
      q2 := add(q2, lt(q1, mm))
    }
  }

  /// @notice Calculates 
  ///
  ///         a * b * c
  /// 'min(----------------, 2 ** 216 - 1)'
  ///       d * (2 ** 143)
  ///
  /// with full precision when 'a * b * c != 0'.
  /// @param a The multiplicand.
  /// @param b The first multiplier.
  /// @param c The second multiplier.
  /// @param d The denominator.
  /// @param roundUp Whether to round up the result.
  /// @return result The output value '(a * b * c) / (d * (2 ** 143))' which is
  /// capped by '2 ** 216 - 1'.
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 c,
    uint256 d,
    bool roundUp
  ) internal pure returns (
    uint256 result
  ) {
    unchecked {
      // ________
      // q2 q1 q0 = a * b * c
      (uint256 q0, uint256 q1, uint256 q2) = mul768(a, b, c);

      // If 'q2 >= (1 << 103)', then the output is greater than or equal to
      //
      //  (2 ** 103) * (2 ** 256) * (2 ** 256)
      // -------------------------------------- == 2 ** 216
      //        (2 ** 256) * (2 ** 143)
      //
      // In this case, '2 ** 216 - 1' should be returned.
      if (q2 >= (1 << 103)) return ((1 << 216) - 1);

      // Divide the numerator by '2 ** 143'
      (q2, q1) = (
        (q2 << 113) | (q1 >> 143),
        (q1 << 113) | (q0 >> 143)
      );

      // Calculating the remainder of the numerator modulo 'd'.
      uint256 r;
      assembly {
        r := addmod(
          addmod(q1, q2, d), // (q1 + q2) % d
          mulmod(q2, not(0), d), // (q2 * (2 ** 256 - 1)) % d
          d
        ) // (q1 + q2 * (2 ** 256)) % d
      }
      
      //                         _____
      // 'r' is subtracted from 'q2 q1'.
      assembly {
        // 'q1 < r' indicates that the subtraction 'q1 - r' underflows.
        // In this case '1' needs to be subtracted from q2.
        q2 := sub(q2, lt(q1, r))
        q1 := sub(q1, r)
      }

      // Determines whether to return '2 ** 216 - 1'.
      //                _____
      // Check whether 'q2 q1 >= (2 ** 256) * d'.
      if (q2 >= d) return ((1 << 216) - 1);

      // 'd' is factored into an odd part and a power of two. 
      // Then, the numerator is divided by the power of two.
      {
        // This is the largest power of two that 'd' is divisible by.
        uint256 twos = (0 - d) & d;
        assembly {
          // Dividing 'd' by 'twos'.
          d := div(d, twos)

          //           _____
          // Dividing 'q2 q1' by 'twos' and storing the least significant '256'
          // bits in 'q1'.
          q1 := or(
            div(q1, twos), // 'q1 / (2 ** k)'
            mul(
              q2,
              add(
                div(
                  sub(0, twos), // '2 ** 256 - 2 ** k'
                  twos // '2 ** k'
                ), // '2 ** (256 - k) - 1'
                1
              ) // '(2 ** (256 - k)) % (2 ** 256)'
            ) // '(q2 * (2 ** (256 - k))) % (2 ** 256)'
          ) // '(q2 * (2 ** (256 - k)) + q1 / (2 ** k)) % (2 ** 256)'
        }
      }

      // The result can now be calculated precisely using modular inverse.
      // Let 'di := modularInverse(d)'.
      //
      //  _____
      // 'q2 q1 == d * result'
      // '(2 ** 256) * q2 + q1 == d * result'
      // 'di * (2 ** 256) * q2 + di * q1 == di * d * result'
      // 'di * (2 ** 256) * q2 + di * q1 == ((2 ** 256) * k + 1) * result'
      // 'di * q1 == result' [mod 2 ** 256]
      result = modularInverse(d) * q1;

      // If either of the remainders are positive, then the result should be
      // rounded up.
      if (roundUp) {
        if ((q0 & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) > 0 || r > 0) {
          ++result;
        }
      }

      // Determines whether to return '2 ** 216 - 1'.
      if (result >= (1 << 216)) return ((1 << 216) - 1);
    }
  }

  /// @notice Calculates
  ///
  ///      a * b * c
  /// '----------------'
  ///   d * (2 ** 111)
  ///
  /// with full precision. Overflows if the result exceeds 'type(int256).max'.
  /// 'e' must be the modular inverse of 'd / (2 ** k)' where 'k' is the
  /// largest power of two within 'd'.
  /// We should have 'a * b * c != 0' and 'd != 0'.
  /// @param a The multiplicand.
  /// @param b The first multiplier.
  /// @param c The second multiplier.
  /// @param d The denominator.
  /// @param e Modular inverse of the odd part of the denominator.
  /// @param roundUp Whether to round up the result.
  /// @return result The output value '(a * b * c) / (d * (2 ** 111))' if there
  /// is no overflow.
  /// @return overflow Whether the result overflows.
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 c,
    uint256 d,
    uint256 e,
    bool roundUp
  ) internal pure returns (
    uint256 result,
    bool overflow
  ) {
    unchecked {
      // ________
      // q2 q1 q0 = a * b * c
      (uint256 q0, uint256 q1, uint256 q2) = mul768(a, b, c);

      // If 'q2 >= (1 << 111)', then the output is greater than or equal to
      //
      //  (2 ** 111) * (2 ** 256) * (2 ** 256)
      // -------------------------------------- == 2 ** 256
      //        (2 ** 256) * (2 ** 111)
      //
      // In this case, we return overflow.
      if (q2 >= (1 << 111)) return (0, true);

      // Divide the numerator by '2 ** 111'
      (q2, q1) = (
        (q2 << 145) | (q1 >> 111),
        (q1 << 145) | (q0 >> 111)
      );

      // Calculating the remainder of the numerator modulo 'd'.
      uint256 r;
      assembly {
        r := addmod(
          addmod(q1, q2, d), // (q1 + q2) % d
          mulmod(q2, not(0), d), // (q2 * (2 ** 256 - 1)) % d
          d
        ) // (q1 + q2 * (2 ** 256)) % d
      }

      //                         _____
      // 'r' is subtracted from 'q2 q1'.
      assembly {
        // 'q1 < r' indicates that the subtraction 'q1 - r' underflowes.
        // In this case '1' needs to be subtracted from q2.
        q2 := sub(q2, lt(q1, r))
        q1 := sub(q1, r)
      }

      // Determines whether to return overflow.
      // The following equality is satisfied if and only if
      //
      //      a * b * c
      // '---------------- >= (2 ** 256)'
      //   d * (2 ** 111)
      //
      if (q2 >= d) return (0, true);

      // 'd' is factored into an odd part and a power of two and the numerator
      // is divided by the power of two.
      d = (0 - d) & d;
      assembly {
        q1 := or(
          div(q1, d), // q1 / (2 ** k)
          mul(
            q2,
            add(
              div(
                sub(0, d), // '2 ** 256 - 2 ** k'
                d // '2 ** k'
              ), // '2 ** (256 - k) - 1'
              1
            ) // '(2 ** (256 - k)) % (2 ** 256)'
          ) // '(q2 * (2 ** (256 - k))) % (2 ** 256)'
        ) // '(q2 * (2 ** (256 - k)) + q1 / (2 ** k)) % (2 ** 256)'
      }

      // The result can now be calculated precisely using 'e'.
      //  _____
      // 'q2 q1 == d * result'
      // '(2 ** 256) * q2 + q1 == d * result'
      // 'e * (2 ** 256) * q2 + e * q1 == e * d * result'
      // 'e * (2 ** 256) * q2 + e * q1 == ((2 ** 256) * k + 1) * result'
      // 'e * q1 == result' [mod 2 ** 256]
      result = e * q1;

      // If either of the remainders are positive, then the result should be
      // rounded up.
      if (roundUp) {
        if ((q0 & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFF) > 0 || r > 0) {
          ++result;
        }
      }

      // Determines whether to overflow.
      if (result >= (1 << 255)) return (0, true);
    }
  }

  /// @notice Calculates floor((a * b) / denominator) with full precision.
  /// Overflow should be avoided externally.
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (
    uint256 result
  ) {
    unchecked {
      //                   ___________
      // 512-bit multiply 'prod1 prod0 = a * b'
      // Compute the product mod 2**256 and mod 2 ** 256 - 1
      // then use the Chinese Remainder Theorem to reconstruct
      // the 512 bit result. The result is stored in two 256
      // variables such that product = prod1 * (2 ** 256) + prod0
      (uint256 prod0, uint256 prod1) = mul512(a, b);

      // Short circuit 256 by 256 division
      // This saves gas when a * b is small, at the cost of making the
      // large case a bit more expensive. Depending on your use case you
      // may want to remove this short circuit and always go through the
      // 512 bit path.
      if (prod1 == 0) {
        assembly {
          result := div(prod0, denominator)
        }
        return result;
      }
      
      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      //                                                        ___________
      // Make division exact by subtracting the remainder from 'prod1 prod0'
      // Compute remainder using mulmod
      // Note mulmod(_, _, 0) == 0
      uint256 remainder;
      assembly {
        remainder := mulmod(a, b, denominator)
      }

      // Subtract 256 bit number from 512 bit number
      assembly {
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }
      
      // Factor powers of two out of denominator
      // Compute largest power of two-divisor of denominator.
      // Always >= 1 unless the denominator is zero, then twos is zero.
      uint256 twos = (0 - denominator) & denominator;
      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }
      
      //         ___________
      // Divide 'prod1 prod0' by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;
      
      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      // If denominator is zero the inverse starts with 2
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      uint256 inv = modularInverse(denominator);
      // If denominator is zero, inv is now 128
      
      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of the denominator. This will give us the
      // correct result modulo 2**256. Since the preconditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
  }

  /// @notice Calculates ceiling((a * b) / denominator) with full precision.
  /// Overflow should be avoided externally.
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    result = mulDiv(a, b, denominator);
    // The result is incremented if 'a * b' is not divisible by 'denominator'.
    assembly {
      result := add(result, gt(mulmod(a, b, denominator), 0))
    }
  }

  /// @notice Calculates floor((a * b) / denominator) with full precision.
  /// Throws in case of overflow.
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function safeMulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    (, uint256 prod1) = mul512(a, b);
    require(prod1 < denominator, MulDivOverflow(a, b, denominator));
    result = mulDiv(a, b, denominator);
  }

  /// @notice Calculates ceiling((a * b) / denominator) with full precision.
  /// Throws in case of overflow.
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function safeMulDivRoundUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // The result is incremented if 'a * b' is not divisible by 'denominator'.
    assembly {
      result := gt(mulmod(a, b, denominator), 0)
    }
    result += safeMulDiv(a, b, denominator);
  }
}