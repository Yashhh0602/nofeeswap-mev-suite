// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {
  _begin_,
  _target_,
  _total0_,
  _total1_,
  _currentToTarget_,
  _incomingCurrentToTarget_,
  _overshoot_,
  _end_,
  _forward1_,
  _current_,
  _currentToOvershoot_,
  _endOfStaticParams_,
  _pointers_,
  setIntegral0,
  setIntegral1,
  getZeroForOne,
  getIntegralLimit,
  setZeroForOne,
  setIntegralLimit,
  getCurve,
  getCurveLength,
  setCurve,
  setCurveLength,
  getKernel,
  getKernelLength,
  setKernel,
  setKernelLength,
  setFreeMemoryPointer,
  getLogPriceLimitOffsetted,
  setLogPriceLimitOffsetted,
  getLogPriceLimitOffsettedWithinInterval
} from "../contracts/utilities/Memory.sol";
import {X15, zeroX15, oneX15} from "../contracts/utilities/X15.sol";
import {
  X59,
  epsilonX59,
  twoX59,
  thirtyTwoX59,
  min,
  max,
  minLogStep,
  minLogSpacing
} from "../contracts/utilities/X59.sol";
import {
  X216,
  zeroX216,
  epsilonX216,
  oneX216,
  expInverse8X216,
  min,
  max
} from "../contracts/utilities/X216.sol";
import {
  IntegralLibrary,
  EXP_INV_8_X240
} from "../contracts/utilities/Integral.sol";
import {FullMathLibrary} from "../contracts/utilities/FullMath.sol";
import {PriceLibrary} from "../contracts/utilities/Price.sol";
import {
  initiateInterval,
  searchOutgoingTarget,
  searchIncomingTarget,
  moveOvershootByEpsilon,
  newIntegrals,
  searchOvershoot,
  moveTarget,
  moveOvershoot
} from "../contracts/utilities/Interval.sol";
import {
  Index,
  zeroIndex,
  oneIndex,
  twoIndex
} from "../contracts/utilities/Index.sol";
import {Curve} from "../contracts/utilities/Curve.sol";
import {Kernel} from "../contracts/utilities/Kernel.sol";

using PriceLibrary for uint256;

/// @notice Reserves 27 bytes in memory for an integral and returns the
/// corresponding memory pointer.
function get_an_integral_pointer() pure returns (uint256 pointer) {
  assembly {
    pointer := mload(0x40)
    mstore(0x40, add(pointer, 27))
  }
}

/// @notice Reserves 64 bytes in memory for a price as outlined in 'price.sol'
/// and returns the corresponding memory pointer.
///
///   pointer
///      |
///   +--+--------+---------------------------+---------------------------+
///   |  | 8 byte |          27 byte          |          27 byte          |
///   +--+--------+---------------------------+---------------------------+
///   |  |        |                           |
///   |  |        |                            \
///   |  |        |                             sqrtInversePrice
///   |  |         \
///   |  |          sqrtPrice
///   |   \
///   |    logPrice
///    \
///     heightPrice
///
function get_a_price_pointer() pure returns (uint256 pointer) {
  assembly {
    pointer := add(mload(0x40), 2)
    mstore(0x40, add(pointer, 62))
  }
}

/// @notice Reserves 128 bytes in memory for two consecutive prices as outlined
/// in 'price.sol' and returns the memory pointer associated with the first
/// one.
function get_a_segment_pointer() pure returns (uint256 pointer) {
  assembly {
    pointer := add(mload(0x40), 2)
    mstore(0x40, add(pointer, 126))
  }
}

/// @notice Transforms the given random 'seed' into an integral of type 'X216'.
function get_an_integral(uint216 seed) pure returns (X216) {
  return X216.wrap(int256(uint256(seed)));
}

/// @notice Transforms the given random 'seed' into an 'X15' value which may
/// not exceed 'oneX15'.
function get_a_height(uint16 seed) pure returns (X15) {
  return X15.wrap(seed % ((2 ** 15) + 1));
}

