// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {
  _current_,
  _origin_,
  _begin_,
  _end_,
  _target_,
  _overshoot_,
  _total0_,
  _total1_,
  _forward0_,
  _forward1_,
  _indexKernelTotal_,
  _indexKernelForward_,
  _indexCurve_,
  _currentToTarget_,
  _incomingCurrentToTarget_,
  _originToOvershoot_,
  _currentToOrigin_,
  _targetToOvershoot_,
  _currentToOvershoot_,
  _interval_,
  _spacing_,
  _endOfInterval_,
  getCurve,
  getLogPriceLimitOffsetted,
  getCurveLength,
  getKernel,
  getDirection,
  getIntegralLimit,
  getZeroForOne,
  getExactInput,
  getLogPriceLimitOffsettedWithinInterval,
  getLogPriceCurrent,
  setZeroForOne,
  setCurveLength,
  setOutgoingMax,
  setOutgoingMaxModularInverse,
  setIncomingMax,
  setCurve,
  setLogPriceLimitOffsetted,
  setIntegralLimit,
  setIndexCurve,
  setDirection,
  setLogPriceLimitOffsettedWithinInterval,
  setIntegral0,
  setIntegral1
} from "./Memory.sol";
import {Index, zeroIndex, oneIndex, IndexLibrary} from "./Index.sol";
import {X15} from "./X15.sol";
import {X59, min, max, zeroX59, twoX59, epsilonX59} from "./X59.sol";
import {X74} from "./X74.sol";
import {
  X216,
  min,
  max,
  zeroX216,
  oneX216,
  epsilonX216,
  expInverse8X216
} from "./X216.sol";
import {FullMathLibrary} from "./FullMath.sol";
import {Curve} from "./Curve.sol";
import {Kernel} from "./Kernel.sol";
import {IntegralLibrary} from "./Integral.sol";
import {PriceLibrary} from "./Price.sol";
import {
  SearchingForOutgoingTargetFailed,
  SearchingForIncomingTargetFailed,
  SearchingForOvershootFailed
} from "./Errors.sol";

using PriceLibrary for uint16;
using IndexLibrary for uint16;
using IntegralLibrary for uint16;
using IntegralLibrary for X216;

/// @notice In order to perform a swap within the current active liquidity
/// interval, the following parameters should be set in memory:
///
/// - 'logPriceLimitOffsettedWithinInterval'
/// - 'indexCurve'
/// - 'direction'
/// - 'current'
/// - 'origin'
/// - 'begin'
/// - 'end'
/// - 'target'
/// - 'total0'
/// - 'total1'
///
/// where the description of each parameter is given in 'Memory.sol'. This
/// function initiates the 'swapWithin' method of 'Swap.sol' by setting the
/// above parameters.
function initiateInterval() pure {
  // We first load the memory pointer for the curve sequence from the memory.
  Curve curve = getCurve();

  // The value set as 'logPriceLimitOffsetted' may be outside of the current
  // active liquidity interval. In such cases, we first need to perform a swap
  // towards the current interval boundary and then we transition to a new
  // interval. In order to perform the former step, 'logPriceLimitOffsetted'
  // needs to be capped by the boundaries of the current active liquidity
  // interval.
  {
    // To this end, the first two members of the curve sequence are loaded. As
    // explained in 'Curve.sol', the first two members are the boundaries of
    // the current active liquidity interval.
    (X59 qLower, X59 qUpper) = curve.boundaries();

    // Signed comparison is valid here because:
    //
    // '0 < qLower < 2 ** 64',
    // '0 < qUpper < 2 ** 64',
    // '0 < getLogPriceLimitOffsetted() < 2 ** 64'.
    //
    // Each of the above values are offsetted logarithmic prices that occupy
    // exactly '64' bits in memory.
    //
    // The resulting value is also between '0' and '2 ** 64' and can be safely
    // stored within the allocated '64' bits of memory.
    setLogPriceLimitOffsettedWithinInterval(
      min(max(qLower, getLogPriceLimitOffsetted()), qUpper)
    );
  }

  // As explained in 'Curve.sol', the length of the curve sequence is always
  // greater than or equal to '2'. Hence, subtraction is safe here.
  Index indexCurve = getCurveLength() - oneIndex;

  // When performing a swap within the current active liquidity interval, we
  // explore members of the curve sequence by starting from the last member.
  // Hence, the initial index should point to the last member, which is how
  // 'indexCurve' is chosen. The very first execution of the method
  // 'movePhase()' reduces 'indexCurve' to 'getCurveLength() - twoIndex' which
  // refers to the very first phase of 'w(.)' to be explored.
  //
  // The value of 'indexCurve' is less than 'getCurveLength()' and therefore
  // does not exceed '2' bytes. Hence, it can be safely stored in the allocated
  // 2 bytes of memory.
  setIndexCurve(indexCurve);

  // Index out of range is not possible because 'indexCurve' refers to the last
  // member of the curve which is the current offsetted logarithmic price as
  // explained in 'Curve.sol'.
  X59 current = curve.member(indexCurve);

  // As explained in 'Memory.sol', the curve sequence leads to a function
  // 'w : [qLower, qUpper] -> [0, qSpacing]' which is composed of 'phases'. For
  // example, let 'qLower, qUpper, qCurrent' represent the curve sequence.
  // Then, 'w(q)' can be plotted as follows:
  //
  //          ^
  //  spacing |\
  //          | \
  //          |  \
  //          |   \
  //          |    \
  //          |     \
  //          |      \
  //          |               /
  //          |              /
  //          |             /
  //          |            /
  //          |           /
  //          |          /
  //          |         /
  //          |        /
  //        0 +-------+--------+
  //       qLower  qCurrent  qUpper
  //
  // See 'Memory.sol' for the precise definition of 'w(q)'. In general, the
  // very first 'phase' to be explored corresponds to the segment in between
  // 'curve.member(getCurveLength() - oneIndex)' and 
  // 'curve.member(getCurveLength() - twoIndex)'. In this example, the first
  // phase is within '(qCurrent, qUpper)'.
  //
  // Here, the direction of the initial 'phase' to be explored is determined
  // and its opposite is set in memory. If
  // '(2 ** 59) * (16 + qCurrent) < curve.member(indexCurve - oneIndex)', then
  // the direction is towards '+oo' and we should store 'true'. Alternatively
  // if '(2 ** 59) * (16 + qCurrent) > curve.member(indexCurve - oneIndex)',
  // then the direction is towards '-oo' and we should store 'false'. Notice
  // that members of the curve sequence may never be equal. Lastly, we store
  // the opposite so that after the first execution of 'movePhase()' the
  // direction is corrected. As explained in 'Memory.sol' regardless of the
  // value for 'zeroForOne' (i.e., whether the swap is towards '+oo' or '-oo'),
  // we flip the direction flag every time that we move to a new 'phase',
  // because consecutive phases have opposite directions. In the above example,
  // the direction of the very first 'phase' within '(qCurrent, qUpper)' is
  // towards '+oo' and the direction of the second 'phase' within
  // '(qLower, qCurrent)' is towards '-oo', i.e., 'false' and 'true',
  // respectively. We store the opposite of the direction for the first
  // 'phase', so that the first run of the function 'movePhase()' would change
  // the direction to the intended value.
  //
  // Subtraction is safe because the length of the curve is always greater than
  // or equal to '2' and hence,
  // 'indexCurve - oneIndex == getCurveLength() - twoIndex >= zeroIndex'.
  //
  // Signed comparison is valid here because both sides are members of curve
  // that are nonnegative and less than '2 ** 64'.
  setDirection(current < curve.member(indexCurve - oneIndex));

  // Next, the values '(2 ** 216) * exp(- 8 - qCurrent / 2)' and
  // '(2 ** 216) * exp(- 8 + qCurrent / 2)' are determined and stored in memory
  // along with '(2 ** 59) * (16 + qCurrent)'. The resulting values are then
  // copied as initial points for 'qOrigin', 'qBegin', 'qEnd', 'qTarget',
  // 'qTotal0', and 'qTotal1'.
  //
  // The requirements of store price are satisfied because 'qCurrent' is a 
  // member of the curve sequence and may never exceed '64' bits. Additionally,
  // the value for all of the pointers below is a constant greater than '32'.
  //
  // The definition for the content of each memory pointer is given in
  // 'Memory.sol'.
  _current_.storePrice(current);
  _origin_.copyPrice(_current_);
  _begin_.copyPrice(_current_);
  _end_.copyPrice(_current_);
  _target_.copyPrice(_current_);
  // Notice that according to 'PriceLibrary' one can copy the content of a
  // price pointer to a price with height which is what we are doing here.
  _total0_.copyPrice(_current_);
  _total1_.copyPrice(_current_);
}

/// @notice Increments 'indexKernelTotal' and substitutes 'total0' with
/// 'total1'. Lastly, loads a new breakpoint from the kernel and stores its
/// resultant with 'qOrigin' into the price pointer '_total1_'.
///
/// ---------------------------------------------------------------------------
///
/// Overflow of 'indexKernelTotal' and index out of range should be avoided
/// externally.
function moveBreakpointTotal() pure {
  // A swap can be interpreted as a price movement. The precise value for
  // 'qTarget' may be determined from 'logPriceLimit' or we may need to
  // determine that based on 'amountSpecified'. We also need to keep track of
  // the outgoing and incoming amounts as we move from the 'qCurrent' to
  // 'qTarget'. As explained in 'Memory.sol', in the definitions for 'amount0'
  // and 'amount1', if 'zeroForOne == false', the outgoing and incoming amounts
  // are proportional to:
  //
  //                           - 8     / qTarget
  //    currentToTarget      e        |    - h / 2
  //  '----------------- := ------- * |  e         k(w(h)) dh'.
  //       2 ** 216            2      |
  //                                 / qCurrent
  //
  //                                   - 8     / qTarget
  //    incomingCurrentToTarget      e        |    + h / 2
  //  '------------------------- := ------- * |  e         k(w(h)) dh',
  //           2 ** 216                2      |
  //                                         / qCurrent
  //
  // and if 'zeroForOne == true', the outgoing and incoming amounts are
  // proportional to:
  //
  //                           - 8     / qCurrent
  //    currentToTarget      e        |    + h / 2
  //  '----------------- := ------- * |  e         k(w(h)) dh',
  //       2 ** 216            2      |
  //                                 / qTarget
  //
  //                                   - 8     / qCurrent
  //    incomingCurrentToTarget      e        |    - h / 2
  //  '------------------------- := ------- * |  e         k(w(h)) dh'.
  //            2 ** 216               2      |
  //                                         / qTarget
  //
  // Hence, in order to keep track of the outgoing and incoming amounts, we
  // need to keep track of the two integrals, 'currentToTarget' and 
  // 'incomingCurrentToTarget'. Remember that both functions 'k' and 'w' are
  // piecewise linear. As a result, 'k(w(h))' is also piecewise linear. In
  // order to keep track of the integrals, we proceed from 'qCurrent' to
  // 'qTarget' piece by piece. At each step, we take the outgoing and incoming
  // integrals of the piece under exploration using 'IntegralLibrary' and
  // increment the total integrals 'currentToTarget' and
  // 'incomingCurrentToTarget' with the resulting values.
  // 
  // To this end, we need to keep track of the pieces for both 'w' and 'k'.
  // As explained in 'Memory.sol', each piece of the function 'w' is regarded
  // as a 'phase' and the current phase under exploration can be characterized
  // by the following three members of the curve sequence:
  //
  //  - 'qEnd := q[indexCurve]',
  //
  //  - 'qOrigin := q[indexCurve + 1]',
  //
  //  - 'q[indexCurve + 2]',
  //
  // where the out of range member 'q[curveLength]' is assigned the same value
  // as the last member 'q[curveLength - 1]'.
  //
  // 'q[indexCurve + 2]' is where the 'phase' starts. 'qEnd' is where the phase
  // ends. If 'q[indexCurve + 2] < qEnd' then the 'phase' under exploration in
  // the diagram of 'w(.)' corresponds to a segment whose extension intersects
  // with the horizontal axis at 'qOrigin' with the angle '+45' degrees. In
  // this case, 'getDirection() == false' and 'w(h) := h - qOrigin'. If
  // 'qBegin > qEnd' then the 'phase' under exploration in the diagram of
  // 'w(.)' corresponds to a segment whose extension intersects with the
  // horizontal axis at 'qOrigin' with the angle '+135' degrees. In this case,
  // 'w(h) := qOrigin - h' and 'getDirection() == true'.
  //
  // As we move from 'qCurrent' towards the destination of the swap, we may
  // need to move from one 'phase' to the next. Let
  // '(qEnd, qOrigin, q[indexCurve + 2])' represent the current 'phase' under
  // exploration. If 'q[indexCurve + 2] < qEnd' ('getDirection() == false'),
  // then we have
  //
  //  'k(w(h)) == k(h - qOrigin)' for every 'q[indexCurve + 2] < h < qEnd'.
  //
  // If 'qEnd < q[indexCurve + 2]' ('getDirection() == true'), then we have
  //
  //  'k(w(h)) == k(qOrigin - h)' for every 'qEnd < h < q[indexCurve + 2]'.
  //
  // But 'k : [0, qSpacing] -> [0, 1]' is also piecewise linear. Now that we
  // fixed one phase of the function 'w' and everything is with respect to the
  // function 'k', we need to account for every piece of 'k' within 
  //
  //  '(q[indexCurve + 2] - qOrigin, qEnd - qOrigin)'
  //
  // or
  //
  //  '(qEnd - qOrigin, q[indexCurve + 2] - qOrigin)',
  //
  // depending on the direction. 'indexKernelTotal' is the index that we use
  // for this purpose. At first, it is equal to 'zeroIndex' and it is
  // incremented by 'oneIndex' every time that this function is called.
  //
  // Let
  //
  //  'b0 := b[indexKernelTotal]',
  //  'c0 := c[indexKernelTotal]',
  //
  // represent the horizontal and vertical coordinates of the kernel breakpoint
  // corresponding to 'indexKernelTotal', respectively (prior to it being
  // incremented). Let
  //
  //  'b1 := b[indexKernelTotal + oneIndex]',
  //  'c1 := c[indexKernelTotal + oneIndex]',
  //
  // represent the vertical and horizontal coordinates of the kernel breakpoint
  // corresponding to 'indexKernelTotal + oneIndex'.
  // 
  // If 'q[indexCurve + 2] < qEnd', then we want to integrate
  //
  //  'exp(- h / 2) * k(h - qOrigin)'
  //
  // and
  //
  //  'exp(+ h / 2) * k(h - qOrigin)'
  //
  // between the two breakpoints characterized by 'indexKernelTotal' and
  // 'indexKernelTotal + oneIndex'. If 'qEnd < q[indexCurve + 2]', then we want
  // to integrate
  //
  //  'exp(- h / 2) * k(qOrigin - h)'
  //
  // and
  //
  //  'exp(+ h / 2) * k(qOrigin - h)'
  //
  // between the two breakpoints characterized by 'indexKernelTotal' and
  // 'indexKernelTotal + oneIndex'.
  //
  // To that end, the first step is to shift the two breakpoints by 'qOrigin'.
  // The memory spaces 'total0' and 'total1' keep track of these shifted
  // breakpoints. In other words, 'total0' and 'total1' are the breakpoints for
  // 'k(h - qOrigin)' or 'k(qOrigin - h)', depending on the direction.
  //
  // As explained in 'Memory.sol', each one of 'total0' and 'total1' are prices
  // with height and each one occupies '64' bytes in memory via the layout
  // explained in 'Price.sol'.
  //
  // If 'q[indexCurve + 2] < qEnd', we have:
  // 
  //  '_total0_.height() := (2 ** 15) * c0'
  //  '_total1_.height() := (2 ** 15) * c1'
  //  '_total0_.log() := (2 ** 59) * (16 + qOrigin + b0)'
  //  '_total1_.log() := (2 ** 59) * (16 + qOrigin + b1)'
  // 
  // If 'qEnd < q[indexCurve + 2]', we have:
  //
  //  '_total0_.height() := (2 ** 15) * c0'
  //  '_total1_.height() := (2 ** 15) * c1'
  //  '_total0_.log() := (2 ** 59) * (16 + qOrigin - b0)'
  //  '_total1_.log() := (2 ** 59) * (16 + qOrigin - b1)'
  //
  // The values for '_total0_.sqrt(false)', '_total1_.sqrt(false)',
  // '_total0_.sqrt(true)', and '_total1_.sqrt(true)' are calculated
  // accordingly to mirror the above logarithmic values.
  //
  // Now, in order to move from one pair of breakpoints to the next we first
  // replace the '64' bytes of 'total0' with the '64' bytes of 'total1' so that
  // 'total1' can be used for the next shifted price to be calculated.
  _total0_.copyPriceWithHeight(_total1_);

  // Then, we calculate the new content of 'total1' as described above using
  // the function 'impose' from 'KernelLibrary'.
  //
  // Index out of range for 'indexKernelTotal' is avoided externally.
  //
  // Next, we are going to prove that:
  //
  //  '0 < (2 ** 59) * (16 + qOrigin + b1) < 2 ** 64',
  //  '0 < (2 ** 59) * (16 + qOrigin - b1) < 2 ** 64',
  //
  // as required by 'impose' in 'Kernel.sol'.
  //
  // Let 'pLower' and 'pUpper' denote the minimum and maximum price in the
  // active liquidity interval, respectively and define
  //
  //  'qLower := log(pLower / pOffset)',
  //  'qUpper := log(pUpper / pOffset)'.
  //
  // Let 'qSpacing := qUpper - qLower' denote the length of every liquidity
  // interval. Upon initializing a pool, the given curve sequence is validated
  // by the method 'validate' in 'Curve.sol'.
  //
  // When validating the curve sequence, the custom
  // error 'BlankIntervalsShouldBeAvoided' ensures that '16 + qLower' is
  // greater than 'qSpacing' and '16 + qUpper' is smaller than '32 - qSpacing'.
  // As a result, every member 'q' of the initial curve sequence
  // satisfies:
  // 
  //  'qSpacing < 16 + q < 32 - qSpacing'
  // 
  // In addition, the method 'setSwapParams' in 'Swap.sol' ensures that
  // 'qTarget' for every swap is also bounded by both
  // 'qSpacing + 1 / (2 ** 59)' and '32 - 1 / (2 ** 59) - qSpacing'.
  // This ensures that the above inequality is always satisfied for every
  // member of the curve and not only the initial curve.
  //
  // Now, since 'qOrigin' is a member of the curve sequence, we also have:
  //
  //  'qSpacing < 16 + qOrigin < 32 - qSpacing'
  //
  // Hence,
  //
  //  '0 < (2 ** 59) * (16 + qOrigin) <= (2 ** 59) * (16 + qOrigin + b1)
  //     < (2 ** 59) * (32 - qSpacing + b1) <= (2 ** 59) * 32 == 2 ** 64'
  //
  // where '0 < (2 ** 59) * (16 + qOrigin)' is because 'qOrigin' is a member of
  // the curve and 'b1 <= qSpacing' is concluded from the custom error
  // 'HorizontalCoordinatesMayNotExceedLogSpacing' when validating kernel in
  // 'KernelCompact.sol'.
  //
  // Additionally,
  //
  //  '2 ** 64 >  (2 ** 59) * (16 + qOrigin)
  //           >= (2 ** 59) * (16 + qOrigin - b1)
  //           >  (2 ** 59) * (qSpacing - b1) >= 0'
  //
  // where '(2 ** 59) * (16 + qOrigin) < 2 ** 64' is because 'qOrigin' is a
  // member of the curve and 'b1 <= qSpacing' is concluded from the custom
  // error 'HorizontalCoordinatesMayNotExceedLogSpacing' when validating kernel
  // in 'KernelCompact.sol'.
  //
  // Lastly, '_total1_' is a fixed value greater than '34'.
  //
  // Therefore, the input requirements of 'impose' are satisfied.
  getKernel().impose(
    // The resulting values are stored using the pointer '_total1_'.
    _total1_,
    // 'qOrigin' is used as the base price for the shift.
    _origin_,
    // The incremented index is safely stored in the allocated 2 bytes of
    // memory because overflow of 'indexKernelTotal' is avoided externally.
    _indexKernelTotal_.incrementIndex(),
    // Since the phase is fixed, the current direction is used for this shift.
    getDirection()
  );
}

