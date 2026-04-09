// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X59} from "./X59.sol";

// Type 'Tag' may refer to any of the followings:
//
// - Native token corresponding to 'Tag.wrap(0)'.
//
// - An ERC-20 address, i.e., 'Tag.wrap(uint256(uint160(tokenAddress)))'.
//
// - An ERC-1155 token whose value is determined by hashing token address and
// token ID, i.e., 
// 'Tag.wrap(uint256(keccak256(abi.encodePacked(tokenAddress, tokenId))))'.
//
// - An ERC-6909 token whose value is determined by hashing token address and
// token ID, i.e., 
// 'Tag.wrap(uint256(keccak256(abi.encodePacked(tokenAddress, tokenId))))'.
//
// - A nofeeswap position whose value is determined by hashing, poolId and
// min/max position boundaries, i.e., 
// 'Tag.wrap(uint256(keccak256(abi.encodePacked(
//    poolId,
//    qMin,
//    qMax
//  ))))'.
//
type Tag is uint256;

Tag constant native = Tag.wrap(0);

using {equals as ==, notEqual as !=} for Tag global;
using {lessThan as <, greaterThan as >} for Tag global;
using {
  lessThanOrEqualTo as <=,
  greaterThanOrEqualTo as >=
} for Tag global;

function equals(
  Tag value0,
  Tag value1
) pure returns (
  bool result
) {
  assembly {
    result := eq(value0, value1)
  }
}

function notEqual(
  Tag value0,
  Tag value1
) pure returns (
  bool result
) {
  return !(value0 == value1);
}

function lessThan(
  Tag value0,
  Tag value1
) pure returns (
  bool result
) {
  assembly {
    result := lt(value0, value1)
  }
}

function greaterThan(
  Tag value0,
  Tag value1
) pure returns (
  bool result
) {
  assembly {
    result := gt(value0, value1)
  }
}

function lessThanOrEqualTo(
  Tag value0,
  Tag value1
) pure returns (
  bool result
) {
  return !(value0 > value1);
}

function greaterThanOrEqualTo(
  Tag value0,
  Tag value1
) pure returns (
  bool result
) {
  return !(value0 < value1);
}

library TagLibrary {
  /// @notice Generates a tag given an ERC-20 address.
  /// @param tokenAddress The given ERC-20 address to be transformed to the
  /// type 'tag'.
  function tag(
    address tokenAddress
  ) internal pure returns (
    Tag tokenTag
  ) {
    assembly {
      tokenTag := and(tokenAddress, sub(shl(160, 1), 1))
    }
  }

  /// @notice Generates a tag given a multi-token address and tokenId.
  /// @param tokenAddress The given multi-token address to be transformed to
  /// the type 'tag'.
  /// @param tokenId The given multi-token id to be used to generate 'tag'.
  function tag(
    address tokenAddress,
    uint256 tokenId
  ) internal pure returns (
    Tag tokenTag
  ) {
    assembly {
      mstore(20, tokenAddress)
      mstore(0, tokenId)
      tokenTag := keccak256(0, 52)
    }
  }

  /// @notice Generates a tag given a nofeeswap liquidity position.
  /// @param poolId The pool identifier hosting this liquidity position.
  /// @param qMin Equal to '(2 ** 59) * log(pMin)' where 'pMin' is the left
  /// position boundary.
  /// @param qMax Equal to '(2 ** 59) * log(pMax)' where 'pMax' is the right
  /// position boundary.
  function tag(
    uint256 poolId,
    X59 qMin,
    X59 qMax
  ) internal pure returns (
    Tag positionTag
  ) {
    assembly {
      // Cache the free memory pointer so that the third memory slot can be
      // used for hashing.
      let freeMemoryPointer := mload(0x40)
      mstore(64, qMax)
      mstore(32, qMin)
      mstore(0, poolId)
      positionTag := keccak256(0, 96)
      // The 'freeMemoryPointer' is restored.
      mstore(0x40, freeMemoryPointer)
    }
  }
}