/// @notice Transforms the given random 'seed' into an 'X15' value which
/// satisfies:
///
///   'min(height0, height1) <= value <= min(height0, height1)'
///
function get_a_height_in_between(
  uint16 seed,
  X15 height0,
  X15 height1
) pure returns (X15) {
  X15 _min = height0 < height1 ? height0 : height1;
  X15 _max = height0 < height1 ? height1 : height0;
  return _min + X15.wrap(seed % (X15.unwrap(_max - _min) + 1));
}

/// @notice Transforms the given random 'seed' into an 'X59' value which may
/// not exceed 'thirtyTwoX59 - epsilonX59'.
function get_a_logPrice(uint64 seed) pure returns (X59) {
  return X59.wrap(int256(uint256(1 + (seed % ((2 ** 64) - 1)))));
}

/// @notice Transforms the given random 'seed' into an 'X59' value which
/// satisfies:
///
///   'min(logPrice0, logPrice1) <= value <= min(logPrice0, logPrice1)'
///
function get_a_logPrice_in_between(
  uint64 seed,
  X59 logPrice0,
  X59 logPrice1
) pure returns (X59) {
  X59 _min = min(logPrice0, logPrice1);
  X59 _max = max(logPrice0, logPrice1);
  return _min + X59.wrap(
    int256(uint256(seed) % uint256(X59.unwrap(_max - _min + epsilonX59)))
  );
}

/// @notice A reference for the function 'evaluate' in 'Integral.sol'.
/// Calculates:
///
///                                      c1 - c0
///  (2 ** 201) * (exp(-8) / 2) * (c0 + --------- (q - b0))
///                                      b1 - b0
///
function evaluate_reference(
  X15 c0,
  X15 c1,
  X59 b0,
  X59 b1,
  X59 q
) pure returns (X216) {
  if (b0 < b1) {
    return X216.wrap(
      int256(
        FullMathLibrary.mulDiv(
          EXP_INV_8_X240,
          X15.unwrap(c0) * uint256(X59.unwrap(b1 - b0)) + 
            X15.unwrap(c1 - c0) * uint256(X59.unwrap(q - b0)),
          uint256(X59.unwrap(b1 - b0))
        )
      ) >> 40
    );
  } else {
    return X216.wrap(
      int256(
        FullMathLibrary.mulDiv(
          EXP_INV_8_X240,
          X15.unwrap(c0) * uint256(X59.unwrap(b0 - b1)) + 
            X15.unwrap(c1 - c0) * uint256(X59.unwrap(b0 - q)),
          uint256(X59.unwrap(b0 - b1))
        )
      ) >> 40
    );
  }
}

/// @notice A reference for the function 'outgoing' in 'Integral.sol'.
/// Define:
///
///               from.log()                          to.log()
///  f := - 16 + ------------    and    t := - 16 + ------------
///                2 ** 59                            2 ** 59
///
/// If 'f < t' this function calculates:
///
///                                / t
///                               |     -h/2         c1 - c0
///  (2 ** 201) * (exp(-8) / 2) * |    e      (c0 + --------- (h - b0)) dh
///                               |                  b1 - b0
///                              / f
///
/// If 't < f' this function calculates:
///
///                                / f
///                               |     +h/2         c1 - c0
///  (2 ** 201) * (exp(-8) / 2) * |    e      (c0 + --------- (b0 - h)) dh
///                               |                  b0 - b1
///                              / t
///
function outgoing_reference(
  X15 c0,
  X15 c1,
  X59 b0,
  X59 b1,
  X59 logFrom,
  X59 logTo
) pure returns (X216) {
  uint256 result;
  if (b0 != b1) {
    unchecked {
      if (logFrom < logTo) {
        (X216 sqrtFrom, ) = logFrom.exp();
        (X216 sqrtTo, ) = logTo.exp();
        result = X15.unwrap(c0) * uint256(X216.unwrap(sqrtFrom - sqrtTo));
        result += FullMathLibrary.mulDiv(
          uint256(X216.unwrap(sqrtFrom)),
          X15.unwrap(c1 - c0) * uint256(X59.unwrap(logFrom - b0 + twoX59)),
          uint256(X59.unwrap(b1 - b0))
        );
        result -= FullMathLibrary.mulDiv(
          uint256(X216.unwrap(sqrtTo)),
          X15.unwrap(c1 - c0) * uint256(X59.unwrap(logTo - b0 + twoX59)),
          uint256(X59.unwrap(b1 - b0))
        );
      } else {
        (, X216 sqrtInverseFrom) = logFrom.exp();
        (, X216 sqrtInverseTo) = logTo.exp();
        result = X15.unwrap(c0) * uint256(
          X216.unwrap(sqrtInverseFrom - sqrtInverseTo)
        );
        result += FullMathLibrary.mulDiv(
          uint256(X216.unwrap(sqrtInverseFrom)),
          X15.unwrap(c1 - c0) * uint256(X59.unwrap(b0 - logFrom + twoX59)),
          uint256(X59.unwrap(b0 - b1))
        );
        result -= FullMathLibrary.mulDiv(
          uint256(X216.unwrap(sqrtInverseTo)),
          X15.unwrap(c1 - c0) * uint256(X59.unwrap(b0 - logTo + twoX59)),
          uint256(X59.unwrap(b0 - b1))
        );
      }
    }
  }
  return X216.wrap(int256(result >> 15));
}

