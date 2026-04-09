// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Growth.sol";
import {
  setProtocolGrowthPortion,
  setPoolGrowthPortion
} from "../utilities/Memory.sol";

/// @title This contract exposes the internal functions of 'Growth.sol'
/// for testing purposes.
contract GrowthWrapper {
  function updateGrowthWrapper(
    X111 _growth,
    X47 _protocolGrowthPortion,
    X47 _poolGrowthPortion,
    X216 numerator,
    X216 denominator
  ) public returns (
    X111 updatedGrowth
  ) {
    setProtocolGrowthPortion(_protocolGrowthPortion);
    setPoolGrowthPortion(_poolGrowthPortion);
    return updateGrowth(
      _growth,
      numerator,
      denominator
    );
  }
}