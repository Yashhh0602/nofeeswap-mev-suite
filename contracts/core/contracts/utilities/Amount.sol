// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {
  getShares,
  getSqrtOffset,
  getSqrtInverseOffset,
  getOutgoingMax,
  getOutgoingMaxModularInverse,
  getExactInput,
  getZeroForOne,
  getAmountSpecified,
  getSharesTotal,
  getGrowth,
  setIntegralLimit
} from "./Memory.sol";
import {X111, zeroX111} from "./X111.sol";
import {X127, zeroX127} from "./X127.sol";
import {X208} from "./X208.sol";
import {X216} from "./X216.sol";
import {FullMathLibrary} from "./FullMath.sol";
import {
  SafeOutOfRangeAmountOverflow,
  SafeInRangeAmountOverflow
} from "./Errors.sol";

/// @notice This function calculates
///
/// 'integralLimit := min(
///
///    oneX216 - epsilonX216,
///
///                        1          2 ** 111     |amountSpecified|
///    outgoingMax * ------------- * ---------- * ------------------- *
///                   sharesTotal      growth          2 ** 127
///
///     (getZeroForOne() != getExactInput()) ? sqrtInverseOffset : sqrtOffset
///    -----------------------------------------------------------------------
///                                   2 ** 127
///
///  )'.
function calculateIntegralLimit() pure {
  // 'outgoingMax' is a positive number which is loaded from 216 bits of memory
  // and theoretically does not exceed 216 bits. Hence, casting is safe.
  //
  // Both 'sqrtOffset' and 'sqrtInverseOffset' are positive numbers which do
  // not exceed 192 bits. This is because they are both within the range
  // '(2 ** 127) * exp(-45)' and '(2 ** 127) * exp(+45)'. Hence, casting is
  // safe.
  //
  // '|amountSpecified|' is a non-negative number which does not exceed
  // '((2 ** 127 - 1) << 127) < 2 ** 254'. Hence, casting is safe.
  //
  // 'growth.times(sharesTotal)' is a non-negative number which does not exceed
  // 'maxGrowth.times(type(int128).max) < 2 ** 254'. Hence, casting is safe.
  //
  // Notice that a zero denominator is handled gracefully by 'mulDiv'.
  //
  // The result is capped by '2 ** 216 - 1'. Hence, casting to 'int256' is also
  // safe.
  //
  // 'result' is capped by 'mulDiv' and does not exceed 216 bits. Hence, it can
  // be safely placed in the following memory location which has exactly 216
  // bits of space.
  setIntegralLimit(
    X216.wrap(int256(
      getExactInput() ? FullMathLibrary.mulDiv(
        uint256(X216.unwrap(getOutgoingMax())),
        uint256(X127.unwrap(
          getZeroForOne() ? getSqrtOffset() : getSqrtInverseOffset()
        )),
        uint256(X127.unwrap(getAmountSpecified())),
        uint256(X111.unwrap(getGrowth().times(getSharesTotal()))),
        // If 'exactInput == true', the result needs to be rounded down because
        // the protocol should never charge more than the specified incoming
        // amount.
        false
      ) : FullMathLibrary.mulDiv(
        uint256(X216.unwrap(getOutgoingMax())),
        uint256(X127.unwrap(
          getZeroForOne() ? getSqrtInverseOffset() : getSqrtOffset()
        )),
        uint256(X127.unwrap(zeroX127 - getAmountSpecified())),
        uint256(X111.unwrap(getGrowth().times(getSharesTotal()))),
        // If 'exactInput == false', the result needs to be rounded up because
        // the protocol should always provide more than the specified outgoing
        // amount.
        true
      )
    ))
  );
}

