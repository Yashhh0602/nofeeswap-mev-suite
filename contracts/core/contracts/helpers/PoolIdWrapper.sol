// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/PoolId.sol";

/// @title This contract exposes the internal functions of 'PoolId.sol' for
/// testing purposes.
contract PoolIdWrapper {
  function _getLogOffsetFromPoolId(
    uint256 poolId
  ) public returns (
    X59 logOffset
  ) {
    return getLogOffsetFromPoolId(poolId);
  }

  function _derivePoolId(
    uint256 unsaltedPoolId
  ) public returns (
    uint256 poolId
  ) {
    return derivePoolId(unsaltedPoolId);
  }
}