/// @notice A reference for the function 'incoming' in 'Integral.sol'.
/// Define:
///
///               from.log()                          to.log()
///  f := - 16 + ------------    and    t := - 16 + ------------
///                2 ** 59                            2 ** 59
///
/// If 'f < t' this function calculates:
///
///                                / t
///                               |     +h/2         c1 - c0
///  (2 ** 201) * (exp(-8) / 2) * |    e      (c0 + --------- (h - b0)) dh
///                               |                  b1 - b0
///                              / f
///
/// If 't < f' this function calculates:
///
///                                / f
///                               |     -h/2         c1 - c0
///  (2 ** 201) * (exp(-8) / 2) * |    e      (c0 + --------- (b0 - h)) dh
///                               |                  b0 - b1
///                              / t
///
function incoming_reference(
  X15 c0,
  X15 c1,
  X59 b0,
  X59 b1,
  X59 logFrom,
  X59 logTo
) pure returns (X216) {
  uint256 result;
  if (b0 != b1) {
    unchecked {
      if (logFrom < logTo) {
        (, X216 sqrtInverseFrom) = logFrom.exp();
        (, X216 sqrtInverseTo) = logTo.exp();
        result = X15.unwrap(c1) * uint256(
          X216.unwrap(sqrtInverseTo - sqrtInverseFrom)
        );
        result += FullMathLibrary.mulDiv(
          uint256(X216.unwrap(sqrtInverseFrom)),
          X15.unwrap(c1 - c0) * uint256(X59.unwrap(b1 - logFrom + twoX59)),
          uint256(X59.unwrap(b1 - b0))
        );
        result -= FullMathLibrary.mulDiv(
          uint256(X216.unwrap(sqrtInverseTo)),
          X15.unwrap(c1 - c0) * uint256(X59.unwrap(b1 - logTo + twoX59)),
          uint256(X59.unwrap(b1 - b0))
        );
      } else {
        (X216 sqrtFrom, ) = logFrom.exp();
        (X216 sqrtTo, ) = logTo.exp();
        result = X15.unwrap(c1) * uint256(X216.unwrap(sqrtTo - sqrtFrom));
        result += FullMathLibrary.mulDiv(
          uint256(X216.unwrap(sqrtFrom)),
          X15.unwrap(c1 - c0) * uint256(X59.unwrap(logFrom - b1 + twoX59)),
          uint256(X59.unwrap(b0 - b1))
        );
        result -= FullMathLibrary.mulDiv(
          uint256(X216.unwrap(sqrtTo)),
          X15.unwrap(c1 - c0) * uint256(X59.unwrap(logTo - b1 + twoX59)),
          uint256(X59.unwrap(b0 - b1))
        );
      }
    }
  }
  return X216.wrap(int256(result >> 15));
}

