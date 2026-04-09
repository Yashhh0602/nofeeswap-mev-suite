// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Interval.sol";
import {twoIndex} from "../utilities/Index.sol";
import {
  setZeroForOne,
  setKernel,
  setKernelLength,
  setLogPriceCurrent,
  getIndexCurve,
  getOutgoingMax,
  getIncomingMax,
  getOutgoingMaxModularInverse,
  getIntegral0,
  getIntegral1,
  _indexKernelTotal_,
  _indexKernelForward_,
  _current_,
  _origin_,
  _begin_,
  _end_,
  _target_,
  _total0_,
  _total1_,
  _forward0_,
  _forward1_,
  _endOfStaticParams_,
  _endOfInterval_
} from "../utilities/Memory.sol";

/// @title This contract exposes the internal functions of 'Interval.sol' for 
/// testing purposes.
contract IntervalWrapper {
  using PriceLibrary for uint16;
  using PriceLibrary for uint256;
  using IndexLibrary for uint16;
  using IntegralLibrary for uint16;
  using IntegralLibrary for X216;

  function _initiateInterval(
    Curve curve,
    Index curveLength,
    X59 qLimit,
    uint256[] calldata curveArray
  ) public returns (
    X59 logPriceLimitOffsettedWithinInterval,
    Index indexCurve,
    bool direction
  ) {
    setCurve(curve);
    setCurveLength(curveLength);
    setLogPriceLimitOffsetted(qLimit);
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

    initiateInterval();

    {
      X59 logPrice = _current_.log();
      X216 sqrtPrice = _current_.sqrt(false);
      X216 sqrtInversePrice = _current_.sqrt(true);
      assembly {
        log3(0, 0, logPrice, sqrtPrice, sqrtInversePrice)
      }
    }

    {
      X59 logPrice = _origin_.log();
      X216 sqrtPrice = _origin_.sqrt(false);
      X216 sqrtInversePrice = _origin_.sqrt(true);
      assembly {
        log3(0, 0, logPrice, sqrtPrice, sqrtInversePrice)
      }
    }

    {
      X59 logPrice = _begin_.log();
      X216 sqrtPrice = _begin_.sqrt(false);
      X216 sqrtInversePrice = _begin_.sqrt(true);
      assembly {
        log3(0, 0, logPrice, sqrtPrice, sqrtInversePrice)
      }
    }

    {
      X59 logPrice = _end_.log();
      X216 sqrtPrice = _end_.sqrt(false);
      X216 sqrtInversePrice = _end_.sqrt(true);
      assembly {
        log3(0, 0, logPrice, sqrtPrice, sqrtInversePrice)
      }
    }

    {
      X59 logPrice = _target_.log();
      X216 sqrtPrice = _target_.sqrt(false);
      X216 sqrtInversePrice = _target_.sqrt(true);
      assembly {
        log3(0, 0, logPrice, sqrtPrice, sqrtInversePrice)
      }
    }

    {
      X15 height = _total0_.height();
      X59 logPrice = _total0_.log();
      X216 sqrtPrice = _total0_.sqrt(false);
      X216 sqrtInversePrice = _total0_.sqrt(true);
      assembly {
        log4(0, 0, height, logPrice, sqrtPrice, sqrtInversePrice)
      }
    }

    {
      X15 height = _total1_.height();
      X59 logPrice = _total1_.log();
      X216 sqrtPrice = _total1_.sqrt(false);
      X216 sqrtInversePrice = _total1_.sqrt(true);
      assembly {
        log4(0, 0, height, logPrice, sqrtPrice, sqrtInversePrice)
      }
    }

    logPriceLimitOffsettedWithinInterval = 
      getLogPriceLimitOffsettedWithinInterval();
    indexCurve = getIndexCurve();
    direction = getDirection();
  }

  function _moveBreakpointTotal(
    uint256 total1Content0,
    uint256 total1Content1,
    uint256 originContent0,
    uint256 originContent1,
    uint256 memberContent0,
    uint256 memberContent1,
    Index indexKernelTotal,
    bool direction
  ) public returns (
    uint256 ,
    uint256 ,
    uint256 ,
    uint256 ,
    Index
  ) {
    {
      uint256 pointer;
      Kernel kernel = Kernel.wrap(_endOfStaticParams_);
      setKernel(kernel);
      assembly {
        mstore(sub(_total1_, 2), total1Content0)
        mstore(add(_total1_, 30), total1Content1)

        mstore(sub(_origin_, 2), originContent0)
        mstore(add(_origin_, 30), originContent1)

        pointer := add(kernel, add(shl(6, indexKernelTotal), 2))
        mstore(sub(pointer, 2), memberContent0)
        mstore(add(pointer, 30), memberContent1)

        mstore(
          _indexKernelTotal_,
          or(
            shl(240, indexKernelTotal),
            shr(16, mload(add(_indexKernelTotal_, 2)))
          )
        )
      }
      setDirection(direction);

      moveBreakpointTotal();

      assembly {
        memberContent0 := mload(sub(_total0_, 2))
        memberContent1 := mload(add(_total0_, 30))

        total1Content0 := mload(sub(_total1_, 2))
        total1Content1 := mload(add(_total1_, 30))
      }
    }

    return (
      memberContent0,
      memberContent1,
      total1Content0,
      total1Content1,
      _indexKernelTotal_.getIndex()
    );
  }

  function _moveBreakpointForward(
    uint256 forward1Content0,
    uint256 forward1Content1,
    uint256 targetContent0,
    uint256 targetContent1,
    uint256 memberContent0,
    uint256 memberContent1,
    Index indexKernelForward,
    bool zeroForOne
  ) public returns (
    uint256 ,
    uint256 ,
    uint256 ,
    uint256 ,
    Index
  ) {
    {
      uint256 pointer;
      Kernel kernel = Kernel.wrap(_endOfStaticParams_);
      setKernel(kernel);
      assembly {
        mstore(sub(_forward1_, 2), forward1Content0)
        mstore(add(_forward1_, 30), forward1Content1)

        mstore(sub(_target_, 2), targetContent0)
        mstore(add(_target_, 30), targetContent1)

        pointer := add(kernel, add(shl(6, indexKernelForward), 2))
        mstore(sub(pointer, 2), memberContent0)
        mstore(add(pointer, 30), memberContent1)

        mstore(
          _indexKernelForward_,
          or(
            shl(240, indexKernelForward),
            shr(16, mload(add(_indexKernelForward_, 2)))
          )
        )
      }
      setZeroForOne(zeroForOne);

      moveBreakpointForward();

      assembly {
        memberContent0 := mload(sub(_forward0_, 2))
        memberContent1 := mload(add(_forward0_, 30))

        forward1Content0 := mload(sub(_forward1_, 2))
        forward1Content1 := mload(add(_forward1_, 30))
      }
    }

    return (
      memberContent0,
      memberContent1,
      forward1Content0,
      forward1Content1,
      _indexKernelForward_.getIndex()
    );
  }

  function _movePhase(
    Index indexCurve,
    Index indexKernelTotal,
    bool direction,
    X59 curveMember,
    uint256[8] calldata input
  ) public returns (
    Index _indexCurve,
    bool _direction,
    uint256[10] memory output
  ) {
    Kernel kernel = Kernel.wrap(_endOfStaticParams_);
    setKernel(kernel);

    Curve curve;
    assembly {
      curve := add(kernel, mul(64, indexKernelTotal))
    }
    setCurve(curve);

    assembly {
      mstore(
        _indexCurve_,
        or(
          shl(240, indexCurve),
          shr(16, mload(add(_indexCurve_, 2)))
        )
      )
    }

    assembly {
      mstore(
        _indexKernelTotal_,
        or(
          shl(240, indexKernelTotal),
          shr(16, mload(add(_indexKernelTotal_, 2)))
        )
      )
    }

    {
      uint256 originContent0 = input[0];
      uint256 originContent1 = input[1];
      assembly {
        mstore(0, originContent0)
        mcopy(_origin_, 2, 30)
        mstore(add(_origin_, 30), originContent1)
      }
    }

    {
      uint256 endContent0 = input[2];
      uint256 endContent1 = input[3];
      assembly {
        mstore(0, endContent0)
        mcopy(_end_, 2, 30)
        mstore(add(_end_, 30), endContent1)
      }
    }

    assembly {
      mstore(0, curveMember)
      let pointer := add(curve, mul(8, sub(indexCurve, 1)))
      mcopy(pointer, 24, 8)
    }

    {
      uint256 content0 = input[4];
      uint256 content1 = input[5];
      assembly {
        let pointer := add(kernel, add(shl(6, sub(indexKernelTotal, 2)), 2))
        mstore(sub(pointer, 2), content0)
        mstore(add(pointer, 30), content1)
      }
    }

    {
      uint256 content0 = input[6];
      uint256 content1 = input[7];
      assembly {
        let pointer := add(kernel, add(shl(6, sub(indexKernelTotal, 1)), 2))
        mstore(sub(pointer, 2), content0)
        mstore(add(pointer, 30), content1)
      }
    }

    setDirection(direction);

    _direction = movePhase();

    _indexCurve = _indexCurve_.getIndex();

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_begin_, 2))
        content1 := mload(add(_begin_, 30))
      }
      output[0] = content0;
      output[1] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_origin_, 2))
        content1 := mload(add(_origin_, 30))
      }
      output[2] = content0;
      output[3] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_end_, 2))
        content1 := mload(add(_end_, 30))
      }
      output[4] = content0;
      output[5] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_total0_, 2))
        content1 := mload(add(_total0_, 30))
      }
      output[6] = content0;
      output[7] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_total1_, 2))
        content1 := mload(add(_total1_, 30))
      }
      output[8] = content0;
      output[9] = content1;
    }
  }

  function _searchOutgoingTarget(
    X216 integralLimit,
    X216 currentToTarget,
    bool zeroForOne,
    uint256[8] calldata input
  ) public returns (
    bool exactAmount,
    X216 outgoing,
    uint256[4] memory output
  ) {
    setIntegralLimit(integralLimit);
    _currentToTarget_.setIntegral(currentToTarget);
    setZeroForOne(zeroForOne);

    {
      uint256 beginContent0 = input[0];
      uint256 beginContent1 = input[1];
      assembly {
        mstore(0, beginContent0)
        mcopy(_begin_, 2, 30)
        mstore(add(_begin_, 30), beginContent1)
      }
    }

    {
      uint256 targetContent0 = input[2];
      uint256 targetContent1 = input[3];
      assembly {
        mstore(0, targetContent0)
        mcopy(_target_, 2, 30)
        mstore(add(_target_, 30), targetContent1)
      }
    }
    
    {
      uint256 total0Content0 = input[4];
      uint256 total0Content1 = input[5];
      assembly {
        mstore(sub(_total0_, 2), total0Content0)
        mstore(add(_total0_, 30), total0Content1)
      }
    }

    {
      uint256 total1Content0 = input[6];
      uint256 total1Content1 = input[7];
      assembly {
        mstore(sub(_total1_, 2), total1Content0)
        mstore(add(_total1_, 30), total1Content1)
      }
    }

    (exactAmount, outgoing) = searchOutgoingTarget();

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_overshoot_, 2))
        content1 := mload(add(_overshoot_, 30))
      }
      output[0] = content0;
      output[1] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_target_, 2))
        content1 := mload(add(_target_, 30))
      }
      output[2] = content0;
      output[3] = content1;
    }
  }

  function _searchIncomingTarget(
    X216 integralLimit,
    X216 incomingCurrentToTarget,
    bool zeroForOne,
    uint256[8] calldata input
  ) public returns (
    bool exactAmount,
    X216 incoming,
    uint256[4] memory output
  ) {
    setIntegralLimit(integralLimit);
    _incomingCurrentToTarget_.setIntegral(incomingCurrentToTarget);
    setZeroForOne(zeroForOne);

    {
      uint256 beginContent0 = input[0];
      uint256 beginContent1 = input[1];
      assembly {
        mstore(0, beginContent0)
        mcopy(_begin_, 2, 30)
        mstore(add(_begin_, 30), beginContent1)
      }
    }

    {
      uint256 targetContent0 = input[2];
      uint256 targetContent1 = input[3];
      assembly {
        mstore(0, targetContent0)
        mcopy(_target_, 2, 30)
        mstore(add(_target_, 30), targetContent1)
      }
    }
    
    {
      uint256 total0Content0 = input[4];
      uint256 total0Content1 = input[5];
      assembly {
        mstore(sub(_total0_, 2), total0Content0)
        mstore(add(_total0_, 30), total0Content1)
      }
    }

    {
      uint256 total1Content0 = input[6];
      uint256 total1Content1 = input[7];
      assembly {
        mstore(sub(_total1_, 2), total1Content0)
        mstore(add(_total1_, 30), total1Content1)
      }
    }

    (exactAmount, incoming) = searchIncomingTarget();

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_overshoot_, 2))
        content1 := mload(add(_overshoot_, 30))
      }
      output[0] = content0;
      output[1] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_target_, 2))
        content1 := mload(add(_target_, 30))
      }
      output[2] = content0;
      output[3] = content1;
    }
  }

  function _moveTarget(
    bool direction,
    bool zeroForOne,
    X59 qLimit,
    X216 originToOvershoot,
    uint256[7] calldata input
  ) public returns (
    bool _direction,
    uint256[12] memory output,
    X216[4] memory integrals
  ) {
    setIntegralLimit(oneX216 - epsilonX216);

    setDirection(direction);

    setZeroForOne(zeroForOne);

    _originToOvershoot_.setIntegral(originToOvershoot);

    {
      Kernel kernel;
      assembly {
        kernel := _endOfStaticParams_
      }
      setKernel(kernel);
    }

    uint16 _total2_;
    {
      Curve curve;
      assembly {
        curve := add(_endOfStaticParams_, 192)
      }
      setCurve(curve);

      uint256 curveContent = input[0];
      assembly {
        mstore(curve, curveContent)
      }

      assembly {
        _total2_ := add(curve, 34)
      }

      assembly {
        mstore(0x40, add(curve, 96))
      }
    }

    assembly {
      let indexKernelTotal := 2
      mstore(
        _indexKernelTotal_,
        or(
          shl(240, indexKernelTotal),
          shr(16, mload(add(_indexKernelTotal_, 2)))
        )
      )
    }

    assembly {
      let indexCurve := 1
      mstore(
        _indexCurve_,
        or(
          shl(240, indexCurve),
          shr(16, mload(add(_indexCurve_, 2)))
        )
      )
    }

    {
      uint256 total0Content0 = input[1];
      uint256 total0Content1 = input[2];
      assembly {
        mstore(sub(_total0_, 2), total0Content0)
        mstore(add(_total0_, 30), total0Content1)
      }
    }

    {
      uint256 total1Content0 = input[3];
      uint256 total1Content1 = input[4];
      assembly {
        mstore(sub(_total1_, 2), total1Content0)
        mstore(add(_total1_, 30), total1Content1)
      }
    }

    {
      uint256 total2Content0 = input[5];
      uint256 total2Content1 = input[6];
      assembly {
        mstore(sub(_total2_, 2), total2Content0)
        mstore(add(_total2_, 30), total2Content1)
      }
    }

    {
      Curve curve = getCurve();
      _begin_.storePrice(curve.member(getIndexCurve() + twoIndex));
      _origin_.storePrice(curve.member(getIndexCurve() + oneIndex));
      _end_.storePrice(curve.member(getIndexCurve()));
    }

    {
      X59 b_0 = getDirection() ? 
                _origin_.log() - _total0_.log() : 
                _total0_.log() - _origin_.log();
      (X216 iSqrt, X216 iSqrtInverse) = b_0.exp();
      Kernel kernel = getKernel();
      uint256 pointer;
      assembly {
        pointer := add(kernel, 2)
      }
      pointer.storePrice(_total0_.height(), b_0, iSqrt, iSqrtInverse);
    }

    {
      X59 b_1 = getDirection() ? 
                _origin_.log() - _total1_.log() : 
                _total1_.log() - _origin_.log();
      (X216 iSqrt, X216 iSqrtInverse) = b_1.exp();
      Kernel kernel = getKernel();
      uint256 pointer;
      assembly {
        pointer := add(kernel, 66)
      }
      pointer.storePrice(_total1_.height(), b_1, iSqrt, iSqrtInverse);
    }

    {
      X59 b_2 = getDirection() ? 
                _origin_.log() - _total2_.log() : 
                _total2_.log() - _origin_.log();
      (X216 iSqrt, X216 iSqrtInverse) = b_2.exp();
      Kernel kernel = getKernel();
      uint256 pointer;
      assembly {
        pointer := add(kernel, 130)
      }
      pointer.storePrice(_total2_.height(), b_2, iSqrt, iSqrtInverse);
    }

    _target_.storePrice(
      (getDirection() == getZeroForOne()) ? 
      (
        getDirection() ? 
        max(max(_end_.log(), _total1_.log()), qLimit) : 
        min(min(_end_.log(), _total1_.log()), qLimit)
      ) : (
        getDirection() ? 
        max(_end_.log(), _total1_.log()) : 
        min(_end_.log(), _total1_.log())
      )
    );

    setLogPriceLimitOffsettedWithinInterval(qLimit);

    moveTarget();

    _direction = getDirection();

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_total0_, 2))
        content1 := mload(add(_total0_, 30))
      }
      output[0] = content0;
      output[1] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_total1_, 2))
        content1 := mload(add(_total1_, 30))
      }
      output[2] = content0;
      output[3] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_begin_, 2))
        content1 := mload(add(_begin_, 30))
      }
      output[4] = content0;
      output[5] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_end_, 2))
        content1 := mload(add(_end_, 30))
      }
      output[6] = content0;
      output[7] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_origin_, 2))
        content1 := mload(add(_origin_, 30))
      }
      output[8] = content0;
      output[9] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_target_, 2))
        content1 := mload(add(_target_, 30))
      }
      output[10] = content0;
      output[11] = content1;
    }

    integrals[0] = _currentToTarget_.integral();
    integrals[1] = _incomingCurrentToTarget_.integral();
    integrals[2] = _originToOvershoot_.integral();
    integrals[3] = _currentToOrigin_.integral();
  }

  function _calculateMaxIntegrals(
    uint256[] calldata kernelArray
  ) public returns (
    X216 outgoingMax,
    X216 incomingMax,
    uint256 outgoingMaxModularInverse
  ) {
    {
      Kernel kernel;
      Index kernelLength;
      assembly {
        kernel := _endOfStaticParams_
        let kernelArrayStart := calldataload(4)
        let kernelArrayLength := calldataload(add(4, kernelArrayStart))
        let kernelArrayByteCount := shl(5, kernelArrayLength)

        calldatacopy(
          kernel,
          add(36, kernelArrayStart),
          kernelArrayByteCount
        )

        kernelLength := add(div(kernelArrayLength, 2), 1)

        mstore(0x40, add(kernel, mul(64, add(kernelLength, 1))))
      }
      setKernel(kernel);
      setKernelLength(kernelLength);
      (
        X15 height,
        X59 logShift,
        X216 sqrtShift,
        X216 sqrtInverseShift
      ) = kernel.member(kernelLength - oneIndex);
      _spacing_.storePrice(logShift, sqrtShift, sqrtInverseShift);
    }

    calculateMaxIntegrals();

    assembly {
      log1(
        _interval_,
        sub(_endOfInterval_, _interval_),
        0
      )
    }

    return (
      getOutgoingMax(),
      getIncomingMax(),
      getOutgoingMaxModularInverse()
    );
  }

  function _calculateIntegrals(
    Index curveLength,
    uint256[] calldata kernelArray,
    uint256[] calldata curveArray
  ) public returns (
    X216 integral0,
    X216 integral1
  ) {
    {
      Kernel kernel;
      Curve curve;
      Index kernelLength;
      assembly {
        kernel := _endOfStaticParams_
        let kernelArrayStart := calldataload(36)
        let kernelArrayLength := calldataload(add(4, kernelArrayStart))
        let kernelArrayByteCount := shl(5, kernelArrayLength)
        calldatacopy(
          kernel,
          add(36, kernelArrayStart),
          kernelArrayByteCount
        )
        kernelLength := add(div(kernelArrayLength, 2), 1)

        curve := add(kernel, kernelArrayByteCount)
        let curveArrayStart := calldataload(68)
        let curveArrayLength := calldataload(add(4, curveArrayStart))
        let curveArrayByteCount := shl(5, curveArrayLength)
        calldatacopy(
          curve,
          add(36, curveArrayStart),
          curveArrayByteCount
        )

        mstore(0x40, add(curve, curveArrayByteCount))
      }
      setKernel(kernel);
      setCurve(curve);
      setKernelLength(kernelLength);
      setCurveLength(curveLength);
      setLogPriceCurrent(curve.member(curveLength - oneIndex));
    }

    calculateIntegrals();

    return (getIntegral0(), getIntegral1());
  }

  function _getMismatch(
    bool zeroForOne,
    X216 currentToOrigin,
    X216 currentToOvershoot,
    X216 currentToTarget,
    X216 incomingCurrentToTarget,
    X216 originToOvershoot,
    X216 targetToOvershoot,
    X216 integral0Incremented,
    X216 integral1Incremented,
    X59 target,
    X59 overshoot,
    X59 origin
  ) public returns (
    X216 mismatch
  ) {
    setZeroForOne(zeroForOne);
    _currentToOrigin_.setIntegral(currentToOrigin);
    _currentToOvershoot_.setIntegral(currentToOvershoot);
    _currentToTarget_.setIntegral(currentToTarget);
    _incomingCurrentToTarget_.setIntegral(incomingCurrentToTarget);
    _originToOvershoot_.setIntegral(originToOvershoot);
    _targetToOvershoot_.setIntegral(targetToOvershoot);
    _target_.storePrice(target);
    _overshoot_.storePrice(overshoot);
    _origin_.storePrice(origin);
    return getMismatch(integral0Incremented, integral1Incremented);
  }

  function _moveOvershoot(
    bool direction,
    bool zeroForOne,
    X216 originToOvershoot,
    uint256[11] calldata input
  ) public returns (
    bool _direction,
    uint256[16] memory output,
    X216[4] memory integrals
  ) {
    setDirection(direction);

    setZeroForOne(zeroForOne);

    _originToOvershoot_.setIntegral(originToOvershoot);

    {
      Kernel kernel;
      assembly {
        kernel := _endOfStaticParams_
      }
      setKernel(kernel);
    }

    uint16 _total2_;
    uint16 _forward2_;
    {
      Curve curve;
      assembly {
        curve := add(_endOfStaticParams_, 320)
      }
      setCurve(curve);

      uint256 curveContent = input[0];
      assembly {
        mstore(curve, curveContent)
      }

      assembly {
        _total2_ := add(curve, 34)
        _forward2_ := add(_total2_, 64)
      }

      assembly {
        mstore(0x40, add(curve, 160))
      }
    }

    assembly {
      let indexKernelForward := 1
      mstore(
        _indexKernelForward_,
        or(
          shl(240, indexKernelForward),
          shr(16, mload(add(_indexKernelForward_, 2)))
        )
      )
    }

    assembly {
      let indexKernelTotal := 4
      mstore(
        _indexKernelTotal_,
        or(
          shl(240, indexKernelTotal),
          shr(16, mload(add(_indexKernelTotal_, 2)))
        )
      )
    }

    assembly {
      let indexCurve := 1
      mstore(
        _indexCurve_,
        or(
          shl(240, indexCurve),
          shr(16, mload(add(_indexCurve_, 2)))
        )
      )
    }

    {
      uint256 forward0Content0 = input[1];
      uint256 forward0Content1 = input[2];
      assembly {
        mstore(sub(_forward0_, 2), forward0Content0)
        mstore(add(_forward0_, 30), forward0Content1)
      }
    }

    {
      uint256 forward1Content0 = input[1];
      uint256 forward1Content1 = input[2];
      assembly {
        mstore(sub(_forward1_, 2), forward1Content0)
        mstore(add(_forward1_, 30), forward1Content1)
      }
    }

    {
      uint256 forward2Content0 = input[3];
      uint256 forward2Content1 = input[4];
      assembly {
        mstore(sub(_forward2_, 2), forward2Content0)
        mstore(add(_forward2_, 30), forward2Content1)
      }
    }

    {
      uint256 total0Content0 = input[5];
      uint256 total0Content1 = input[6];
      assembly {
        mstore(sub(_total0_, 2), total0Content0)
        mstore(add(_total0_, 30), total0Content1)
      }
    }

    {
      uint256 total1Content0 = input[7];
      uint256 total1Content1 = input[8];
      assembly {
        mstore(sub(_total1_, 2), total1Content0)
        mstore(add(_total1_, 30), total1Content1)
      }
    }

    {
      uint256 total2Content0 = input[9];
      uint256 total2Content1 = input[10];
      assembly {
        mstore(sub(_total2_, 2), total2Content0)
        mstore(add(_total2_, 30), total2Content1)
      }
    }

    {
      Curve curve = getCurve();
      if (getZeroForOne()) {
        _target_.storePrice(_forward1_.log() + epsilonX59);
      } else {
        _target_.storePrice(_forward1_.log() - epsilonX59);
      }

      X59 qBegin = curve.member(getIndexCurve() + twoIndex);
      _begin_.storePrice(
        (
          getDirection() == getZeroForOne()
        ) ? (
          getDirection() ? 
          min(min(qBegin, _total0_.log()), _forward0_.log()) : 
          max(max(qBegin, _total0_.log()), _forward0_.log())
        ) : (
          getDirection() ? 
          min(qBegin, _total0_.log()) : 
          max(qBegin, _total0_.log())
        )
      );
      _origin_.storePrice(curve.member(getIndexCurve() + oneIndex));
      _end_.storePrice(curve.member(getIndexCurve()));
      _overshoot_.storePrice(
        (getDirection() == getZeroForOne()) ? 
        (
          getDirection() ? 
          max(max(_end_.log(), _total1_.log()), _forward1_.log()) : 
          min(min(_end_.log(), _total1_.log()), _forward1_.log())
        ) : (
          getDirection() ? 
          max(_end_.log(), _total1_.log()) : 
          min(_end_.log(), _total1_.log())
        )
      );
    }

    {
      X59 d_1 = getZeroForOne() ? 
                _target_.log() - _forward1_.log() : 
                _forward1_.log() - _target_.log();
      (X216 iSqrt, X216 iSqrtInverse) = d_1.exp();
      Kernel kernel = getKernel();
      uint256 pointer;
      assembly {
        pointer := add(kernel, 2)
      }
      pointer.storePrice(_forward1_.height(), d_1, iSqrt, iSqrtInverse);
    }

    {
      X59 d_2 = getZeroForOne() ? 
                _target_.log() - _forward2_.log() : 
                _forward2_.log() - _target_.log();
      (X216 iSqrt, X216 iSqrtInverse) = d_2.exp();
      Kernel kernel = getKernel();
      uint256 pointer;
      assembly {
        pointer := add(kernel, 66)
      }
      pointer.storePrice(_forward2_.height(), d_2, iSqrt, iSqrtInverse);
    }

    {
      X59 b_0 = getDirection() ? 
                _origin_.log() - _total0_.log() : 
                _total0_.log() - _origin_.log();
      (X216 iSqrt, X216 iSqrtInverse) = b_0.exp();
      Kernel kernel = getKernel();
      uint256 pointer;
      assembly {
        pointer := add(kernel, 130)
      }
      pointer.storePrice(_total0_.height(), b_0, iSqrt, iSqrtInverse);
    }

    {
      X59 b_1 = getDirection() ? 
                _origin_.log() - _total1_.log() : 
                _total1_.log() - _origin_.log();
      (X216 iSqrt, X216 iSqrtInverse) = b_1.exp();
      Kernel kernel = getKernel();
      uint256 pointer;
      assembly {
        pointer := add(kernel, 194)
      }
      pointer.storePrice(_total1_.height(), b_1, iSqrt, iSqrtInverse);
    }

    {
      X59 b_2 = getDirection() ? 
                _origin_.log() - _total2_.log() : 
                _total2_.log() - _origin_.log();
      (X216 iSqrt, X216 iSqrtInverse) = b_2.exp();
      Kernel kernel = getKernel();
      uint256 pointer;
      assembly {
        pointer := add(kernel, 258)
      }
      pointer.storePrice(_total2_.height(), b_2, iSqrt, iSqrtInverse);
    }

    moveOvershoot(zeroX216, zeroX216);

    _direction = getDirection();

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_forward0_, 2))
        content1 := mload(add(_forward0_, 30))
      }
      output[0] = content0;
      output[1] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_forward1_, 2))
        content1 := mload(add(_forward1_, 30))
      }
      output[2] = content0;
      output[3] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_total0_, 2))
        content1 := mload(add(_total0_, 30))
      }
      output[4] = content0;
      output[5] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_total1_, 2))
        content1 := mload(add(_total1_, 30))
      }
      output[6] = content0;
      output[7] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_begin_, 2))
        content1 := mload(add(_begin_, 30))
      }
      output[8] = content0;
      output[9] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_end_, 2))
        content1 := mload(add(_end_, 30))
      }
      output[10] = content0;
      output[11] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_origin_, 2))
        content1 := mload(add(_origin_, 30))
      }
      output[12] = content0;
      output[13] = content1;
    }

    {
      uint256 content0;
      uint256 content1;
      assembly {
        content0 := mload(sub(_overshoot_, 2))
        content1 := mload(add(_overshoot_, 30))
      }
      output[14] = content0;
      output[15] = content1;
    }

    integrals[0] = _currentToOvershoot_.integral();
    integrals[1] = _targetToOvershoot_.integral();
    integrals[2] = _originToOvershoot_.integral();
    integrals[3] = _currentToOrigin_.integral();
  }

  function _getNewtonStep(
    bool zeroForOne,
    X59 begin,
    X59 origin,
    X59 target,
    X59 overshoot,
    X216[8] calldata integrals,
    uint256[8] calldata input
  ) public returns (
    bool sign,
    X59 step,
    X216 integral0Amended,
    X216 integral1Amended
  ) {
    setZeroForOne(zeroForOne);
    
    _begin_.storePrice(begin);
    _origin_.storePrice(origin);
    _target_.storePrice(target);
    _overshoot_.storePrice(overshoot);
    
    {
      uint256 total0Content0 = input[0];
      uint256 total0Content1 = input[1];
      assembly {
        mstore(sub(_total0_, 2), total0Content0)
        mstore(add(_total0_, 30), total0Content1)
      }
    }

    {
      uint256 total1Content0 = input[2];
      uint256 total1Content1 = input[3];
      assembly {
        mstore(sub(_total1_, 2), total1Content0)
        mstore(add(_total1_, 30), total1Content1)
      }
    }

    {
      uint256 forward0Content0 = input[4];
      uint256 forward0Content1 = input[5];
      assembly {
        mstore(sub(_forward0_, 2), forward0Content0)
        mstore(add(_forward0_, 30), forward0Content1)
      }
    }

    {
      uint256 forward1Content0 = input[6];
      uint256 forward1Content1 = input[7];
      assembly {
        mstore(sub(_forward1_, 2), forward1Content0)
        mstore(add(_forward1_, 30), forward1Content1)
      }
    }

    _currentToTarget_.setIntegral(integrals[2]);
    _currentToOvershoot_.setIntegral(integrals[3]);
    _targetToOvershoot_.setIntegral(integrals[4]);
    _originToOvershoot_.setIntegral(integrals[5]);
    _currentToOrigin_.setIntegral(integrals[6]);
    _incomingCurrentToTarget_.setIntegral(integrals[7]);

    return newtonStep(integrals[0], integrals[1]);
  }

  function _newIntegrals(
    bool zeroForOne,
    X59 begin,
    X59 origin,
    X59 target,
    X59 overshoot,
    X216[8] calldata integrals,
    uint256[8] calldata input
  ) public returns (
    X216 integral0Amended,
    X216 integral1Amended
  ) {
    setZeroForOne(zeroForOne);
    
    _begin_.storePrice(begin);
    _origin_.storePrice(origin);
    _target_.storePrice(target);
    _overshoot_.storePrice(overshoot);
    
    {
      uint256 total0Content0 = input[0];
      uint256 total0Content1 = input[1];
      assembly {
        mstore(sub(_total0_, 2), total0Content0)
        mstore(add(_total0_, 30), total0Content1)
      }
    }

    {
      uint256 total1Content0 = input[2];
      uint256 total1Content1 = input[3];
      assembly {
        mstore(sub(_total1_, 2), total1Content0)
        mstore(add(_total1_, 30), total1Content1)
      }
    }

    {
      uint256 forward0Content0 = input[4];
      uint256 forward0Content1 = input[5];
      assembly {
        mstore(sub(_forward0_, 2), forward0Content0)
        mstore(add(_forward0_, 30), forward0Content1)
      }
    }

    {
      uint256 forward1Content0 = input[6];
      uint256 forward1Content1 = input[7];
      assembly {
        mstore(sub(_forward1_, 2), forward1Content0)
        mstore(add(_forward1_, 30), forward1Content1)
      }
    }

    _currentToTarget_.setIntegral(integrals[2]);
    _currentToOvershoot_.setIntegral(integrals[3]);
    _targetToOvershoot_.setIntegral(integrals[4]);
    _originToOvershoot_.setIntegral(integrals[5]);
    _currentToOrigin_.setIntegral(integrals[6]);
    _incomingCurrentToTarget_.setIntegral(integrals[7]);

    return newIntegrals(integrals[0], integrals[1]);
  }

  function _moveOvershootByEpsilon(
    X59 overshoot,
    bool left
  ) public returns (
    uint256 overshootContent0,
    uint256 overshootContent1
  ) {
    _overshoot_.storePrice(overshoot);

    moveOvershootByEpsilon(left);
    
    assembly {
      overshootContent0 := mload(sub(_overshoot_, 2))
      overshootContent1 := mload(add(_overshoot_, 30))
    }
  }

  function _clearInterval() public returns (
    uint256 pre,
    uint256 post
  ) {
    uint256 pointer = _interval_;
    while (true) {
      assembly {
        mstore(pointer, not(0))
      }
      if (pointer > _originToOvershoot_ + 27) break;
      pointer += 32;
    }
    assembly {
      mstore(sub(_interval_, 32), not(0))
      mstore(_endOfInterval_, not(0))
    }

    clearInterval();

    assembly {
      log1(
        _interval_,
        sub(_endOfInterval_, _interval_),
        0
      )
      pre := mload(sub(_interval_, 32))
      post := mload(_endOfInterval_)
    }
  }

  function _movements(
    X216 integral0,
    X216 integral1,
    X59 qLimit,
    Index curveLength,
    uint256[] calldata kernelArray,
    uint256[] calldata curveArray
  ) public {
    setIntegral0(integral0);
    setIntegral1(integral1);
    {
      Kernel kernel;
      Curve curve;
      Index kernelLength;
      assembly {
        kernel := _endOfStaticParams_
        let kernelArrayStart := calldataload(132)
        let kernelArrayLength := calldataload(add(4, kernelArrayStart))
        let kernelArrayByteCount := shl(5, kernelArrayLength)
        calldatacopy(
          kernel,
          add(36, kernelArrayStart),
          kernelArrayByteCount
        )
        kernelLength := add(div(kernelArrayLength, 2), 1)

        curve := add(kernel, kernelArrayByteCount)
        let curveArrayStart := calldataload(164)
        let curveArrayLength := calldataload(add(4, curveArrayStart))
        let curveArrayByteCount := shl(5, curveArrayLength)
        calldatacopy(
          curve,
          add(36, curveArrayStart),
          curveArrayByteCount
        )

        mstore(0x40, add(curve, curveArrayByteCount))
      }
      setKernel(kernel);
      setCurve(curve);
      setKernelLength(kernelLength);
      setCurveLength(curveLength);
      setLogPriceCurrent(curve.member(curveLength - oneIndex));
    }

    setLogPriceLimitOffsetted(qLimit);
    
    setZeroForOne(qLimit <= getLogPriceCurrent());
    
    setIntegralLimit(oneX216 - epsilonX216);
    
    initiateInterval();
    
    while (_target_.log() != qLimit) {
      moveTarget();
      assembly {
        log4(0, 0, 0xA, 0, 0, 0)
      }
    }

    _overshoot_.copyPrice(_target_);
    _forward1_.copyPrice(_target_);
    _currentToOvershoot_.setIntegral(_currentToTarget_.integral());

    if (
      (
        _target_.log() != getCurve().member(zeroIndex)
      ) && (
        _target_.log() != getCurve().member(oneIndex)
      )
    ) {
      while (_overshoot_.log() != getCurve().member(zeroIndex)) {
        moveOvershoot(zeroX216, zeroX216);

        (
          X216 integral0Incremented,
          X216 integral1Incremented
        ) = getZeroForOne() ? (
          _incomingCurrentToTarget_.integral() + getIntegral0(),
          getIntegral1() - _currentToTarget_.integral()
        ) : (
          getIntegral0() - _currentToTarget_.integral(),
          _incomingCurrentToTarget_.integral() + getIntegral1()
        );

        uint16 _temp_ = 2;
        _temp_.copyPrice(_begin_);
        _begin_.copyPrice(_overshoot_);

        (
          bool sign,
          X59 step,
          X216 integral0Amended,
          X216 integral1Amended
        ) = newtonStep(integral0Incremented, integral1Incremented);

        _begin_.copyPrice(_temp_);

        X216 mismatch = getMismatch(integral0Incremented, integral1Incremented);
        assembly {
          log4(
            0,
            0,
            mismatch,
            step,
            integral0Amended,
            integral1Amended
          )
        }
      }
    }
  }

  function _searchOvershoot(
    X216 integral0,
    X216 integral1,
    X59 qLimit,
    Index curveLength,
    uint256[] calldata kernelArray,
    uint256[] calldata curveArray
  ) public returns (
    X59 overshoot,
    X216 integral0Amended,
    X216 integral1Amended
  ) {
    setIntegral0(integral0);
    setIntegral1(integral1);
    {
      Kernel kernel;
      Curve curve;
      Index kernelLength;
      assembly {
        kernel := _endOfStaticParams_
        let kernelArrayStart := calldataload(132)
        let kernelArrayLength := calldataload(add(4, kernelArrayStart))
        let kernelArrayByteCount := shl(5, kernelArrayLength)
        calldatacopy(
          kernel,
          add(36, kernelArrayStart),
          kernelArrayByteCount
        )
        kernelLength := add(div(kernelArrayLength, 2), 1)

        curve := add(kernel, kernelArrayByteCount)
        let curveArrayStart := calldataload(164)
        let curveArrayLength := calldataload(add(4, curveArrayStart))
        let curveArrayByteCount := shl(5, curveArrayLength)
        calldatacopy(
          curve,
          add(36, curveArrayStart),
          curveArrayByteCount
        )

        mstore(0x40, add(curve, curveArrayByteCount))
      }
      setKernel(kernel);
      setCurve(curve);
      setKernelLength(kernelLength);
      setCurveLength(curveLength);
      setLogPriceCurrent(curve.member(curveLength - oneIndex));
    }

    setLogPriceLimitOffsetted(qLimit);
    
    setZeroForOne(qLimit <= getLogPriceCurrent());
    
    setIntegralLimit(oneX216 - epsilonX216);
    
    initiateInterval();
    
    while (_target_.log() != qLimit) {
      moveTarget();
    }

    _overshoot_.copyPrice(_target_);
    _forward1_.copyPrice(_target_);
    _currentToOvershoot_.setIntegral(_currentToTarget_.integral());

    (
      X216 integral0Incremented,
      X216 integral1Incremented
    ) = getZeroForOne() ? (
      _incomingCurrentToTarget_.integral() + getIntegral0(),
      getIntegral1() - _currentToTarget_.integral()
    ) : (
      getIntegral0() - _currentToTarget_.integral(),
      _incomingCurrentToTarget_.integral() + getIntegral1()
    );

    while (moveOvershoot(integral0Incremented, integral1Incremented)) {}

    (integral0Amended, integral1Amended) = searchOvershoot(
      integral0Incremented,
      integral1Incremented
    );

    return (_overshoot_.log(), integral0Amended, integral1Amended);
  }
}