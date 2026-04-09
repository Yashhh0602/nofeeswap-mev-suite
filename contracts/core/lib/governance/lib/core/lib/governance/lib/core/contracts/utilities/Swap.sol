// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {
  _back_,
  _next_,
  _zeroForOne_,
  _current_,
  _target_,
  _overshoot_,
  _total1_,
  _forward1_,
  _spacing_,
  _currentToTarget_,
  _currentToOvershoot_,
  _incomingCurrentToTarget_,
  getPoolId,
  getZeroForOne,
  getExactInput,
  getOutgoingMax,
  getIncomingMax,
  getAmount0,
  getAmount1,
  getAmountSpecified,
  getCurve,
  getLogPriceLimitOffsetted,
  getLogPriceLimit,
  getLogPriceCurrent,
  getSharesTotal,
  getCrossThreshold,
  getLogPriceLimitOffsettedWithinInterval,
  getIntegral0,
  getIntegral1,
  getKernel,
  getGrowth,
  getStaticParamsStoragePointerExtension,
  getPendingKernelLength,
  getNextGrowthMultiplier,
  getBackGrowthMultiplier,
  getPoolRatio0,
  getPoolRatio1,
  getAccrued0,
  getAccrued1,
  setIntegralLimitInterval,
  setAmount0,
  setAmount1,
  setAmountSpecified,
  setLogPriceLimitOffsetted,
  setZeroForOne,
  setExactInput,
  setIntegral0,
  setIntegral1,
  setGrowth,
  setLogPriceCurrent,
  setAccrued0,
  setAccrued1,
  setPoolRatio0,
  setPoolRatio1,
  setBackGrowthMultiplier,
  setNextGrowthMultiplier,
  setSharesTotal,
  setStaticParamsStoragePointerExtension,
  setKernelLength,
  setPoolGrowthPortion,
  getPoolGrowthPortion,
  getMaxPoolGrowthPortion
} from "./Memory.sol";
import {
  initiateInterval,
  moveTarget,
  moveOvershoot,
  searchOvershoot,
  clearInterval
} from "./Interval.sol";
import {zeroX15} from "./X15.sol";
import {X23} from "./X23.sol";
import {X47, min} from "./X47.sol";
import {X59, epsilonX59, sixteenX59, thirtyTwoX59, min, max} from "./X59.sol";
import {X111, oneX111, min, max} from "./X111.sol";
import {X127, zeroX127, min, max} from "./X127.sol";
import {X208, zeroX208, exp8X208} from "./X208.sol";
import {X216, zeroX216, oneX216, min, max, minFractions} from "./X216.sol";
import {isGrowthPortion, calculateGrowthPortion} from "./GrowthPortion.sol";
import {Index, twoIndex} from "./Index.sol";
import {getLogOffsetFromPoolId} from "./PoolId.sol";
import {updateGrowth} from "./Growth.sol";
import {calculateIntegralLimit, safeInRangeAmount} from "./Amount.sol";
import {PriceLibrary} from "./Price.sol";
import {IntegralLibrary} from "./Integral.sol";
import {
  getGrowthMultiplierSlot,
  readSharesDelta,
  getStaticParamsStorageAddress,
  readKernel,
  readGrowthMultiplier,
  writeGrowthMultiplier,
  readStaticParams,
  getSharesDeltaSlot
} from "./Storage.sol";
import {InvalidDirection} from "./Errors.sol";

using PriceLibrary for uint16;
using IntegralLibrary for uint16;

