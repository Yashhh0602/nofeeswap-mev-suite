// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Curve.sol";
import {X216} from "../utilities/X216.sol";
import {
  getLogPriceCurrent
} from "../utilities/Memory.sol";

/// @title This contract exposes the internal functions of 'Curve.sol' for 
/// testing purposes.
contract CurveWrapper {
  using PriceLibrary for uint16;

  function _member(
    Curve curve,
    uint256[] calldata curveArray
  ) public returns (
    X59[] memory result
  ) {
    assembly {
      let curveArrayStart := calldataload(36)
      let curveArrayLength := calldataload(add(4, curveArrayStart))
      let curveArrayByteCount := shl(5, curveArrayLength)

      calldatacopy(
        curve,
        add(36, curveArrayStart),
        curveArrayByteCount
      )

      result := add(curve, curveArrayByteCount)
      mstore(result, shl(2, curveArrayLength))
    }

    for (uint256 kk = 0; kk < result.length; ++kk) {
      result[kk] = curve.member(Index.wrap(kk));
    }
  }

  function _boundaries(
    Curve curve,
    uint256[] calldata curveArray
  ) public returns (
    X59 qLower,
    X59 qUpper
  ) {
    assembly {
      let curveArrayStart := calldataload(36)
      let curveArrayLength := calldataload(add(4, curveArrayStart))
      let curveArrayByteCount := shl(5, curveArrayLength)

      calldatacopy(
        curve,
        add(36, curveArrayStart),
        curveArrayByteCount
      )
    }

    (qLower, qUpper) = curve.boundaries();
  }

  function _validate(
    Curve curve,
    uint256[] calldata curveArray
  ) public returns (
    X59 qLower,
    X59 qUpper,
    X59 qCurrent,
    X59 qSpacing,
    X216 sqrtSpacing,
    X216 sqrtInverseSpacing,
    Index curveLength
  ) {
    assembly {
      let curveArrayStart := calldataload(36)
      let curveArrayLength := calldataload(add(4, curveArrayStart))
      let curveArrayByteCount := shl(5, curveArrayLength)

      calldatacopy(
        curve,
        add(36, curveArrayStart),
        curveArrayByteCount
      )
    }

    (qLower, qUpper) = curve.validate();
    qCurrent = getLogPriceCurrent();
    qSpacing = _spacing_.log();
    sqrtSpacing = _spacing_.sqrt(false);
    sqrtInverseSpacing = _spacing_.sqrt(true);
    curveLength = getCurveLength();
  }

  function _newCurve(
    Curve curve,
    X59 qCurrent,
    X59 qOther
  ) public returns (
    X59 _qCurrent,
    X59 _qOther,
    Index curveLength
  ) {
    curve.newCurve(qCurrent, qOther);
    return (
      curve.member(oneIndex),
      curve.member(zeroIndex),
      getCurveLength()
    );
  }

  function _amend(
    Curve curve,
    Index curveLength,
    X59 target,
    uint256[] calldata curveArray
  ) public returns (
    Index curveLengthAmended
  ) {
    assembly {
      let curveArrayStart := calldataload(100)
      let curveArrayLength := calldataload(add(4, curveArrayStart))
      let curveArrayByteCount := shl(5, curveArrayLength)

      calldatacopy(
        curve,
        add(36, curveArrayStart),
        curveArrayByteCount
      )
    }

    setCurveLength(curveLength);
    curve.amend(target);
    curveLengthAmended = getCurveLength();

    assembly {
      let length := div(curveLengthAmended, 4)
      if gt(mod(curveLengthAmended, 4), 0) {
        length := add(length, 1)
      }
      log1(curve, mul(32, length), 0)
    }
  }
}