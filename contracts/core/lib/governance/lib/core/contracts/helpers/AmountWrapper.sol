// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/Amount.sol';
import {
  setExactInput,
  setOutgoingMax,
  setOutgoingMaxModularInverse,
  setSqrtOffset,
  setSqrtInverseOffset,
  setAmountSpecified,
  setGrowth,
  setSharesTotal,
  setZeroForOne,
  setShares,
  getIntegralLimit
} from "../utilities/Memory.sol";

/// @title This contract exposes the internal functions of 'Amount.sol' for 
/// testing purposes.
contract AmountWrapper {
  function calculateIntegralLimitWrapper(
    X216 _outgoingMax,
    X127 _sqrtOffset,
    X127 _sqrtInverseOffset,
    X127 _amountSpecified,
    X111 _growth,
    uint256 _shares
  ) public returns (
    X216 limit0,
    X216 limit1
  ) {
    setExactInput(_amountSpecified > zeroX127);
    setOutgoingMax(_outgoingMax);
    setSqrtOffset(_sqrtOffset);
    setSqrtInverseOffset(_sqrtInverseOffset);
    setAmountSpecified(_amountSpecified);
    setGrowth(_growth);
    setSharesTotal(_shares);
    setZeroForOne(false);
    calculateIntegralLimit();
    limit0 = getIntegralLimit();
    setZeroForOne(true);
    calculateIntegralLimit();
    limit1 = getIntegralLimit();
  }

  function safeOutOfRangeAmountWrapper(
    X127 _sqrtOffset,
    X127 _sqrtInverseOffset,
    X208 _growthMultiplier,
    int256 _shares,
    bool _zeroOrOne
  ) public returns (
    X127 result
  ) {
    setSqrtOffset(_sqrtOffset);
    setSqrtInverseOffset(_sqrtInverseOffset);
    setShares(_shares);
    result = safeOutOfRangeAmount(_growthMultiplier, _zeroOrOne);
  }

  function inRangeAmountWrapper(
    X127 _sqrtOffset,
    X127 _sqrtInverseOffset,
    X216 _integral,
    X111 _growth,
    int256 _shares,
    X216 _outgoingMax,
    uint256 _outgoingMaxModularInverse,
    bool _zeroOrOne,
    bool roundUp
  ) public returns (
    X127 result,
    bool overflow
  ) {
    setSqrtOffset(_sqrtOffset);
    setSqrtInverseOffset(_sqrtInverseOffset);
    setOutgoingMax(_outgoingMax);
    setOutgoingMaxModularInverse(_outgoingMaxModularInverse);
    return inRangeAmount(
      _integral,
      _growth.times(_shares),
      _zeroOrOne,
      roundUp
    );
  }

  function safeInRangeAmountWrapper(
    X127 _sqrtOffset,
    X127 _sqrtInverseOffset,
    X216 _integral,
    X111 _growth,
    int256 _shares,
    X216 _outgoingMax,
    uint256 _outgoingMaxModularInverse,
    bool _zeroOrOne,
    bool roundUp
  ) public returns (
    X127 result
  ) {
    setSqrtOffset(_sqrtOffset);
    setSqrtInverseOffset(_sqrtInverseOffset);
    setOutgoingMax(_outgoingMax);
    setOutgoingMaxModularInverse(_outgoingMaxModularInverse);
    return safeInRangeAmount(
      _integral,
      _growth.times(_shares),
      _zeroOrOne,
      roundUp
    );    
  }
}