/// @notice Let 'pLower' and 'pUpper', respectively, denote the minimum and
/// maximum price in the current active liquidity interval and define
///
///  'qLower := log(pLower / pOffset)',
///  'qUpper := log(pUpper / pOffset)'.
///
/// As explained in 'Memory.sol', define:
///
///  'integralLimitInterval := (getExactInput() ? incomingMax : outgoingMax)
///
///           (getZeroForOne() != getExactInput() ? - qLower : + qUpper) / 2
///       * e                                                               '.
///
/// The present function calculates 'integralLimitInterval' and stores it in
/// the appropriate memory location.
function calculateIntegralLimitInterval() pure {
  // Multiplications are safe because as proven in 'Interval.sol', we have
  //
  //  'qSpacing < 32 / 3'
  //
  // Hence,
  //
  //                       - 8     / qSpacing
  //    outgoingMax      e        |    - h / 2
  //  '------------- := ------- * |  e         k(h) dh <
  //     2 ** 216          2      |
  //                             / 0
  //
  //                       - 8     / 32 / 3
  //                     e        |    - h / 2        - 8
  //                    ------- * |  e         dh < e     '
  //                       2      |
  //                             / 0
  //
  // and
  //
  //                       - 8 - qSpacing / 2     / qSpacing
  //    incomingMax      e                       |    + h / 2
  //  '------------- := ---------------------- * |  e         k(h) dh < 
  //     2 ** 216                 2              |
  //                                            / 0
  //
  //                       - 8 - 32 / 6     / 32 / 3
  //                     e                 |    + h / 2        - 8
  //                    ---------------- * |  e         dh < e     '.
  //                            2          |
  //                                      / 0
  //
  // Therefore, overflow is not possible.
  setIntegralLimitInterval(
    getExactInput() ? (
      getIncomingMax() % _next_.sqrt(!getZeroForOne())
    ) : (
      getOutgoingMax() % _back_.sqrt(getZeroForOne())
    )
  );
}

/// @notice updates the incoming and outgoing values in the memory as well as
/// the 'amountSpecified' after interactions with an interval.
function updateAmounts(
  X127 outgoingAmount,
  X127 incomingAmount
) pure {
  // 'amount0' and 'amount1' are adjusted.
  (X127 amount0, X127 amount1) = getZeroForOne() ? (
    incomingAmount,
    zeroX127 - outgoingAmount
  ) : (
    zeroX127 - outgoingAmount,
    incomingAmount
  );
  setAmount0(getAmount0() & amount0);
  setAmount1(getAmount1() & amount1);

  // 'amountSpecified' is adjusted.
  setAmountSpecified(
    getExactInput() ? 
    max(zeroX127, getAmountSpecified() - incomingAmount) : 
    min(zeroX127, getAmountSpecified() + outgoingAmount)
  );
}

/// @notice Calculates prerequisite parameters that are needed to perform swaps.
function setSwapParams() pure {
  // Interval boundaries are read from the curve sequence in memory.
  (X59 qLower, X59 qUpper) = getCurve().boundaries();

  // 'qLimit' is calculated and capped by the maximum and minimum possible
  // values for log price.
  {
    X59 qSpacing = _spacing_.log();

    // The addition and the subtraction are both safe because as proven in
    // 'Interval.sol', we always have 'qSpacing < 32 / 3'.
    X59 qLeast = qSpacing + epsilonX59;
    X59 qMost = thirtyTwoX59 - qLeast;

    setLogPriceLimitOffsetted(
      min(
        max(
          // Smallest possible log price:
          // All operations are safe, because the output is non-negative and
          // less than '2 ** 64'.
          qLeast + ((qUpper - qLeast) % qSpacing),
          // The addition and subtraction are not necessarily safe, which is
          // why we cap this value.
          sixteenX59 + getLogPriceLimit() - getLogOffsetFromPoolId(getPoolId())
        ),
        // Largest possible log price:
        // All operations are safe, because the output is non-negative and less
        // than '2 ** 64'.
        qMost - ((qMost - qLower) % qSpacing)
      )
    );
  }

  // 'zeroForOne' and 'exactInput' flags are determined next.
  bool zeroForOne = getLogPriceLimitOffsetted() <= getLogPriceCurrent();
  {
    uint256 _zeroForOne;
    assembly {
      _zeroForOne := shr(248, mload(_zeroForOne_))
    }
    if (_zeroForOne <= 1) {
      require(
        (_zeroForOne > 0) == zeroForOne,
        InvalidDirection(getLogPriceCurrent(), getLogPriceLimitOffsetted())
      );
    }
  }
  setZeroForOne(zeroForOne);
  setExactInput(getAmountSpecified() >= zeroX127);

  // 'back' and 'next' log price values are determined based on the direction
  // of the swap.
  (qLower, qUpper) = zeroForOne ? (qUpper, qLower) : (qLower, qUpper);

  // Square root of the price for 'back' is calculated via the exponential 
  // function.
  // The requirement of 'exp' is satisfied because '0 < qLower < 2 ** 64'.
  _back_.storePrice(qLower);

  // Square root of the price for 'next' is calculated.
  // Multiplications are safe because the results are smaller than 'oneX216'.
  {
    (X216 nextSqrt, X216 nextSqrtInverse) = zeroForOne ? (
      _back_.sqrt(false) ^ _spacing_.sqrt(true),
      _back_.sqrt(true) & _spacing_.sqrt(false)
    ) : (
      _back_.sqrt(false) & _spacing_.sqrt(false),
      _back_.sqrt(true) ^ _spacing_.sqrt(true)
    );
    _next_.storePrice(qUpper, nextSqrt, nextSqrtInverse);
  }

  // Integral limits are calculated next.
  calculateIntegralLimit();
  calculateIntegralLimitInterval();
}