/// @notice Increments 'indexKernelForward' and substitutes 'forward0' with
/// 'forward1'. Lastly, loads a new breakpoint from the kernel and stores its
/// resultant with 'qTarget' into the memory space 'forward1'.
///
/// ---------------------------------------------------------------------------
///
/// Overflow of 'indexKernelForward' and index out of range should be avoided
/// externally.
function moveBreakpointForward() pure {
  // In order to perform a swap within the active liquidity interval, we first
  // determine 'qTarget' as well as the outgoing and incoming amounts. After
  // this step, we need to construct a new curve sequence in preparation for
  // the next swap. To that end, we amend the curve sequence. The process of
  // amending is explained in 'Curve.sol'. Each amendment involves potentially
  // disposing a number of members from the end of the curve sequence and then
  // adding a new member to the end.
  //
  // As explained in 'Memory.sol', in the definition of 'overshoot', each swap
  // involves a maximum of two amendments. We first amend the curve sequence
  // with 'qOvershoot'. Then, we amend the resulting curve sequence with
  // 'qTarget' so that the last member becomes 'qTarget'. The purpose of
  // amending with 'qOvershoot' is to ensure that the conservation of reserves
  // is maintained. In other words, we want to have:
  // 
  //  'totalReserveOfTag0Before == totalReserveOfTag0After',
  //  'totalReserveOfTag1Before == totalReserveOfTag1After'.
  //
  // In order to satisfy the two equations above, we need two variables. One is
  // 'growth', which increases with every swap. But since we have two
  // equations, we need another degree of freedom in the choice for the new
  // curve sequence. This is why we resort to the notion of 'overshoot'. The
  // reason behind 'overshoot' is further explained in 'Memory.sol'.
  //
  // Consider the new curve sequence which is amended by both 'qOvershoot' and
  // then 'qTarget'. Construct 'wAmended' accordingly using the formula given
  // in 'Memory.sol'. By canceling the first variable 'growth', the search for
  // 'qOvershoot' boils down to solving the following equation:
  //
  //      / qTarget                         / qUpper
  //     |   + h/2                         |   - h/2
  //     |  e      k(wAmended(h)) dh       |  e      k(wAmended(h)) dh
  //     |                                 |
  //    / qLower                          / qTarget
  //  '------------------------------ == ------------------------------'.
  //         / qTarget                         / qUpper
  //        |    + h/2                        |    - h/2
  //        |  e       k(w(h)) dh             |  e       k(w(h)) dh
  //        |                                 |
  //       / qLower                          / qTarget
  //
  // For simplicity, consider the case 'zeroForOne == false'. In this case,
  //
  //                     /  k(w(h))            if  qOvershoot < h < qUpper
  //  'k(wAmended(h)) = |   k(h - qTarget)     if  qTarget < h < qOvershoot '
  //                    |   k(qOvershoot - h)  if  qOrigin < h < qTarget
  //                     \  k(w(h))            if  qLower < h < qOrigin
  //
  // which means that
  //
  //     / qUpper
  //    |   - h / 2
  //  ' |  e        k(wAmended(h)) dh ==
  //    |
  //   / qTarget
  //
  //     / qOvershoot                    / qUpper
  //    |   - h / 2                     |   - h / 2
  //    |  e        k(h - qTarget) dh + |  e        k(w(h)) dh '.
  //    |                               |
  //   / qTarget                       / qOvershoot
  //
  // Hence, we need to integrate 'exp(-h / 2) * k(h - qTarget)' from 'qTarget'
  // to 'qOvershoot'.
  // 
  // Remember that at this stage, 'qOvershoot' is still an unknown value which
  // will be determined via numerical search. More precisely, after 'qTarget'
  // is determined, we keep moving forward in the same direction until we find
  // the precise value for 'qOvershoot'. But as we move forward, we need to
  // keep track of the integral
  //
  //     / qOvershoot
  //    |   - h / 2
  //  ' |  e        k(h - qTarget) dh
  //    |
  //   / qTarget
  //
  // To this end, we enumerate pieces of 'k' one by one and
  // 'indexKernelForward' is the index that we use for this purpose. At first,
  // before the start of the search for 'qOvershoot', this index is equal to
  // 'zeroIndex' and it is incremented by 'oneIndex' everytime that the present
  // function is called.
  //
  // Let
  //
  //  'b0 := b[indexKernelForward]',
  //  'c0 := c[indexKernelForward]',
  //
  // represent the horizontal and vertical coordinates of the kernel breakpoint
  // corresponding to 'indexKernelForward', respectively (prior to it being
  // incremented). Let
  //
  //  'b1 := b[indexKernelForward + oneIndex]',
  //  'c1 := c[indexKernelForward + oneIndex]',
  //
  // represent the vertical and horizontal coordinates of the kernel breakpoint
  // corresponding to 'indexKernelForward + oneIndex'.
  // 
  // If 'zeroForOne == false', then we want to integrate 
  //
  //  'exp(- h / 2) * k(h - qTarget)'
  //
  // between the two breakpoints that are characterized by 'indexKernelForward'
  // and 'indexKernelForward + oneIndex'. If 'zeroForOne == true', then we want
  // to integrate
  //
  //  'exp(+ h / 2) * k(qTarget - h)'
  //
  // between the two breakpoints characterized by 'indexKernelForward' and
  // 'indexKernelForward + oneIndex'.
  //
  // To that end, the first step is to shift the two breakpoints by 'qTarget'.
  // The memory spaces 'forward0' and 'forward1' keep track of these shifted
  // breakpoints. In other words, 'forward0' and 'forward1' are the breakpoints
  // for 'k(h - qTarget)' or 'k(qTarget - h)', depending on 'zeroForOne'.
  //
  // As explained in 'Memory.sol', each one of 'forward0' and 'forward1' are
  // prices with height and each one occupies '64' bytes in memory via the
  // layout explained in 'Price.sol'.
  //
  // If 'zeroForOne == false', we have:
  // 
  //  '_forward0_.height() := (2 ** 15) * c0'
  //  '_forward1_.height() := (2 ** 15) * c1'
  //  '_forward0_.log() := (2 ** 59) * (16 + qTarget + b0)'
  //  '_forward1_.log() := (2 ** 59) * (16 + qTarget + b1)'
  // 
  // If 'zeroForOne == true', we have:
  //
  //  '_forward0_.height() := (2 ** 15) * c0'
  //  '_forward1_.height() := (2 ** 15) * c1'
  //  '_forward0_.log() := (2 ** 59) * (16 + qTarget - b0)'
  //  '_forward1_.log() := (2 ** 59) * (16 + qTarget - b1)'
  //
  // The values for 'forward0.sqrt(false)', 'forward1.sqrt(false)',
  // 'forward0.sqrt(true)', and 'forward1.sqrt(true)' are calculated
  // accordingly to mirror the above logarithmic prices.
  //
  // Now, in order to move from one pair of breakpoints to the next we first
  // replace the '64' bytes of 'forward0' with the '64' bytes of 'forward1' so
  // that 'forward1' can be used for the next shifted price to be calculated.
  _forward0_.copyPriceWithHeight(_forward1_);

  // Then we calculate the new value for 'forward1' as described above using
  // the function 'impose' from 'KernelLibrary'.
  //
  // Index out of range for 'indexKernelForward' is avoided externally.
  //
  // Next, we are going to prove that:
  //
  //  '0 < (2 ** 59) * (16 + qTarget - b1) < 2 ** 64'
  //  '0 < (2 ** 59) * (16 + qTarget + b1) < 2 ** 64'
  //
  // as required by 'impose' in 'Kernel.sol' for cases 'left == false' and
  // 'left == true', respectively.
  //
  // Let 'pLower' and 'pUpper' denote the minimum and maximum price in the
  // active liquidity interval, respectively and define
  //
  //  'qLower := log(pLower / pOffset)',
  //  'qUpper := log(pUpper / pOffset)'.
  //
  // Let 'qSpacing := qUpper - qLower' denote the length of every liquidity
  // interval. Upon initializing a pool, the given curve sequence is validated
  // by the method 'validate' in 'Curve.sol'. When validating the curve
  // sequence, the custom error 'BlankIntervalsShouldBeAvoided' ensures that
  // '16 + qLower' is greater than 'qSpacing' and '16 + qUpper' is smaller than
  // '32 - qSpacing'. As a result, every member 'q' of the initial curve
  // sequence satisfies:
  // 
  //  'qSpacing < 16 + q < 32 - qSpacing'
  // 
  // In addition, the method 'setSwapParams' in 'Swap.sol' ensures that
  // 'qTarget' for every swap is also bounded by both
  // 'qSpacing + 1 / (2 ** 59)' and '32 - 1 / (2 ** 59) - qSpacing'.
  // This ensures that the above inequality is always satisfied for every
  // member of the curve and not only the initial curve.
  //
  // Remember that 'logPriceLimitOffsettedWithinInterval' is capped by both
  // 'qLower' and 'qUpper' in 'initiateInterval'. Hence, if
  // 'zeroForOne == false':
  //
  //  'qLower <= qCurrent <= qTarget <= qLimit <= qUpper'
  //
  // and if 'zeroForOne == true':
  //
  //  'qLower <= qLimit <= qTarget <= qCurrent <= qUpper'
  //
  // which means that in both cases:
  //
  //  'qSpacing < 16 + qLower <= 16 + qTarget <= 16 + qUpper < 32 - qSpacing'.
  //
  // Put simply, since at this stage we are swapping within the current active
  // interval, then the target belongs to the current active interval.
  //
  // Hence,
  //
  //  '0 <  (2 ** 59) * (16 + qLower)
  //     <= (2 ** 59) * (16 + qTarget)
  //     <= (2 ** 59) * (16 + qTarget + b1)
  //     <  (2 ** 59) * (32 - qSpacing + b1)
  //     <= (2 ** 59) * 32 == 2 ** 64'
  //
  // where '0 < (2 ** 59) * (16 + qLower)' is because 'qLower' is a member of
  // the curve sequence and 'b1 <= qSpacing' is concluded from the custom error
  // 'HorizontalCoordinatesMayNotExceedLogSpacing' when validating kernel in
  // 'KernelCompact.sol'.
  //
  // Additionally,
  //
  //  '2 ** 64 >  (2 ** 59) * (16 + qUpper)
  //           >= (2 ** 59) * (16 + qTarget)
  //           >= (2 ** 59) * (16 + qTarget - b1)
  //           >  (2 ** 59) * (qSpacing - b1) >= 0'
  //
  // where '(2 ** 59) * (16 + qUpper) < 2 ** 64' is because 'qUpper' is a
  // member of the curve sequence and 'b1 <= qSpacing' is concluded from the
  // custom error 'HorizontalCoordinatesMayNotExceedLogSpacing' when validating
  // kernel in 'KernelCompact.sol'.
  //
  // Lastly, '_forward1_' is a fixed value greater than '34'.
  //
  // Therefore, the input requirements of 'impose' are satisfied.
  getKernel().impose(
    // The resulting values are stored using the pointer '_forward1_'.
    _forward1_,
    // 'target' is used as the base price for the shift.
    _target_,
    // The incremented index is safely stored in the allocated 2 bytes of
    // memory because overflow of 'indexKernelForward' is avoided externally.
    _indexKernelForward_.incrementIndex(),
    // In other words, if 'getZeroForOne() == false', we have
    // 'qTarget <= qOvershoot' and we keep track of the breakpoints for
    // 'k(h - qTarget)'. If 'getZeroForOne() == true', we have
    // 'qOvershoot <= qTarget' and we keep track of the breakpoints for
    // 'k(qTarget - h)'. Hence, the direction of the shift should be aligned
    // with 'getZeroForOne()'.
    getZeroForOne()
  );
}

/// @notice This function transitions from one 'phase' of the curve sequence to
/// the next one.
///
/// To this end, 'direction' is flipped. 'indexCurve' is decremented. 'begin'
/// is replaced with 'origin'. 'origin' is replaced with 'end'. A new member of
/// the curve sequence is loaded using the decremented index and is stored in
/// 'end'. Lastly, 'total0' and 'total1' are recalculated based on the new
/// 'origin'.
///
/// ---------------------------------------------------------------------------
///
/// Underflow of 'indexCurve' should be avoided externally.
///
/// Underflow and index out of range for 'indexKernelTotal - oneIndex' should
/// be avoided externally.
///
/// Index out of range for 'indexKernelTotal' should be avoided externally.
function movePhase() pure returns (bool direction) {
  // As explained in 'Memory.sol' and earlier in this script, a swap within the
  // active liquidity interval can be seen as a movement in price from
  // 'qCurrent' to 'qTarget'. In order to determine the outgoing and incoming
  // amounts for a swap, we need to integrate a number of piecewise functions
  // from 'qCurrent' to 'qTarget'.
  //
  // One of these functions is 'w(.)' whose pieces need to be examined one by
  // one. 'w(.)' is constructed from the curve sequence as explained in
  // 'Memory.sol'. Every piece of the function 'w(.)' is regarded as a 'phase'.
  // As explained above, a 'phase' corresponds to three consecutive members of
  // the curve sequence:
  //
  //  - 'qEnd := q[indexCurve]',
  //
  //  - 'qOrigin := q[indexCurve + 1]',
  //
  //  - 'q[indexCurve + 2]'.
  //
  // where the out of range member 'q[curveLength]' is assigned the same value
  // as the last member 'q[curveLength - 1]'.
  //
  // If 'q[indexCurve + 2] < qEnd', we have
  //
  //  'w(q) == q - qOrigin' for every 'q[indexCurve + 2] < q < qEnd'.
  //
  // If 'qEnd < q[indexCurve + 2]', we have
  //
  //  'w(q) == qOrigin - q' for every 'qEnd < q < q[indexCurve + 2]'.
  //
  // Initially, (i.e., for the very first 'phase') we have:
  //
  //  - 'indexCurve == curveLength - 2',
  //
  //  - 'qEnd := q[indexCurve] == q[curveLength - 2]',
  //
  //  - 'qOrigin := q[indexCurve + 1] == q[curveLength - 1]',
  //
  //  - 'q[indexCurve + 2] := q[curveLength] == q[curveLength - 1]'.
  //
  // Then, with each call to the present function, 'indexCurve' is decremented
  // and the following three members of the curve sequence are used to
  // characterize the current phase:
  //
  //  - 'qEnd := q[indexCurve]',
  //
  //  - 'qOrigin := q[indexCurve + 1]',
  //
  //  - 'q[indexCurve + 2]'.
  //
  // Hence, in order to move from a 'phase' to the next one, we need to copy
  // the content of 'origin' to 'begin', then copy the content of 'end' to
  // 'origin', and lastly, we need to load a new member from the curve sequence
  // corresponding to the decremented index.
  //
  // Index out of range for 'indexCurve' is avoided externally.
  //
  // The requirements of 'storePrice' are satisfied because '_end_' is a
  // constant greater than '32' and
  // 'getCurve().member(_indexCurve_.decrementIndex())' is a member of the
  // curve which is positive and less than '2 ** 64'.
  _begin_.copyPrice(_origin_);
  _origin_.copyPrice(_end_);
  _end_.storePrice(getCurve().member(_indexCurve_.decrementIndex()));

  // Next, we need to flip the direction flag. Let the triplet
  //
  //  'q[indexCurve + 1]', 'q[indexCurve + 2]', 'q[indexCurve + 3]'
  //
  // represent the 'phase' prior to the above update and let
  //
  //  'q[indexCurve]', 'q[indexCurve + 1]', 'q[indexCurve + 2]'
  //
  // represent the new 'phase'.
  //
  // Remember that the curve sequence is constructed in such a way that every
  // member is in between the preceding two members. As explained in
  // 'Curve.sol', this ordering rule is always preserved with every amendment
  // of the curve sequence. Hence, we have:
  //
  //  'min(q[indexCurve + 1], q[indexCurve + 2]) <
  //
  //   q[indexCurve + 3] <
  //
  //   max(q[indexCurve + 1], q[indexCurve + 2])'
  //
  // and
  //
  //  'min(q[indexCurve], q[indexCurve + 1]) < 
  //
  //   q[indexCurve + 2] < 
  //
  //   max(q[indexCurve], q[indexCurve + 1])'.
  //
  // Now, consider the following two possibilities:
  //
  //  - If
  //
  //      'q[indexCurve] < q[indexCurve + 1]',
  //
  //    then the second inequality boils down to
  //
  //      'q[indexCurve] < q[indexCurve + 2] < q[indexCurve + 1]',
  //
  //    and, consequently, the first inequality boils do
  //
  //      'q[indexCurve + 2] < q[indexCurve + 3] < q[indexCurve + 1]'.
  //
  //    Hence, we have
  //
  //      'q[indexCurve] < q[indexCurve + 2]',
  //      'q[indexCurve + 3] < q[indexCurve + 1]',
  //
  //    and therefore, the old phase and the new phase have opposite
  //    directions.
  //
  //  - If
  //
  //      'q[indexCurve + 1] < q[indexCurve]',
  //
  //    then the second inequality boils down to
  //
  //      'q[indexCurve + 1] < q[indexCurve + 2] < q[indexCurve]',
  //
  //    and, consequently, the first inequality boils do
  //
  //      'q[indexCurve + 1] < q[indexCurve + 3] < q[indexCurve + 2]'.
  //
  //    Hence, we have
  //
  //      'q[indexCurve + 2] < q[indexCurve]',
  //      'q[indexCurve + 1] < q[indexCurve + 3]',
  //
  //    and therefore, in this case, the old phase and the new phase have
  //    opposite directions as well.
  //
  // So, in both cases as we transition to a new 'phase', the direction should
  // be flipped. The resulting boolean is stored in memory and it is also
  // cached to be given as output and to be used later in the present function.
  setDirection(direction = !getDirection());

  // Fetch the memory pointer for the kernel from the memory.
  Kernel kernel = getKernel();
  Index indexKernelTotal = _indexKernelTotal_.getIndex();

  // Let 'b0' and 'b1' represent the horizontal coordinates of the kernel
  // breakpoint corresponding to 'indexKernelTotal - oneIndex' and
  // 'indexKernelTotal', respectively.
  //
  // Remember that if 'direction == false', we have:
  // 
  //  '_total0_.log() := (2 ** 59) * (16 + qOrigin + b0)',
  //  '_total1_.log() := (2 ** 59) * (16 + qOrigin + b1)',
  // 
  // and if 'direction == true', we have:
  //
  //  '_total0_.log() := (2 ** 59) * (16 + qOrigin - b0)',
  //  '_total1_.log() := (2 ** 59) * (16 + qOrigin - b1)'.
  //
  // Since the 'direction' and 'qOrigin' have been revised, we need to
  // recalculate the content of both 'total0' and 'total1' using the function
  // 'impose' from the 'KernelLibrary'.
  //
  // Index out of range for 'indexKernelTotal' is avoided externally.
  //
  // The subtraction 'indexKernelTotal - oneIndex' is safe because underflow is
  // avoided externally.
  //
  // As explained in 'moveBreakpointTotal' we should also prove that:
  //
  //  '0 < (2 ** 59) * (16 + qOrigin - b0) < 2 ** 64'
  //  '0 < (2 ** 59) * (16 + qOrigin + b0) < 2 ** 64'
  //  '0 < (2 ** 59) * (16 + qOrigin - b1) < 2 ** 64'
  //  '0 < (2 ** 59) * (16 + qOrigin + b1) < 2 ** 64'
  //
  // as required by 'impose' in 'Kernel.sol'.
  //
  // Let 'pLower' and 'pUpper' denote the minimum and maximum price in the
  // active liquidity interval, respectively and define
  //
  //  'qLower := log(pLower / pOffset)',
  //  'qUpper := log(pUpper / pOffset)'.
  //
  // Let 'qSpacing := qUpper - qLower' denote the length of every liquidity
  // interval. Upon initializing a pool, the given curve sequence is validated
  // by the method 'validate' in 'Curve.sol'. When validating the curve
  // sequence, the custom error 'BlankIntervalsShouldBeAvoided' ensures that
  // '16 + qLower' is greater than 'qSpacing' and '16 + qUpper' is smaller than
  // '32 - qSpacing'. As a result, every member 'q' of the initial curve
  // sequence satisfies:
  // 
  //  'qSpacing < 16 + q < 32 - qSpacing'.
  // 
  // In addition, the method 'setSwapParams' in 'Swap.sol' ensures that
  // 'qTarget' for every swap is also bounded by both
  // 'qSpacing + 1 / (2 ** 59)' and '32 - 1 / (2 ** 59) - qSpacing'.
  // This ensures that the above inequality is always satisfied for every
  // member of the curve and not only the initial curve.
  //
  // Now, since 'qOrigin' is a member of the curve sequence, we also have:
  //
  //  'qSpacing < 16 + qOrigin < 32 - qSpacing'.
  //
  // Hence,
  //
  //  '0 < (2 ** 59) * (16 + qOrigin) <= (2 ** 59) * (16 + qOrigin + b0)
  //     < (2 ** 59) * (32 - qSpacing + b0) <= (2 ** 59) * 32 == 2 ** 64',
  //
  //  '0 < (2 ** 59) * (16 + qOrigin) <= (2 ** 59) * (16 + qOrigin + b1)
  //     < (2 ** 59) * (32 - qSpacing + b1) <= (2 ** 59) * 32 == 2 ** 64',
  //
  // where '0 < (2 ** 59) * (16 + qOrigin)' is because 'qOrigin' is a member of
  // the curve and 'b0 <= qSpacing' and 'b1 <= qSpacing' are concluded from the
  // custom error 'HorizontalCoordinatesMayNotExceedLogSpacing' when validating
  // kernel in 'KernelCompact.sol'.
  //
  // Additionally,
  //
  //  '2 ** 64 >  (2 ** 59) * (16 + qOrigin)
  //           >= (2 ** 59) * (16 + qOrigin - b0) 
  //           >  (2 ** 59) * (qSpacing - b0)
  //           >= 0'
  //
  //  '2 ** 64 >  (2 ** 59) * (16 + qOrigin)
  //           >= (2 ** 59) * (16 + qOrigin - b1)
  //           >  (2 ** 59) * (qSpacing - b1)
  //           >= 0'
  //
  // where '(2 ** 59) * (16 + qOrigin) < 2 ** 64' is because 'qOrigin' is a
  // member of the curve sequence and 'b0 <= qSpacing' and 'b1 <= qSpacing'
  // are concluded from the custom error
  // 'HorizontalCoordinatesMayNotExceedLogSpacing' when validating kernel in
  // 'KernelCompact.sol'.
  //
  // Lastly, both '_total0_' and '_total1_' are fixed values greater than '34'.
  //
  // Therefore, in both cases, the input requirements of 'impose' are
  // satisfied.
  kernel.impose(
    // The resulting values are stored using the pointer '_total0_'.
    _total0_,
    // The new value for 'qOrigin' is used as the base price for the shift.
    _origin_,
    // 'total0' corresponds to the kernel breakpoint
    // 'indexKernelTotal - oneIndex'.
    indexKernelTotal - oneIndex,
    // The flipped direction is used for this shift.
    direction
  );
  kernel.impose(
    // The resulting values are stored using the pointer '_total1_'.
    _total1_,
    // The new value for 'qOrigin' is used as the base price for the shift.
    _origin_,
    // 'total1' corresponds to the kernel breakpoint 'indexKernelTotal'.
    indexKernelTotal,
    // The flipped direction is used for this shift.
    direction
  );
}

