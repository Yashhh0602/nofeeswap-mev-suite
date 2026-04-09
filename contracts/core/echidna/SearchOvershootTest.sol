// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "./FuzzUtilities.sol";

using PriceLibrary for uint16;
using IntegralLibrary for uint16;
using PriceLibrary for uint256;
using IntegralLibrary for uint256;

contract SearchOvershootTest {
  function searchOvershoot_test(
    bool[3] calldata seed_base,
    uint64[3] calldata seed_boundaries,
    uint88[] calldata seed_kernel,
    uint64[] calldata seed_curve,
    uint64 seed_target
  ) public {
    KernelAndCurveFactory factory = new KernelAndCurveFactory(10, 10);
    bool success;
    bytes4 selector = KernelAndCurveFactory.buildAndIntegrate.selector;
    assembly {
      mstore(128, selector)
      calldatacopy(132, 4, sub(calldatasize(), 4))
      success := call(gas(), factory, 0, 128, calldatasize(), 0, 0)
      for { let i := 128 } lt(i, add(_pointers_, 32)) { i := add(i, 32) }
      {
        mstore(i, 0)
        let j := mload(i)
      }
      returndatacopy(_pointers_, 0, returndatasize())
    }
    assert(success);

    setLogPriceLimitOffsetted(
      get_a_logPrice_in_between(
        seed_target,
        min(getCurve().member(zeroIndex), getCurve().member(oneIndex)),
        max(getCurve().member(zeroIndex), getCurve().member(oneIndex))
      )
    );
    setIntegralLimit(oneX216 - epsilonX216);
    initiateInterval();
    require(getLogPriceLimitOffsetted() != _current_.log());
    setZeroForOne(getLogPriceLimitOffsetted() < _current_.log());

    (X216 _integral0, X216 _integral1) = (
      getCurve().member(zeroIndex) < getCurve().member(oneIndex)
    ) ? (
      factory.currentToOrigin_reference(),
      factory.currentToTarget_reference()
    ) : (
      factory.currentToTarget_reference(),
      factory.currentToOrigin_reference()
    );
    setIntegral0(_integral0);
    setIntegral1(_integral1);

    while (_target_.log() != getLogPriceLimitOffsettedWithinInterval()) {
      if (moveTarget()) break;
    }

    _overshoot_.copyPrice(_target_);
    _currentToOvershoot_.setIntegral(_currentToTarget_.integral());
    getKernel().impose(_forward1_, _target_, zeroIndex, getZeroForOne());
    (
      _integral0,
      _integral1
    ) = getZeroForOne() ? (
      _integral0 + _incomingCurrentToTarget_.integral(),
      _integral1 - _currentToTarget_.integral()
    ) : (
      _integral0 - _currentToTarget_.integral(),
      _integral1 + _incomingCurrentToTarget_.integral()
    );

    X59 _end = _end_.log();

    X216 _integralNew0;
    X216 _integralNew1;
    if (
      (_target_.log() != getCurve().member(zeroIndex)) && 
      (_target_.log() != getCurve().member(oneIndex)) && 
      (_total1_.height() != zeroX15) && 
      (_target_.log() != _current_.log())
    ) {
      while (moveOvershoot(_integral0, _integral1)) {}

      (_integralNew0, _integralNew1) = searchOvershoot(_integral0, _integral1);

      X216 currentMismatch = max(
        oneX216.mulDiv(_integralNew0, _integral0),
        oneX216.mulDiv(_integralNew1, _integral1)
      );

      if (_begin_.log() != _overshoot_.log()) {
        moveOvershootByEpsilon(!getZeroForOne());
        (_integralNew0, _integralNew1) = newIntegrals(_integral0, _integral1);
        X216 backMismatch = max(
          oneX216.mulDiv(_integralNew0, _integral0),
          oneX216.mulDiv(_integralNew1, _integral1)
        );
        assert(backMismatch >= currentMismatch);
        moveOvershootByEpsilon(getZeroForOne());
      }

      _end_.storePrice(_end);

      if (_overshoot_.log() != _end_.log()) {
        moveOvershootByEpsilon(getZeroForOne());
        (_integralNew0, _integralNew1) = newIntegrals(_integral0, _integral1);
        X216 forwardMismatch = max(
          oneX216.mulDiv(_integralNew0, _integral0),
          oneX216.mulDiv(_integralNew1, _integral1)
        );
        assert(forwardMismatch >= currentMismatch);
      }
    }
  }
}