/// @notice Performs a swap within an interval.
function swapWithin() pure returns (
  bool exactAmount
) {
  // The number of shares should not be less than 'crossThreshold' for this
  // function to swap within the interval.
  if (getSharesTotal() < getCrossThreshold()) return true;

  // Prerequisite values are calculated and set in memory. 
  initiateInterval();

  // Now, 'qTarget' is determined. The target moves forward until we encounter
  // 'qLimitWithinInterval' or 'amountSpecified'.
  {
    X59 qLimitWithinInterval = getLogPriceLimitOffsettedWithinInterval();
    while (_target_.log() != qLimitWithinInterval) {
      // The input requirements of 'moveTarget' are met because of the
      // condition '_target_.log() != qLimitWithinInterval'.
      if (exactAmount = moveTarget()) break;
    }
  }

  // 'zeroForOne' is loaded from the memory.
  bool zeroForOne = getZeroForOne();

  // 'currentToTarget' is capped to prevent underflow due to rounding error
  // because we use this value to update 'integral0' and 'integral1'.
  _currentToTarget_.setIntegral(
    min(
      _currentToTarget_.integral(),
      zeroForOne ? getIntegral1() : getIntegral0()
    )
  );

  // 'qOvershoot' is set as 'qTarget'. We later move 'qOvershoot' forward until
  // the mismatch function 'f(qOvershoot)' is minimized.
  _overshoot_.copyPrice(_target_);
  _currentToOvershoot_.setIntegral(_currentToTarget_.integral());

  // 'qForward1' is set as 'qTarget' and 'cForward1' is set to zero. Because
  // the new liquidity distribution function is centered around 'qTarget'.
  _forward1_.copyPrice(_target_);

  // The 'outgoing' and 'incoming' amounts as well as the incremented integrals 
  // are determined next.
  // The multiplication is safe because both values are less than '2 ** 127'.
  X111 liquidity = getGrowth().times(getSharesTotal());

  //                                 - 8     / qUpper
  //     integral0Incremented      e        |    - h / 2
  //   '---------------------- := ------- * |  e         k(w(h)) dh',
  //           2 ** 216              2      |
  //                                       / qTarget
  X216 integral0Incremented;

  //                                 - 8     / qTarget
  //     integral1Incremented      e        |    + h / 2
  //   '---------------------- := ------- * |  e         k(w(h)) dh'.
  //           2 ** 216              2      |
  //                                       / qLower
  X216 integral1Incremented;

  // The outgoing and incoming amounts are calculated next:
  //
  //   'outgoingAmount := (zeroForOne ? sqrtOffset : sqrtInverseOffset) *
  //
  //                    growth      currentToTarget
  //    sharesTotal * ---------- * ----------------- '.
  //                   2 ** 111       outgoingMax
  //
  //   'incomingAmount := (zeroForOne ? sqrtInverseOffset : sqrtOffset) *
  //
  //                    growth      incomingCurrentToTarget
  //    sharesTotal * ---------- * ------------------------- '.
  //                   2 ** 111           outgoingMax
  //
  X127 outgoingAmount;
  X127 incomingAmount;
  {
    X216 currentToTarget = _currentToTarget_.integral();
    X216 incomingCurrentToTarget = _incomingCurrentToTarget_.integral();
    // All operations are safe. Because 'currentToTarget' is capped.
    // Additionally, the other integral may not exceed 216-bits.
    (integral0Incremented, integral1Incremented) = zeroForOne ? (
      incomingCurrentToTarget + getIntegral0(),
      getIntegral1() - currentToTarget
    ) : (
      getIntegral0() - currentToTarget,
      incomingCurrentToTarget + getIntegral1()
    );
    outgoingAmount = safeInRangeAmount(
      currentToTarget,
      liquidity,
      zeroForOne,
      false
    );
    incomingAmount = safeInRangeAmount(
      incomingCurrentToTarget,
      liquidity,
      !zeroForOne,
      true
    );
  }

  // 'qOvershoot' is calculated next, along with the amended integrals and
  // 'growthAmended'.

  //                            - 8     / qUpper
  //    integral0Amended      e        |    - h / 2
  //  '------------------ := ------- * |  e         k(wAmended(h)) dh == 
  //        2 ** 216            2      |
  //                                  / qTarget
  //
  //                              growth        integral0Incremented
  //                         --------------- * ---------------------- == 
  //                          growthAmended           2 ** 216
  //
  //                          growthDenominator     integral0Incremented
  //                         ------------------- * ---------------------- '.
  //                           growthNumerator            2 ** 216
  //
  X216 integral0Amended = integral0Incremented;

  //                            - 8     / qTarget
  //    integral1Amended      e        |    + h / 2
  //  '------------------ := ------- * |  e         k(wAmended(h)) dh == 
  //        2 ** 216            2      |
  //                                  / qLower
  //
  //                              growth        integral1Incremented
  //                         --------------- * ---------------------- == 
  //                          growthAmended           2 ** 216
  //
  //                          growthDenominator     integral1Incremented
  //                         ------------------- * ---------------------- '.
  //                           growthNumerator            2 ** 216
  //
  X216 integral1Amended = integral1Incremented;

  X216 growthNumerator = oneX216;
  X216 growthDenominator = oneX216;

  // If 'qTarget' reaches 'qNext', then we do not need to calculate
  // 'qOvershoot'.
  if (_target_.log() == _next_.log()) {
    if (zeroForOne) {
      // Residual value in the interval is calculated and given to swapper.
      // 'integral1Incremented' is supposed to be '0' since we have reached the
      // right boundary of the interval. Hence, the remaining value is
      // calculated and given to the swapper.
      outgoingAmount = outgoingAmount & safeInRangeAmount(
        integral1Incremented,
        liquidity,
        true,
        false
      );

      // The multiplication is safe because 'outgoingMax < oneX216 * exp(-8)'.
      integral0Amended = min(
        _next_.sqrt(false) % getOutgoingMax(),
        integral0Amended
      );
      integral1Amended = zeroX216;
      
      integral1Incremented = zeroX216;
      
      growthNumerator = integral0Incremented;
      growthDenominator = integral0Amended;
    } else {
      // Residual value in the interval is calculated and given to swapper.
      // 'integral0Incremented' is supposed to be '0' since we have reached the
      // left boundary of the interval. Hence, the remaining value is
      // calculated and given to swapper.
      outgoingAmount = outgoingAmount & safeInRangeAmount(
        integral0Incremented,
        liquidity,
        false,
        false
      );

      // The multiplication is safe because 'outgoingMax < oneX216 * exp(-8)'.
      integral1Amended = min(
        _next_.sqrt(true) % getOutgoingMax(),
        integral1Amended
      );
      integral0Amended = zeroX216;

      integral0Incremented = zeroX216;

      growthNumerator = integral1Incremented;
      growthDenominator = integral1Amended;
    }

  // If 'qTarget' is not in a zero liquidity region, and 'qCurrent != qTarget',
  // then we search for 'qOvershoot'.
  } else if (
    (_total1_.height() != zeroX15) && (_target_.log() != _current_.log())
  ) {
    // 'qOvershoot' is moved forward, until we reach a segment whose two heads
    // give negative mismatch signs.
    while (moveOvershoot(integral0Amended, integral1Amended)) {}

    // We perform a Newton search to find the precise value for 'qOvershoot'.
    (integral0Amended, integral1Amended) = searchOvershoot(
      integral0Amended,
      integral1Amended
    );

    // The curve is amended with 'qOvershoot'.
    // The requirement of 'amend' is satisfied because
    // '0 < qOvershoot < 2 ** 64'.
    getCurve().amend(_overshoot_.log());

    // The minimum of left and right growth values are calculated.
    // All four integrals are non-negative and either 'integral0Amended' or
    // 'integral1Amended' is non-zero. Because an amended integral is zero if
    // and only if we 'qTarget' is at an interval boundary. And, it cannot be
    // on both boundaries at the same time. Hence the requirements of 
    // 'minFractions' are satisfied.
    bool which;
    (growthNumerator, growthDenominator, which) = minFractions(
      integral0Incremented,
      integral0Amended,
      integral1Incremented,
      integral1Amended
    );
    if (which) {
      // Residual value resulted from mismatch is calculated and given to the
      // swapper. The difference between the left and right growth values
      // incurs this residual amount.
      // 'mulDiv' and the subtraction are safe because the output is not
      // greater than 'integral0Incremented'.
      X216 integralIncremented = integral0Amended.mulDiv(
        growthNumerator,
        growthDenominator
      );
      X127 value = safeInRangeAmount(
        integral0Incremented - integralIncremented,
        liquidity,
        false,
        false
      );
      integral0Incremented = integralIncremented;
      if (zeroForOne) incomingAmount = max(zeroX127, incomingAmount - value);
      else outgoingAmount = outgoingAmount & value;
    } else {
      // Residual value resulted from mismatch is calculated and given to
      // swapper. The difference between the left and right growth values
      // incurs this residual amount.
      // 'mulDiv' and the subtraction are safe because the output is not
      // greater than 'integral1Incremented'.
      X216 integralIncremented = integral1Amended.mulDiv(
        growthNumerator,
        growthDenominator
      );
      X127 value = safeInRangeAmount(
        max(integral1Incremented - integralIncremented, zeroX216),
        liquidity,
        true,
        false
      );
      integral1Incremented = integralIncremented;
      if (zeroForOne) outgoingAmount = outgoingAmount & value;
      else incomingAmount = max(zeroX127, incomingAmount - value);
    }
  }

  // The two amended integrals are placed in memory.
  setIntegral0(integral0Amended);
  setIntegral1(integral1Amended);

  // The current value is moved.
  setLogPriceCurrent(_target_.log());

  // The curve is amended with the target.
  // The requirement of 'amend' is satisfied because
  // '0 < target < 2 ** 64'.
  getCurve().amend(_target_.log());

  // Accrued growth portions are calculated next.
  if (isGrowthPortion()) {
    // Subtraction is safe because 'integralIncremented' is greater than
    // 'integralAmended'.
    (X127 updatedAccrued0, X23 updatedPoolRatio0) = calculateGrowthPortion(
      safeInRangeAmount(
        integral0Incremented - integral0Amended,
        liquidity,
        false,
        false
      ),
      getAccrued0(),
      getPoolRatio0()
    );
    setAccrued0(updatedAccrued0);
    setPoolRatio0(updatedPoolRatio0);

    // Subtraction is safe because 'integralIncremented' is greater than
    // 'integralAmended'.
    (X127 updatedAccrued1, X23 updatedPoolRatio1) = calculateGrowthPortion(      
      safeInRangeAmount(
        integral1Incremented - integral1Amended,
        liquidity,
        true,
        false
      ),
      getAccrued1(),
      getPoolRatio1()
    );
    setAccrued1(updatedAccrued1);
    setPoolRatio1(updatedPoolRatio1);
  }

  // Growth value for the active interval is updated.
  // Subtraction is safe because 'integralIncremented' is greater than
  // 'integralAmended'.
  // The requirements of 'updateGrowth' are satisfied because the current 
  // growth does not exceed 'maxGrowth', all inputs are non-negative and a
  // zero denominator is never chosen by 'minFractions'.
  setGrowth(
    updateGrowth(
      getGrowth(),
      growthNumerator - growthDenominator,
      growthDenominator
    )
  );

  // The outgoing and incoming amounts are added to 'amount0' and 'amount1'.
  updateAmounts(outgoingAmount, incomingAmount);

  // Interval needs to be cleared in memory because 'swapWithin' may be called
  // twice per transaction.
  if (!exactAmount) clearInterval();
  return exactAmount;
}

