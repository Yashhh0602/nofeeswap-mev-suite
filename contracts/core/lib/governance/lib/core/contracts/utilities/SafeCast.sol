// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {SafeCastOverflow} from "./Errors.sol";

library SafeCastLibrary {
  /// @notice Converts an unsigned uint256 into a signed int256.
  function toInt256(uint256 value) internal pure returns (int256) {
    require(value <= uint256(type(int256).max), SafeCastOverflow(value));
    return int256(value);
  }
}