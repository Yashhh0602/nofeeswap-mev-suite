// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X59} from "@core/utilities/X59.sol";
import {X127} from "@core/utilities/X127.sol";

/// @title This contract plays the role of a quoter contract for testing
/// purposes.
contract MockQuoter {
  function swap(
    uint256 poolId,
    int256 amountSpecified,
    X59 logPriceLimit,
    uint256 zeroForOne,
    bytes calldata hookData
  ) external returns (
    X127 amount0,
    X127 amount1
  ) {
    assembly {
      calldatacopy(128, 0, calldatasize())
      amount0 := keccak256(128, calldatasize())
    }
    amount1 = X127.wrap(int256(type(uint256).max));
  }

  function modifyPosition(
    uint256 poolId,
    X59 logPriceMin,
    X59 logPriceMax,
    int256 shares,
    bytes calldata hookData
  ) external returns (
    X127 amount0,
    X127 amount1
  ) {
    assembly {
      calldatacopy(128, 0, calldatasize())
      amount0 := keccak256(128, calldatasize())
    }
    amount1 = X127.wrap(int256(type(uint256).max));
  }

  function donate(
    uint256 poolId,
    uint256 shares,
    bytes calldata hookData
  ) external returns (
    X127 amount0,
    X127 amount1
  ) {
    assembly {
      calldatacopy(128, 0, calldatasize())
      amount0 := keccak256(128, calldatasize())
    }
    amount1 = X127.wrap(int256(type(uint256).max));
  }

  function transientAccess(
    bytes32 slot
  ) external view returns (bytes32 result) {
    assembly {
      mstore(0, slot)
      result := keccak256(0, 32)
    }
  }
}