/// @notice If 'left == false' this function increments 'qOvershoot' by
/// '1 / (2 ** 59)'. If 'left == true' this function decrements 'qOvershoot'
/// by '1 / (2 ** 59)'.
///
/// Let 'q' denote an arbitrary member of the curve sequence with index 'i'.
/// Then, 'curve.member(i)' is a positive value read from 64 bits of memory.
/// Hence,
///
///  '1 <= curve.member(indexLower) <= (2 ** 64) - 1'
///
///  '1 <= (2 ** 59) * (16 + q) <= (2 ** 64) - 1'
///
///  '1 / (2 ** 59) <= 16 + q <= 32 - 1 / (2 ** 59)'
///
///  '- 16 + 1 / (2 ** 59) <= q <= + 16 - 1 / (2 ** 59)'
///
/// The above inequality will be used to prove the safety of operations in this
/// function.
///
/// ---------------------------------------------------------------------------
///
/// If 'left == false' then 'qOvershoot + 1 / (2 ** 59) <= qUpper' should be
/// enforced externally.
///
/// If 'left == true' then 'qLower <= qOvershoot - 1 / (2 ** 59)' should be
/// enforced externally.
function moveOvershootByEpsilon(
  bool left
) pure {
  // '_overshoot_' is a constant which is greater than '32'.
  //
  // In both cases, we will argue that
  //
  //  - the resulting value for '(2 ** 59) * (16 + qOvershoot)' is nonnegative
  //    and less than '2 ** 64', and
  //
  //  - both square root values are nonnegative and less than 'one216'.
  //
  // Hence, the requirements of 'storePrice' are satisfied.
  left ? _overshoot_.storePrice(
    // The subtraction is safe, because in this case, we have
    //
    //  '0 <  (2 ** 59) * (16 + qLower)
    //     <= (2 ** 59) * (16 + qOvershoot - 1 / (2 ** 59))
    //
    // where the first inequality is because 'qLower' is a member of the curve
    // sequence and the second inequality is enforced externally.
    //
    // Additionally, because
    //
    //  '_overshoot_.log() == (2 ** 59) * (16 + qOvershoot)'
    //
    // is read from 64 bits of memory,
    //
    //  '_overshoot_.log() - epsilonX59 == 
    //   (2 ** 59) * (16 + qOvershoot - 1 / (2 ** 59))'
    //
    // can be safely stored in 64 bits of memory as well.
    _overshoot_.log() - epsilonX59,
    // Here, we calculate:
    //
    //  '(2 ** 216) * exp(- 8 - qOvershoot / 2 + 1 / (2 ** 60)) ==
    //   (2 ** 216) * exp(- 8 - qOvershoot / 2) * exp(1 / (2 ** 60)) ==
    //   _overshoot_.sqrt(false) * exp(1 / (2 ** 60))'
    //
    // '_overshoot_.sqrt(false)' is a nonnegative value which is read from 216
    // bits of memory. Additionally, since
    // 'qLower <= qOvershoot - 1 / (2 ** 59)' is enforced externally, we have:
    //
    //  '(2 ** 216) * exp(- 8 - qOvershoot / 2 + 1 / (2 ** 60)) ==
    //   (2 ** 216) * exp(- (16 + qOvershoot - 1 / (2 ** 59)) / 2) <=
    //   (2 ** 216) * exp(- (16 + qLower) / 2) <=
    //   (2 ** 216) * exp(- 1 / (2 ** 60))'
    //
    // which means, that
    //
    //  '(2 ** 216) * exp(- 8 - qOvershoot / 2 + 1 / (2 ** 60))'
    //
    // does not exceed 216 bits and overflow of
    // '_overshoot_.sqrt(false).multiplyByExpEpsilon()' is impossible.
    //
    // Hence, the requirements of 'multiplyByExpEpsilon' are satisfied.
    _overshoot_.sqrt(false).multiplyByExpEpsilon(),
    // Here, we calculate:
    //
    //  '(2 ** 216) * exp(- 8 + qOvershoot / 2 - 1 / (2 ** 60)) ==
    //   (2 ** 216) * exp(- 8 + qOvershoot / 2) / exp(1 / (2 ** 60)) ==
    //   _overshoot_.sqrt(true) / exp(1 / (2 ** 60))'
    //
    // Since '_overshoot_.sqrt(true)' is a nonnegative value which is read
    // from 216 bits of memory, the requirement of 'divideByExpEpsilon' is
    // satisfied.
    _overshoot_.sqrt(true).divideByExpEpsilon()
  ) : _overshoot_.storePrice(
    // The addition is safe, because in this case, we have
    //
    //  '(2 ** 59) * (16 + qOvershoot + 1 / (2 ** 59)) <=
    //   (2 ** 59) * (16 + qUpper) < 2 ** 64
    //
    // where the first inequality is enforced externally and the second
    // inequality is because 'qUpper' is a member of the curve sequence.
    //
    // Additionally, due to the above argument,
    // '(2 ** 59) * (16 + qOvershoot + 1 / (2 ** 59))' fits within 64 bits and
    // can be safely stored in 64 bits of memory.
    _overshoot_.log() + epsilonX59,
    // Here, we calculate:
    //
    //  '(2 ** 216) * exp(- 8 - qOvershoot / 2 - 1 / (2 ** 60)) ==
    //   (2 ** 216) * exp(- 8 - qOvershoot / 2) / exp(1 / (2 ** 60)) ==
    //   _overshoot_.sqrt(false) / exp(1 / (2 ** 60))'
    //
    // Since '_overshoot_.sqrt(false)' is a nonnegative value which is read
    // from 216 bits of memory, the requirement of 'divideByExpEpsilon' is
    // satisfied.
    _overshoot_.sqrt(false).divideByExpEpsilon(),
    // Here, we calculate:
    //
    //  '(2 ** 216) * exp(- 8 + qOvershoot / 2 + 1 / (2 ** 60)) ==
    //   (2 ** 216) * exp(- 8 + qOvershoot / 2) * exp(1 / (2 ** 60)) ==
    //   _overshoot_.sqrt(true) * exp(1 / (2 ** 60))'
    //
    // '_overshoot_.sqrt(true)' is a nonnegative value which is read from 216
    // bits of memory. Additionally, since
    // 'qOvershoot + 1 / (2 ** 59) <= qUpper' is enforced externally, we have:
    //
    //  '(2 ** 216) * exp(- 8 + qOvershoot / 2 + 1 / (2 ** 60)) <=
    //   (2 ** 216) * exp(- (16 - qOvershoot - 1 / (2 ** 59)) / 2) <=
    //   (2 ** 216) * exp(- (16 - qUpper) / 2) <=
    //   (2 ** 216) * exp(- 1 / (2 ** 60)) < oneX216'
    //
    // which means, that
    //
    //  '(2 ** 216) * exp(- 8 + qOvershoot / 2 + 1 / (2 ** 60))'
    //
    // does not exceed 216 bits and overflow of
    // '_overshoot_.sqrt(true).multiplyByExpEpsilon()' is impossible.
    //
    // Hence, the requirements of 'multiplyByExpEpsilon' are satisfied.
    _overshoot_.sqrt(true).multiplyByExpEpsilon()
  );
}

/// @notice For the case 'exactInput == false', i.e., when the specified amount
/// is outgoing, this function performs a Halley search to determine 'qTarget'
/// based on 'integralLimit'. As explained in 'Memory.sol', 'integralLimit' is
/// is derived from 'amountSpecified'.
///
/// Let
///
///  'cTotal0 := c[indexKernelTotal - 1]',
///  'cTotal1 := c[indexKernelTotal]',
///
/// represent the vertical coordinates of the kernel breakpoints corresponding
/// to 'indexKernelTotal - 1' and 'indexKernelTotal', respectively. As
/// explained in 'Memory.sol', the memory spaces that are pointed to by
/// '_total0_' and '_total1_' host the following vertical coordinates:
///
///  '_total0_.height() := (2 ** 15) * cTotal0',
///  '_total1_.height() := (2 ** 15) * cTotal1'.
///
/// Additionally, if 'getDirection() == false', define
///
///  'qTotal0 := qOrigin + b[indexKernelTotal - 1]',
///  'qTotal1 := qOrigin + b[indexKernelTotal]',
///
/// and if 'getDirection() == true', define
///
///  'qTotal0 := qOrigin - b[indexKernelTotal - 1]',
///  'qTotal1 := qOrigin - b[indexKernelTotal]',
///
/// as the shifted horizontal coordinates of the kernel breakpoint
/// corresponding to 'indexKernelTotal - 1' and 'indexKernelTotal',
/// respectively. Hence, the memory spaces that are pointed to by '_total0_'
/// and '_total1_' host the following horizontal coordinates as well:
/// 
///  '_total0_.log() := (2 ** 59) * (16 + qTotal0)',
///  '_total1_.log() := (2 ** 59) * (16 + qTotal1)',
/// 
/// Let 'qBegin' and 'qCurrent' represent the offsetted logarithmic prices that
/// are hosted by the memory pointers '_begin_' and '_current_', i.e.,
///
///  '_begin_.log() == (2 ** 59) * (16 + qBegin)',
///  '_current_.log() == (2 ** 59) * (16 + qCurrent)'.
///
/// At this stage, 'qTarget' is not yet determined. Hence, if 
/// 'getZeroForOne() == false', we have:
///
///                           - 8     / qBegin
///    currentToTarget      e        |    - h / 2
///  '----------------- := ------- * |  e         k(w(h)) dh'
///       2 ** 216            2      |
///                                 / qCurrent
///
/// and we want to determine 'qTarget' based on the following equation:
///
///                              - 8     / qTarget
///    getIntegralLimit()      e        |    - h / 2
///  '-------------------- == ------- * |  e         k(w(h)) dh',
///         2 ** 216             2      |
///                                    / qCurrent
///
/// which is equivalent to
///
///    getIntegralLimit() - currentToTarget
///  '-------------------------------------- == 
///                  2 ** 216
///
///      - 8     / qTarget
///    e        |    - h / 2
///   ------- * |  e         k(w(h)) dh == 
///      2      |
///            / qBegin
///
///      - 8     / qTarget
///    e        |    - h / 2             cTotal1 - cTotal0
///   ------- * |  e         (cTotal0 + ------------------- (h - qTotal0)) dh'.
///      2      |                        qTotal1 - qTotal0
///            / qBegin
///
/// Hence, we define
///
///  'outgoingLimit := getIntegralLimit() - currentToTarget'.
///
/// and solve
///
///      - 8     / qBegin + x
///    e        |   - h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (h - qTotal0)) dh
///      2      |                       qTotal1 - qTotal0
///            / qBegin
///
///       outgoingLimit
///   == ---------------'
///         2 ** 216
///
/// with respect to 'x' and then we store
///
///  'qTarget := qBegin + x'.
///
/// in the memory spaces that are pointed to by '_target_' and '_overshoot_'.
///
/// Similarly, if 'getZeroForOne() == true', we solve the equation:
///
///      - 8     / qBegin
///    e        |   + h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (qTotal0 - h)) dh
///      2      |                       qTotal0 - qTotal1
///            / qBegin - x
///
///       outgoingLimit
///   == ---------------'
///         2 ** 216
///
/// with respect to 'x' and then we store:
///
///  'qTarget := qBegin - x'.
///
/// in the memory spaces that are pointed to by '_target_' and '_overshoot_'.
///
/// For simplicity, consider the first case of 'getZeroForOne() == false',
/// since the second case 'getZeroForOne() == true' can be argued similarly.
/// Define:
///
///  'q2 := 2 * (cTotal1 - cTotal0)'
///
///  'q1 := cTotal1 * (2 - qTotal0 + qBegin) - 
///         cTotal0 * (2 - qTotal1 + qBegin)'
///
///  'q0 := 2 * 
///
///                                      outgoingLimit
///         (q1 - (qTotal1 - qTotal0) * --------------- * exp(+ qBegin / 2))'
///                                         2 ** 216
///
/// Then the equation can be cast as 'f(x) == 0' where
///
///  '      f(x) == + ((cTotal1 - cTotal0) * x + q1) * exp(- x / 2) - q0 / 2'
///
///      d f(x)
///  '  -------- == - ((cTotal1 - cTotal0) * x + q1 - q2) * exp(- x / 2) / 2'
///       d x
///
///                                                                 - x / 2
///    d^2 f(x)                                                   e
///  '---------- == + ((cTotal1 - cTotal0) * x + q1 - q2 - q2) * -----------'
///     d x^2                                                         4
///
/// Define:
///
///  'g(x) == (cTotal1 - cTotal0) * x + q1 - q2'
///
///  'h(x) == (cTotal1 - cTotal0) * x + q1 - (q0 / 2) * exp(+ x / 2)'
///
/// To solve our equation, we perform the following Halley's search:
///
///  'x = x + 
///                             4 * (h(x) / g(x))
///   ----------------------------------------------------------------------'
///    2 - (h(x) / g(x)) + 2 * (h(x) / g(x)) * ((cTotal1 - cTotal0) / g(x))
///
/// --------------------------------------------------------------------------- 
///
/// Underflow of 'getIntegralLimit() - _currentToTarget_.integral()' should be
/// avoided externally.
///
/// We should have 'getDirection() == getZeroForOne()'.
///
/// @return exactAmount Whether the search is performed.
///
/// Let 'qTarget' represent the existing value stored in the memory space which
/// is pointed to by '_target_' (prior to calling this function). As explained
/// in 'Memory.sol', we have:
///
///   'qTarget := (
///                 getDirection() == getZeroForOne()
///               ) ? (
///                 getDirection() ? 
///                 max(max(qEnd, qTotal1), qLimitWithinInterval) : 
///                 min(min(qEnd, qTotal1), qLimitWithinInterval)
///               ) : (
///                 getDirection() ? 
///                 max(qEnd, qTotal1) : 
///                 min(qEnd, qTotal1)
///               )',
///
/// Additionally, because of the input requirement
///
///   'getDirection() == getZeroForOne()',
///
/// the above equation is equivalent to:
///
///   'qTarget := getDirection() ? 
///               max(max(qEnd, qTotal1), qLimitWithinInterval) : 
///               min(min(qEnd, qTotal1), qLimitWithinInterval)'.
///
/// If 'getZeroForOne() == false', then the current 'qTarget' is an upper bound
/// for the unknown value 'qBegin + x' and the numerical search for 'x' is
/// performed within the range '0' to 'qTarget - qBegin'. In this case, we
/// first need to check the following inequality:
///
///      - 8     / qTarget
///    e        |   - h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (h - qTotal0)) dh
///      2      |                       qTotal1 - qTotal0
///            / qBegin
///
///      outgoingLimit
///   < ---------------'.
///        2 ** 216
///
/// If satisfied, then the outgoing integral across the entire range does not
/// reach 'outgoingLimit / (2 ** 216)', which means that there is no solution.
/// In this case, we simply return the value for the above integral in 'X216'
/// representation along with 'exactAmount == false'.
///
/// Similarly, if 'getZeroForOne == true', then 'qTarget' is a lower bound for
/// the unknown value 'qTarget == qBegin - x' and the numerical search for 'x'
/// is performed within the range '0' to 'qBegin - qTarget'. In this case,
/// we first need to check the following inequality:
///
///      - 8     / qBegin
///    e        |   + h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (qTotal0 - h)) dh
///      2      |                       qTotal0 - qTotal1
///            / qTarget
///
///      outgoingLimit
///   < ---------------'.
///        2 ** 216
///
/// If satisfied, then the outgoing integral across the entire range does not
/// reach 'outgoingLimit / (2 ** 216)', which means that there is no solution.
/// In this case, we simply return the value for the above integral in 'X216'
/// representation along with 'exactAmount == false'.
///
/// @return outgoing Integral increment to be added to
/// 'currentToTarget / (2 ** 216)', i.e.,
///
///      - 8     / qTarget
///    e        |   - h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (h - qTotal0)) dh'
///      2      |                       qTotal1 - qTotal0
///            / qBegin
///
/// if 'getZeroForOne() == false' and
///
///      - 8     / qBegin
///    e        |   + h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (qTotal0 - h)) dh'
///      2      |                       qTotal0 - qTotal1
///            / qTarget
///
/// if 'getZeroForOne() == true'.
///
/// If 'exactAmount == false', this value is equal to the outgoing integral
/// across the entire search range and if the search is performed, this value
/// is equal to the left hand side of the equation that we are solving.
function searchOutgoingTarget() pure returns (
  bool exactAmount,
  X216 outgoing
) {
  // First, we subtract 'currentToTarget' from 'getIntegralLimit()' in order to
  // get 'outgoingLimit'.
  //
  // Subtraction is safe because underflow is handled externally.
  X216 outgoingLimit = getIntegralLimit() - _currentToTarget_.integral();

  // The next step is to see if the integral taken across the entire search
  // range between 'qBegin' and 'qTarget' exceeds 'outgoingLimit' or not. If it
  // does not, then we simply stop the search and return the resulting integral
  // along with 'exactAmount == false'.
  //
  // As defined in 'Memory.sol', we have
  //
  //  'qBegin := getDirection() ? 
  //             min(q[indexCurve + 2], qTotal0) : 
  //             max(q[indexCurve + 2], qTotal0)',
  //
  //  'qTarget := (
  //                getDirection() == getZeroForOne()
  //              ) ? (
  //                getDirection() ? 
  //                max(max(qEnd, qTotal1), qLimitWithinInterval) : 
  //                min(min(qEnd, qTotal1), qLimitWithinInterval)
  //              ) : (
  //                getDirection() ? 
  //                max(qEnd, qTotal1) : 
  //                min(qEnd, qTotal1)
  //              )
  //           == getDirection() ? 
  //              max(max(qEnd, qTotal1), qLimitWithinInterval) : 
  //              min(min(qEnd, qTotal1), qLimitWithinInterval)
  //
  // which implies that if 'getDirection() == false', then
  //
  //  'qTotal0 <= qBegin <= qTarget <= qTotal1'.
  //
  // and if 'getDirection() == true', then
  //
  //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
  //
  // Additionally, since the vertical coordinates of kernel are monotonic, we
  // have 'cTotal0 <= cTotal1' and the input requirements of 'outgoing' are
  // satisfied.
  outgoing = _total0_.outgoing(_begin_, _target_);
  // Signed comparison is valid because:
  //
  //  - the output of 'outgoing' is always a nonnegative value which is less
  //    than 'oneX216'.
  //
  //  - 'outgoingLimit <= getIntegralLimit() < one216', and
  //
  //  - 'getIntegralLimit() >= zeroX216' because of the first input
  //    requirement.
  if (outgoing <= outgoingLimit) return (false, outgoing);

  // 'zeroForOne' is loaded from the memory.
  bool left = getZeroForOne();

  // '|qTotal1 - qTotal0|' is calculated once and used throughout the search.
  //
  // As we argued before, if 'left == false', then
  //
  //  'qTotal0 <= qBegin <= qTarget <= qTotal1'.
  //
  // and if 'left == true', then
  //
  //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
  X59 db = left ? 
    _total0_.log() - _total1_.log() : 
    _total1_.log() - _total0_.log();

  // 'cTotal1 - cTotal0' is calculated once and used throughout the search.
  //
  // The subtraction is safe because 'total0' and 'total1' correspond to the
  // kernel breakpoints 'indexKernelTotal - oneIndex' and 'indexKernelTotal',
  // respectively, and the vertical coordinates of kernel breakpoints are
  // monotonically non-decreasing due to the custom error
  // 'NonMonotonicVerticalCoordinates' in 'KernelCompact.sol'.
  X15 dc = _total1_.height() - _total0_.height();

  // Next we calculate
  //
  //  'q2 := 2 * (cTotal1 - cTotal0)'
  //
  // The multiplication is safe because 'twoX59' is positive and the output
  // does not exceed '64 + 16 == 80' bits.
  X74 q2 = twoX59.times(dc);

  // The second coefficient is calculated as
  //
  // 'q1 := (cTotal1 - cTotal0) * (2 + |qBegin - qTotal0|)
  //      + cTotal0 * |qTotal1 - qTotal0|'

  // The multiplication 'db.times(_total0_.height())' is safe because the
  // output does not exceed 80 bits.
  //
  // The addition is safe because neither 'q2' nor
  // 'db.times(_total0_.height())' do not exceed 80 bits.
  X74 q1 = q2 + db.times(_total0_.height());

  // The subtractions are safe because of the last input requirement and the
  // fact that
  //
  //  'getDirection() == getZeroForOne() == left'.
  //
  // Lastly, the additions are safe because neither values exceed 81 bits.
  q1 = left ? 
    q1 + (_total0_.log() - _begin_.log()).times(dc) : 
    q1 + (_begin_.log() - _total0_.log()).times(dc);

  // Next, in order to compute 'q0', if 'left == false', we calculate:
  //
  //        outgoingLimit          db
  //  '---------------------- * --------- * exp(+ qBegin / 2) ==
  //    (2 ** 216) * exp(-8)     2 ** 59
  //
  //    outgoingLimit * db * ((2 ** 216) * exp(- 8 + qBegin / 2))
  //   ----------------------------------------------------------- ==
  //                  (2 ** (216 + 59)) * exp(-16)
  //
  //    outgoingLimit * db * _begin_.sqrt(true)
  //   -----------------------------------------'
  //         (2 ** (216 + 59)) * exp(-16)
  //
  // and if 'left == true', we calculate:
  //
  //        outgoingLimit          db
  //  '---------------------- * --------- * exp(- qBegin / 2) ==
  //    (2 ** 216) * exp(-8)     2 ** 59
  //
  //    outgoingLimit * db * ((2 ** 216) * exp(- 8 - qBegin / 2))
  //   ----------------------------------------------------------- ==
  //                  (2 ** (216 + 59)) * exp(-16)
  //
  //    outgoingLimit * db * _begin_.sqrt(false)
  //   ------------------------------------------'.
  //          (2 ** (216 + 59)) * exp(-16)
  //
  // The three inputs of 'mulDivByExpInv16' are non-negative and overflow is
  // not possible because
  //
  //    outgoingLimit * db * _begin_.sqrt(!left)
  //  '------------------------------------------ < 
  //          (2 ** (216 + 59)) * exp(-16)
  //
  //    (2 ** 216) * (2 ** 64) * (2 ** 216)
  //   ------------------------------------- == 
  //       (2 ** (216 + 59)) * exp(-16)
  //
  //   32 * exp(16) * oneX216 < 2 ** 256 - 1'.
  //
  // Hence, the requirements of 'mulDivByExpInv16' are satisfied.
  //
  // Additionally, 'toX216' does not overflow because 'q1' does not exceed
  // '81' bits.
  //
  // Next, we need to prove that the subtraction is safe. Consider the case of
  // 'getDirection() == false' as the other case can be argued similarly. To
  // that end, we need to show that
  //
  //      q1             outgoingLimit          db
  //  '--------- >= ---------------------- * --------- * exp(+ qBegin / 2)'.
  //    2 ** 74      (2 ** 216) * exp(-8)     2 ** 59
  //
  // Or equivalently:
  //
  //  'cTotal1 * (2 - qTotal0 + qBegin) - cTotal0 * (2 - qTotal1 + qBegin) >=
  //
  //        outgoingLimit          db
  //   ---------------------- * --------- * exp(+ qBegin / 2)'.
  //    (2 ** 216) * exp(-8)     2 ** 59
  //
  // Notice that due to our prior check,
  //
  //       outgoingLimit
  //  '----------------------'
  //    exp(-8) * (2 ** 216)
  //
  // does not exceed
  //
  //         / qTarget
  //    1   |   - h / 2             cTotal1 - cTotal0
  //  '---  |  e        (cTotal0 + ------------------- (h - qTotal0)) dh'
  //    2   |                       qTotal1 - qTotal0
  //       / qBegin
  //
  // which is equal to:
  //
  //  'cTotal0 * (exp(- qBegin / 2) - exp(- qTarget / 2)) +
  //
  //    cTotal1 - cTotal0
  //   ------------------- * (
  //    qTotal1 - qTotal0
  //
  //     (qBegin - qTotal0 + 2) * exp(- qBegin / 2) - 
  //     (qTarget - qTotal0 + 2) * exp(- qTarget / 2)
  //   )'
  //
  // Hence, we need to prove that
  //
  //  'cTotal1 * (2 - qTotal0 + qBegin) - cTotal0 * (2 - qTotal1 + qBegin) >=
  //
  //   (qTotal1 - qTotal0) * exp(+ qBegin / 2) * (
  //
  //     cTotal0 * (exp(- qBegin / 2) - exp(- qTarget / 2)) + 
  //
  //      cTotal1 - cTotal0
  //     ------------------- * (
  //      qTotal1 - qTotal0
  //
  //       (qBegin - qTotal0 + 2) * exp(- qBegin/2) - 
  //       (qTarget - qTotal0 + 2) * exp(- qTarget/2)
  //     )
  //   )'
  //
  // which is equivalent to:
  //
  //  '(2 + qTarget - qTotal0) * (cTotal1 - cTotal0) + 
  //   cTotal0 * (qTotal1 - qTotal0) >= 0'.
  //
  // As we have already proven, if 'getDirection() == false', then
  //
  //  'qTotal0 <= qBegin <= qTarget <= qTotal1'.
  //
  // which means that the subtraction is safe.
  X216 q0 = 
    q1.toX216() - db.mulDivByExpInv16(_begin_.sqrt(!left), outgoingLimit);
  // The following addition is also safe, because
  // 
  //       q0           q1
  //  '---------- <= --------- == 
  //    2 ** 216      2 ** 74
  //
  //   cTotal1 * (2 - qTotal0 + qBegin) - cTotal0 * (2 - qTotal1 + qBegin) <= 
  //
  //   (cTotal1 - cTotal0) * (2 + qBegin) + 
  //
  //   cTotal0 * qTotal1 - cTotal1 * qTotal0 <= 
  //
  //   1 * (2 + 16) + 1 * 16 + 1 * 16 <= 50
  //
  // which concludes that 'q0' does not take more than 222-bits in 'X216'
  // representation.
  q0 = q0 + q0;

  // The initial value for 'x' is calculated here. The subtractions are safe
  // because as we argued before, if 'left == false', then
  //
  //  'qTotal0 <= qBegin <= qTarget <= qTotal1'
  //
  // and if 'left == true', then
  //
  //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
  X59 xLimit = 
    left ? _begin_.log() - _target_.log() : _target_.log() - _begin_.log();

  // All three inputs of 'cheapMulDiv' are non-negative.
  //
  // Due to the prior check, 'outgoingLimit < outgoing'. Additionally, we have
  //
  //  '|_begin_.log() - _target_.log()| <= 2 ** 64 - 1 < 
  //
  //   75557863725914323375445 <= (2 ** 216) * 
  //
  //                                      1
  //      - 8     / 16                --------- - 0
  //    e        |   - h / 2           2 ** 15
  //   ------- * |  e           (0 + ---------------  * (h + 16)) dh <
  //      2      |                     16 - (- 16)
  //            / 16 - 1 / (2 ** 59)
  //
  //   outgoing'.
  //
  // Here, '75557863725914323375445' is the minimum value for an outgoing
  // integral. Hence, we have:
  //
  //  'xLimit * outgoingLimit < outgoing * (outgoing - 1)'
  //
  // and the requirement of 'cheapMulDiv' is met.
  //
  // Signed comparison is valid because the first term is a positive constant
  // and the second term is non-negative.
  X59 x = max(epsilonX59, xLimit.cheapMulDiv(outgoingLimit, outgoing));

  while (true) {
    // For each iteration, we evaluate 'g(x)' and 'h(x)' in 'X74' and 'X216'
    // representations, respectively.
    //
    // 'x.times(dc)' is safe because 'x' is not less than 'epsilonX59' due to
    // the above check and we have already checked that 'dc' is nonnegative.
    //
    // The addition 'x.times(dc) + q1' is safe because both values do not
    // exceed 81-bits.
    //
    // Next, we prove the requirements of 'cheapMulDiv'.
    //
    // Upon initializing a pool, the given curve sequence is validated by the
    // method 'validate' in 'Curve.sol'. When validating the curve sequence,
    // the custom error 'BlankIntervalsShouldBeAvoided' ensures that:
    // 
    //  'qSpacing < 16 + qLower < 16 + qUpper < 32 - qSpacing'
    //
    // Hence,
    //
    //  '32 - qSpacing > 16 + qUpper == 16 + qLower + qSpacing > 2 * qSpacing'
    //
    // which concludes:
    //
    //  '|_target_.log() - _begin_.log()| / (2 ** 59) <= qSpacing < 32 / 3'.
    //
    // Due to the above arguments, the input requirements of 'expInverse' are
    // satisfied because 'x' is not less than 'epsilonX59' and
    //
    //  'x <= |_target_.log() - _begin_.log()| < (2 ** 64) / 3'.
    //
    // Hence,
    //
    //  'x.expInverse() == (2 ** 256) * exp(- x / (2 ** 60))
    //                  >= (2 ** 256) * exp(- qSpacing / 2)
    //                  >= (2 ** 256) * exp(- 16 / 3) > 2 ** 248.
    //
    // On the other hand, 'q0' is non-negative and may not be more than
    // 223-bits as we argued before.
    //
    // Hence, the input requirement of 'cheapMulDiv' is satisfied because
    // the number of bits for 'q0 * (1 << 255)' does not exceed the number of
    // bits for 'x.expInverse()', i.e.,
    //
    //  '223 bits + 255 bits < 248 bits + 248 bits'.
    //
    // The subtraction 'g - q2' is safe because:
    //
    //  'g(x) := (cTotal1 - cTotal0) * x + q1 - q2
    //
    //        == (cTotal1 - cTotal0) * x + 
    //           cTotal1 * (2 - qTotal0 + qBegin) - 
    //           cTotal0 * (2 - qTotal1 + qBegin) - 
    //           2 * (cTotal1 - cTotal0)
    //
    //        == (cTotal1 - cTotal0) * (x + qBegin) + 
    //           cTotal0 * qTotal1 - cTotal1 * qTotal0
    //
    //        == (cTotal1 - cTotal0) * (x + qBegin - qTotal0) + 
    //           cTotal0 * (qTotal1 - qTotal0)
    //
    //        >= (cTotal1 - cTotal0) * x >= 1 / ((2 ** 15) * (2 ** 59)) > 0'
    //
    // where 'qBegin >= qTotal0' is concluded from the last input requirement.
    // Also, 'cTotal1 - cTotal0 >= 1 / (2 ** 15)' is concluded from the initial
    // check for the determination of 'exactAmount', because if
    // 'cTotal1 == cTotal0 == 0', then we have 'exactAmount == false' and this
    // part of the code would not be reached. Hence, 'g' is positive which will
    // be used later.
    //
    // The subtraction 'g.toX216() - q0.cheapMulDiv(1 << 255, x.expInverse())'
    // is unsafe and may be negative.
    X74 g = x.times(dc) + q1;
    X216 h = g.toX216() - q0.cheapMulDiv(1 << 255, x.expInverse());
    g = g - q2;

    // Next, we calculate the following Halley step:
    //
    //                            2 * (h(x) / g(x))
    //  'step = -----------------------------------------------------'
    //           1 - (h(x) / g(x)) / 2 + (h(x) / g(x)) * (dc / g(x))
    //
    // in 'X59' representation.
    //
    // The numerator is in 'X142' representation.
    // The denominator is in 'X83' representation.
    X59 step;
    uint256 denominator;
    assembly {
      // The division is safe because 'g' is positive as we argued before.
      let h_over_g_X142 := sdiv(h, g) // h(x) / g(x)
      denominator := sub(
        shl(83, 1), // oneX83
        sub(
          // Here, 'h_over_g_X142' is shifted to the right by
          // '60 == 142 - 83 + 1' bits where '1' appears because we are
          // dividing by two. '142' appears because we are casting from the 
          // 'X142' representation and '83' appears because we are casting to  
          // the 'X83' representation.
          sar(60, h_over_g_X142), // (h(x) / g(x)) / 2
          sdiv(mul(h_over_g_X142, dc), g) // (h(x) / g(x)) * (dc / g(x))
        )
      ) // 1 - (h(x) / g(x)) / 2 + (h(x) / g(x)) * (dc / g(x))
      step := sdiv(
        add(h_over_g_X142, h_over_g_X142), // 2 * (h(x) / g(x))
        denominator
      )
    }

    if (step == zeroX59) {
      require(denominator != 0, SearchingForOutgoingTargetFailed());
      break;
    }

    // The solution is capped by 'epsilonX59' and 'xLimit'. Hence, we do not
    // need to argue whether the addition 'x + step' is safe or not.
    x = min(max(epsilonX59, x + step), xLimit);
  }

  // The subtraction and the addition are safe because if 'left == false':
  //
  //  '0 < x <= xLimit := qTarget - qBegin',
  //
  // and if 'left == true':
  //
  //  '0 < x <= xLimit := qBegin - qTarget'.
  //
  x = left ? _begin_.log() - x : _begin_.log() + x;

  // The output should be stored in both of the memory spaces that are pointed
  // to by '_overshoot_' and '_target_'.
  //
  // The requirements of 'storePrice' and 'outgoing' are satisfied because
  //
  //  'min(qBegin, qTarget) <= x <= max(qBegin, qTarget)'.
  //
  _overshoot_.storePrice(x);

  // As argued before, if 'getDirection() == false', then
  //
  //  'qTotal0 <= qBegin <= qOvershoot <= qTarget <= qTotal1'.
  //
  // and if 'getDirection() == true', then
  //
  //  'qTotal1 <= qTarget <= qOvershoot <= qBegin <= qTotal0'.
  //
  // Additionally, since the vertical coordinates of kernel are monotonic, we
  // have 'cTotal0 <= cTotal1' and the input requirements of 'outgoing' are
  // satisfied.
  outgoing = _total0_.outgoing(_begin_, _overshoot_);

  // 'x' is moved forward to ensure that the resulting integral is an over
  // approximation.
  while (outgoing < outgoingLimit) {
    // The addition and the subtraction are safe here because:
    //
    //  'outgoingLimit < _total0_.outgoing(_begin_, _target_)'.
    //
    // Hence, the loop is stopped before we reach 'qTarget'.
    x = left ? x - epsilonX59 : x + epsilonX59;

    // Due to the above argument, if 'left == false' then
    //
    //  'qOvershoot + 1 / (2 ** 59) < qTarget <= qUpper'
    //
    // and if 'left == true' then
    //
    //  'qLower <= qTarget < qOvershoot - 1 / (2 ** 59)'.
    //
    // Hence the input requirements of 'moveOvershootByEpsilon' are satisfied.
    moveOvershootByEpsilon(left);

    // As argued before, if 'getDirection() == false', then
    //
    //  'qTotal0 <= qBegin <= qOvershoot <= qTarget <= qTotal1'.
    //
    // and if 'getDirection() == true', then
    //
    //  'qTotal1 <= qTarget <= qOvershoot <= qBegin <= qTotal0'.
    //
    // Additionally, since the vertical coordinates of kernel are monotonic, we
    // have 'cTotal0 <= cTotal1' and the input requirements of 'outgoing' are
    // satisfied.
    outgoing = _total0_.outgoing(_begin_, _overshoot_);
  }

  // The output should be stored in both of the memory spaces that are pointed
  // to by '_overshoot_' and '_target_'.
  _target_.copyPrice(_overshoot_);

  return (true, outgoing);
}

