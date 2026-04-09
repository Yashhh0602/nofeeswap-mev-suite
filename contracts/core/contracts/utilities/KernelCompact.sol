// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {
  _spacing_,
  getKernel,
  getKernelLength,
  setKernelLength
} from "./Memory.sol";
import {
  Index,
  zeroIndex,
  oneIndex,
  twoIndex,
  maxKernelIndex
} from "./Index.sol";
import {X15, oneX15} from "./X15.sol";
import {X59, zeroX59, minLogStep} from "./X59.sol";
import {X216} from "./X216.sol";
import {PriceLibrary} from "./Price.sol";
import {Kernel} from "./Kernel.sol";
import {
  SecondHorizontalCoordinateIsZero,
  NonMonotonicHorizontalCoordinates,
  NonMonotonicVerticalCoordinates,
  RepetitiveKernelPoints,
  SlopeTooHigh,
  HorizontalCoordinatesMayNotExceedLogSpacing,
  RepetitiveHorizontalCoordinates,
  RepetitiveVerticalCoordinates,
  KernelIndexOutOfRange,
  LastVerticalCoordinateMismatch
} from "./Errors.sol";

using PriceLibrary for uint16;
using PriceLibrary for uint256;

// For every pool, the kernel function 'k : [0, qSpacing] -> [0, 1]' represents
// a monotonically non-decreasing piece-wise linear function. Let 'm + 1'
// denote the number of these breakpoints. For every integer '0 <= i <= m' the
// i-th breakpoint of the kernel represents the pair '(b[i], c[i])' where
//
//  '0 == b[0] <  b[1] <= b[2] <= ... <= b[m - 1] <  b[m] == qSpacing',
//  '0 == c[0] <= c[1] <= c[2] <= ... <= c[m - 1] <= c[m] == 1'.
// 
// In its compact form, each breakpoint occupies 10 bytes, in which:
//
//  - the 'X15' representation of '(2 ** 15) * c[i]' occupies 2 bytes,
//
//  - the 'X59' representation of '(2 ** 59) * b[i]' occupies 8 bytes,
//
// The above-mentioned layout is illustrated as follows:
//
//          A 80 bit kernel breakpoint
//  +--------+--------------------------------+
//  | 2 byte |             8 byte             |
//  +--------+--------------------------------+
//  |        |
//  |         \
//  |          (2 ** 59) * b[i]
//   \
//    (2 ** 15) * c[i]
//
// These 80 bit breakpoints are compactly encoded in a 'uint256[]' array and
// given as input to 'initialize' or 'modifyKernel' methods.
//
// The expanded form of kernel is calculated based on the given compact form
// and stored on the storage smart contract.
type KernelCompact is uint256;

using KernelCompactLibrary for KernelCompact global;