/// @notice A reference for the function 'shift' in 'Integral.sol'.
/// Calculates:
///
///  sqrt0 * sqrt1 * integral
/// --------------------------
///   (2 ** 432) * exp(-16)
///
function shift_reference(
  X216 integral,
  X216 sqrt0,
  X216 sqrt1
) pure returns (X216) {
  return X216.wrap(
    int256(FullMathLibrary.mulDiv(
      uint256(X216.unwrap(integral)),
      FullMathLibrary.mulDiv(
        uint256(X216.unwrap(sqrt0)) << 20,
        uint256(X216.unwrap(sqrt1)) << 20,
        2 ** 216
      ),
      0x1e355bbaee85cada65f73f32e88fb3cc629b709109f57564d7e0b35f378
    ))
  );
}

/// @notice Returns true if and only if:
///
///   |a - b| <= err
///
function approximatelyEqual(
  X216 a,
  X216 b,
  uint256 err
) pure returns (bool) {
  (a, b) = (a > b) ? (a, b) : (b, a);
  return uint256(X216.unwrap(a - b)) <= err;
}

/// @notice Produces a pseudorandom transient slot by hashing the content of
/// slot0. The resulting transient slot is then returned and also stored on
/// slot0 to be used as a future seed. 
function get_a_transient_pointer() returns (
  uint256 pointer
) {
  assembly {
    mstore(0, tload(0))
    pointer := keccak256(0, 32)
    tstore(0, pointer)
  }
}

/// @notice Writes an X59 value on transient.
function store_logPrice(uint256 pointer, X59 logPrice) {
  assembly {
    tstore(pointer, logPrice)
  }
}

/// @notice Writes an X59 value on transient.
function load_logPrice(
  uint256 pointer
) view returns (X59 logPrice) {
  assembly {
    logPrice := tload(pointer)
  }
}

/// @notice Writes an X15 value on transient.
function store_height(uint256 pointer, X15 height) {
  assembly {
    tstore(pointer, height)
  }
}

/// @notice Reads an X15 value on transient.
function load_height(
  uint256 pointer
) view returns (X15 height) {
  assembly {
    height := tload(pointer)
  }
}

/// @notice These two functions will be used to created a sorted sequence of
/// values. A value is stored at 'pointer' and 'pointer + 1' points to the next
/// value.
function store_next(
  uint256 pointer,
  uint256 nextPointer
) {
  assembly {
    sstore(add(pointer, 1), nextPointer)
  }
}
function load_next(
  uint256 pointer
) view returns (
  uint256 nextPointer
) {
  assembly {
    nextPointer := sload(add(pointer, 1))
  }
}

/// @notice Sets a new memeber for the current kernel set in memory.
function set_breakPoint(
  Index ii,
  X59 iLog,
  X15 iHeight
) pure {
  uint256 pointer;
  Kernel kernel = getKernel();
  assembly {
    pointer := add(sub(kernel, 62), mul(ii, 64))
  }
  (X216 iSqrt, X216 iSqrtInverse) = iLog.exp();
  pointer.storePrice(iHeight, iLog, iSqrt, iSqrtInverse);
}