/// @notice For the case 'exactInput == true', i.e., when the specified amount
/// is incoming, this function performs a Halley search to determine 'qTarget'
/// based on 'integralLimit'. As explained in 'Memory.sol', 'integralLimit' is
/// is derived from 'amountSpecified'.
///
/// Let
///
///  'cTotal0 := c[indexKernelTotal - 1]',
///  'cTotal1 := c[indexKernelTotal]',
///
/// represent the vertical coordinates of the kernel breakpoints corresponding
/// to 'indexKernelTotal - 1' and 'indexKernelTotal', respectively. As
/// explained in 'Memory.sol', the memory spaces that are pointed to by
/// '_total0_' and '_total1_' host the following vertical coordinates:
///
///  '_total0_.height() := (2 ** 15) * cTotal0',
///  '_total1_.height() := (2 ** 15) * cTotal1'.
///
/// Additionally, if 'getDirection() == false', define
///
///  'qTotal0 := qOrigin + b[indexKernelTotal - 1]',
///  'qTotal1 := qOrigin + b[indexKernelTotal]',
///
/// and if 'getDirection() == true', define
///
///  'qTotal0 := qOrigin - b[indexKernelTotal - 1]',
///  'qTotal1 := qOrigin - b[indexKernelTotal]',
///
/// as the shifted horizontal coordinates of the kernel breakpoint
/// corresponding to 'indexKernelTotal - 1' and 'indexKernelTotal',
/// respectively. Hence, the memory spaces that are pointed to by '_total0_'
/// and '_total1_' host the following horizontal coordinates as well:
/// 
///  '_total0_.log() := (2 ** 59) * (16 + qTotal0)',
///  '_total1_.log() := (2 ** 59) * (16 + qTotal1)',
/// 
/// Let 'qBegin' and 'qCurrent' represent the offsetted logarithmic prices that
/// are hosted by the memory pointers '_begin_' and '_current_', i.e.,
///
///  '_begin_.log() == (2 ** 59) * (16 + qBegin)',
///  '_current_.log() == (2 ** 59) * (16 + qCurrent)'.
///
/// At this stage, 'qTarget' is not yet determined. Hence, if 
/// 'getZeroForOne() == false', we have:
///
///                                   - 8     / qBegin
///    incomingCurrentToTarget      e        |    + h / 2
///  '------------------------- := ------- * |  e         k(w(h)) dh'
///           2 ** 216                2      |
///                                         / qCurrent
///
/// and we want to determine 'qTarget' based on the following equation:
///
///                              - 8     / qTarget
///    getIntegralLimit()      e        |    + h / 2
///  '-------------------- == ------- * |  e         k(w(h)) dh',
///         2 ** 216             2      |
///                                    / qCurrent
///
/// which is equivalent to
///
///    getIntegralLimit() - incomingCurrentToTarget
///  '---------------------------------------------- == 
///                      2 ** 216
///
///      - 8     / qTarget
///    e        |    + h / 2
///   ------- * |  e         k(w(h)) dh == 
///      2      |
///            / qBegin
///
///      - 8     / qTarget
///    e        |    + h / 2             cTotal1 - cTotal0
///   ------- * |  e         (cTotal0 + ------------------- (h - qTotal0)) dh'.
///      2      |                        qTotal1 - qTotal0
///            / qBegin
///
/// Hence, we define
///
///  'incomingLimit := getIntegralLimit() - incomingCurrentToTarget'.
///
/// and solve
///
///      - 8     / qBegin + x
///    e        |   + h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (h - qTotal0)) dh
///      2      |                       qTotal1 - qTotal0
///            / qBegin
///
///       incomingLimit
///   == ---------------'
///         2 ** 216
///
/// with respect to 'x' and then we store
///
///  'qTarget := qBegin + x'.
///
/// in the memory spaces that are pointed to by '_target_' and '_overshoot_'.
///
/// Similarly, if 'getZeroForOne() == true', we solve the equation:
///
///      - 8     / qBegin
///    e        |   - h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (qTotal0 - h)) dh
///      2      |                       qTotal0 - qTotal1
///            / qBegin - x
///
///       incomingLimit
///   == ---------------'
///         2 ** 216
///
/// with respect to 'x' and then we store:
///
///  'qTarget := qBegin - x'.
///
/// in the memory spaces that are pointed to by '_target_' and '_overshoot_'.
///
/// For simplicity, consider the first case of 'getZeroForOne() == false',
/// since the second case 'getZeroForOne() == true' can be argued similarly.
/// Define:
///
///  'q2 := 2 * (cTotal1 - cTotal0)'
///
///  'q1 := cTotal1 * (2 + qTotal0 - qBegin) - 
///         cTotal0 * (2 + qTotal1 - qBegin)'
///
///                                     incomingLimit
///  'q0 := q1 - (qTotal1 - qTotal0) * --------------- * exp(- qBegin / 2)'
///                                        2 ** 216
///
/// Then the equation can be cast as 'f(x) == 0', where
///
///  '  f(x) == + ((cTotal1 - cTotal0) * x - q1) * exp(x / 2) + q0'
///
///  ' f'(x) == + ((cTotal1 - cTotal0) * x - q1 + q2) * exp(x / 2) / 2'
///
///  'f''(x) == + ((cTotal1 - cTotal0) * x - q1 + q2 + q2) * exp(x / 2) / 4'
///
/// Define:
///
///  'g(x) == (cTotal1 - cTotal0) * x - q1 + q2'
///
///  'h(x) == (cTotal1 - cTotal0) * x - q1 + q0 * exp(- x / 2)'
///
/// To solve our equation, we perform the following Halley's search:
///
/// 'x = x - 
///                            4 * (h(x) / g(x))
///  ----------------------------------------------------------------------'
///   2 - (h(x) / g(x)) - 2 * (h(x) / g(x)) * ((cTotal1 - cTotal0) / g(x))
///
/// --------------------------------------------------------------------------- 
///
/// Underflow of 'getIntegralLimit() - _incomingCurrentToTarget_.integral()'
/// should be avoided externally.
///
/// We should have 'getDirection() == getZeroForOne()'.
///
/// @return exactAmount Whether the search is performed.
///
/// Let 'qTarget' represent the existing value stored in the memory space which
/// is pointed to by '_target_' (prior to calling this function). As explained
/// in 'Memory.sol', we have:
///
///   'qTarget := (
///                 getDirection() == getZeroForOne()
///               ) ? (
///                 getDirection() ? 
///                 max(max(qEnd, qTotal1), qLimitWithinInterval) : 
///                 min(min(qEnd, qTotal1), qLimitWithinInterval)
///               ) : (
///                 getDirection() ? 
///                 max(qEnd, qTotal1) : 
///                 min(qEnd, qTotal1)
///               )',
///
/// Additionally, because of the input requirement
///
///   'getDirection() == getZeroForOne()',
///
/// the above equation is equivalent to:
///
///   'qTarget := getDirection() ? 
///               max(max(qEnd, qTotal1), qLimitWithinInterval) : 
///               min(min(qEnd, qTotal1), qLimitWithinInterval)'.
///
/// If 'getZeroForOne() == false', then the current 'qTarget' is an upper bound
/// for the unknown value 'qBegin + x' and the numerical search for 'x' is
/// performed within the range '0' to 'qTarget - qBegin'. In this case, we
/// first need to check the following inequality:
///
///      - 8     / qTarget
///    e        |   + h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (h - qTotal0)) dh
///      2      |                       qTotal1 - qTotal0
///            / qBegin
///
///      incomingLimit
///   < ---------------'.
///        2 ** 216
///
/// If satisfied, then the incoming integral across the entire range does not
/// reach 'incomingLimit / (2 ** 216)', which means that there is no solution.
/// In this case, we simply return the value for the above integral in 'X216'
/// representation along with 'exactAmount == false'.
///
/// Similarly, if 'getZeroForOne == true', then 'qTarget' is a lower bound for
/// the unknown value 'qTarget == qBegin - x' and the numerical search for 'x'
/// is performed within the range '0' to 'qBegin - qTarget'. In this case,
/// we first need to check the following inequality:
///
///      - 8     / qBegin
///    e        |   + h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (qTotal0 - h)) dh
///      2      |                       qTotal0 - qTotal1
///            / qTarget
///
///      incomingLimit
///   < ---------------'.
///        2 ** 216
///
/// If satisfied, then the incoming integral across the entire range does not
/// reach 'incomingLimit / (2 ** 216)', which means that there is no solution.
/// In this case, we simply return the value for the above integral in 'X216'
/// representation along with 'exactAmount == false'.
///
/// @return incoming Integral increment to be added to
/// 'incomingCurrentToTarget / (2 ** 216)', i.e.,
///
///      - 8     / qTarget
///    e        |   + h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (h - qTotal0)) dh'
///      2      |                       qTotal1 - qTotal0
///            / qBegin
///
/// if 'getZeroForOne() == false' and
///
///      - 8     / qBegin
///    e        |   - h / 2             cTotal1 - cTotal0
///  '------- * |  e        (cTotal0 + ------------------- (qTotal0 - h)) dh'
///      2      |                       qTotal0 - qTotal1
///            / qTarget
///
/// if 'getZeroForOne() == true'.
///
/// If 'exactAmount == false', this value is equal to the incoming integral
/// across the entire search range and if the search is performed, this value
/// is equal to the left hand side of the equation that we are solving.
function searchIncomingTarget() pure returns (
  bool exactAmount,
  X216 incoming
) {
  // First, we subtract 'incomingCurrentToTarget' from 'getIntegralLimit()' in
  // order to get 'incomingLimit'.
  //
  // Subtraction is safe because underflow is handled externally.
  X216 incomingLimit = 
    getIntegralLimit() - _incomingCurrentToTarget_.integral();

  // The next step is to see if the integral taken across the entire search
  // range between 'qBegin' and 'qTarget' exceeds 'incomingLimit' or not. If it
  // does not, then we simply stop the search and return the resulting integral
  // along with 'exactAmount == false'.
  //
  // As defined in 'Memory.sol', we have
  //
  //  'qBegin := getDirection() ? 
  //             min(q[indexCurve + 2], qTotal0) : 
  //             max(q[indexCurve + 2], qTotal0)',
  //
  //  'qTarget := (
  //                getDirection() == getZeroForOne()
  //              ) ? (
  //                getDirection() ? 
  //                max(max(qEnd, qTotal1), qLimitWithinInterval) : 
  //                min(min(qEnd, qTotal1), qLimitWithinInterval)
  //              ) : (
  //                getDirection() ? 
  //                max(qEnd, qTotal1) : 
  //                min(qEnd, qTotal1)
  //              )
  //           == getDirection() ? 
  //              max(max(qEnd, qTotal1), qLimitWithinInterval) : 
  //              min(min(qEnd, qTotal1), qLimitWithinInterval)
  //
  // which implies that if 'getDirection() == false', then
  //
  //  'qTotal0 <= qBegin <= qTarget <= qTotal1'.
  //
  // and if 'getDirection() == true', then
  //
  //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
  //
  // Additionally, since the vertical coordinates of kernel are monotonic, we
  // have 'cTotal0 <= cTotal1' and the input requirements of 'incoming' are
  // satisfied.
  incoming = _total0_.incoming(_begin_, _target_);
  // Signed comparison is valid because:
  //
  //  - the output of 'incoming' is always a nonnegative value which is less
  //    than 'oneX216'.
  //
  //  - 'incomingLimit <= getIntegralLimit() < one216', and
  //
  //  - 'getIntegralLimit() >= zeroX216' because of the first input
  //    requirement.
  if (incoming <= incomingLimit) return (false, incoming);

  // 'zeroForOne' is loaded from the memory.
  bool left = getZeroForOne();

  // '|qTotal1 - qTotal0|' is calculated once and used throughout the search.
  //
  // As we argued before, if 'left == false', then
  //
  //  'qTotal0 <= qBegin <= qTarget <= qTotal1'.
  //
  // and if 'left == true', then
  //
  //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
  X59 db = left ? 
    _total0_.log() - _total1_.log() : 
    _total1_.log() - _total0_.log();

  // 'cTotal1 - cTotal0' is calculated once and used throughout the search.
  //
  // The subtraction is safe because 'total0' and 'total1' correspond to the
  // kernel breakpoints 'indexKernelTotal - oneIndex' and 'indexKernelTotal',
  // respectively, and the vertical coordinates of kernel breakpoints are
  // monotonically non-decreasing due to the custom error
  // 'NonMonotonicVerticalCoordinates' in 'KernelCompact.sol'.
  X15 dc = _total1_.height() - _total0_.height();

  // Next we calculate
  //
  //  'q2 := 2 * (cTotal1 - cTotal0)'
  //
  // The multiplication is safe because 'twoX59' is positive and the output
  // does not exceed '64 + 16 == 80' bits.
  X74 q2 = twoX59.times(dc);

  // The second coefficient is calculated as
  //
  // 'q1 := (cTotal1 - cTotal0) * (2 + |qTotal1 - qBegin|)
  //      - cTotal1 * |qTotal1 - qTotal0|'

  // The multiplication 'db.times(_total1_.height())' is safe because the
  // output does not exceed 80 bits.
  //
  // The subtraction is unsafe and 'q1' may be negative.
  X74 q1 = q2 - db.times(_total1_.height());

  // The subtractions are safe because of the last input requirement and the
  // fact that
  //
  //  'getDirection() == getZeroForOne() == left'.
  //
  // Lastly, the additions are safe because neither values exceed 81 bits.
  q1 = left ? 
    q1 + (_begin_.log() - _total1_.log()).times(dc) : 
    q1 + (_total1_.log() - _begin_.log()).times(dc);

  // Next, in order to compute 'q0', if 'left == false', we calculate:
  //
  //        incomingLimit          db
  //  '---------------------- * --------- * exp(- qBegin / 2) ==
  //    (2 ** 216) * exp(-8)     2 ** 59
  //
  //    incomingLimit * db * ((2 ** 216) * exp(- 8 - qBegin / 2))
  //   ----------------------------------------------------------- ==
  //                  (2 ** (216 + 59)) * exp(-16)
  //
  //    incomingLimit * db * _begin_.sqrt(false)
  //   ------------------------------------------'
  //          (2 ** (216 + 59)) * exp(-16)
  //
  // and if 'left == true', we calculate:
  //
  //        incomingLimit          db
  //  '---------------------- * --------- * exp(+ qBegin / 2) ==
  //    (2 ** 216) * exp(-8)     2 ** 59
  //
  //    incomingLimit * db * ((2 ** 216) * exp(- 8 + qBegin / 2))
  //   ----------------------------------------------------------- ==
  //                  (2 ** (216 + 59)) * exp(-16)
  //
  //    incomingLimit * db * _begin_.sqrt(true)
  //   -----------------------------------------'.
  //          (2 ** (216 + 59)) * exp(-16)
  //
  // The three inputs of 'mulDivByExpInv16' are non-negative and overflow is
  // not possible because
  //
  //    incomingLimit * db * _begin_.sqrt(left)
  //  '----------------------------------------- < 
  //          (2 ** (216 + 59)) * exp(-16)
  //
  //    (2 ** 216) * (2 ** 64) * (2 ** 216)
  //   ------------------------------------- == 
  //       (2 ** (216 + 59)) * exp(-16)
  //
  //   32 * exp(16) * oneX216 < 2 ** 256 - 1'.
  //
  // Hence, the requirements of 'mulDivByExpInv16' are satisfied.
  //
  // Additionally, 'toX216' does not overflow because
  //
  //  '- (2 ** 80) < q1 < + (2 ** 80)'.
  //
  // The subtraction is unsafe and may be negative.
  X216 q0 = 
    q1.toX216() - db.mulDivByExpInv16(_begin_.sqrt(left), incomingLimit);

  // The initial value for 'x' is calculated here. The subtractions are safe
  // because as we argued before, if 'left == false', then
  //
  //  'qTotal0 <= qBegin <= qTarget <= qTotal1'
  //
  // and if 'left == true', then
  //
  //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
  X59 xLimit = 
    left ? _begin_.log() - _target_.log() : _target_.log() - _begin_.log();

  X59 x = xLimit;
  if (X59.unwrap(xLimit) <= X216.unwrap(incoming)) {
    // All three inputs of 'cheapMulDiv' are non-negative.
    //
    // Due to the prior check, 'incomingLimit < incoming'. Additionally, due to
    // the above condition, we have 'xLimit <= incoming'. Hence,
    //
    //  'xLimit * incomingLimit < incoming * (incoming - 1)'
    //
    // and the requirement of 'cheapMulDiv' is met.
    //
    // Signed comparison is valid because the first term is a positive constant
    // and the second term is non-negative.
    x = max(epsilonX59, xLimit.cheapMulDiv(incomingLimit, incoming));
  }

  while (true) {
    // For each iteration, we evaluate 'g(x)' and 'h(x)' in 'X74' and 'X216'
    // representations, respectively.
    //
    // 'x.times(dc)' is safe because 'x' is not less than 'epsilonX59' due to
    // the above check and we have already checked that 'dc' is nonnegative.
    //
    // 'g.toX216()' is safe because:
    //
    //   '- (2 ** 81) < x.times(dc) - q1 < + (2 ** 81)'.
    //
    // The input requirements of 'expInverse' are satisfied because 'x' is not
    // less than 'epsilonX59' and
    //
    //  'x <= |_target_.log() - _begin_.log()| < (2 ** 64) / 3'.
    //
    // Additionally,
    //
    //  'x.expInverse() == (2 ** 256) * exp(- x / (2 ** 60))
    //                  >= (2 ** 256) * exp(- qSpacing / 2)
    //                  >= (2 ** 256) * exp(- 16 / 3) > 2 ** 248
    //
    // Hence,
    //
    //  '(x.expInverse() >> 40) < oneX216'
    //
    // which means that casting to 'int256' is safe and the product
    //
    //  'q0 * X216.wrap(int256(x.expInverse() >> 40))'
    //
    // does not overflow.
    //
    // However, the addition
    //
    //   'h = g.toX216() + q0 * X216.wrap(int256(x.expInverse() >> 40))'
    //
    // is unsafe and 'h' may be negative.
    //
    // On the other hand, the addition 'g + q2' is safe and the outcome is
    // positive because
    //
    //   'g(x) := (cTotal1 - cTotal0) * x - q1 + q2
    //
    //         == (cTotal1 - cTotal0) * x + 
    //            2 * (cTotal1 - cTotal0) - 
    //            (cTotal1 - cTotal0) * (2 + |qTotal1 - qBegin|) + 
    //            cTotal1 * |qTotal1 - qTotal0|
    //
    //         == (cTotal1 - cTotal0) * x + 
    //            cTotal0 * |qTotal1 - qBegin| + 
    //            cTotal1 * (|qTotal1 - qTotal0| - |qTotal1 - qBegin|)
    //
    //         > (cTotal1 - cTotal0) * x >= 1 / ((2 ** 15) * (2 ** 59)) > 0'
    //
    // where the first inequality is concluded from the fact that, if
    // 'left == false', then
    //
    //  'qTotal0 <= qBegin <= qTarget <= qTotal1'
    //
    // and if 'left == true', then
    //
    //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
    //
    // Also, 'cTotal1 - cTotal0 >= 1 / (2 ** 15)' is concluded from the initial
    // check for the determination of 'exactAmount', because if
    // 'cTotal1 == cTotal0 == 0', then we have 'exactAmount == false' and this
    // part of the code would not be reached. Hence, 'g' is positive which will
    // be used later.
    X74 g = x.times(dc) - q1;
    X216 h = g.toX216() + q0 * X216.wrap(int256(x.expInverse() >> 40));
    g = g + q2;

    // Next, we calculate the following Halley step:
    //
    //                           2 * (h(x) / g(x))
    //  'step = -----------------------------------------------------'
    //           1 - (h(x) / g(x)) / 2 - (h(x) / g(x)) * (dc / g(x))
    //
    // in 'X59' representation.
    //
    // The numerator is in 'X142' representation.
    // The denominator is in 'X83' representation.
    X59 step;
    uint256 denominator;
    assembly {
      // The division is safe because 'g' is positive as we argued before.
      let h_over_g_X142 := sdiv(h, g) // h(x) / g(x)
      denominator := sub(
        shl(83, 1), // oneX83
        add(
          // Here, 'h_over_g_X142' is shifted to the right by
          // '60 == 142 - 83 + 1' bits where '1' appears because we are
          // dividing by two. '142' appears because we are casting from the 
          // 'X142' representation and '83' appears because we are casting to  
          // the 'X83' representation.
          sar(60, h_over_g_X142), // (h(x) / g(x)) / 2
          sdiv(mul(h_over_g_X142, dc), g) // (h(x) / g(x)) * (dc / g(x))
        )
      ) // 1 - (h(x) / g(x)) / 2 - (h(x) / g(x)) * (dc / g(x))
      step := sdiv(
        add(h_over_g_X142, h_over_g_X142), // 2 * (h(x) / g(x))
        denominator
      )
    }

    if (step == zeroX59) {
      require(denominator != 0, SearchingForIncomingTargetFailed());
      break;
    }

    // The solution is capped by 'epsilonX59' and 'xLimit'. Hence, we do not
    // need to argue whether the addition 'x - step' is safe or not.
    x = min(max(epsilonX59, x - step), xLimit);
  }

  // The subtraction and the addition are safe because if 'left == false':
  //
  //  '0 < x <= xLimit := qTarget - qBegin',
  //
  // and if 'left == true':
  //
  //  '0 < x <= xLimit := qBegin - qTarget'.
  //
  x = min(x + epsilonX59, xLimit);
  x = left ? _begin_.log() - x : _begin_.log() + x;

  // The output should be stored in both of the memory spaces that are pointed
  // to by '_overshoot_' and '_target_'.
  //
  // The requirements of 'storePrice' and 'incoming' are satisfied because
  //
  //  'min(qBegin, qTarget) <= x <= max(qBegin, qTarget)'.
  //
  _overshoot_.storePrice(x);

  // As argued before, if 'getDirection() == false', then
  //
  //  'qTotal0 <= qBegin <= qOvershoot <= qTarget <= qTotal1'.
  //
  // and if 'getDirection() == true', then
  //
  //  'qTotal1 <= qTarget <= qOvershoot <= qBegin <= qTotal0'.
  //
  // Additionally, since the vertical coordinates of kernel are monotonic, we
  // have 'cTotal0 <= cTotal1' and the input requirements of 'incoming' are
  // satisfied.
  incoming = _total0_.incoming(_begin_, _overshoot_);

  // 'x' is moved backward to ensure that the resulting integral is an under
  // approximation.
  while (incoming > incomingLimit) {
    // All safety requirements are satisfied here, because:
    //
    //  'incomingLimit < _total0_.incoming(_begin_, _target_)'.
    //
    // Hence, the loop is stopped before we reach 'qTarget'.
    x = left ? x + epsilonX59 : x - epsilonX59;

    // Due to the above argument, if 'left == false' then
    //
    //  'qOvershoot + 1 / (2 ** 59) < qTarget <= qUpper'
    //
    // and if 'left == true' then
    //
    //  'qLower <= qTarget < qOvershoot - 1 / (2 ** 59)'.
    //
    // Hence the input requirements of 'moveOvershootByEpsilon' are satisfied.
    moveOvershootByEpsilon(!left);

    // As argued before, if 'getDirection() == false', then
    //
    //  'qTotal0 <= qBegin <= qOvershoot <= qTarget <= qTotal1'.
    //
    // and if 'getDirection() == true', then
    //
    //  'qTotal1 <= qTarget <= qOvershoot <= qBegin <= qTotal0'.
    //
    // Additionally, since the vertical coordinates of kernel are monotonic, we
    // have 'cTotal0 <= cTotal1' and the input requirements of 'incoming' are
    // satisfied.
    incoming = _total0_.incoming(_begin_, _overshoot_);
  }

  // The output should be stored in both of the memory spaces that are pointed
  // to by '_overshoot_' and '_target_'.
  _target_.copyPrice(_overshoot_);

  return (true, incoming);
}