/// @notice Crosses an entire interval from 'qBack' to 'qNext'.
function cross() pure returns (bool halt) {
  // The number of shares should not be less than 'crossThreshold' for this
  // function to cross the interval.
  if (getSharesTotal() < getCrossThreshold()) return true;

  // The current logPrice value is moved all the way to the end.
  setLogPriceCurrent(_next_.log());

  // A new curve is constructed.
  // The requirements of 'newCurve' are met because both both inputs are
  // between '0' and '2 ** 64 - 1'.
  getCurve().newCurve(_next_.log(), _back_.log());

  // The 'outgoing' and 'incoming' amounts are determined next.
  // The multiplication is safe because both values are less than '2 ** 127'.
  X111 liquidity = getGrowth().times(getSharesTotal());
  X127 outgoingAmount;
  X127 incomingAmount;
  // Multiplications are safe because 'incomingMax < oneX216 * exp(-8)'.
  if (getZeroForOne()) {
    outgoingAmount = safeInRangeAmount(
      getIntegral1(),
      liquidity,
      true,
      false
    );
    incomingAmount = safeInRangeAmount(
      _next_.sqrt(false) % getIncomingMax(),
      liquidity,
      false,
      true
    );
  } else {
    outgoingAmount = safeInRangeAmount(
      getIntegral0(),
      liquidity,
      false,
      false
    );
    incomingAmount = safeInRangeAmount(
      _next_.sqrt(true) % getIncomingMax(),
      liquidity,
      true,
      true
    );
  }

  // Here, the two outgoing integrals are determined.
  // Multiplications are safe because 'outgoingMax < oneX216 * exp(-8)'.
  (X216 integral0, X216 integral1) = getZeroForOne() ? 
    (_next_.sqrt(false) % getOutgoingMax(), zeroX216) : 
    (zeroX216, _next_.sqrt(true) % getOutgoingMax());
  setIntegral0(integral0);
  setIntegral1(integral1);

  // Growth value for the active interval is updated.
  // Subtraction is safe because 'incomingMax > outgoingMax'.
  // The requirements of 'updateGrowth' are satisfied because the current 
  // growth does not exceed 'maxGrowth' and all inputs are positive.
  setGrowth(
    updateGrowth(
      getGrowth(),
      getIncomingMax() - getOutgoingMax(),
      getOutgoingMax()
    )
  );

  // If the interval is empty, then we do not need to adjust exchange amounts.
  if (getSharesTotal() == 0) return false;

  // Accrued growth portions are calculated next.
  if (isGrowthPortion()) {
    // Subtraction and 'mulDiv' are safe because 'incomingMax > outgoingMax'.
    X127 amount = incomingAmount.mulDiv(
      getIncomingMax() - getOutgoingMax(),
      getIncomingMax()
    );

    // The three requirements of 'calculateGrowthPortion' are satisfied.
    if (getZeroForOne()) {
      (X127 updatedAccrued, X23 updatedPoolRatio) = calculateGrowthPortion(
        amount,
        getAccrued0(),
        getPoolRatio0()
      );
      setAccrued0(updatedAccrued);
      setPoolRatio0(updatedPoolRatio);
    } else {
      (X127 updatedAccrued, X23 updatedPoolRatio) = calculateGrowthPortion(
        amount,
        getAccrued1(),
        getPoolRatio1()
      );
      setAccrued1(updatedAccrued);
      setPoolRatio1(updatedPoolRatio);
    }
  }

  // The outgoing and incoming amounts are added to 'amount0' and 'amount1'.
  updateAmounts(outgoingAmount, incomingAmount);
}

