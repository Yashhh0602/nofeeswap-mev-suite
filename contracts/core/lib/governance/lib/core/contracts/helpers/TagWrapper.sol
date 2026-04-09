// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Tag.sol";

/// @title This contract exposes the functions of 'Tag.sol' for testing
/// purposes.
contract TagWrapper {
  function equals(
    Tag value0,
    Tag value1
  ) public returns (
    bool result
  ) {
    return value0 == value1;
  }

  function notEqual(
    Tag value0,
    Tag value1
  ) public returns (
    bool result
  ) {
    return value0 != value1;
  }

  function lessThan(
    Tag value0,
    Tag value1
  ) public returns (
    bool result
  ) {
    return value0 < value1;
  }

  function greaterThan(
    Tag value0,
    Tag value1
  ) public returns (
    bool result
  ) {
    return value0 > value1;
  }

  function lessThanOrEqualTo(
    Tag value0,
    Tag value1
  ) public returns (
    bool result
  ) {
    return value0 <= value1;
  }

  function greaterThanOrEqualTo(
    Tag value0,
    Tag value1
  ) public returns (
    bool result
  ) {
    return value0 >= value1;
  }

  function tag(
    address tokenAddress
  ) public returns (
    Tag tokenTag
  ) {
    return TagLibrary.tag(tokenAddress);
  }

  function tag(
    address tokenAddress,
    uint256 tokenId
  ) public returns (
    Tag tokenTag
  ) {
    return TagLibrary.tag(tokenAddress, tokenId);
  }

  function tag(
    uint256 poolId,
    X59 logPriceMinOffsetted,
    X59 logPriceMaxOffsetted
  ) public returns (
    Tag tokenTag
  ) {
    return TagLibrary.tag(
      poolId,
      logPriceMinOffsetted,
      logPriceMaxOffsetted
    );
  }
}