/// @notice Enumerates the pieces of the liquidity distribution function
/// 'k(w(.))' in search for the logarithmic price 'qTarget' which satisfies
/// either of the following two conditions:
///
///  - 'qLimitWithinInterval == qTarget', or
///
///  - 'integralLimit == (
///       getExactInput() ? incomingCurrentToTarget : currentToTarget
///     )'.
///
/// As explained in 'Memory.sol', the boundaries of the current piece under
/// exploration is given as:
///
///  'qBegin := getDirection() ? 
///             min(q[indexCurve + 2], qTotal0) : 
///             max(q[indexCurve + 2], qTotal0)',
///
///  'qTarget := (
///                getDirection() == getZeroForOne()
///              ) ? (
///                getDirection() ? 
///                max(max(qEnd, qTotal1), qLimitWithinInterval) : 
///                min(min(qEnd, qTotal1), qLimitWithinInterval)
///              ) : (
///                getDirection() ? 
///                max(qEnd, qTotal1) : 
///                min(qEnd, qTotal1)
///              )'.
///
/// The present function transitions to the next piece of 'k(w(.))' by updating 
/// the appropriate values in memory and by incrementing the following
/// integrals:
///  
///  - 'currentToTarget',
///
///  - 'incomingCurrentToTarget',
///
///  - 'currentToOrigin',
///
///  - 'originToOvershoot'.
///
/// --------------------------------------------------------------------------- 
///
/// The underflow of
///
///  'getIntegralLimit() - getExactInput() ? 
///                        _incomingCurrentToTarget_.integral() : 
///                        _currentToTarget_.integral()'
///
/// should be avoided externally.
///
/// Out of range values for 'indexKernelTotal' should be avoided externally.
///
/// Underflow of 'indexCurve' should be avoided externally.
function moveTarget() pure returns (
  bool stop
) {
  // According to the above definitions for 'qBegin' and 'qTarget', if
  // 'getDirection() == false', then we have:
  //
  //  'qTotal0 <= qBegin <= qTarget <= qTotal1'.
  //
  // In this case, if 'qTarget == qTotal1' as illustrated below,
  //
  //      +---------+---------+
  //      |         |         |
  //   qTotal0   qBegin    qTotal1
  //                          |
  //                       qTarget
  //
  // then 'indexKernelTotal' is incremented and the next piece of 'k(.)' is
  // loaded and stored in the memory spaces that are pointed to by '_total0_'
  // and '_total1_':
  //
  //      +---------+---------+-------------------+
  //                |         |                   |
  //             qBegin    qTotal0             qTotal1
  //                          |
  //                       qTarget
  //
  // If 'getDirection() == true', then we have:
  //
  //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
  //
  // In this case, if 'qTarget == qTotal1' as illustrated below,
  //
  //                          +---------+---------+
  //                          |         |         |
  //                       qTotal1   qBegin    qTotal0
  //                          |
  //                       qTarget
  //
  // then 'indexKernelTotal' is incremented and the next piece of 'k(.)' is
  // loaded and stored in the memory spaces that are pointed to by '_total0_'
  // and '_total1_':
  //
  //      +-------------------+---------+---------+
  //      |                   |         |
  //   qTotal1             qTotal0   qBegin
  //                          |
  //                       qTarget
  //
  // Out of range values for 'indexKernelTotal' are avoided because of an
  // input requirement for the present function.
  if (_target_.log() == _total1_.log()) moveBreakpointTotal();

  // The current direction is loaded from memory.
  bool direction = getDirection();

  // According to the above definitions for 'qBegin' and 'qTarget', if
  // 'getDirection() == false', then we have:
  //
  //  'q[indexCurve + 2] <= qBegin <= qTarget <= qEnd'.
  //
  // In this case, if 'qTarget == qEnd' as illustrated below,
  //
  //         w(q)
  //          ^
  //  spacing |                                              /
  //          |                                             /
  //          |                                            /
  //          |                                           /
  //          |                                          /
  //          |                                         /
  //          |                                        /
  //          |                                       /
  //          |                                      /
  //          |                                     /
  //          |                                    /
  //          |\
  //          | \
  //          |  \
  //          |   \
  //          |    \
  //          |     \
  //          |      \
  //          |       \
  //          |        \
  //          |         \
  //          |          \
  //          |                                  /
  //          |                                 /
  //          |                                /
  //          |                               /
  //          |                              /
  //          |                             /
  //          |                            /
  //          |                           /
  //          |                          /
  //          |                         /
  //          |                        /
  //          |            \
  //          |             \
  //          |              \
  //          |               \
  //          |                \
  //          |                 \
  //          |                  \
  //          |                   \
  //          |                    \
  //          |                     \
  //          |                      \
  //        0 +-----------+-----------+-----+-----+-----+-----+> q
  //                      |           |     |     |
  //                   qOrigin        |  qBegin  qEnd
  //                                  |           |
  //                                  |        qTarget
  //                                  |
  //                          q[indexCurve + 2]
  //
  // then 'indexCurve' is decremented, the direction is flipped and the next
  // phase of 'w(.)' is loaded by setting:
  //
  //  'qEnd := q[indexCurve]'
  //
  //  'qOrigin := q[indexCurve + 1]'
  //
  //  'qBegin := q[indexCurve + 2]'
  //
  // which is illustrated as follows:
  //
  //         w(q)
  //          ^
  //  spacing |                                              /
  //          |                                             /
  //          |                                            /
  //          |                                           /
  //          |                                          /
  //          |                                         /
  //          |                                        /
  //          |                                       /
  //          |                                      /
  //          |                                     /
  //          |                                    /
  //          |\
  //          | \
  //          |  \
  //          |   \
  //          |    \
  //          |     \
  //          |      \
  //          |       \
  //          |        \
  //          |         \
  //          |          \
  //          |                                  /
  //          |                                 /
  //          |                                /
  //          |                               /
  //          |                              /
  //          |                             /
  //          |                            /
  //          |                           /
  //          |                          /
  //          |                         /
  //          |                        /
  //          |            \
  //          |             \
  //          |              \
  //          |               \
  //          |                \
  //          |                 \
  //          |                  \
  //          |                   \
  //          |                    \
  //          |                     \
  //          |                      \
  //        0 +-----------+-----------+-----------+-----------+> q
  //          |           |                       |
  //        qEnd       qBegin                  qOrigin
  //                      |                       |
  //              q[indexCurve + 2]            qTarget
  //
  // If 'getDirection() == true', then we have:
  //
  //  'qEnd <= qTarget <= qBegin <= q[indexCurve + 2]'.
  //
  // and a similar argument can be made.
  if (_target_.log() == _end_.log()) {
    // Once we move the phase, the direction flips and 'qOrigin' will be moved
    // to 'qEnd'. Hence, the following integral
    //
    //                             - 8
    //    originToOvershoot      e
    //  '------------------- == ------- * (
    //        2 ** 216             2
    //
    //     getZeroForOne() ? 
    //
    //       / qOrigin
    //      |    + h / 2
    //      |  e         k(qOrigin - h) dh :
    //      |
    //     / qEnd
    //
    //       / qEnd
    //      |    - h / 2
    //      |  e         k(h - qOrigin) dh
    //      |
    //     / qOrigin
    //
    //   )'
    //
    // should be transformed to
    //
    //                             - 8
    //    originToOvershoot      e
    //  '------------------- := ------- * (
    //        2 ** 216             2
    //
    //     getZeroForOne() ? 
    //
    //       / qOrigin
    //      |    - h / 2
    //      |  e         k(h - qEnd) dh :
    //      |
    //     / qEnd
    //
    //       / qEnd
    //      |    + h / 2
    //      |  e         k(qEnd - h) dh
    //      |
    //     / qOrigin
    //
    //   )'
    //
    // Notice that at this stage 'overshoot' and 'target' are equal.
    //
    // The loaded integral does not exceed 216-bits and hence, the input
    // requirement of shift is satisfied.
    _originToOvershoot_.setIntegral(
      _originToOvershoot_.integral().shift(_target_, _origin_, direction)
    );

    // Underflow of 'indexCurve' is avoided externally via an input requirement
    // of the present function.
    direction = movePhase();
  }

  // If the phase is moved, then we have:
  //
  //  'qBegin == q[indexCurve + 2]'.
  //
  // If the phase is not moved, then the kernel piece is moved and we have:
  //
  //  'qBegin <= qTarget == qTotal0'.
  //
  // In both cases, we need to set:
  //
  //  'qBegin := direction ? min(qBegin, qTotal0) : max(qBegin, qTotal0)'
  //
  // which is equivalent to setting:
  //
  //  'qBegin := qTotal0'
  //
  // if and only if 'direction != (qBegin < qTotal0)'.
  //
  // Signed comparison is valid because as we argued before in this script,
  // both 'qBegin' and 'qTotal0' are greater than '0' and less than '32'. This
  // is due to the custom error 'BlankIntervalsShouldBeAvoided' ensures that
  // '16 + qLower' is greater than 'qSpacing' and '16 + qUpper' is smaller than
  // '32 - qSpacing'.
  if (direction != (_begin_.log() < _total0_.log())) {
    _begin_.copyPrice(_total0_);
  }

  // Next, we need to set:
  //
  //  'qTarget := direction ? min(qEnd, qTotal1) : max(qEnd, qTotal1)'
  //
  // which is equivalent to setting:
  //
  //  'qTarget := qTotal1'
  //
  // if and only if 'direction == (qEnd <= qTotal1)' and
  //
  //  'qTarget := qEnd'
  //
  // otherwise.
  //
  // Signed comparison is valid because as we argued before in this script,
  // both 'qEnd' and 'qTotal1' are greater than '0' and less than '32'. This
  // is due to the custom error 'BlankIntervalsShouldBeAvoided' ensures that
  // '16 + qLower' is greater than 'qSpacing' and '16 + qUpper' is smaller than
  // '32 - qSpacing'.
  _target_.copyPrice(
    (direction == (_end_.log() <= _total1_.log())) ? _total1_ : _end_
  );

  // Next, if 'direction == getZeroForOne()', we increment the integrals:
  //
  //  - 'currentToTarget',
  //  - 'incomingCurrentToTarget',
  //
  // and search for 'qTarget'. Otherwise, we increment the integral:
  //
  //  - 'currentToOrigin'
  //
  // and in both cases we increment 'originToOvershoot' as well.
  X216 outgoing;
  if (direction == getZeroForOne()) {
    // 'qLimitWithinInterval' is loaded from the memory.
    X59 logPriceLimitOffsettedWithinInterval = 
      getLogPriceLimitOffsettedWithinInterval();

    // If 'qTarget' encounters 'qLimitWithinInterval', then we set 'qTarget' as
    // 'qLimitWithinInterval'.
    //
    // Signed comparison is valid as we argued before.
    if (direction != (logPriceLimitOffsettedWithinInterval < _target_.log())) {
      // '_target_' is a constant value which satisfies the input requirement
      // of 'storePrice'.
      //
      // Also we have: 
      //
      //  '0 < qLower <= qLimitWithinInterval <= qUpper < 2 ** 64'
      //
      // which means that 'logPriceLimitOffsettedWithinInterval' satisfies the
      // input requirement of 'storePrice'.
      _target_.storePrice(logPriceLimitOffsettedWithinInterval);
    }

    X216 incoming;
    // Check if 'amountSpecified' is incoming or outgoing.
    if (getExactInput()) {
      // In this case, we search for a 'qTarget' which satisfies
      //
      //                              - 8     / qTarget
      //    getIntegralLimit()      e        |    + h / 2
      //  '-------------------- == ------- * |  e         k(w(h)) dh',
      //         2 ** 216             2      |
      //                                    / qCurrent
      //
      // if 'zeroForOne == false' and satisfies:
      //
      //                              - 8     / qCurrent
      //    getIntegralLimit()      e        |    - h / 2
      //  '-------------------- == ------- * |  e         k(w(h)) dh',
      //         2 ** 216             2      |
      //                                    / qTarget
      //
      // if 'zeroForOne == true'. If no solution exists, then the integral
      // within the whole range from 'min(qCurrent, qTarget)' to
      // 'max(qCurrent, qTarget)' is calculated to be used as an increment to
      // update 'incomingCurrentToTarget'.
      //
      // The input requirement 'getDirection() == getZeroForOne()' is checked
      // by the above 'if'.
      //
      // The underflow of
      //
      //  'getIntegralLimit() - _incomingCurrentToTarget_.integral()'
      //
      // is not possible because of the input requirement of the present
      // function.
      (stop, incoming) = searchIncomingTarget();

      // As argued before, if 'getDirection() == false', then
      //
      //  'qTotal0 <= qBegin <= qTarget <= qTotal1'.
      //
      // and if 'getDirection() == true', then
      //
      //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
      //
      // Additionally, since the vertical coordinates of kernel are monotonic,
      // we have 'cTotal0 <= cTotal1' and the input requirements of 'outgoing'
      // are satisfied.
      outgoing = _total0_.outgoing(_begin_, _target_);
    } else {
      // In this case, we search for a 'qTarget' which satisfies
      //
      //                              - 8     / qTarget
      //    getIntegralLimit()      e        |    - h / 2
      //  '-------------------- == ------- * |  e         k(w(h)) dh',
      //         2 ** 216             2      |
      //                                    / qCurrent
      //
      // if 'zeroForOne == false' and satisfies:
      //
      //                              - 8     / qCurrent
      //    getIntegralLimit()      e        |    + h / 2
      //  '-------------------- == ------- * |  e         k(w(h)) dh',
      //         2 ** 216             2      |
      //                                    / qTarget
      //
      // if 'zeroForOne == true'. If no solution exists, then the integral
      // within the whole range from 'min(qCurrent, qTarget)' to
      // 'max(qCurrent, qTarget)' is calculated to be used as an increment to
      // update 'currentToTarget'.
      //
      // The input requirement 'getDirection() == getZeroForOne()' is checked
      // by the above 'if'.
      //
      // The underflow of
      //
      //  'getIntegralLimit() - _currentToTarget_.integral()'
      //
      // is not possible because of the input requirement of the present
      // function.
      (stop, outgoing) = searchOutgoingTarget();

      // As argued before, if 'getDirection() == false', then
      //
      //  'qTotal0 <= qBegin <= qTarget <= qTotal1'.
      //
      // and if 'getDirection() == true', then
      //
      //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
      //
      // Additionally, since the vertical coordinates of kernel are monotonic,
      // we have 'cTotal0 <= cTotal1' and the input requirements of 'incoming'
      // are satisfied.
      incoming = _total0_.incoming(_begin_, _target_);
    }

    // Next, 'currentToTarget' is incremented with 'outgoing'.
    //
    //                   - 8     / qTarget
    //                 e        |    - h / 2
    //  '(2 ** 216) * ------- * |  e         k(w(h)) dh   <
    //                   2      |
    //                         / qCurrent
    //
    //                   - 8     / +16
    //                 e        |    - h / 2
    //   (2 ** 216) * ------- * |  e         dh   <   2 ** 216 - 1.
    //                   2      |
    //                         / -16
    //
    // Based on the above inequality, overflow is not possible because
    // theoretically, no outgoing or incoming integral may exceed 216 bits.
    _currentToTarget_.incrementIntegral(outgoing);

    // Next, 'incomingCurrentToTarget' is incremented with 'incoming'.
    // Based on the above argument, overflow is not possible because
    // theoretically, no outgoing or incoming integral may exceed 216 bits.
    _incomingCurrentToTarget_.incrementIntegral(incoming);
  } else {
    // As argued before, if 'getDirection() == false', then
    //
    //  'qTotal0 <= qBegin <= qTarget <= qTotal1'.
    //
    // and if 'getDirection() == true', then
    //
    //  'qTotal1 <= qTarget <= qBegin <= qTotal0'.
    //
    // Additionally, since the vertical coordinates of kernel are monotonic,
    // we have 'cTotal0 <= cTotal1' and the input requirements of 'outgoing'
    // are satisfied.
    outgoing = _total0_.outgoing(_begin_, _target_);

    // Next, 'currentToOrigin' is incremented with 'outgoing'.
    // Based on the above argument, overflow is not possible because
    // theoretically, no outgoing or incoming integral may exceed 216 bits.
    _currentToOrigin_.incrementIntegral(outgoing);
  }

  // In both cases, (i.e. regardless of 'direction == getZeroForOne()') the
  // integral 'originToOvershoot' should be incremented with 'outgoing'.
  // Based on the above argument, overflow is not possible because
  // theoretically, no outgoing or incoming integral may exceed 216 bits.
  _originToOvershoot_.incrementIntegral(outgoing);
}

