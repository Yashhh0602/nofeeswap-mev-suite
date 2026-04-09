// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "./FuzzUtilities.sol";

using PriceLibrary for uint16;
using IntegralLibrary for uint16;

contract SearchOutgoingTest {
  function searchOutgoingTarget_test(
    bool zeroForOne_seed,
    uint64 begin_seed,
    uint64 target_seed,
    uint80 total0_seed,
    uint80 total1_seed,
    uint216 integral_seed
  ) public pure {
    X59 _begin;
    X59 _target;
    X59 _total0 = get_a_logPrice(uint64(total0_seed));
    X59 _total1 = get_a_logPrice(uint64(total1_seed));
    X15 _total0_height = get_a_height(uint16(total0_seed >> 64));
    X15 _total1_height = get_a_height_in_between(
      uint16(total1_seed >> 64),
      X15.wrap(1),
      oneX15
    );
    (_total0_height, _total1_height) = (_total0_height < _total1_height) ? 
      (_total0_height, _total1_height) : (_total1_height, _total0_height);
    if (zeroForOne_seed) {
      (_total0, _total1) = (max(_total0, _total1), min(_total0, _total1));
      _begin = get_a_logPrice_in_between(begin_seed, _total1, _total0);
      _target = get_a_logPrice_in_between(target_seed, _total1, _total0);
      (_begin, _target) = (max(_begin, _target), min(_begin, _target));
    } else {
      (_total0, _total1) = (min(_total0, _total1), max(_total0, _total1));
      _begin = get_a_logPrice_in_between(begin_seed, _total0, _total1);
      _target = get_a_logPrice_in_between(target_seed, _total0, _total1);
      (_begin, _target) = (min(_begin, _target), max(_begin, _target));
    }
    (X216 sqrt, X216 sqrtInverse) = _total0.exp();
    _total0_.storePrice(_total0_height, _total0, sqrt, sqrtInverse);
    (sqrt, sqrtInverse) = _total1.exp();
    _total1_.storePrice(_total1_height, _total1, sqrt, sqrtInverse);
    (sqrt, sqrtInverse) = _begin.exp();
    _begin_.storePrice(_begin, sqrt, sqrtInverse);
    (sqrt, sqrtInverse) = _target.exp();
    _target_.storePrice(_target, sqrt, sqrtInverse);
    setIntegralLimit(get_an_integral(
      1 + integral_seed % uint216(
        uint256(X216.unwrap(_total0_.outgoing(_begin_, _target_))) - 1
      )
    ));
    setZeroForOne(zeroForOne_seed);

    (, X216 outgoing) = searchOutgoingTarget();
    X216 outgoingLimit = getIntegralLimit() - _currentToTarget_.integral();

    X59 x = _target_.log();
    assert(outgoingLimit <= outgoing);
    if (x != _begin_.log()) {
      x = getZeroForOne() ? x + epsilonX59 : x - epsilonX59;
      _target_.storePrice(x);
      assert(_total0_.outgoing(_begin_, _target_) < outgoingLimit);
    }
  }
}