library KernelCompactLibrary {
  /// @notice Returns the breakpoint components corresponding to the given
  /// index of a compact kernel.
  ///
  /// Index out of range should be avoided externally.
  function member(
    KernelCompact kernelCompact,
    Index index
  ) internal pure returns (
    X15 height,
    X59 logShift
  ) {
    // If 'index' is equal to 0, then this function should return 
    // '(zeroX15, zeroX59)', because the first member of 'kernelCompact' is
    // always '(zeroX15, zeroX59)'.
    if (index > zeroIndex) {
      uint256 pointer;
      assembly {
        // Each member of 'kernelCompact' is 10 bytes. 2 bytes for the 'height'
        // and 8 bytes for the 'logShift'.
        // '8 == 10 - 2'. We move 2 bytes forward because 'priceLibrary' uses
        // the following layout to read prices from the memory:
        //
        //          A 80 bit kernel breakpoint
        //
        //              pointer
        //            /
        //  +--------+--------------------------------+
        //  | 2 byte |             8 byte             |
        //  +--------+--------------------------------+
        //  |        |
        //  |         \
        //  |          (2 ** 59) * b[i]
        //   \
        //    (2 ** 15) * c[i]
        //
        // In other words, the pointer to be used to access the 'height' and 
        // 'logShift' should point to the end of 'height' and the beginning of
        // 'logShift'. Since 'height' occupies 2 bytes, we move 2 bytes forward
        // to point to the end of it. We move 10 bytes backward because the
        // first breakpoint which is supposed to be '(zeroX15, zeroX59)' is 
        // always omitted.
        // The addition and multiplication are safe because index out-of-range
        // is handled externally.
        pointer := add(kernelCompact, sub(mul(10, index), 8))
      }
      // Now that we have the pointer, we can load both the 'height' and
      // 'logShift' from the memory.
      height = pointer.height();
      logShift = pointer.log();
    }
  }

  /// @notice Sqrt values are calculated and the kernel array is constructed.
  function expand(
    KernelCompact kernelCompact
  ) internal pure {
    Index i = oneIndex;
    uint256 pointer;
    // This is the place in memory where the expanded kernel is stored.
    Kernel kernel = getKernel();
    assembly {
      // We move '62 = 8 + 27 + 27' bytes backward. When we later move 64 bytes
      // forward, the pointer would point to 'kernel + 2' which follows this
      // layout:
      //
      //        pointer to the first price
      //      /
      //     |        A 512 bit kernel breakpoint
      //  +--+--------+-----------------+-----------------+
      //  |  | 8 byte |     27 byte     |     27 byte     |
      //  +--+--------+-----------------+-----------------+
      //  |  |        |                 |
      //  |  |        |                  \
      //  |  |        |                   (2 ** 216) * exp(- 16 + b[i] / 2)
      //  |  |         \
      //  |  |          (2 ** 216) * exp(- b[i] / 2)
      //  |   \
      //  |    (2 ** 59) * b[i]
      //   \
      //    (2 ** 15) * c[i]
      //
      pointer := sub(kernel, 62)
    }
    Index length = getKernelLength();
    while (i < length) {
      // We move 64 bytes forward because each member of kernel occupies 
      // exactly 64 bytes.
      // The addition is safe because we do not go beyond the length of the
      // kernel which is calculated prior to calling this method by the
      // function 'validate'.
      unchecked {
        pointer = pointer + 64;
      }

      // 'height' and 'logShift' are loaded first.
      // Index-out-of-range is not possible, because we do not go beyond the 
      // length of the kernel which is calculated prior to calling this method
      // by the function 'validate'.
      (X15 c_i, X59 b_i) = kernelCompact.member(i);

      // The requirements of 'exp' are met because 'kernelCompact' is validated
      // prior to calling this function. The custom errors
      // 'SecondHorizontalCoordinateIsZero' and 
      // 'NonMonotonicHorizontalCoordinates' safeguard against any horizontal
      // coordinate being zero.
      // On the other hand, the custom errors 'BlankIntervalsShouldBeAvoided'
      // and 'HorizontalCoordinatesMayNotExceedLogSpacing' safeguard against
      // any horizontal coordinate exceeding '2 ** 64 - 1'.
      (X216 iSqrt, X216 iSqrtInverse) = b_i.exp();

      // The requirements of 'storePrice' are met because the custom errors
      // 'LastVerticalCoordinateMismatch' and 'NonMonotonicVerticalCoordinates'
      // safeguard against any vertical coordinate exceeding 'oneX15'. As 
      // discussed above, all horizontal coordinates are between '0' and 
      // '2 ** 64'. The outputs of the function 'exp()' never exceed 'oneX216'
      // because both 'exp(- x / (2 ** 60))' and  'exp(-16 + x / (2 ** 60))'
      // are positive and smaller than '1'. Lastly, since 'kernel' always
      // appears after the end of static parameters, (i.e., 
      // 'kernel >= _endOfStaticParams_') the value of 'pointer' is not less
      // than 32.
      pointer.storePrice(c_i, b_i, iSqrt, iSqrtInverse);

      // The addition is safe because we do not go beyond the length of the
      // kernel which is calculated prior to calling this method by the
      // function 'validate'.
      i = i + oneIndex;
    }
  }

  /// @notice Validates a given kernel for compliance.
  function validate(
    KernelCompact kernelCompact
  ) internal pure {
    X59 qSpacing = _spacing_.log();

    // The length of any given 'kernelCompact' is at least 2. The first member
    // is '(zeroX15, zeroX59)' which is omitted. The last member is
    // '(oneX15, qSpacing)'.
    Index length = twoIndex;

    // 'i', 'j', and 'k' are indices representing consecutive members of
    // the given 'kernelCompact', respectively.
    Index i = zeroIndex;
    Index j = oneIndex;

    // The following two coordinates are zero by default to represent the first
    // member '(zeroX15, zeroX59)'.
    X15 c_i;
    X59 b_i;

    // The second member of 'kernelCompact' is loaded next. 
    (X15 c_j, X59 b_j) = kernelCompact.member(j);

    // The third member of 'kernelCompact' is loaded next. 'k' may be an out of
    // range index in which case its values will not be used. This is
    // intentional, because the line 'if (b_j == qSpacing) break;' appears
    // prior to using 'k'.
    (X15 c_k, X59 b_k) = kernelCompact.member(length);

    // The second horizontal coordinate may not be zero. Remember that the
    // first member of the kernel is '(zeroX15, zeroX59)'. If the second
    // horizontal coordinate is 'zeroX59', it means that we have a vertical
    // jump at the origin. This is not permitted because it would limit
    // liquidity growth.
    require(b_j != zeroX59, SecondHorizontalCoordinateIsZero());

    // A loop over every member of 'kernelCompact'.
    while (true) {
      // The horizontal coordinates should be monotonically nondecreasing. This
      // is because we are inputting breakpoints from the left to the right and
      // from the bottom to the top.
      require(b_i <= b_j, NonMonotonicHorizontalCoordinates(b_i, b_j));

      // The vertical coordinates should be monotonically nondecreasing. This
      // is because we are inputting breakpoints from the left to the right and
      // from the bottom to the top.
      require(
        c_i <= c_j,
        NonMonotonicVerticalCoordinates(c_i, c_j)
      );

      // Repetitive breakpoints should be avoided.
      require(
        (b_i != b_j) || (c_i != c_j),
        RepetitiveKernelPoints(c_i, b_i)
      );

      // If 'b_i == b_j', we have a vertical jump (discontinuity) which is
      // permitted. If 'c_i == c_j', we have a flat segment which is
      // also permitted. However, in case of a sloped segment, 'b_j - b_i'
      // may not be less than 'minLogStep' which corresponds to a price
      // movement by a factor of approximately '1.0000000075'.
      require(
        (b_i == b_j) || (c_i == c_j) || (b_j - b_i >= minLogStep),
        SlopeTooHigh(b_i, b_j)
      );

      // The kernel is characterized via a sequence of monotonically 
      // non-decreasing horizontal coordinates from 'zeroX59' to 'qSpacing'
      // and a sequence of monotonically non-decreasing vertical coordinates
      // from 'zeroX15' to 'oneX15'. Hence, no horizontal coordinate may exceed
      // 'qSpacing'.
      require(
        b_j <= qSpacing,
        HorizontalCoordinatesMayNotExceedLogSpacing(b_j, qSpacing)
      );

      // 'b_j == qSpacing' indicates that we have reached the end of
      // 'kernelCompact'. This is because the last member is supposed to be
      // '(oneX15, qSpacing)' and the horizontal coordinates for all other
      // members should be less than 'qSpacing'.
      if (b_j == qSpacing) break;

      // A horizontal coordinate cannot be repeated twice. It may be repeated
      // once, which would indicate a vertical jump (kernel discontinuity).
      require(
        (b_i != b_j) || (b_j != b_k),
        RepetitiveHorizontalCoordinates(b_i)
      );

      // A vertical coordinate cannot be repeated twice. It may be repeated
      // once, which would indicate a flat segment.
      require(
        (c_i != c_j) || (c_j != c_k),
        RepetitiveVerticalCoordinates(c_i)
      );

      // We substitute 'i' with 'j' to move one step forward.
      i = j;
      c_i = c_j;
      b_i = b_j;

      // We substitute 'j' with 'k' to move one step forward.
      j = length;
      c_j = c_k;
      b_j = b_k;

      // 'length' is incremented. The addition is safe because of the following
      // check.
      length = length + oneIndex;

      // The deployment code for static parameters and kernel reserves 2 bytes
      // for the byte count of the content to be deployed. Because of this
      // limit, we should have:
      //
      // '_endOfStaticParams_ - _staticParams_ + 64*(length - 1) + 1 < 2 ** 16'
      //
      // where
      //
      // - '64' accounts for the number of bytes that each member of kernel
      // occupies.
      // - '-1' accounts for the omitted origin point.
      // - '+1' accounts for a '00' padding byte.
      //
      // Hence:
      //
      // 'length <= 1 + (
      //    ((2 ** 16 - 1) - 1 - _endOfStaticParams_ + _staticParams_) / 64
      // ) == 1020'
      //
      require(length <= maxKernelIndex, KernelIndexOutOfRange(length));

      // 'k' may be an out of range index in which case its values will not be 
      // used. This is intentional, because the line
      // 'if (b_j == qSpacing) break;' appears prior to using 'k'.
      (c_k, b_k) = kernelCompact.member(length);
    }

    // The last member of 'kernelCompact' should be '(oneX15, qSpacing)'.
    // The loop is already broken at 'b_j == qSpacing' and now we check the
    // vertical coordinate.
    require(c_j == oneX15, LastVerticalCoordinateMismatch(c_j));

    // The length for 'kernel' is set in memory. Due to the above check, this
    // value does not exceed 'maxKernelIndex' and can be safely stored in the
    // allocated 2 bytes of memory.
    setKernelLength(length);
  }
}