/// @notice Calculates the amount of a tag within a range of inactive
/// liquidity intervals
///
/// 'amount := ceiling(
///
///     shares *
///
///     (zeroOrOne ? sqrtOffset : sqrtInverseOffset) * 
///
///      multiplier
///     ------------
///       2 ** 208
///  )'.
///
/// Throws if the absolute value of the result is greater than or equal to
// 'type(int256).max'.
function safeOutOfRangeAmount(
  X208 multiplier,
  bool zeroOrOne
) pure returns (
  X127 amount
) {
  unchecked {
    int256 shares = getShares();
    X127 offset = zeroOrOne ? getSqrtOffset() : getSqrtInverseOffset();

    // 'mul768' will calculate the following product:
    //
    // '(offset << 48) * multiplier * |shares| / (2 ** 256)'
    //
    // Hence, 'q1' is the value that we are looking for.
    (uint256 q0, uint256 q1, uint256 q2) = FullMathLibrary.mul768(
      // The casting and the shift are safe because both 'sqrtOffset' and 
      // 'sqrtInverseOffset' are non-negative and do not exceed 192 bits. More
      // precisely, '(2 ** 127) * exp(45) < 2 ** 192'.
      uint256(X127.unwrap(offset)) << 48,
      X208.unwrap(multiplier),
      // The subtraction and casting are safe because 'shares' is capped by 
      // '0 - type(int128).max' and 'type(int128).max' in 'Calldata.sol' and
      // we are taking the absolute value of 'shares' here.
      uint256(shares < 0 ? 0 - shares : shares)
    );

    // 'q2 > 0' indicates that 'amount > 2 ** 256' which causes overflow.
    require(q2 == 0, SafeOutOfRangeAmountOverflow(offset, multiplier, shares));

    if (shares < 0) {
      // In this case we do not need to adjust the rounding because the
      // absolute value of the result is rounded down and since it is negative,
      // the actual value of the result is rounded up.

      // In this case, the negative sign should be restored since we have
      // calculated the product based on the absolute value of shares. Since
      // 'q1' is to be negated, 'q1 >= (1 << 255)' should be avoided.
      require(
        q1 < (1 << 255),
        SafeOutOfRangeAmountOverflow(offset, multiplier, shares)
      );

      // Due to the above checks, we have 'q1 < (1 << 255)' and the casting is
      // safe. The subtraction is also safe and the results in a negative
      // number greater than '-(1 << 255)'.
      amount = X127.wrap(0 - int256(q1));
    } else {
      // The amount should be rounded up.
      if (q0 > 0) {
        // 'q1 >= (1 << 255) - 1' should be avoided, since we are incrementing
        // 'q1' and then cast it to an integer.
        require(
          q1 < ((1 << 255) - 1),
          SafeOutOfRangeAmountOverflow(offset, multiplier, shares)
        );
        ++q1;
      } else {
        // 'q1 >= (1 << 255)' should be avoided, since we are casting to an
        // integer later.
        require(
          q1 < (1 << 255),
          SafeOutOfRangeAmountOverflow(offset, multiplier, shares)
        );
      }

      // Due to the above checks, we have 'q1 < (1 << 255)' and the casting is
      // safe.
      amount = X127.wrap(int256(q1));
    }
  }
}

/// @notice Calculates the amounts of a tag within the active liquidity
/// interval:
///
/// 'amount := (zeroOrOne ? sqrtOffset : sqrtInverseOffset) * 
///
///             liquidity      integral
///            ----------- * -------------'
///              2 ** 111     outgoingMax
///
/// 'integral' should be non-negative.
/// 'liquidity' should be greater than '- 2 ** 255'.
function inRangeAmount(
  X216 integral,
  X111 liquidity,
  bool zeroOrOne,
  bool roundUp
) pure returns (
  X127 amount,
  bool overflow
) {
  uint256 result;
  (result, overflow) = FullMathLibrary.mulDiv(
    // The casting is safe because both 'sqrtOffset' and 'sqrtInverseOffset'
    // are non-negative and do not exceed 192 bits. More precisely, 
    // '(2 ** 127) * exp(45) < 2 ** 192'.
    uint256(X127.unwrap(
      zeroOrOne ? getSqrtOffset() : getSqrtInverseOffset()
    )),
    // The casting is safe because of the input requirement.
    uint256(X216.unwrap(integral)),
    // The subtraction is safe because 'liquidity > - 2 ** 255' due to the
    // input requirement. The casting is safe because we are casting an
    // absolute value which is less than '2 ** 255'.
    uint256(X111.unwrap(
      liquidity < zeroX111 ? zeroX111 - liquidity : liquidity
    )),
    // 'outgoingMax' is a positive number which is loaded from 216 bits of
    // memory and theoretically does not exceed 216 bits. Hence, casting is
    // safe.
    uint256(X216.unwrap(getOutgoingMax())),
    getOutgoingMaxModularInverse(),
    // If 'liquidity >= zeroX111', then the rounding of 'mulDiv' follow
    // 'roundUp'. If not, then the rounding of 'mulDiv' should be the opposite
    // of 'roundUp' because 'result' will be negated later.
    roundUp == (liquidity >= zeroX111)
  );
  // The casting is safe because 'mulDiv' returns 'overflow == true' if 
  // 'result' exceeds 'type(int256).max'.
  amount = X127.wrap(int256(result));
  // The sign is restored because we have taken the absolute value of liquidity
  // before.
  // The subtraction is safe because the result is a non-negative number, i.e.,
  // greater than '- (1 << 255)'.
  amount = liquidity < zeroX111 ? zeroX127 - amount : amount;
}

/// @notice Calculates the amounts of tags within the active liquidity
/// interval and throws if the absolute value of the result exceeds
/// 'type(int256).max':
///
/// 'amount := (zeroOrOne ? sqrtOffset : sqrtInverseOffset) * 
///
///             liquidity      integral
///            ----------- * -------------'.
///              2 ** 111     outgoingMax
///
/// 'integral' should be non-negative.
/// 'liquidity' should be greater than '- 2 ** 255'.
function safeInRangeAmount(
  X216 integral,
  X111 liquidity,
  bool zeroOrOne,
  bool roundUp
) pure returns (
  X127 amount
) {
  bool overflow;
  // The requirements of 'inRangeAmount' are satisfied because of the 
  // requirements for this function.
  (amount, overflow) = inRangeAmount(
    integral,
    liquidity,
    zeroOrOne,
    roundUp
  );
  require(
    !overflow,
    SafeInRangeAmountOverflow(
      zeroOrOne ? getSqrtOffset() : getSqrtInverseOffset(),
      integral,
      liquidity,
      getOutgoingMax(),
      getOutgoingMaxModularInverse()
    )
  );
}