/// @notice This contract generates a random curve and a random kernel given
/// the given seeds and sets them in memory.
contract KernelAndCurveFactory {
  uint256 immutable kernelLimit;
  uint256 immutable curveLimit;

  constructor(uint256 _kernelLimit, uint256 _curveLimit) {
    kernelLimit = _kernelLimit;
    curveLimit = _curveLimit;
  }

  function kernelLengthLimit(
    uint256 length
  ) private returns (
    uint256 limitedLength
  ) {
    if (length > kernelLimit) {
      limitedLength = kernelLimit;
    } else {
      limitedLength = length;
    }
  }

  function curveLengthLimit(
    uint256 length
  ) private returns (
    uint256 limitedLength
  ) {
    if (length > curveLimit) {
      limitedLength = curveLimit;
    } else {
      limitedLength = length;
    }
  }

  /// @notice Generates a random curve and a random kernel based on the given
  /// seeds and gives them as returndata.
  function buildAndIntegrate(
    bool[3] calldata seed_base,
    uint64[3] calldata seed_boundaries,
    uint88[] calldata seed_kernel,
    uint64[] calldata seed_curve
  ) external {
    // In this case, the spacing is determined based on the given seeds.
    _build(
      get_a_logPrice_in_between(
        seed_boundaries[0],
        minLogSpacing,
        X59.wrap(6148914691236517204)
      ),
      seed_base,
      seed_boundaries,
      seed_kernel,
      seed_curve
    );
  }

  /// @notice Generates a random spacing, curve and kernel based on the given
  /// seeds and gives them as returndata.
  function buildWithSpacingAndIntegrate(
    X59 qSpacing,
    bool[3] calldata seed_base,
    uint64[3] calldata seed_boundaries,
    uint88[] calldata seed_kernel,
    uint64[] calldata seed_curve
  ) external {
    // In this case, the spacing is read from the storage contract.
    _build(qSpacing, seed_base, seed_boundaries, seed_kernel, seed_curve);
  }

  /// @notice This function creates a sorted chain of X59 values between
  /// 'zeroX59' and 'spacing' in storage. It is going to look like this:
  ///
  ///    +-----------------+--------------------------------+
  ///    |   logPrice[0]   | Storage pointer to logPrice[1] |
  ///    +-----------------+--------------------------------+
  ///
  ///    +-----------------+--------------------------------+
  ///    |   logPrice[1]   | Storage pointer to logPrice[2] |
  ///    +-----------------+--------------------------------+
  ///
  ///    +-----------------+--------------------------------+
  ///    |   logPrice[2]   | Storage pointer to logPrice[3] |
  ///    +-----------------+--------------------------------+
  ///    
  ///      .
  ///      .
  ///      .
  ///
  ///    +-----------------+--------------------------------+
  ///    | logPrice[n - 1] | Storage pointer to logPrice[n] |
  ///    +-----------------+--------------------------------+
  ///
  ///    +-----------------+
  ///    |   logPrice[n]   |
  ///    +-----------------+
  ///
  function _sortedX59(
    uint88[] calldata seed_kernel,
    uint64 seed,
    X59 qSpacing
  ) private returns (
    uint256 smallestPointer
  ) {
    smallestPointer = get_a_transient_pointer();
    store_logPrice(
      smallestPointer,
      get_a_logPrice_in_between(
        seed,
        epsilonX59,
        qSpacing - epsilonX59
      )
    );
    uint256 largestPointer = smallestPointer;

    for (uint256 ii = 0; ii < kernelLengthLimit(seed_kernel.length); ++ii) {
      X59 logPrice = get_a_logPrice_in_between(
        uint64(seed_kernel[ii]),
        epsilonX59,
        qSpacing - epsilonX59
      );
      uint256 pointer = get_a_transient_pointer();
      store_logPrice(pointer, logPrice);

      if (logPrice <= load_logPrice(smallestPointer)) {
        store_next(pointer, smallestPointer);
        smallestPointer = pointer;
      } else if (load_logPrice(largestPointer) < logPrice) {
        store_next(largestPointer, pointer);
        largestPointer = pointer;
      } else {
        uint256 pointer0 = smallestPointer;
        uint256 pointer1 = load_next(smallestPointer);
        while (
          logPrice < load_logPrice(pointer0)
           || 
          load_logPrice(pointer1) < logPrice
        ) {
          pointer0 = pointer1;
          pointer1 = load_next(pointer0);
        }
        store_next(pointer0, pointer);
        store_next(pointer, pointer1);
      }
    }
  }

  /// @notice This function creates a sorted chain of X15 values within
  /// '[zeroX15, oneX15 - 1]' in storage. It is going to look like this:
  ///
  ///    +-----------------+------------------------------+
  ///    |    height[0]    | Storage pointer to height[1] |
  ///    +-----------------+------------------------------+
  ///
  ///    +-----------------+------------------------------+
  ///    |    height[1]    | Storage pointer to height[2] |
  ///    +-----------------+------------------------------+
  ///
  ///    +-----------------+------------------------------+
  ///    |    height[2]    | Storage pointer to height[3] |
  ///    +-----------------+------------------------------+
  ///    
  ///      .
  ///      .
  ///      .
  ///
  ///    +-----------------+------------------------------+
  ///    |  height[n - 1]  | Storage pointer to height[n] |
  ///    +-----------------+------------------------------+
  ///
  ///    +-----------------+
  ///    |    height[n]    |
  ///    +-----------------+
  ///
  function _sortedX15(
    uint88[] calldata seed_kernel
  ) private returns (
    uint256 smallestPointer
  ) {
    smallestPointer = get_a_transient_pointer();
    store_height(smallestPointer, zeroX15);
    uint256 largestPointer = smallestPointer;

    for (uint256 ii = 0; ii < kernelLengthLimit(seed_kernel.length); ++ii) {
      X15 height = get_a_height_in_between(
        uint16(seed_kernel[ii] >> 64),
        X15.wrap(1),
        oneX15 - X15.wrap(1)
      );
      uint256 pointer = get_a_transient_pointer();
      store_height(pointer, height);

      if (height <= load_height(smallestPointer)) {
        store_next(pointer, smallestPointer);
        smallestPointer = pointer;
      } else if (load_height(largestPointer) < height) {
        store_next(largestPointer, pointer);
        largestPointer = pointer;
      } else {
        uint256 pointer0 = smallestPointer;
        uint256 pointer1 = load_next(smallestPointer);
        while (
          height < load_height(pointer0)
           || 
          load_height(pointer1) < height
        ) {
          pointer0 = pointer1;
          pointer1 = load_next(pointer0);
        }
        store_next(pointer0, pointer);
        store_next(pointer, pointer1);
      }
    }
  }

  /// @notice This function remove repetitions in the chain of breakpoints.
  function _pruneRepetition(
    uint256 initialLength,
    uint256 smallestPointerX59,
    uint256 smallestPointerX15
  ) private returns (
    uint256 length
  ) {
    length = initialLength;
    for (uint256 ii = 0; ii < initialLength; ++ii) {
      if (
        (
          load_logPrice(smallestPointerX59)
           == 
          load_logPrice(load_next(smallestPointerX59))
        ) || (
          load_height(smallestPointerX15)
           == 
          load_height(load_next(smallestPointerX15))
        )
      ) {
        store_next(
          smallestPointerX59,
          load_next(load_next(smallestPointerX59))
        );
        store_next(
          smallestPointerX15,
          load_next(load_next(smallestPointerX15))
        );
        --length;
      } else {
        smallestPointerX59 = load_next(smallestPointerX59);
        smallestPointerX15 = load_next(smallestPointerX15);
      }
    }
  }

  /// @notice This function builds a kernel and places it in memory.
  function _buildKernel(
    uint88[] calldata seed_kernel,
    X59 qSpacing,
    bool notSkip0,
    bool notSkip1,
    uint256 length,
    uint256 smallestPointerX59,
    uint256 smallestPointerX15
  ) private {
    // Repetitions are removed.
    length = _pruneRepetition(
      length,
      smallestPointerX59,
      smallestPointerX15
    );

    Kernel kernel;
    assembly {
      kernel := _endOfStaticParams_
    }
    setKernel(kernel);

    Index index = oneIndex;

    // In this case, we first add a breakpoint corresponding to the first X59
    // and X15.
    if (notSkip0 || load_logPrice(smallestPointerX59) <= minLogStep) {
      set_breakPoint(
        index,
        load_logPrice(smallestPointerX59),
        load_height(smallestPointerX15)
      );
      index = index + oneIndex;
    }

    if (length >= 1) {
      for (uint256 ii = 0; ii < length - 1; ++ii) {
        // The X15 is updated while the X59 remains the same.
        smallestPointerX15 = load_next(smallestPointerX15);

        // In this case, we add a vertical breakpoint.
        if (
          (
            (seed_kernel[ii] >> 80) % 2 == 0
          ) || (
            load_logPrice(load_next(smallestPointerX59))
             - 
            load_logPrice(smallestPointerX59) <= minLogStep
          )
        ) {
          set_breakPoint(
            index,
            load_logPrice(smallestPointerX59),
            load_height(smallestPointerX15)
          );
          index = index + oneIndex;
        }

        // In this case, if the previous 'if' condition is met, we add a
        // horizontal breakpoint. Otherwise, we add a ramp.
        if (
          (
            (seed_kernel[ii] >> 84) % 2 == 0
          ) || (
            load_logPrice(load_next(smallestPointerX59))
             - 
            load_logPrice(smallestPointerX59) <= minLogStep
          )
        ) {
          set_breakPoint(
            index,
            load_logPrice(load_next(smallestPointerX59)),
            load_height(smallestPointerX15)
          );
          index = index + oneIndex;
        }

        smallestPointerX59 = load_next(smallestPointerX59);
      }
    }

    if (
      notSkip1
       || 
      qSpacing - load_logPrice(smallestPointerX59) <= minLogStep
    ) {
      set_breakPoint(
        index,
        load_logPrice(smallestPointerX59),
        oneX15
      );
      index = index + oneIndex;
    }

    set_breakPoint(index, qSpacing, oneX15);
    index = index + oneIndex;

    setKernelLength(index);
  }

  /// @notice This function builds a curve and places it in memory.
  function _buildCurve(
    uint64[] calldata seed_curve,
    bool seed,
    X59 qLower,
    X59 qUpper
  ) private {
    uint256 pointer;
    {
      Curve curve;
      Kernel kernel = getKernel();
      Index length = getKernelLength() - oneIndex;
      assembly {
        pointer := add(kernel, shl(6, length))
        curve := pointer
      }
      setCurve(curve);
    }

    (
      X59 logPrice0,
      X59 logPrice1
    ) = seed ? (qLower, qUpper) : (qUpper, qLower);

    assembly {
      mstore(pointer, shl(192, logPrice0))
    }
    pointer += 8;

    uint256 k = 0;
    while (true) {
      assembly {
        mstore(pointer, shl(192, logPrice1))
      }
      pointer += 8;

      if (k == curveLengthLimit(seed_curve.length)) break;

      if (
        min(logPrice0, logPrice1) == max(logPrice0, logPrice1) - epsilonX59
      ) break;

      (logPrice0, logPrice1) = (
        logPrice1,
        get_a_logPrice_in_between(
          seed_curve[k],
          min(logPrice0, logPrice1) + epsilonX59,
          max(logPrice0, logPrice1) - epsilonX59
        )
      );

      ++k;
    }
    
    {
      Index length;
      assembly {
        length := k
      }
      setCurveLength(length + twoIndex);
    }

    setFreeMemoryPointer(pointer + 64);
  }

  /// @notice This function calculates 'originToOvershoot' for a swap from
  /// 'getCurve().member(getKernelLength() - oneIndex)' to
  /// 'getCurve().member(zeroIndex)'.
  X216 public originToOvershoot_reference;
  function _originToOvershoot() private {
    originToOvershoot_reference = zeroX216;
    for (
      Index index = zeroIndex;
      index < getKernelLength() - oneIndex;
      index = index + oneIndex
    ) {
      (X15 c0, X59 b0, , ) = getKernel().member(index);
      (X15 c1, X59 b1, , ) = getKernel().member(index + oneIndex);
      if (
        getCurve().member(zeroIndex) <= getCurve().member(oneIndex)
      ) {
        b0 = getCurve().member(oneIndex) - b0;
        b1 = getCurve().member(oneIndex) - b1;
      } else {
        b0 = b0 + getCurve().member(oneIndex);
        b1 = b1 + getCurve().member(oneIndex);
      }
      originToOvershoot_reference = originToOvershoot_reference + 
        outgoing_reference(c0, c1, b0, b1, b0, b1);
    }
  }

  /// @notice This function calculates 'incomingCurrentToTarget',
  /// 'currentToOrigin', and 'currentToTarget' for a swap from
  /// 'getCurve().member(getKernelLength() - oneIndex)' to
  /// 'getCurve().member(zeroIndex)'.
  X216 public incomingCurrentToTarget_reference;
  X216 public currentToOrigin_reference;
  X216 public currentToTarget_reference;
  function _integrals() private {
    incomingCurrentToTarget_reference = zeroX216;
    currentToOrigin_reference = zeroX216;
    currentToTarget_reference = zeroX216;

    Index iIndex = getCurveLength() - oneIndex;
    X59 begin = getCurve().member(iIndex);
    X59 origin = getCurve().member(iIndex);
    X59 end = getCurve().member(iIndex);
    while(iIndex >= oneIndex) {
      iIndex = iIndex - oneIndex;
      begin = origin;
      origin = end;
      end = getCurve().member(iIndex);
      for (
        Index jIndex = zeroIndex;
        jIndex < getKernelLength() - oneIndex;
        jIndex = jIndex + oneIndex
      ) {
        (X15 c0, X59 b0, , ) = getKernel().member(jIndex);
        (X15 c1, X59 b1, , ) = getKernel().member(jIndex + oneIndex);
        X59 from;
        X59 to;
        if (end < begin) {
          b0 = origin - b0;
          b1 = origin - b1;
          from = min(begin, b0);
          to = max(end, b1);
          if (from < to) continue;
        } else {
          b0 = origin + b0;
          b1 = origin + b1;
          from = max(begin, b0);
          to = min(end, b1);
          if (to < from) continue;
        }
        if (
          (getCurve().member(zeroIndex) <= getCurve().member(oneIndex))
           == 
          (end < begin)
        ) {
          incomingCurrentToTarget_reference = 
            incomingCurrentToTarget_reference + 
            incoming_reference(c0, c1, b0, b1, from, to);
          currentToTarget_reference = 
            currentToTarget_reference + 
            outgoing_reference(c0, c1, b0, b1, from, to);
        } else {
          currentToOrigin_reference = 
            currentToOrigin_reference + 
            outgoing_reference(c0, c1, b0, b1, from, to);
        }
      }
    }
  }

  // This function builds a random curve and a random kernel and returns them
  // as returndata.
  function _build(
    X59 qSpacing,
    bool[3] calldata seed_base,
    uint64[3] calldata seed_boundaries,
    uint88[] calldata seed_kernel,
    uint64[] calldata seed_curve
  ) private {
    // The lower boundary of active interval is chosen between 'qSpacing' and
    // 'thirtyTwoX59 - qSpacing - qSpacing'.
    X59 qLower = get_a_logPrice_in_between(
      seed_boundaries[1],
      qSpacing + epsilonX59,
      thirtyTwoX59 - epsilonX59 - qSpacing - qSpacing
    );

    // We build a kernel and places it in memory.
    uint256 smallestPointer = _sortedX59(
      seed_kernel,
      seed_boundaries[2],
      qSpacing
    );
    _buildKernel(
      seed_kernel,
      qSpacing,
      seed_base[0],
      seed_base[1],
      kernelLengthLimit(seed_kernel.length),
      smallestPointer,
      _sortedX15(seed_kernel)
    );

    // We build a curve and places it in memory.
    _buildCurve(seed_curve, seed_base[2], qLower, qLower + qSpacing);

    // calculates 'originToOvershoot' for a swap from
    // 'getCurve().member(getKernelLength() - oneIndex)' to
    // 'getCurve().member(zeroIndex)'.
    _originToOvershoot();

    // calculates 'incomingCurrentToTarget',
    // 'currentToOrigin', and 'currentToTarget' for a swap from
    // 'getCurve().member(getKernelLength() - oneIndex)' to
    // 'getCurve().member(zeroIndex)'.
    _integrals();

    // Returns the generated curve and kernel as returndata.
    {
      Curve curve = getCurve();
      Index length = getCurveLength();
      assembly {
        return(_pointers_, sub(add(curve, shl(3, length)), _pointers_))
      }
    }
  }
}