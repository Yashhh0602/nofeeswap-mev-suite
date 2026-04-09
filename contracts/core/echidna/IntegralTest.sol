// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "./FuzzUtilities.sol";

using PriceLibrary for uint256;
using IntegralLibrary for uint256;
using IntegralLibrary for X216;

contract IntegralTest {
  function integral_setter_getter_test(uint216 seed) public pure {
    X216 value = get_an_integral(seed);
    uint256 pointer = get_an_integral_pointer();
    pointer.setIntegral(value);
    assert(value == pointer.integral());
  }

  function integral_increment_decrement_test(
    uint216 seed0,
    uint216 seed1
  ) public pure {
    X216 value0 = get_an_integral(seed0);
    X216 value1 = get_an_integral(seed1);
    (value0, value1) = (value0 <= value1) ? (value0, value1) : (value1, value0);

    uint256 pointer = get_an_integral_pointer();
    pointer.setIntegral(value1);

    pointer.decrementIntegral(value0);
    assert(value1 - value0 == pointer.integral());

    pointer.incrementIntegral(value0);
    assert(value1 == pointer.integral());
  }

  function evaluate_test(
    uint16 seed_c0,
    uint16 seed_c1,
    uint64 seed_b0,
    uint64 seed_b1,
    bool left,
    uint64 seed_q
  ) public pure {
    X15 c0 = get_a_height(seed_c0);
    X15 c1 = get_a_height(seed_c1);
    (c0, c1) = (c0 < c1) ? (c0, c1) : (c1, c0);
    X59 b0 = get_a_logPrice_in_between(
      seed_b0,
      epsilonX59,
      thirtyTwoX59 - epsilonX59 - epsilonX59
    );
    X59 b1 = get_a_logPrice_in_between(
      seed_b1, b0 + epsilonX59,
      thirtyTwoX59 - epsilonX59
    );
    (b0, b1) = left ? (b0, b1) : (b1, b0);
    X59 q = get_a_logPrice_in_between(seed_q, b0, b1);

    (X216 sqrt0, X216 sqrtInverse0) = b0.exp();
    (X216 sqrt1, X216 sqrtInverse1) = b1.exp();
    uint256 segmentCoordinates = get_a_segment_pointer();
    segmentCoordinates.storePrice(c0, b0, sqrt0, sqrtInverse0);
    (segmentCoordinates + 64).storePrice(c1, b1, sqrt1, sqrtInverse1);

    (X216 sqrt, X216 sqrtInverse) = q.exp();
    uint256 targetPrice = get_a_price_pointer();
    targetPrice.storePrice(q, sqrt, sqrtInverse);

    assert(
      segmentCoordinates.evaluate(targetPrice) == 
        evaluate_reference(c0, c1, b0, b1, q)
    );
  }

  function outgoing_incoming_test(
    uint16 seed_c0,
    uint16 seed_c1,
    uint64 seed_b0,
    uint64 seed_b1,
    bool direction,
    uint64 seed_from,
    uint64 seed_to
  ) public pure {
    X59 b0 = get_a_logPrice_in_between(
      seed_b0,
      epsilonX59,
      thirtyTwoX59 - epsilonX59 - epsilonX59
    );
    X59 b1 = get_a_logPrice_in_between(
      seed_b1,
      b0 + epsilonX59,
      thirtyTwoX59 - epsilonX59
    );
    (b0, b1) = direction ? (b0, b1) : (b1, b0);
    X15 c0 = get_a_height(seed_c0);
    X15 c1 = get_a_height(seed_c1);
    uint256 segmentCoordinates = get_a_segment_pointer();
    uint256 fromPrice = get_a_price_pointer();
    uint256 toPrice = get_a_price_pointer();
    X59 from = get_a_logPrice_in_between(seed_from, b0, b1);
    X59 to = get_a_logPrice_in_between(seed_to, b0, b1);
    {
      (c0, c1) = (c0 < c1) ? (c0, c1) : (c1, c0);
      (from, to) = (from < to) ? (from, to) : (to, from);
      (from, to) = direction ? (from, to) : (to, from);

      (X216 sqrt0, X216 sqrtInverse0) = b0.exp();
      (X216 sqrt1, X216 sqrtInverse1) = b1.exp();
      segmentCoordinates.storePrice(c0, b0, sqrt0, sqrtInverse0);
      (segmentCoordinates + 64).storePrice(c1, b1, sqrt1, sqrtInverse1);

      (X216 sqrt, X216 sqrtInverse) = from.exp();
      fromPrice.storePrice(from, sqrt, sqrtInverse);

      (sqrt, sqrtInverse) = to.exp();
      toPrice.storePrice(to, sqrt, sqrtInverse);
    }

    assert(
      approximatelyEqual(
        segmentCoordinates.outgoing(fromPrice, toPrice),
        outgoing_reference(c0, c1, b0, b1, from, to),
        16
      )
    );

    assert(
      approximatelyEqual(
        segmentCoordinates.incoming(fromPrice, toPrice),
        incoming_reference(c0, c1, b0, b1, from, to),
        16
      )
    );
  }

  function shift_test(
    uint256 seed_integral,
    uint64 seed_price0,
    uint64 seed_price1
  ) public pure {
    X216 integralValue = X216.wrap(int256(
      seed_integral % uint256(X216.unwrap(expInverse8X216 * expInverse8X216))
    ));

    X59 price0 = get_a_logPrice_in_between(
      seed_price0,
      epsilonX59,
      thirtyTwoX59 - epsilonX59
    );
    (X216 sqrt0, X216 sqrtInverse0) = price0.exp();
    uint256 pointer0 = get_a_price_pointer();
    pointer0.storePrice(price0, sqrt0, sqrtInverse0);

    X59 price1 = get_a_logPrice_in_between(
      seed_price1,
      epsilonX59,
      thirtyTwoX59 - epsilonX59
    );
    (X216 sqrt1, X216 sqrtInverse1) = price1.exp();
    uint256 pointer1 = get_a_price_pointer();
    pointer1.storePrice(price1, sqrt1, sqrtInverse1);

    assert(
      approximatelyEqual(
        integralValue.shift(pointer0, pointer1, false),
        shift_reference(
          integralValue,
          sqrtInverse0,
          sqrtInverse1
        ),
        2 ** 32
      )
    );

    assert(
      approximatelyEqual(
        integralValue.shift(pointer0, pointer1, true),
        shift_reference(
          integralValue,
          sqrt0,
          sqrt1
        ),
        2 ** 32
      )
    );
  }
}