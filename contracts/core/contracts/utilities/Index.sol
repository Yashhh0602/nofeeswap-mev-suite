// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

// Type index is used to enumerate members of the curve and kernel.
type Index is uint256;

Index constant zeroIndex = Index.wrap(0);
Index constant oneIndex = Index.wrap(1);
Index constant twoIndex = Index.wrap(2);
Index constant threeIndex = Index.wrap(3);
Index constant maxCurveIndex = Index.wrap(type(uint16).max);
Index constant maxKernelIndex = Index.wrap(1020);

using {equals as ==, notEquals as !=} for Index global;
using {lessThan as <, greaterThan as >} for Index global;
using {lessThanOrEqualTo as <=, greaterThanOrEqualTo as >=} for Index global;
using {add as +, sub as -} for Index global;

function equals(
  Index value0,
  Index value1
) pure returns (
  bool result
) {
  assembly {
    result := eq(value0, value1)
  }
}

function notEquals(
  Index value0,
  Index value1
) pure returns (
  bool result
) {
  return !(value0 == value1);
}

function lessThan(
  Index value0,
  Index value1
) pure returns (
  bool result
) {
  assembly {
    result := lt(value0, value1)
  }
}

function greaterThan(
  Index value0,
  Index value1
) pure returns (
  bool result
) {
  assembly {
    result := gt(value0, value1)
  }
}

function lessThanOrEqualTo(
  Index value0,
  Index value1
) pure returns (
  bool result
) {
  return !(value0 > value1);
}

function greaterThanOrEqualTo(
  Index value0,
  Index value1
) pure returns (
  bool result
) {
  return !(value0 < value1);
}

// Overflow should be avoided externally.
function add(
  Index value0,
  Index value1
) pure returns (
  Index result
) {
  assembly {
    result := add(value0, value1)
  }
}

// Underflow should be avoided externally.
function sub(
  Index value0,
  Index value1
) pure returns (
  Index result
) {
  assembly {
    result := sub(value0, value1)
  }
}

function min(
  Index value0,
  Index value1
) pure returns (
  Index result
) {
  return (value0 < value1) ? value0 : value1;
}

function max(
  Index value0,
  Index value1
) pure returns (
  Index result
) {
  return (value0 < value1) ? value1 : value0;
}

library IndexLibrary {
  /// @notice Returns the current 16-bit index of the curve or kernel under 
  /// exploration given the corresponding pointer.
  ///
  /// 'pointer' should be a constant value.
  function getIndex(
    uint256 pointer
  ) internal pure returns (
    Index value
  ) {
    assembly {
      // First, the memory slot whose most significant 16 bits host the index
      // is loaded and then the least significant 240 bits are discarded.
      value := shr(240, mload(pointer))
    }
  }

  /// @notice Increases a 16-bit index stored in memory by one, given a 
  /// pointer. The new value for the index is then returned.
  /// Overflow should be avoided externally.
  ///
  /// 'pointer' should be a constant value.
  function incrementIndex(
    uint256 pointer
  ) internal pure returns (
    Index value
  ) {
    assembly {
      // Index is the most significant 16 bit. Hence, to increment it we need
      // to add the slot by '2 ** 240'.
      value := add(mload(pointer), shl(240, 1))
      mstore(pointer, value)

      // Then, the least significant 240 bits are discarded and the resulting
      // value is returned.
      value := shr(240, value)
    }
  }

  /// @notice Decreases a 16-bit index stored in memory by one, given a 
  /// pointer. The new value for the index is then returned.
  /// Underflow should be avoided externally.
  ///
  /// 'pointer' should be a constant value.
  function decrementIndex(
    uint256 pointer
  ) internal pure returns (
    Index value
  ) {
    assembly {
      // Index is the most significant 16 bit. Hence, to decrement it we need
      // to subtract the slot by '2 ** 240'.
      value := sub(mload(pointer), shl(240, 1))
      mstore(pointer, value)

      // Then, the least significant 240 bits are discarded and the resulting
      // value is returned.
      value := shr(240, value)
    }
  }
}