/// @notice Calculates 'outgoingMax', 'incomingMax', and
/// 'outgoingMaxModularInverse', and sets each in the dedicated memory space.
///
/// 'outgoingMax' is calculated based on the formula:
///
///                       - 8 + qLower / 2     / qUpper
///    outgoingMax      e                     |    - h / 2
///  '------------- := -------------------- * |  e         k(h - qLower) dh
///     2 ** 216                 2            |
///                                          / qLower
///
///                          - 8     / qSpacing + qEpsilon
///        qEpsilon / 2    e        |                        - h / 2
///   == e              * ------- * |    k(h - qEpsilon) * e         dh'
///                          2      |
///                                / qEpsilon
///
/// and 'incomingMax' is calculated based on the formula:
///
///                       - 8 - qUpper / 2     / qUpper
///    incomingMax      e                     |    + h / 2
///  '------------- := -------------------- * |  e         k(h - qLower) dh
///     2 ** 216                 2            |
///                                          / qLower
///
///        - (qSpacing + qEpsilon) / 2
///   == e                             *
///
///         - 8     / qSpacing + qEpsilon
///       e        |                        + h / 2
///      ------- * |    k(h - qEpsilon) * e         dh'.
///         2      |
///               / qEpsilon
///
/// where 'qEpsilon := - 16 + 1 / (2 ** 59)'.
///
/// Let '2 ** n' be the largest power of '2' that divides 'outgoingMax' and
/// define 'outgoingMaxModularInverse' as the modular inverse of 
/// 
///    outgoingMax
///  '-------------'
///      2 ** n
///
/// modulo '2 ** 256'.
function calculateMaxIntegrals() pure {
  // In order to calculate 'outgoingMax' and 'incomingMax' we need to create
  // the following curve sequence in memory:
  //
  //  'q[0] := qSpacing + qEpsilon',
  //  'q[1] := qEpsilon',
  //
  // which we refer to as 'toyCurve'.

  // To this end, we first cache the memory pointer for the current curve
  // sequence and the current 'curveLength' from the memory.
  Curve curve = getCurve();
  Index curveLength = getCurveLength();

  // Next, a plain curve is constructed in the first slot of the memory so that
  // 'outgoingMax' and 'incomingMax' can be calculated.
  //
  // The first member of 'toyCurve' is set as:
  //
  //  'qLimit := qSpacing + 1 / (2 ** 59)'.
  //
  // The addition is safe because as we argued before in this script:
  //
  //  'qSpacing < (2 ** 64) / 3'.
  //
  X59 qLimit = _spacing_.log() + epsilonX59;
  {
    // A new pointer is initialized and set in memory.
    Curve toyCurve;
    setCurve(toyCurve);

    // Both inputs are positive and less than 'thirtyTwoX59'. So, the
    // requirements of 'newCurve' are satisfied.
    toyCurve.newCurve(epsilonX59, qLimit);
  }

  // As is the case for swaps, we employ the method 'moveTarget()' in order to
  // calculate both of the integrals:
  //
  //      - 8     / qLimit
  //    e        |                        - h / 2
  //  '------- * |    k(h - qEpsilon) * e         dh'
  //      2      |
  //            / qEpsilon
  //
  // and
  //
  //      - 8     / qLimit
  //    e        |                        + h / 2
  //  '------- * |    k(h - qEpsilon) * e         dh'.
  //      2      |
  //            / qEpsilon
  //
  // To this end, 'qLimit' is set in memory as the end of the interval.
  setLogPriceLimitOffsetted(qLimit);

  // And, '|amountSpecified|' is set to 'infinity'.
  setIntegralLimit(oneX216 - epsilonX216);
  
  // A fresh interval is initiated for us to start the swap that calculates the
  // two integrals.
  initiateInterval();
  
  // 'currentToTarget' and 'incomingCurrentToTarget' are incremented until 
  // 'qTarget' reaches 'qLimit'.
  while (_target_.log() != qLimit) {
    // The input requirement of 'moveTarget()' are satisfied because
    // 'integralLimit' is set to 'infinity' and because 'qTarget' reaches
    // 'qLimit' before 'indexKernelTotal' becomes out of range or 'indexCurve'
    // underflows.
    if (moveTarget()) break;
  }
  
  // The 'curve' pointer and 'curveLength' are set to their previous value.
  setCurve(curve);
  setCurveLength(curveLength);

  {
    // Next, 'outgoingMax' is calculated from 'currentToTarget' as follows:
    //
    //    outgoingMax
    //  '------------- ==
    //     2 ** 216
    //
    //                       - 8     / qLimit
    //     qEpsilon / 2    e        |                      - h / 2
    //   e              * ------- * |  k(h - qEpsilon) * e         dh ==
    //                       2      |
    //                             / qEpsilon
    //
    //     qEpsilon / 2    currentToTarget
    //   e              * ----------------- ==
    //                        2 ** 216
    //
    //     - 8    currentToTarget      1 / (2 ** 60)
    //   e     * ----------------- * e              '
    //               2 ** 216
    //
    // The use of 'cheapMul' is safe, because 'expInverse8X216' is positive and
    // less than 'oneX216'. Moreover, like every outgoing integral,
    // 'currentToTarget' is nonnegative and less than 'oneX216'.
    //
    // Overflow of 'multiplyByExpEpsilon' is impossible because, theoretically,
    // the output satisfies:
    //
    //                       - 8     / qSpacing
    //    outgoingMax      e        |    - h / 2
    //  '------------- := ------- * |  e         k(h) dh
    //     2 ** 216          2      |
    //                             / 0
    //
    //                       - 8     / 32
    //                     e        |    - h / 2
    //                  < ------- * |  e         dh < 1
    //                       2      |
    //                             / 0
    //
    X216 outgoingMax = (
      _currentToTarget_.integral() & expInverse8X216
    ).multiplyByExpEpsilon();

    // Due to the above argument, 'outgoingMax' does not exceed 216 bits and
    // can be safely stored in the dedicated memory space which is pointed to
    // by '_outgoingMax_'.
    setOutgoingMax(outgoingMax);

    // Next, the modular inverse of the largest odd factor of 'outgoingMax'
    // is calculated.
    //
    // Let 'outgoingMax == (2 ** n) * (2 * r + 1)' where 'n' and 'r' are
    // nonnegative integers (i.e., '2 ** n' is the largest power of '2' that
    // divides 'outgoingMax'). Then, the binary representation of 'outgoingMax'
    // looks like:
    //
    //        ___________
    //        r 1 0 ... 0
    //
    // with exactly 'n' zero digits appearing as the least significant. On the
    // other hand, the binary representation of '(2 ** 256) - outgoingMax'
    // looks like:
    //
    //   ________________
    //   not(r) 1 0 ... 0
    //
    // with exactly 'n' zero digits appearing as the least significant.
    //
    // Hence, we have:
    //
    //  'outgoingMax & ((2 ** 256) - outgoingMax) == 2 ** n'.
    //
    uint256 outgoingMaxLargestOddFactor;
    assembly {
      // 'outgoingMax / (2 ** n)'
      outgoingMaxLargestOddFactor := div(
        outgoingMax,
        and(sub(0, outgoingMax), outgoingMax) // '2 ** n'
      )
    }
    setOutgoingMaxModularInverse(
      FullMathLibrary.modularInverse(outgoingMaxLargestOddFactor)
    );
  }

  // Next, 'incomingMax' is calculated from 'incomingCurrentToTarget' as
  // follows:
  //
  //    incomingMax       - (qSpacing + qEpsilon) / 2
  //  '------------- == e                             *
  //     2 ** 216
  //
  //      - 8     / qLimit
  //    e        |                      + h / 2
  //   ------- * |  k(h - qEpsilon) * e         dh ==
  //      2      |
  //            / qEpsilon
  //
  //     - (qSpacing + qEpsilon) / 2    incomingCurrentToTarget
  //   e                             * ------------------------- ==
  //                                           2 ** 216
  //
  //      - qSpacing    incomingCurrentToTarget
  //    e            * -------------------------
  //                          2 ** 216                - 1 / (2 ** 60)
  //   ------------------------------------------ * e                 '.
  //                       - 8
  //                     e
  //
  // The use of 'mulDivByExpInv8' is safe, because both inputs are positive and
  // less than 'oneX216'. Moreover, overflow is not possible because the output
  // of 'mulDivByExpInv8' is smaller than 'incomingMax' which satisfies
  //
  //                       - 8 - qSpacing / 2     / qSpacing
  //    incomingMax      e                       |    + h / 2
  //  '------------- := ---------------------- * |  e         k(h) dh
  //     2 ** 216                 2              |
  //                                            / 0
  //
  //                       - 24     / 32
  //                     e         |    + h / 2
  //                  < -------- * |  e         dh < 1
  //                       2       |
  //                              / 0
  //
  setIncomingMax((
    _incomingCurrentToTarget_.integral() % _spacing_.sqrt(false)
  ).divideByExpEpsilon());

  // Clears memory so that it can be used later for the calculation of
  // 'integral0' and 'integral1'.
  clearInterval();
}

/// @notice Calculates 'integral0' and 'integral1' where:
///
///                     - 8     / qUpper
///    integral0      e        |    - h / 2
///  '----------- := ------- * |  e         k(w(h)) dh',
///    2 ** 216         2      |
///                           / qCurrent
///
/// and
///
///                     - 8     / qCurrent
///    integral1      e        |    + h / 2
///  '----------- := ------- * |  e         k(w(h)) dh'.
///    2 ** 216         2      |
///                           / qLower
///
/// This method is called during initialization.
function calculateIntegrals() pure {
  // In order to calculate 'integral0' and 'integral1', we need to employ the
  // method 'moveTarget()'. To this end, 'qLimit' is set as the very first
  // member of the curve sequence which is one of the interval boundaries.
  X59 qLimit = getCurve().member(zeroIndex);

  // 'qLimit' is set in memory.
  setLogPriceLimitOffsetted(qLimit);

  // The direction of our exploration is set with respect to 'qLimit'.
  setZeroForOne(qLimit <= getLogPriceCurrent());

  // 'integralLimit' (i.e., '|amountSpecified|') is set to 'infinity'.
  setIntegralLimit(oneX216 - epsilonX216);

  // A fresh interval is initiated for us to start the swap that calculates the
  // two integrals.
  initiateInterval();

  // 'currentToTarget' and 'incomingCurrentToTarget' are incremented until 
  // 'qTarget' reaches 'qLimit'.
  while (_target_.log() != qLimit) {
    // The input requirement of 'moveTarget()' are satisfied because
    // 'integralLimit' is set to 'infinity' and because 'qTarget' reaches
    // 'qLimit' before 'indexKernelTotal' becomes out of range or 'indexCurve'
    // underflows.
    if (moveTarget()) break;
  }

  // Depending on the direction, the two integrals are determined and set in
  // their dedicated memory location.
  (X216 integral0, X216 integral1) = getZeroForOne() ? (
    _currentToOrigin_.integral(),
    _currentToTarget_.integral()
  ) : (
    _currentToTarget_.integral(),
    _currentToOrigin_.integral()
  );
  setIntegral0(integral0);
  setIntegral1(integral1);
}

/// @notice Assume that the search for 'qTarget' is concluded and we need to
/// determine 'qOvershoot'. To this end, the following equation should be
/// solved:
///
///   'f(qOvershoot) == 0'
///
/// where
///
///   'f(qOvershoot) := getZeroForOne() ? 
///                     s0(qOvershoot) - s1(qOvershoot) : 
///                     s1(qOvershoot) - s0(qOvershoot)',
///
/// and the two functions 's0' and 's1' are defined as:
///
///                          - 8      / qTarget
///                        e         |   + h / 2
///                       ------- *  |  e        k(wAmended(h)) dh
///                          2       |
///                                 / qLower
///   's1(qOvershoot) := ------------------------------------------',
///                                integral1Incremented
///
///                          - 8      / qUpper
///                        e         |   - h / 2
///                       ------- *  |  e        k(wAmended(h)) dh
///                          2       |
///                                 / qTarget
///   's0(qOvershoot) := ------------------------------------------',
///                                integral0Incremented
///
/// where, according to the amendment procedure which is described in
/// 'Curve.sol', if 'getZeroForOne() == false', we have:
///
///                       / k(w(h))            if  qOvershoot < h < qUpper
///   'k(wAmended(h)) == |  k(h - qTarget)     if  qTarget < h < qOvershoot '
///                      |  k(qOvershoot - h)  if  qOrigin < h < qTarget
///                       \ k(w(h))            if  qLower < h < qOrigin
///
/// and if 'getZeroForOne() == true', we have:
///
///                       / k(w(h))            if  qLower < h < qOvershoot
///   'k(wAmended(h)) == |  k(qTarget - h)     if  qOvershoot < h < qTarget '.
///                      |  k(h - qOvershoot)  if  qTarget < h < qOrigin
///                       \ k(w(h))            if  qOrigin < h < qUpper
///
/// The present function evaluates the mismatch function 'f(qOvershoot)'. To
/// this end, we use the following formula which is proven in 'Memory.sol'.
///
///   'f(qOvershoot) := getZeroForOne() ? (
///
///      (
///
///        exp(- (qOrigin + qOvershoot) / 2) * originToOvershoot -
///
///        exp(- (qTarget + qOvershoot) / 2) * targetToOvershoot - 
///
///        incomingCurrentToTarget - currentToOrigin
///
///      ) / integral0Incremented - (
///
///        targetToOvershoot + currentToTarget - currentToOvershoot
///      
///      ) / integral1Incremented
///
///    ) : (
///
///      (
///
///        exp(+ (qOrigin + qOvershoot) / 2) * originToOvershoot -
///
///        exp(+ (qTarget + qOvershoot) / 2) * targetToOvershoot - 
///
///        incomingCurrentToTarget - currentToOrigin
///
///      ) / integral1Incremented - (
///
///        targetToOvershoot + currentToTarget - currentToOvershoot
///      
///      ) / integral0Incremented
///
///    )'.
///
/// @param integral0Incremented The integral of the liquidity distribution
/// function from 'qTarget' to 'qUpper' prior to the amendment of the curve
/// sequence:
///
///                                 - 8     / qUpper
///     integral0Incremented      e        |    - h / 2
///   '---------------------- := ------- * |  e         k(w(h)) dh',
///           2 ** 216              2      |
///                                       / qTarget
///
/// @param integral1Incremented The integral of the liquidity distribution
/// function from 'qLower' to 'qTarget' prior to the amendment of the curve
/// sequence:
///
///                                 - 8     / qTarget
///     integral1Incremented      e        |    + h / 2
///   '---------------------- := ------- * |  e         k(w(h)) dh'.
///           2 ** 216              2      |
///                                       / qLower
///
function getMismatch(
  X216 integral0Incremented,
  X216 integral1Incremented
) pure returns (
  X216 mismatch
) {
  // First 'zeroForOne' is loaded from the memory.
  bool zeroForOne = getZeroForOne();

  // The following value is calculated next:
  //
  //  'zeroForOne ? (
  //
  //     exp(- (qOrigin + qOvershoot) / 2) * originToOvershoot -
  //
  //     exp(- (qTarget + qOvershoot) / 2) * targetToOvershoot - 
  //
  //     incomingCurrentToTarget - currentToOrigin
  //
  //   ) : (
  //
  //     exp(+ (qOrigin + qOvershoot) / 2) * originToOvershoot -
  //
  //     exp(+ (qTarget + qOvershoot) / 2) * targetToOvershoot - 
  //
  //     incomingCurrentToTarget - currentToOrigin
  //
  //   )'.
  //
  // The requirement of 'shift' is satisfied because all of the integrals are
  // read from 216 bits of memory and do not exceed oneX216.
  //
  // The subtractions are unsafe and
  // 'integral1AmendedMinusIntegral1Incremented' may or may not be negative.
  X216 integral1AmendedMinusIntegral1Incremented = 
    _originToOvershoot_.integral().shift(
      _overshoot_,
      _origin_,
      zeroForOne
    ) - _targetToOvershoot_.integral().shift(
      _overshoot_,
      _target_,
      zeroForOne
    ) - _currentToOrigin_.integral() - _incomingCurrentToTarget_.integral();

  // Now, we calculate:
  //
  //  'targetToOvershoot + currentToTarget - currentToOvershoot'
  //  
  // The subtractions are unsafe and
  // 'integral0AmendedMinusIntegral0Incremented' may or may not be negative.
  X216 integral0AmendedMinusIntegral0Incremented = _currentToTarget_.integral()
    + _targetToOvershoot_.integral()
    - _currentToOvershoot_.integral();

  // Neither of 'integral0Incremented' and 'integral1Incremented' do not exceed
  // 'oneX216'. Additionally, since each of
  // 'integral0AmendedMinusIntegral0Incremented' and
  // 'integral1AmendedMinusIntegral1Incremented' are composed of up to four
  // integrals, their absolute value do not exceed '4 * oneX216'. Hence, both
  // multiplications are safe.
  //
  // The subtractions are unsafe and the output may or may not be negative.
  return zeroForOne ? (
    (
      integral1AmendedMinusIntegral1Incremented * integral1Incremented
    ) - (
      integral0AmendedMinusIntegral0Incremented * integral0Incremented
    )
  ) : (
    (
      integral1AmendedMinusIntegral1Incremented * integral0Incremented
    ) - (
      integral0AmendedMinusIntegral0Incremented * integral1Incremented
    )
  );
}