/// @notice Transitions to the next interval.
function transition() {
  bool zeroForOne = getZeroForOne();

  // The two reserve integrals are moved next.
  (
    X216 integral0,
    X216 integral1
  ) = zeroForOne ? (
    zeroX216,
    // We use '%' because 'outgoingMax' has an 'exp(-8)' factor.
    _next_.sqrt(true) % getOutgoingMax()
  ) : (
    // We use '%' because 'outgoingMax' has an 'exp(-8)' factor.
    _next_.sqrt(false) % getOutgoingMax(),
    zeroX216
  );
  setIntegral0(integral0);
  setIntegral1(integral1);

  // 'qBack' is moved.
  _back_.copyPrice(_next_);

  // 'qNext' is moved.
  {
    (X59 qNext, X216 nextSqrt, X216 nextSqrtInverse) = zeroForOne ? (
      _next_.log() - _spacing_.log(),
      _next_.sqrt(false) ^ _spacing_.sqrt(true),
      _next_.sqrt(true) & _spacing_.sqrt(false)
    ) : (
      _next_.log() + _spacing_.log(),
      _next_.sqrt(false) & _spacing_.sqrt(false),
      _next_.sqrt(true) ^ _spacing_.sqrt(true)
    );
    _next_.storePrice(qNext, nextSqrt, nextSqrtInverse);
  }

  // growth ratios are updated next.
  X208 growthMultiplierCurrent = getNextGrowthMultiplier();

  uint256 storageSlot = getGrowthMultiplierSlot(getPoolId(), _next_.log());
  X208 growthMultiplier = readGrowthMultiplier(storageSlot);
  if (growthMultiplier == zeroX208) {
    // 'mulDiv' is safe because the output does not exceed 256-bits.
    growthMultiplier = exp8X208.mulDiv(
      _next_.sqrt(zeroForOne),
      oneX216 - _spacing_.sqrt(false)
    );
    writeGrowthMultiplier(storageSlot, growthMultiplier);
  }
  setNextGrowthMultiplier(growthMultiplier);

  // The requirements of 'mulDivByExpInv8' are satisfied because the current
  // growth does not exceed 'maxGrowth' and 'backSqrt < oneX216'.
  // The addition is safe because the output does not exceed 256-bits.
  growthMultiplier = getBackGrowthMultiplier() + getGrowth().mulDivByExpInv8(
    _back_.sqrt(!zeroForOne)
  );
  setBackGrowthMultiplier(growthMultiplier);
  storageSlot = getGrowthMultiplierSlot(getPoolId(), _back_.log());
  writeGrowthMultiplier(storageSlot, growthMultiplier);

  // Here, the new value for 'growth' is determined.
  // The requirements of 'mulDivByExpInv8' are satisfied because the resulting
  // value does not exceed 'maxGrowth'.
  setGrowth(
    max(
      oneX111,
      (growthMultiplierCurrent - getNextGrowthMultiplier()).mulDivByExpInv8(
        _back_.sqrt(!zeroForOne)
      )
    )
  );

  // 'sharesTotal' is updated as we transition to a new interval.
  unchecked {
    int256 sharesDelta = readSharesDelta(
      getSharesDeltaSlot(getPoolId(), _back_.log())
    );
    // The subtraction and addition are safe because of 'sharesGross'.
    setSharesTotal(
      zeroForOne ? 
      uint256(int256(getSharesTotal()) - sharesDelta) : 
      uint256(int256(getSharesTotal()) + sharesDelta)
    );    
  }

  // A new curve is constructed next.
  // The requirements of 'newCurve' are met because both both inputs are
  // between '0' and '2 ** 64 - 1'.
  getCurve().newCurve(_back_.log(), _next_.log());

  // New integral limits are determined for the new interval.
  calculateIntegralLimit();
  calculateIntegralLimitInterval();
}

/// @notice Substitutes 'static parameters' with 'next static parameters' and
/// updates the corresponding storage pointer.
function updateKernel() view {
  unchecked {
    // The addition is safe because 'staticParamsStoragePointerExtension' has
    // the limit of '2 ** 256 - 1'.
    uint256 pointer = getStaticParamsStoragePointerExtension() + 1;
    setStaticParamsStoragePointerExtension(pointer);
    Index length = getPendingKernelLength();
    address storageAddress = getStaticParamsStorageAddress(pointer);
    readStaticParams(storageAddress);
    setPoolGrowthPortion(
      min(getPoolGrowthPortion(), getMaxPoolGrowthPortion())
    );
    readKernel(getKernel(), storageAddress, length);
    setKernelLength(length);
  }
}