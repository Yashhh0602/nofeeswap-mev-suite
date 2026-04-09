// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/GrowthPortion.sol";
import {
  setProtocolGrowthPortion,
  setPoolGrowthPortion
} from "../utilities/Memory.sol";

/// @title This contract exposes the internal functions of 'GrowthPortion.sol'
/// for testing purposes.
contract GrowthPortionWrapper {
  function _calculateGrowthPortion(
    X47 protocolGrowthPortion,
    X47 poolGrowthPortion,
    X127 increment,
    X127 currentAccrued,
    X23 currentPoolRatio
  ) public returns (
    X127 updatedAccrued,
    X23 updatedPoolRatio
  ) {
    setProtocolGrowthPortion(protocolGrowthPortion);
    setPoolGrowthPortion(poolGrowthPortion);
    return calculateGrowthPortion(increment, currentAccrued, currentPoolRatio);
  }

  function _isGrowthPortion(
    X47 protocolGrowthPortion,
    X47 poolGrowthPortion
  ) public returns (bool result) {
    setProtocolGrowthPortion(protocolGrowthPortion);
    setPoolGrowthPortion(poolGrowthPortion);
    return isGrowthPortion();
  }
}