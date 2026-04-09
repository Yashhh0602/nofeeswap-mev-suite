// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X59} from "./X59.sol";

/// @notice Extracts '(2 ** 59) * log(pOffset)' from poolId.
function getLogOffsetFromPoolId(
  uint256 poolId
) pure returns (
  X59 logOffset
) {
  assembly {
    // Bits 181 to 188 of poolId represent an 8-bit integer in two's
    // complement which is equal to the natural logarithm of 'pOffset'. We
    // extract this value and convert it to an 'int256' by extending its sign
    // bit. Next, we multiply it by '2 ** 59' to obtain 'log(pOffset)' in 'X59'
    // representation.
    logOffset := mul(shl(59, 1), signextend(0, shr(180, poolId)))
  }
}

/// @notice Derives 'poolId' based on the following rule:
///
/// 'poolId = unsaltedPoolId + (
///     keccak256(abi.encodePacked(msg.sender, unsaltedPoolId)) << 188
///  )'
///
function derivePoolId(
  uint256 unsaltedPoolId
) view returns (
  uint256 poolId
) {
  assembly {
    mstore(0, shl(96, caller()))
    mstore(20, unsaltedPoolId)
    poolId := add(unsaltedPoolId, shl(188, keccak256(0, 52)))
  }
}