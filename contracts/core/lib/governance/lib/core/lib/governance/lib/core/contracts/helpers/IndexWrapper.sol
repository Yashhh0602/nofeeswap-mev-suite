// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Index.sol";

/// @title This contract exposes the functions of 'Index.sol' for testing
/// purposes.
contract IndexWrapper {
  function equals(
    Index index0,
    Index index1
  ) public returns (
    bool result
  ) {
    return index0 == index1;
  }

  function notEqual(
    Index index0,
    Index index1
  ) public returns (
    bool result
  ) {
    return index0 != index1;
  }

  function lessThan(
    Index index0,
    Index index1
  ) public returns (
    bool result
  ) {
    return index0 < index1;
  }

  function greaterThan(
    Index index0,
    Index index1
  ) public returns (
    bool result
  ) {
    return index0 > index1;
  }

  function lessThanOrEqualTo(
    Index index0,
    Index index1
  ) public returns (
    bool result
  ) {
    return index0 <= index1;
  }

  function greaterThanOrEqualTo(
    Index index0,
    Index index1
  ) public returns (
    bool result
  ) {
    return index0 >= index1;
  }
  
  function add(
    Index index0,
    Index index1
  ) public returns (
    Index result
  ) {
    return index0 + index1;
  }

  function sub(
    Index index0,
    Index index1
  ) public returns (
    Index result
  ) {
    return index0 - index1;
  }

  function minIndex(
    Index value0,
    Index value1
  ) public returns (
    Index result
  ) {
    return min(value0, value1);
  }

  function maxIndex(
    Index value0,
    Index value1
  ) public returns (
    Index result
  ) {
    return max(value0, value1);
  }

  function getIndex(
    Index index
  ) public returns (
    Index result
  ) {
    uint256 pointer;
    assembly {
      pointer := mload(0x40)
      mstore(0x40, add(pointer, 32))
      mstore(pointer, shl(240, index))
    }
    return IndexLibrary.getIndex(pointer);
  }

  function incrementIndex(
    Index index
  ) public returns (
    Index result
  ) {
    uint256 pointer;
    assembly {
      pointer := mload(0x40)
      mstore(0x40, add(pointer, 32))
      mstore(pointer, shl(240, index))
    }
    return IndexLibrary.incrementIndex(pointer);
  }

  function decrementIndex(
    Index index
  ) public returns (
    Index result
  ) {
    uint256 pointer;
    assembly {
      pointer := mload(0x40)
      mstore(0x40, add(pointer, 32))
      mstore(pointer, shl(240, index))
    }
    return IndexLibrary.decrementIndex(pointer);
  }
}