// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {
  _spacing_,
  getCurveLength,
  setLogPriceCurrent,
  setCurveLength
} from "./Memory.sol";
import {
  Index,
  zeroIndex,
  oneIndex,
  twoIndex,
  maxCurveIndex
} from "./Index.sol";
import {PriceLibrary} from "./Price.sol";
import {
  X59,
  min,
  max,
  zeroX59,
  thirtyTwoX59,
  minLogSpacing
} from "./X59.sol";
import {
  LogSpacingIsTooSmall,
  BlankIntervalsShouldBeAvoided,
  InvalidCurveArrangement,
  CurveIndexOutOfRange
} from "./Errors.sol";

// The curve sequence comprises 64 bit logarithmic prices in the form of
//
//  '(2 ** 59) * (16 + qHistorical)'
//
// where
//
//  'qHistorical := log(pHistorical / pOffset)'.
//
// Hence, each slot of the curve sequence consists of up to four members. The
// curve sequence should have at least two members. The first and the second
// members are 'qLower' and 'qUpper' (i.e., boundaries of the active liquidity
// interval) with the order depending on the pool's history. The last member is
// always 'qCurrent'. Consider the following curve sequence:
// 
//  'q[0], q[1], q[2], ..., q[l - 1]'
//
// where 'l' is the number of members. In order for the above sequence to be
// considered valid, we should have:
//
//  'min(q[i - 1], q[i - 2]) < q[i] < max(q[i - 1], q[i - 2])'.
//
// This ordering rule is verified upon initialization of any pool and it is
// preserved by each amendment to the curve sequence.
type Curve is uint256;

using PriceLibrary for uint16;
using CurveLibrary for Curve global;