/// @notice Enumerates the pieces of the liquidity distribution function
/// 'k(w(.))' in search for the pair of logarithmic prices:
///
///   'qBegin := (
///                direction == getZeroForOne()
///              ) ? (
///                direction ? 
///                max(max(q[indexCurve + 2], qTotal0), qForward0) : 
///                min(min(q[indexCurve + 2], qTotal0), qForward0)
///              ) : (
///                direction ? 
///                max(q[indexCurve + 2], qTotal0) : 
///                min(q[indexCurve + 2], qTotal0)
///              )',
///
/// and
///
///   'qOvershoot := (
///                    direction == getZeroForOne()
///                  ) ? (
///                    direction ? 
///                    max(max(qEnd, qTotal1), qForward1) : 
///                    min(min(qEnd, qTotal1), qForward1)
///                  ) : (
///                    direction ? 
///                    max(qEnd, qTotal1) : 
///                    min(qEnd, qTotal1)
///                  )',
///
/// which satisfy:
///
///   'f(qBegin) <= 0' and 'f(qOvershoot) >  0'.
///
/// where the mismatch function 'f(.)' is defined in 'Memory.sol' and earlier
/// in this document.
///
/// The present function transitions to the next piece of 'k(w(.))' by updating 
/// the appropriate values in memory and by incrementing the following
/// integrals:
///  
///  - 'currentToOvershoot',
///
///  - 'targetToOvershoot',
///
///  - 'currentToOrigin',
///
///  - 'originToOvershoot'.
///
/// ---------------------------------------------------------------------------
///
/// The underflow of
///
///  'getIntegralLimit() - getExactInput() ? 
///                        _incomingCurrentToTarget_.integral() : 
///                        _currentToTarget_.integral()'
///
/// should be avoided externally.
///
/// Out of range values for 'indexKernelTotal' should be avoided externally.
///
/// Out of range values for 'indexKernelForward' should be avoided externally.
///
/// Underflow of 'indexCurve' should be avoided externally.
///
/// @param integral0Incremented The integral of the liquidity distribution
/// function from 'qTarget' to 'qUpper' prior to the amendment of the curve
/// sequence:
///
///                                 - 8     / qUpper
///     integral0Incremented      e        |    - h / 2
///   '---------------------- := ------- * |  e         k(w(h)) dh',
///           2 ** 216              2      |
///                                       / qTarget
///
/// @param integral1Incremented The integral of the liquidity distribution
/// function from 'qLower' to 'qTarget' prior to the amendment of the curve
/// sequence:
///
///                                 - 8     / qTarget
///     integral1Incremented      e        |    + h / 2
///   '---------------------- := ------- * |  e         k(w(h)) dh'.
///           2 ** 216              2      |
///                                       / qLower
///
/// @return proceed whether to proceed forward in the search for 'qTarget' and
/// 'qOvershoot'.
function moveOvershoot(
  X216 integral0Incremented,
  X216 integral1Incremented
) pure returns (
  bool proceed
) {
  // According to the above definitions for 'qBegin' and 'qOvershoot', if
  // 'direction != getZeroForOne() == false', we have:
  //
  //  'qOvershoot < qBegin <= qCurrent <= qForward0 <= qForward1',
  //
  // and if 'direction != getZeroForOne() == true', we have:
  //
  //  'qForward1 <= qForward0 <= qCurrent <= qBegin < qOvershoot'.
  //
  // In both cases, the 'if' condition is bypassed.
  //
  // However, if 'getDirection() == getZeroForOne() == false', we have:
  //
  //  'qForward0 <= qBegin <= qOvershoot <= qForward1'.
  //
  // In this case, if 'qOvershoot == qForward1' as illustrated below,
  //
  //      +---------+---------+
  //      |         |         |
  //  qForward0  qBegin   qForward1
  //                          |
  //                     qOvershoot
  //
  // then 'indexKernelForward' is incremented and the next piece of 'k(.)' is
  // loaded and stored in the memory spaces that are pointed to by '_forward0_'
  // and '_forward1_':
  //
  //      +---------+---------+-------------------+
  //                |         |                   |
  //             qBegin   qForward0           qForward1
  //                          |
  //                     qOvershoot
  //
  // If 'getDirection() == getZeroForOne() == true', then we have:
  //
  //  'qForward1 <= qOvershoot <= qBegin <= qForward0'.
  //
  // In this case, if 'qOvershoot == qForward1' as illustrated below,
  //
  //                          +---------+---------+
  //                          |         |         |
  //                      qForward1  qBegin   qForward0
  //                          |
  //                     qOvershoot
  //
  // then 'indexKernelForward' is incremented and the next piece of 'k(.)' is
  // loaded and stored in the memory spaces that are pointed to by '_forward0_'
  // and '_forward1_':
  //
  //      +-------------------+---------+---------+
  //      |                   |         |
  //  qForward1           qForward0  qBegin
  //                          |
  //                     qOvershoot
  //
  // Out of range values for 'indexKernelForward' are avoided because of an
  // input requirement here.
  if (_overshoot_.log() == _forward1_.log()) moveBreakpointForward();

  // According to the above definitions for 'qBegin' and 'qOvershoot', if
  // 'getDirection() == false', then we have:
  //
  //  'qTotal0 <= qBegin <= qOvershoot <= qTotal1'.
  //
  // In this case, if 'qOvershoot == qTotal1' as illustrated below,
  //
  //      +---------+---------+
  //      |         |         |
  //   qTotal0   qBegin    qTotal1
  //                          |
  //                     qOvershoot
  //
  // then 'indexKernelTotal' is incremented and the next piece of 'k(.)' is
  // loaded and stored in the memory spaces that are pointed to by '_total0_'
  // and '_total1_':
  //
  //      +---------+---------+-------------------+
  //                |         |                   |
  //             qBegin    qTotal0             qTotal1
  //                          |
  //                     qOvershoot
  //
  // If 'getDirection() == true', then we have:
  //
  //  'qTotal1 <= qOvershoot <= qBegin <= qTotal0'.
  //
  // In this case, if 'qOvershoot == qTotal1' as illustrated below,
  //
  //                          +---------+---------+
  //                          |         |         |
  //                       qTotal1   qBegin    qTotal0
  //                          |
  //                     qOvershoot
  //
  // then 'indexKernelTotal' is incremented and the next piece of 'k(.)' is
  // loaded and stored in the memory spaces that are pointed to by '_total0_'
  // and '_total1_':
  //
  //      +-------------------+---------+---------+
  //      |                   |         |
  //   qTotal1             qTotal0   qBegin
  //                          |
  //                     qOvershoot
  //
  // Out of range values for 'indexKernelTotal' are avoided because of an
  // input requirement here.
  if (_overshoot_.log() == _total1_.log()) moveBreakpointTotal();

  // The current direction is loaded from memory.
  bool direction = getDirection();

  // According to the above definitions for 'qBegin' and 'qOvershoot', if
  // 'getDirection() == false', then we have:
  //
  //  'q[indexCurve + 2] <= qBegin <= qOvershoot <= qEnd'.
  //
  // In this case, if 'qOvershoot == qEnd' as illustrated below,
  //
  //         w(q)
  //          ^
  //  spacing |                                              /
  //          |                                             /
  //          |                                            /
  //          |                                           /
  //          |                                          /
  //          |                                         /
  //          |                                        /
  //          |                                       /
  //          |                                      /
  //          |                                     /
  //          |                                    /
  //          |\
  //          | \
  //          |  \
  //          |   \
  //          |    \
  //          |     \
  //          |      \
  //          |       \
  //          |        \
  //          |         \
  //          |          \
  //          |                                  /
  //          |                                 /
  //          |                                /
  //          |                               /
  //          |                              /
  //          |                             /
  //          |                            /
  //          |                           /
  //          |                          /
  //          |                         /
  //          |                        /
  //          |            \
  //          |             \
  //          |              \
  //          |               \
  //          |                \
  //          |                 \
  //          |                  \
  //          |                   \
  //          |                    \
  //          |                     \
  //          |                      \
  //        0 +-----------+-----------+-----+-----+-----+-----+> q
  //                      |           |     |     |
  //                   qOrigin        |  qBegin  qEnd
  //                                  |           |
  //                                  |       qOvershoot
  //                                  |
  //                                  |
  //                                  |
  //                          q[indexCurve + 2]
  //
  // then 'indexCurve' is decremented, the direction is flipped and the next
  // phase of 'w(.)' is loaded by setting:
  //
  //  'qEnd := q[indexCurve]'
  //
  //  'qOrigin := q[indexCurve + 1]'
  //
  //  'qBegin := q[indexCurve + 2]'
  //
  // which is illustrated as follows:
  //
  //         w(q)
  //          ^
  //  spacing |                                              /
  //          |                                             /
  //          |                                            /
  //          |                                           /
  //          |                                          /
  //          |                                         /
  //          |                                        /
  //          |                                       /
  //          |                                      /
  //          |                                     /
  //          |                                    /
  //          |\
  //          | \
  //          |  \
  //          |   \
  //          |    \
  //          |     \
  //          |      \
  //          |       \
  //          |        \
  //          |         \
  //          |          \
  //          |                                  /
  //          |                                 /
  //          |                                /
  //          |                               /
  //          |                              /
  //          |                             /
  //          |                            /
  //          |                           /
  //          |                          /
  //          |                         /
  //          |                        /
  //          |            \
  //          |             \
  //          |              \
  //          |               \
  //          |                \
  //          |                 \
  //          |                  \
  //          |                   \
  //          |                    \
  //          |                     \
  //          |                      \
  //        0 +-----------+-----------+-----------+-----------+> q
  //          |           |                       |
  //        qEnd       qBegin                  qOrigin
  //                      |                       |
  //              q[indexCurve + 2]          qOvershoot
  //
  // If 'getDirection() == true', then we have:
  //
  //  'qEnd <= qOvershoot <= qBegin <= q[indexCurve + 2]'.
  //
  // and a similar argument can be made.
  if (_overshoot_.log() == _end_.log()) {
    // Once we move the phase, the direction flips and 'qOrigin' will be moved
    // to 'qEnd'. Hence, the following integral
    //
    //                             - 8
    //    originToOvershoot      e
    //  '------------------- == ------- * (
    //        2 ** 216             2
    //
    //     getZeroForOne() ? 
    //
    //       / qOrigin
    //      |    + h / 2
    //      |  e         k(qOrigin - h) dh :
    //      |
    //     / qEnd
    //
    //       / qEnd
    //      |    - h / 2
    //      |  e         k(h - qOrigin) dh
    //      |
    //     / qOrigin
    //
    //   )'
    //
    // should be transformed to
    //
    //                             - 8
    //    originToOvershoot      e
    //  '------------------- := ------- * (
    //        2 ** 216             2
    //
    //     getZeroForOne() ? 
    //
    //       / qOrigin
    //      |    - h / 2
    //      |  e         k(h - qEnd) dh :
    //      |
    //     / qEnd
    //
    //       / qEnd
    //      |    + h / 2
    //      |  e         k(qEnd - h) dh
    //      |
    //     / qOrigin
    //
    //   )'
    //
    // The loaded integral does not exceed 216-bits and hence, the input
    // requirement of shift is satisfied.
    _originToOvershoot_.setIntegral(
      _originToOvershoot_.integral().shift(_overshoot_, _origin_, direction)
    );

    // Underflow of 'indexCurve' is avoided externally via an input requirement
    // of the present function.
    direction = movePhase();
  }

  // If the phase is moved, then we have:
  //
  //  'qBegin == q[indexCurve + 2]'.
  //
  // If the phase is not moved, then the kernel piece is moved and we have:
  //
  //  'qBegin <= qOvershoot == qTotal0'.
  //
  // In both cases, we need to set:
  //
  //  'qBegin := direction ? min(qBegin, qTotal0) : max(qBegin, qTotal0)'
  //
  // which is equivalent to setting:
  //
  //  'qBegin := qTotal0'
  //
  // if and only if 'direction != (qBegin < qTotal0)'.
  //
  // Signed comparison is valid because as we argued before in this script,
  // both 'qBegin' and 'qTotal0' are greater than '0' and less than '32'. This
  // is due to the custom error 'BlankIntervalsShouldBeAvoided' ensures that
  // '16 + qLower' is greater than 'qSpacing' and '16 + qUpper' is smaller than
  // '32 - qSpacing'.
  if (direction != _begin_.log() < _total0_.log()) {
    _begin_.copyPrice(_total0_);
  }

  // Next, we need to set:
  //
  //  'qOvershoot := direction ? min(qEnd, qTotal1) : max(qEnd, qTotal1)'
  //
  // which is equivalent to setting:
  //
  //  'qOvershoot := qTotal1'
  //
  // if and only if 'direction == (qEnd < qTotal1)' and
  //
  //  'qOvershoot := qEnd'
  //
  // otherwise.
  //
  // Signed comparison is valid because as we argued before.
  _overshoot_.copyPrice(
    (direction == (_end_.log() < _total1_.log())) ? _total1_ : _end_
  );

  if (direction == getZeroForOne()) {
    // In this case, we need to set:
    //
    //  'qBegin := direction ? min(qBegin, qForward0) : max(qBegin, qForward0)'
    //
    // which is equivalent to setting:
    //
    //  'qBegin := qForward0'
    //
    // if and only if 'direction != (qBegin < qForward0)'.
    //
    // Signed comparison is valid because as we argued before.
    if (direction != (_begin_.log() < _forward0_.log())) {
      _begin_.copyPrice(_forward0_);
    }

    // Next, we need to set:
    //
    //  'qOvershoot := direction ? 
    //                 min(qOvershoot, qForward1) : 
    //                 max(qOvershoot, qForward1)'
    //
    // which is equivalent to setting:
    //
    //  'qOvershoot := qForward1'
    //
    // if and only if 'direction == (qOvershoot < qForward1)'.
    //
    // Signed comparison is valid because as we argued before.
    if (direction == (_overshoot_.log() < _forward1_.log())) {
      _overshoot_.copyPrice(_forward1_);
    }
  }

  // Next, if 'direction == getZeroForOne()', we increment the integrals:
  //
  //  - 'currentToOvershoot',
  //  - 'targetToOvershoot',
  //  - 'originToOvershoot'.
  //
  // Otherwise, we increment the integrals:
  //
  //  - 'currentToOrigin'
  //  - 'originToOvershoot'
  //
  // As argued before, if 'direction == false', then
  //
  //  'qTotal0 <= qBegin <= qOvershoot <= qTotal1'.
  //
  // and if 'direction == true', then
  //
  //  'qTotal1 <= qOvershoot <= qBegin <= qTotal0'.
  //
  // Additionally, since the vertical coordinates of kernel are monotonic,
  // we have 'cTotal0 <= cTotal1' and the input requirements of 'outgoing'
  // are satisfied.
  X216 outgoingTotal = _total0_.outgoing(_begin_, _overshoot_);
  if (direction == getZeroForOne()) {
    // As argued before, if 'direction == false', then
    //
    //  'qForward0 <= qBegin <= qOvershoot <= qForward1'.
    //
    // and if 'direction == true', then
    //
    //  'qForward1 <= qOvershoot <= qBegin <= qForward0'.
    //
    // Additionally, since the vertical coordinates of kernel are monotonic,
    // we have 'cForward0 <= cForward1' and the input requirements of
    // 'outgoing' are satisfied.
    X216 outgoingForward = _forward0_.outgoing(_begin_, _overshoot_);

    // Next, 'currentToOvershoot' is incremented with 'outgoingTotal'. Based on
    // the earlier argument in this script, overflow is not possible because
    // theoretically, no outgoing or incoming integral may exceed 216 bits.
    _currentToOvershoot_.incrementIntegral(outgoingTotal);

    // Next, 'targetToOvershoot' is incremented with 'outgoingForward'. Based
    // on the earlier argument in this script, overflow is not possible because
    // theoretically, no outgoing or incoming integral may exceed 216 bits.
    _targetToOvershoot_.incrementIntegral(outgoingForward);

    // Next, 'originToOvershoot' is incremented with 'outgoingTotal'. Based on
    // the earlier argument in this script, overflow is not possible because
    // theoretically, no outgoing or incoming integral may exceed 216 bits.
    _originToOvershoot_.incrementIntegral(outgoingTotal);

    // If 'f(qOvershoot) > 0', then we project all of the integrals back to
    // their original values (prior to calling this function) and return
    // 'false'. The numerical search for overshoot will then start from
    // 'qBegin'.
    if (getMismatch(integral0Incremented, integral1Incremented) > zeroX216) {
      _end_.copyPrice(_overshoot_);
      _currentToOvershoot_.decrementIntegral(outgoingTotal);
      _targetToOvershoot_.decrementIntegral(outgoingForward);
      _originToOvershoot_.decrementIntegral(outgoingTotal);
      _overshoot_.copyPrice(_begin_);
      return false;
    }
  } else {
    // Next, 'currentToOrigin' is incremented with 'outgoingTotal'. Based on
    // the earlier argument in this script, overflow is not possible because
    // theoretically, no outgoing or incoming integral may exceed 216 bits.
    _currentToOrigin_.incrementIntegral(outgoingTotal);

    // Next, 'originToOvershoot' is incremented with 'outgoingTotal'. Based on
    // the earlier argument in this script, overflow is not possible because
    // theoretically, no outgoing or incoming integral may exceed 216 bits.
    _originToOvershoot_.incrementIntegral(outgoingTotal);
  }
  return true;
}

/// @notice Assume that the search for 'qTarget' is concluded and we need to
/// determine 'qOvershoot'. To this end, the following equation should be
/// solved:
///
///   'f(qOvershoot) == 0'
///
/// where
///
///   'f(qOvershoot) := getZeroForOne() ? 
///                     s0(qOvershoot) - s1(qOvershoot) : 
///                     s1(qOvershoot) - s0(qOvershoot)',
///
/// and the two functions 's0' and 's1' are defined as:
///
///                          - 8      / qTarget
///                        e         |   + h / 2
///                       ------- *  |  e        k(wAmended(h)) dh
///                          2       |
///                                 / qLower
///   's1(qOvershoot) := ------------------------------------------',
///                                integral1Incremented
///
///                          - 8      / qUpper
///                        e         |   - h / 2
///                       ------- *  |  e        k(wAmended(h)) dh
///                          2       |
///                                 / qTarget
///   's0(qOvershoot) := ------------------------------------------',
///                                integral0Incremented
///
/// where, according to the amendment procedure which is described in
/// 'Curve.sol', if 'getZeroForOne() == false', we have:
///
///                       / k(w(h))            if  qOvershoot < h < qUpper
///   'k(wAmended(h)) == |  k(h - qTarget)     if  qTarget < h < qOvershoot '
///                      |  k(qOvershoot - h)  if  qOrigin < h < qTarget
///                       \ k(w(h))            if  qLower < h < qOrigin
///
/// and if 'getZeroForOne() == true', we have:
///
///                       / k(w(h))            if  qLower < h < qOvershoot
///   'k(wAmended(h)) == |  k(qTarget - h)     if  qOvershoot < h < qTarget '.
///                      |  k(h - qOvershoot)  if  qTarget < h < qOrigin
///                       \ k(w(h))            if  qOrigin < h < qUpper
///
/// The present function evaluates the Newton step:
///
///                    f(qOvershoot)
///   'qStep = ------------------------------'.
///                   d
///             -------------- f(qOvershoot)
///              d qOvershoot
///
/// To this end, we use the following formula for 'f(qOvershoot)' which is
/// proven in 'Memory.sol':
///
///   'f(qOvershoot) := getZeroForOne() ? (
///
///          integral0Amended         integral1Amended
///       ---------------------- - ----------------------
///        integral0Incremented     integral1Incremented
///
///    ) : (
///
///          integral1Amended         integral0Amended
///       ---------------------- - ----------------------
///        integral1Incremented     integral0Incremented
///
///    )',
///
/// where
///
///   'integral0Amended := getZeroForOne() ? (
///
///       exp(- (qOrigin + qOvershoot) / 2) * originToOvershoot -
///
///       exp(- (qTarget + qOvershoot) / 2) * targetToOvershoot - 
///
///       integral0Incremented + incomingCurrentToTarget - currentToOrigin
///
///    ) : (
///
///       integral0Incremented + targetToOvershoot + 
///
///       currentToTarget - currentToOvershoot
///
///    )',
///
/// and
///
///   'integral1Amended := getZeroForOne() ? (
///
///       integral1Incremented + targetToOvershoot + 
///
///       currentToTarget - currentToOvershoot
///
///    ) : (
///
///       exp(+ (qOrigin + qOvershoot) / 2) * originToOvershoot -
///
///       exp(+ (qTarget + qOvershoot) / 2) * targetToOvershoot - 
///
///       integral1Incremented + incomingCurrentToTarget - currentToOrigin
///
///    )'.
///
/// In addition the following formula is used to compute the derivative:
///
///          d f
///   '-------------- == getZeroForOne() ? (
///     d qOvershoot
///
///      (
///
///           - 8 + qOvershoot / 2
///         e
///        ------------------------ * k(qTarget - qOvershoot) - 
///                    2
///
///           - 8 + qOvershoot / 2
///         e
///        ------------------------ * k(qOrigin - qOvershoot) 
///                    2
///
///      ) / integral1Incremented - (
///
///          - (qOrigin + qOvershoot) / 2    originToOvershoot
///        e                              * ------------------- -
///                                                  2
///
///          - (qTarget + qOvershoot) / 2    targetToOvershoot
///        e                              * ------------------- +
///                                                  2
///           - 8 - qOrigin / 2
///         e
///        --------------------- * k(qOrigin - qOvershoot) - 
///                  2
///
///           - 8 - qTarget / 2
///         e
///        --------------------- * k(qTarget - qOvershoot)
///                  2
///
///      ) / integral0Incremented
///
///    ) : (
///
///      (
///
///          + (qOrigin + qOvershoot) / 2    originToOvershoot
///        e                              * ------------------- -
///                                                  2
///
///          + (qTarget + qOvershoot) / 2    targetToOvershoot
///        e                              * ------------------- +
///                                                  2
///           - 8 + qOrigin / 2
///         e
///        --------------------- * k(qOvershoot - qOrigin) -
///                  2
///
///           - 8 + qTarget / 2
///         e
///        --------------------- * k(qOvershoot - qTarget)
///                  2
///
///      ) / integral1Incremented - (
///
///           - 8 - qOvershoot / 2
///         e
///        ------------------------ * k(qOvershoot - qTarget) - 
///                    2
///
///           - 8 - qOvershoot / 2
///         e
///        ------------------------ * k(qOvershoot - qOrigin) 
///                    2
///
///      ) / integral0Incremented
///
///    )'.
///
/// @param integral0Incremented The integral of the liquidity distribution
/// function from 'qTarget' to 'qUpper' prior to the amendment of the curve
/// sequence:
///
///                                 - 8     / qUpper
///     integral0Incremented      e        |    - h / 2
///   '---------------------- := ------- * |  e         k(w(h)) dh',
///           2 ** 216              2      |
///                                       / qTarget
///
/// @param integral1Incremented The integral of the liquidity distribution
/// function from 'qLower' to 'qTarget' prior to the amendment of the curve
/// sequence:
///
///                                 - 8     / qTarget
///     integral1Incremented      e        |    + h / 2
///   '---------------------- := ------- * |  e         k(w(h)) dh'.
///           2 ** 216              2      |
///                                       / qLower
///
/// @return sign The sign of Newton step.
/// @return step Newton step to be added to/subtracted from the current value
/// of 'qOvershoot'.
/// @return integral0Amended The integral of the liquidity distribution function
/// from 'qTarget' to 'qUpper' after the amendment of the curve sequence:
///
///                             - 8     / qUpper
///     integral0Amended      e        |    - h / 2
///   '------------------ := ------- * |  e         k(wAmended(h)) dh'.
///         2 ** 216            2      |
///                                   / qTarget
///
/// @return integral1Amended The integral of the liquidity distribution function
/// from 'qLower' to 'qTarget' after the amendment of the curve sequence:
///
///                             - 8     / qTarget
///     integral1Amended      e        |    + h / 2
///   '------------------ := ------- * |  e         k(wAmended(h)) dh'.
///         2 ** 216            2      |
///                                   / qLower
///
function newtonStep(
  X216 integral0Incremented,
  X216 integral1Incremented
) pure returns (
  bool sign,
  X59 step,
  X216 integral0Amended,
  X216 integral1Amended
) {
  bool zeroForOne = getZeroForOne();
  (integral0Incremented, integral1Incremented) = zeroForOne ? 
    (integral1Incremented, integral0Incremented) : 
    (integral0Incremented, integral1Incremented);

  X216 originToTarget;
  {
    // At this stage, we have:
    //
    //  'currentToOvershoot := _currentToOvershoot_.integral() + outgoingTotal'
    //
    // and
    //
    //  'originToOvershoot := _originToOvershoot_.integral() + outgoingTotal'
    //
    // where
    //
    //                         - 8
    //    outgoingTotal      e
    //  '--------------- := ------- * (
    //      2 ** 216           2
    //
    //     getZeroForOne() ? 
    //
    //       / qBegin
    //      |    + h / 2
    //      |  e         k(w(h)) dh :
    //      |
    //     / qOvershoot
    //
    //       / qOvershoot
    //      |    - h / 2
    //      |  e         k(w(h)) dh
    //      |
    //     / qBegin
    //
    //   )'.
    //
    // As argued before, if 'direction == false', then
    //
    //  'qTotal0 <= qBegin <= qOvershoot <= qTotal1'.
    //
    // and if 'direction == true', then
    //
    //  'qTotal1 <= qOvershoot <= qBegin <= qTotal0'.
    //
    // Additionally, since the vertical coordinates of kernel are monotonic,
    // we have 'cTotal0 <= cTotal1' and the input requirements of 'outgoing'
    // are satisfied.
    X216 outgoingTotal = _total0_.outgoing(_begin_, _overshoot_);

    // At this stage, we have:
    //
    //  'targetToOvershoot := _targetToOvershoot_.integral() + outgoingForward'
    //
    // where
    //                           - 8
    //    outgoingForward      e
    //  '----------------- := ------- * (
    //       2 ** 216            2
    //
    //     getZeroForOne() ? 
    //
    //       / qBegin
    //      |    + h / 2
    //      |  e         k(qTarget - h) dh :
    //      |
    //     / qOvershoot
    //
    //       / qOvershoot
    //      |    - h / 2
    //      |  e         k(h - qTarget) dh
    //      |
    //     / qBegin
    //
    //   )'.
    //
    // As argued before, if 'direction == false', then
    //
    //  'qForward0 <= qBegin <= qOvershoot <= qForward1'.
    //
    // and if 'direction == true', then
    //
    //  'qForward1 <= qOvershoot <= qBegin <= qForward0'.
    //
    // Additionally, since the vertical coordinates of kernel are monotonic,
    // we have 'cForward0 <= cForward1' and the input requirements of
    // 'outgoing' are satisfied.
    X216 outgoingForward = _forward0_.outgoing(_begin_, _overshoot_);

    // Next, we calculate:
    //
    //  'getZeroForOne() ? integral1Amended : integral0Amended'.
    //
    // The operations are theoretically safe. However, the output may be negative
    // due to rounding error.
    integral0Amended = integral0Incremented
      + _currentToTarget_.integral()
      - (_currentToOvershoot_.integral() + outgoingTotal)
      + (_targetToOvershoot_.integral() + outgoingForward);

    // The output is capped to prevent negative values due to rounding error.
    integral0Amended = max(integral0Amended, zeroX216);

    // Define, 'originToTarget' as:
    //
    //   'getZeroForOne() ? (
    //
    //       exp(- (qOrigin + qOvershoot) / 2) * originToOvershoot -
    //
    //       exp(- (qTarget + qOvershoot) / 2) * targetToOvershoot
    //
    //    ) : (
    //
    //       exp(+ (qOrigin + qOvershoot) / 2) * originToOvershoot -
    //
    //       exp(+ (qTarget + qOvershoot) / 2) * targetToOvershoot
    //
    //    )'
    //
    originToTarget = (
      _originToOvershoot_.integral() + outgoingTotal
    ).shift(
      _overshoot_,
      _origin_,
      zeroForOne
    ) - (
      _targetToOvershoot_.integral() + outgoingForward
    ).shift(
      _overshoot_,
      _target_,
      zeroForOne
    );
  }

  // Next, we calculate:
  //
  //   'integral1Amended := getZeroForOne() ? (
  //
  //       exp(- (qOrigin + qOvershoot) / 2) * originToOvershoot -
  //
  //       exp(- (qTarget + qOvershoot) / 2) * targetToOvershoot - 
  //
  //       integral0Incremented + incomingCurrentToTarget - currentToOrigin
  //
  //    ) : (
  //
  //       exp(+ (qOrigin + qOvershoot) / 2) * originToOvershoot -
  //
  //       exp(+ (qTarget + qOvershoot) / 2) * targetToOvershoot - 
  //
  //       integral1Incremented + incomingCurrentToTarget - currentToOrigin
  //
  //    )',
  //
  // The operations are theoretically safe. However, the output may be negative
  // due to rounding error.
  integral1Amended = integral1Incremented
    + originToTarget
    - _currentToOrigin_.integral()
    - _incomingCurrentToTarget_.integral();

  // The output is capped to prevent negative values due to rounding error.
  integral1Amended = max(integral1Amended, zeroX216);

  // Next, we calculate:
  //
  //      - 8
  //    e
  //  '------- * k(|qOrigin - qOvershoot|)'.
  //      2
  //
  // As argued before, if 'direction == false', then
  //
  //  'qTotal0 <= qOvershoot <= qTotal1'.
  //
  // and if 'direction == true', then
  //
  //  'qTotal1 <= qOvershoot <= qTotal0'.
  //
  // Additionally, since the vertical coordinates of kernel are monotonic,
  // we have 'cTotal0 <= cTotal1' and the input requirements of 'outgoing'
  // are satisfied.
  X216 overshootMinusOrigin = _total0_.evaluate(_overshoot_);

  // Then:
  //
  //      - 8
  //    e
  //  '------- * k(|qTarget - qOvershoot|)'.
  //      2
  //
  // As argued before, if 'direction == false', then
  //
  //  'qForward0 <= qOvershoot <= qForward1'.
  //
  // and if 'direction == true', then
  //
  //  'qForward1 <= qOvershoot <= qForward0'.
  //
  // Additionally, since the vertical coordinates of kernel are monotonic,
  // we have 'cForward0 <= cForward1' and the input requirements of
  // 'outgoing' are satisfied.
  X216 overshootMinusTarget = _forward0_.evaluate(_overshoot_);

  //  'getZeroForOne() ? (
  //
  //         - 8 - qOrigin / 2
  //       e
  //      --------------------- * k(qOrigin - qOvershoot) - 
  //                2
  //
  //         - 8 - qTarget / 2
  //       e
  //      --------------------- * k(qTarget - qOvershoot)
  //                2
  //
  //   ) : (
  //
  //         - 8 + qOrigin / 2
  //       e
  //      --------------------- * k(qOvershoot - qOrigin) -
  //                2
  //
  //         - 8 + qTarget / 2
  //       e
  //      --------------------- * k(qOvershoot - qTarget)
  //                2
  //
  //   )'.
  //
  // The requirements 'mulDivByExpInv8' are satisfied because:
  //
  //  'zeroX216 <= _origin_.sqrt(!zeroForOne) < oneX216',
  //  'zeroX216 <= _target_.sqrt(!zeroForOne) < oneX216'.
  //
  X216 integral1AmendedPrime = 
    _origin_.sqrt(!zeroForOne) % overshootMinusOrigin  - 
    _target_.sqrt(!zeroForOne) % overshootMinusTarget;

  //  'getZeroForOne() ? (
  //
  //      exp(- (qOrigin + qOvershoot) / 2) * originToOvershoot -
  //
  //      exp(- (qTarget + qOvershoot) / 2) * targetToOvershoot +
  //
  //        - 8 - qOrigin / 2
  //      e                   * k(qOrigin - qOvershoot) - 
  //
  //        - 8 - qTarget / 2
  //      e                   * k(qTarget - qOvershoot)
  //
  //   ) : (
  //
  //      exp(+ (qOrigin + qOvershoot) / 2) * originToOvershoot -
  //
  //      exp(+ (qTarget + qOvershoot) / 2) * targetToOvershoot +
  //
  //        - 8 + qOrigin / 2
  //      e                   * k(qOvershoot - qOrigin) -
  //
  //        - 8 + qTarget / 2
  //      e                   * k(qOvershoot - qTarget)
  //
  //   )'.
  integral1AmendedPrime = 
    originToTarget + integral1AmendedPrime + integral1AmendedPrime;

  //   'getZeroForOne() ? (
  //
  //           - 8 + qOvershoot / 2
  //         e                      * k(qTarget - qOvershoot) - 
  //
  //           - 8 + qOvershoot / 2
  //         e                      * k(qOrigin - qOvershoot) 
  //
  //    ) : (
  //
  //           - 8 - qOvershoot / 2
  //         e                      * k(qOvershoot - qTarget) - 
  //
  //           - 8 - qOvershoot / 2
  //         e                      * k(qOvershoot - qOrigin) 
  //
  //    )'.
  X216 integral0AmendedPrime = _overshoot_.sqrt(zeroForOne) % (
    overshootMinusOrigin - overshootMinusTarget
  );
  integral0AmendedPrime = integral0AmendedPrime + integral0AmendedPrime;

  // 'f(qOvershoot)' is calculated next. The result may or may not be negative.
  // The requirements of cheapMul are satisfied because all four integrals are
  // non-negative and less than 'oneX216'.
  X216 mismatch;
  (mismatch, integral0Amended, integral1Amended) = zeroForOne ? (
    (
      integral0Incremented & integral1Amended
    ) - (
      integral1Incremented & integral0Amended
    ),
    integral1Amended,
    integral0Amended
  ) : (
    (
      integral1Incremented & integral0Amended
    ) - (
      integral0Incremented & integral1Amended
    ),
    integral0Amended,
    integral1Amended
  );

  // Next, the derivative of 'f' with respect to 'qOvershoot' is calculated.
  // Multiplications do not overflow because both integrals are non-negative
  // and less than 'oneX216'. Additionally, 'integral0AmendedPrime' and
  // 'integral1AmendedPrime' are composed of up to 4 integrals and their
  // absolute value does not exceed '2 ** 218'.
  X216 mismatchPrime = (
    integral0Incremented * integral1AmendedPrime
  ) + (
    integral1Incremented * integral0AmendedPrime
  );

  // Sign of the Newton step is determined.
  sign = (mismatch > zeroX216) != (mismatchPrime > zeroX216);

  // The Newton step is calculated next.
  // Multiplication does not overflow because '-oneX216 <= mismatch <= oneX216'
  // Division by zero results on 'step == zeroX59'.
  assembly {
    step := sdiv(mul(shl(38, 1), mismatch), sar(22, mismatchPrime))
  }

  if (step == zeroX59) {
    assembly {
      mismatchPrime := sar(22, mismatchPrime)
    }
    if (mismatch != zeroX216) {
      require(mismatchPrime != zeroX216, SearchingForOvershootFailed());
    }
  }
}

/// @notice Calculates 'integral0Amended' and 'integral1Amended' efficiently.
///
/// @param integral0Incremented The integral of the liquidity distribution
/// function from 'qTarget' to 'qUpper' prior to the amendment of the curve
/// sequence:
///
///                                 - 8     / qUpper
///     integral0Incremented      e        |    - h / 2
///   '---------------------- := ------- * |  e         k(w(h)) dh',
///           2 ** 216              2      |
///                                       / qTarget
///
/// @param integral1Incremented The integral of the liquidity distribution
/// function from 'qLower' to 'qTarget' prior to the amendment of the curve
/// sequence:
///
///                                 - 8     / qTarget
///     integral1Incremented      e        |    + h / 2
///   '---------------------- := ------- * |  e         k(w(h)) dh'.
///           2 ** 216              2      |
///                                       / qLower
///
/// @return integral0Amended The integral of the liquidity distribution function
/// from 'qTarget' to 'qUpper' after the amendment of the curve sequence:
///
///                             - 8     / qUpper
///     integral0Amended      e        |    - h / 2
///   '------------------ := ------- * |  e         k(wAmended(h)) dh'.
///         2 ** 216            2      |
///                                   / qTarget
///
/// @return integral1Amended The integral of the liquidity distribution function
/// from 'qLower' to 'qTarget' after the amendment of the curve sequence:
///
///                             - 8     / qTarget
///     integral1Amended      e        |    + h / 2
///   '------------------ := ------- * |  e         k(wAmended(h)) dh'.
///         2 ** 216            2      |
///                                   / qLower
///
function newIntegrals(
  X216 integral0Incremented,
  X216 integral1Incremented
) pure returns (
  X216 integral0Amended,
  X216 integral1Amended
) {
  bool zeroForOne = getZeroForOne();
  (integral0Incremented, integral1Incremented) = zeroForOne ? 
    (integral1Incremented, integral0Incremented) : 
    (integral0Incremented, integral1Incremented);

  // At this stage, we have:
  //
  //  'currentToOvershoot := _currentToOvershoot_.integral() + outgoingTotal'
  //
  // and
  //
  //  'originToOvershoot := _originToOvershoot_.integral() + outgoingTotal'
  //
  // where
  //
  //                         - 8
  //    outgoingTotal      e
  //  '--------------- := ------- * (
  //      2 ** 216           2
  //
  //     getZeroForOne() ? 
  //
  //       / qBegin
  //      |    + h / 2
  //      |  e         k(w(h)) dh :
  //      |
  //     / qOvershoot
  //
  //       / qOvershoot
  //      |    - h / 2
  //      |  e         k(w(h)) dh
  //      |
  //     / qBegin
  //
  //   )'.
  //
  // As argued before, if 'direction == false', then
  //
  //  'qTotal0 <= qBegin <= qOvershoot <= qTotal1'.
  //
  // and if 'direction == true', then
  //
  //  'qTotal1 <= qOvershoot <= qBegin <= qTotal0'.
  //
  // Additionally, since the vertical coordinates of kernel are monotonic,
  // we have 'cTotal0 <= cTotal1' and the input requirements of 'outgoing'
  // are satisfied.
  X216 outgoingTotal = _total0_.outgoing(_begin_, _overshoot_);

  // At this stage, we have:
  //
  //  'targetToOvershoot := _targetToOvershoot_.integral() + outgoingForward'
  //
  // where
  //                           - 8
  //    outgoingForward      e
  //  '----------------- := ------- * (
  //       2 ** 216            2
  //
  //     getZeroForOne() ? 
  //
  //       / qBegin
  //      |    + h / 2
  //      |  e         k(qTarget - h) dh :
  //      |
  //     / qOvershoot
  //
  //       / qOvershoot
  //      |    - h / 2
  //      |  e         k(h - qTarget) dh
  //      |
  //     / qBegin
  //
  //   )'.
  //
  // As argued before, if 'direction == false', then
  //
  //  'qForward0 <= qBegin <= qOvershoot <= qForward1'.
  //
  // and if 'direction == true', then
  //
  //  'qForward1 <= qOvershoot <= qBegin <= qForward0'.
  //
  // Additionally, since the vertical coordinates of kernel are monotonic,
  // we have 'cForward0 <= cForward1' and the input requirements of
  // 'outgoing' are satisfied.
  X216 outgoingForward = _forward0_.outgoing(_begin_, _overshoot_);

  // Define, 'originToTarget' as:
  //
  //   'getZeroForOne() ? (
  //
  //       exp(- (qOrigin + qOvershoot) / 2) * originToOvershoot -
  //
  //       exp(- (qTarget + qOvershoot) / 2) * targetToOvershoot
  //
  //    ) : (
  //
  //       exp(+ (qOrigin + qOvershoot) / 2) * originToOvershoot -
  //
  //       exp(+ (qTarget + qOvershoot) / 2) * targetToOvershoot
  //
  //    )'
  //
  X216 originToTarget = (_originToOvershoot_.integral() + outgoingTotal).shift(
    _overshoot_,
    _origin_,
    zeroForOne
  ) - (_targetToOvershoot_.integral() + outgoingForward).shift(
    _overshoot_,
    _target_,
    zeroForOne
  );

  // Next, we calculate:
  //
  //  'getZeroForOne() ? integral1Amended : integral0Amended'.
  //
  // The operations are theoretically safe. However, the output may be negative
  // due to rounding error.
  integral0Amended = integral0Incremented
    + _currentToTarget_.integral()
    - (_currentToOvershoot_.integral() + outgoingTotal)
    + (_targetToOvershoot_.integral() + outgoingForward);

  // The output is capped to prevent negative values due to rounding error.
  integral0Amended = max(integral0Amended, zeroX216);

  // Next, we calculate:
  //
  //   'integral1Amended := getZeroForOne() ? (
  //
  //       exp(- (qOrigin + qOvershoot) / 2) * originToOvershoot -
  //
  //       exp(- (qTarget + qOvershoot) / 2) * targetToOvershoot - 
  //
  //       integral0Incremented + incomingCurrentToTarget - currentToOrigin
  //
  //    ) : (
  //
  //       exp(+ (qOrigin + qOvershoot) / 2) * originToOvershoot -
  //
  //       exp(+ (qTarget + qOvershoot) / 2) * targetToOvershoot - 
  //
  //       integral1Incremented + incomingCurrentToTarget - currentToOrigin
  //
  //    )',
  //
  // The operations are theoretically safe. However, the output may be negative
  // due to rounding error.
  integral1Amended = integral1Incremented
    + originToTarget
    - _currentToOrigin_.integral()
    - _incomingCurrentToTarget_.integral();

  // The output is capped to prevent negative values due to rounding error.
  integral1Amended = max(integral1Amended, zeroX216);

  // The amended integrals are set depending on the direction.
  (integral0Amended, integral1Amended) = zeroForOne ? 
    (integral1Amended, integral0Amended) : 
    (integral0Amended, integral1Amended);
}

/// @notice Performs Newton search to find the optimal mismatch value.
/// For each swap, the protocol moves the current price to an 'overshoot' price
/// and then projects it back to the 'target' price. The 'overshoot' value
/// is determined using newton search in such a way that the total liquidity
/// growth is maximized. Notice that the incoming and outgoing values are
/// already determined and this process is only concerned with curve update.
///
/// @param integral0Incremented The integral of the liquidity distribution
/// function from 'qTarget' to 'qUpper' prior to the amendment of the curve
/// sequence:
///
///                                 - 8     / qUpper
///     integral0Incremented      e        |    - h / 2
///   '---------------------- := ------- * |  e         k(w(h)) dh',
///           2 ** 216              2      |
///                                       / qTarget
///
/// @param integral1Incremented The integral of the liquidity distribution
/// function from 'qLower' to 'qTarget' prior to the amendment of the curve
/// sequence:
///
///                                 - 8     / qTarget
///     integral1Incremented      e        |    + h / 2
///   '---------------------- := ------- * |  e         k(w(h)) dh'.
///           2 ** 216              2      |
///                                       / qLower
///
/// @return integral0Amended The integral of the liquidity distribution function
/// from 'qTarget' to 'qUpper' after the amendment of the curve sequence:
///
///                             - 8     / qUpper
///     integral0Amended      e        |    - h / 2
///   '------------------ := ------- * |  e         k(wAmended(h)) dh'.
///         2 ** 216            2      |
///                                   / qTarget
///
/// @return integral1Amended The integral of the liquidity distribution function
/// from 'qLower' to 'qTarget' after the amendment of the curve sequence:
///
///                             - 8     / qTarget
///     integral1Amended      e        |    + h / 2
///   '------------------ := ------- * |  e         k(wAmended(h)) dh'.
///         2 ** 216            2      |
///                                   / qLower
///
function searchOvershoot(
  X216 integral0Incremented,
  X216 integral1Incremented
) pure returns (
  X216 integral0Amended,
  X216 integral1Amended
) {
  bool zeroForOne = getZeroForOne();

  // Newton search is performed here:
  X59 step;
  bool sign;
  while (true) {
    (sign, step, integral0Amended, integral1Amended) = newtonStep(
      integral0Incremented,
      integral1Incremented
    );
    if (step == zeroX59) break;
    // The addition is safe because overshoot remains within the interval.
    _overshoot_.storePrice(
      zeroForOne ? 
      min(max(_end_.log(), _overshoot_.log() + step), _begin_.log()) :
      min(max(_begin_.log(), _overshoot_.log() + step), _end_.log())
    );
  }

  // We intend to maximize marginal growth which is equal to:
  //
  //        integral0Incremented     integral1Incremented
  //  'min(---------------------- , ----------------------)'
  //          integral0Amended         integral1Amended
  //
  // Given that 'integral0Incremented' and 'integral1Incremented' are constant,
  // this is equivalent to minimizing the following.
  //
  // Both multiplications are safe because all four integrals do not exceed
  // 'oneX216'.
  X216 growthInverse = max(
    integral0Incremented & integral1Amended,
    integral1Incremented & integral0Amended
  );

  // Next, we move overshoot one step forward or backward to make sure that it
  // is perfectly optimized.

  // If we are not at the end of the search interval and sign is aligned with
  // zeroForOne, then overshoot is moved one step forward.
  bool forward = (_overshoot_.log() != _end_.log()) && (sign == zeroForOne);

  // If we are not at the beginning of the search interval and sign is not 
  // aligned with zeroForOne, then overshoot is moved one step backward.
  bool backward = (_overshoot_.log() != _begin_.log()) && (sign != zeroForOne);

  // If either forward or backward are true we move the overshoot.
  if (forward || backward) {
    // Backing up 'integral0Amended' and 'integral1Amended'.
    X216 _integral0Amended = integral0Amended;
    X216 _integral1Amended = integral1Amended;
    _end_.copyPrice(_overshoot_); // Backing up 'overshoot'.

    // Moving one step forward or backward.
    // This is safe due to the prior 'if'.
    // Notice that 'forward' and 'backward' are mutually exclusive.
    moveOvershootByEpsilon(forward == zeroForOne);
    (integral0Amended, integral1Amended) = newIntegrals(
      integral0Incremented,
      integral1Incremented
    );

    // Both multiplications are safe because all four integrals do not exceed
    // 'oneX216'.
    X216 _growthInverse = max(
      integral0Incremented & integral1Amended,
      integral1Incremented & integral0Amended
    );

    if (_growthInverse >= growthInverse) {
      _overshoot_.copyPrice(_end_); // Moving forward.
      integral0Amended = _integral0Amended; // Moving forward.
      integral1Amended = _integral1Amended; // Moving forward.
    }
  }

  // Amended integrals should never be greater than the original ones.
  integral0Amended = min(integral0Incremented, integral0Amended);
  integral1Amended = min(integral1Incremented, integral1Amended);
}

/// @notice Clears this interval from memory so that a second 'swapWithin' can
/// be called.
function clearInterval() pure {
  assembly {
    //
    //  _interval_                               _endOfInterval_
    //      |                                           |
    //      +-------------------------------------------+
    //      |                     0                     |
    //      +-------------------------------------------+
    //
    codecopy(
      _interval_,
      sub(0, sub(_endOfInterval_, _interval_)),
      sub(_endOfInterval_, _interval_)
    )
  }
}