library CurveLibrary {
  /// @notice Returns the member of the curve sequence corresponding to the
  /// given index.
  ///
  /// Index out-of-range should be avoided externally.
  function member(
    Curve curve,
    Index index
  ) internal pure returns (
    X59 q
  ) {
    assembly {
      // Each member of the curve sequence is '64 bits == 8 bytes' which is why
      // we are shifting index by '3' bits (i.e., we are multiplying index by
      // '8 == 2 ** 3'). We load the memory slot whose most significant 64 bits
      // host the member that we are interested in. Then, we shift the content
      // by 192 bits to the right in order to discard the remaining bits.
      //
      //       ----------------------------------------------------
      //       | 64 bit member to be loaded | 192 additional bits |
      //       +---------------------------------------------------
      //       |
      //    pointer == curve + (index << 3)
      //
      // The addition is safe because index out-of-range is avoided externally.
      q := shr(192, mload(add(curve, shl(3, index))))
    }
  }

  /// @notice Returns the leftmost and rightmost members of the curve sequence.
  function boundaries(
    Curve curve
  ) internal pure returns (
    X59 qLower,
    X59 qUpper
  ) {
    // The first and the second members of the curve sequence are loaded.
    // Index-out-of-range is not possible because the curve sequence has at
    // least two members.
    qLower = curve.member(zeroIndex);
    qUpper = curve.member(oneIndex);

    // The two boundaries are arranged in order.
    //
    // Signed comparison is valid because both values are nonnegative and 
    // do not exceed '2 ** 64' since each one is loaded from 64 bits of memory.
    (qLower, qUpper) = (qUpper <= qLower) ? 
                       (qUpper, qLower) : 
                       (qLower, qUpper);
  }

  /// @notice Validates an initial curve provided by the pool creator.
  function validate(
    Curve curve
  ) internal pure returns (
    X59 qLower,
    X59 qUpper
  ) {
    // The first and the second members of the curve sequence to be verified
    // are loaded. The curve sequence is read from an 'uint256[]' calldata
    // array, whose length is non-zero due to the custom error
    // 'CurveLengthIsZero()'. Hence, index out of range is not possible at this
    // point.
    X59 q0 = curve.member(zeroIndex);
    X59 q1 = curve.member(oneIndex);
    
    // The output of 'member' is always non-negative and never exceeds 
    // '2 ** 64' (read from 64 bits of memory). Hence, signed comparison is
    // valid.
    (qLower, qUpper) = (q0 <= q1) ? (q0, q1) : (q1, q0);

    // Underflow is not possible due to the above rearrangement of 'qLower' and
    // 'qUpper'.
    X59 qSpacing = qUpper - qLower;

    // This is a one time calculation of 'sqrtSpacing' and 
    // 'sqrtInverseSpacing'. They will be used later for swaps.
    _spacing_.storePrice(qSpacing);

    // Since both sides are non-negative and less than '2 ** 64', all three 
    // signed comparisons are valid.
    require(qSpacing >= minLogSpacing, LogSpacingIsTooSmall(qSpacing));
    require(
      qLower > qSpacing,
      BlankIntervalsShouldBeAvoided(qLower, qUpper)
    );

    // Underflow is not possible because 'qSpacing' does not exceed '64' bits.
    // Hence, 'qSpacing <= (2 ** 64) - 1 < thirtyTwoX59'.
    require(
      qUpper < thirtyTwoX59 - qSpacing,
      BlankIntervalsShouldBeAvoided(qLower, qUpper)
    );

    Index length = twoIndex;
    while (true) {
      // This may be an out-of-range access which is intentional, because we
      // break before using 'q2' if 'length' is out of range.
      X59 q2 = curve.member(length);

      // During initialization of a pool, the provided 'curve' is always
      // followed by at least '64' bits of '0'. Hence, this indicates that we
      // have reached the end of the curve.
      if (q2 == zeroX59) break;

      // Here, we are checking the requirement:
      //
      //  'min(q0, q1) < q2 < max(q0, q1)'
      //
      // The output of 'member' is always non-negative and never exceeds 64
      // bits (loaded from 64 bits of memory). Hence signed comparisons are
      // valid.
      if ((q2 <= q0) || (q1 <= q2)) {
        if ((q2 <= q1) || (q0 <= q2)) {
          revert InvalidCurveArrangement(q0, q1, q2);
        }
      }

      // The two most recent members are shifted so that a new member can be
      // loaded as 'q2'.
      q0 = q1;
      q1 = q2;

      // This addition is safe and never exceeds the '2 ** 256 - 1' limit.
      length = length + oneIndex;
    }

    // The length of the given curve should not exceed 'maxCurveIndex'.
    require(length <= maxCurveIndex, CurveIndexOutOfRange(length));

    // 'q1' is the last valid member of the curve and therefore, it is set in
    // memory as 'qCurrent'.
    setLogPriceCurrent(q1);

    // The 'length' of the curve is stored in its appropriate memory location.
    // Due to the above check, this value is less than '2 ** 16' and can be
    // safely stored in the allocated 2 bytes of memory space.
    setCurveLength(length);
  }

  /// @notice Generates a new curve with two members and stores its memory
  /// pointer in the appropriate memory location.
  ///
  /// 'qCurrent' and 'qOther' should be positive and smaller than 
  /// 'thirtyTwoX59'.
  function newCurve(
    Curve curve,
    X59 qCurrent,
    X59 qOther
  ) internal pure {
    assembly {
      mstore(
        curve,
        or(
          // 'qOther' is written in the first place.
          shl(192, qOther),
          // 'qCurrent' is written in the second place.
          shl(128, qCurrent)
        )
      )
    }

    // The new length is stored in the allocated memory location.
    setCurveLength(twoIndex);
  }

  /// @notice Amends the curve by adding a new member.
  /// @param q is the given logarithmic price to be added to the curve
  /// sequence.
  /// 'q' must be positive and less than '2 ** 64'.
  function amend(
    Curve curve,
    X59 q
  ) internal pure {
    // The first and second members of the curve are loaded.
    // Index out of range is not possible because the curve has at least two 
    // members.
    X59 q0 = curve.member(zeroIndex);
    X59 q1 = curve.member(oneIndex);

    // If 'q' is not within the current active interval, then a new curve
    // sequence is constructed. Signed comparison is valid because 'q0', 'q1',
    // and 'q' are nonnegative and do not exceed 64 bits.
    if (q <= min(q0, q1)) {
      newCurve(curve, min(q0, q1), max(q0, q1));
      return;
    }
    if (max(q0, q1) <= q) {
      newCurve(curve, max(q0, q1), min(q0, q1));
      return;
    }

    // The length of the curve is loaded from the memory.
    Index length = getCurveLength();

    // Every member of the curve is exhausted until either the following rule
    // is violated or runs out of members:
    //
    // 'min(q[k - 1], q[k - 2]) < q[k] < max(q[k - 1], q[k - 2])'.
    //
    // Then, 'q' is written in the corresponding place and the rest of that
    // slot is cleared.
    Index index = oneIndex;
    while (true) {
      // Is 'q' between 'q0' and 'q1'? If so, we proceed forward, otherwise,
      // 'q' is written in place of 'q1' and the rest of that slot is cleared.
      // Signed comparisons are valid because 'q0', 'q1', and 'q' are
      // non-negative and do not exceed 64 bits.
      if ((q0 < q1) ? (q < q1) : (q1 < q)) {
        // This addition is safe and never exceeds the '2 ** 256 - 1' limit.
        index = index + oneIndex;
        q0 = q1;
        if (index < length) {
          // Index out-of-range is not possible due to the above check.
          q1 = curve.member(index);
        } else {
          break;
        }
      } else {
        break;
      }
    }

    // 'q' is added to the end.
    // This is not an out-of-range addition because one additional slot is
    // always reserved for the amendment of the curve. A maximum of 2
    // amendments occur per swap.
    assembly {
      mstore(add(curve, shl(3, index)), shl(192, q))
    }

    // 'index + oneIndex' must not exceed 'maxIndex'.
    require(index < maxCurveIndex, CurveIndexOutOfRange(index));

    // Lastly, 'curveLength' is updated.
    // Due to the above check, this value is less than '2 ** 16' and can be
    // safely stored in the allocated 2 bytes of memory space.
    setCurveLength(index + oneIndex);
  }
}