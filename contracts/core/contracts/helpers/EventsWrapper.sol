// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {ISentinel} from "../interfaces/ISentinel.sol";
import {Tag} from "../utilities/Tag.sol";
import {X59} from "../utilities/X59.sol";
import "../utilities/Events.sol";
import {_hookSelector_} from "../utilities/Memory.sol";
import {INofeeswap} from "../interfaces/INofeeswap.sol";

/// @title This contract exposes the internal functions of 'Events.sol' for 
/// testing purposes.
contract EventsWrapper is INofeeswap {
  function _emitInitializeEvent(
    bytes calldata content
  ) public {
    assembly {
      calldatacopy(_hookSelector_, 68, calldataload(36))
    }
    emitInitializeEvent();
  }

  function _emitModifyPositionEvent(
    bytes calldata content
  ) public {
    assembly {
      calldatacopy(_hookSelector_, 68, calldataload(36))
    }
    emitModifyPositionEvent();
  }

  function _emitDonateEvent(
    bytes calldata content
  ) public {
    assembly {
      calldatacopy(_hookSelector_, 68, calldataload(36))
    }
    emitDonateEvent();
  }

  function _emitSwapEvent(
    bytes calldata content
  ) public {
    assembly {
      calldatacopy(_hookSelector_, 68, calldataload(36))
    }
    emitSwapEvent();
  }

  function _emitModifyKernelEvent(
    bytes calldata content
  ) public {
    assembly {
      calldatacopy(_hookSelector_, 68, calldataload(36))
    }
    emitModifyKernelEvent();
  }

  function _emitModifyPoolGrowthPortionEvent(
    bytes calldata content
  ) public {
    assembly {
      calldatacopy(_hookSelector_, 68, calldataload(36))
    }
    emitModifyPoolGrowthPortionEvent();
  }

  function _emitUpdateGrowthPortionsEvent(
    bytes calldata content
  ) public {
    assembly {
      calldatacopy(_hookSelector_, 68, calldataload(36))
    }
    emitUpdateGrowthPortionsEvent();
  }

  function supportsInterface(
    bytes4 interfaceId
  ) external pure returns (bool) {}

  function balanceOf(
    address owner,
    Tag tag
  ) external view returns (
    uint256 amount
  ) {}

  function allowance(
    address owner,
    address spender,
    Tag tag
  ) external view returns (
    uint256 amount
  ) {}

  function isOperator(
    address owner,
    address spender
  ) external view returns (
    bool status
  ) {}

  function transfer(
    address receiver,
    Tag tag,
    uint256 amount
  ) external returns (
    bool success
  ) {}

  function transferFrom(
    address sender,
    address receiver,
    Tag tag,
    uint256 amount
  ) external returns (
    bool success
  ) {}

  function approve(
    address spender,
    Tag tag,
    uint256 amount
  ) external returns (
    bool success
  ) {}

  function setOperator(
    address spender,
    bool approved
  ) external returns (
    bool success
  ) {}

  function modifyBalance(
    address owner,
    Tag tag,
    int256 amount
  ) external {}

  function modifyBalance(
    address owner,
    Tag tag0,
    Tag tag1,
    int256 amount0,
    int256 amount1
  ) external {}

  function unlock(
    address unlockTarget,
    bytes calldata data
  ) external payable returns (
    bytes memory result
  ) {}

  function clear(
    Tag tag,
    uint256 amount
  ) external {}

  function take(
    address token,
    address to,
    uint256 amount
  ) external {}

  function take(
    address token,
    uint256 tokenId,
    address to,
    uint256 amount
  ) external {}

  function take(
    address token,
    uint256 tokenId,
    address to,
    uint256 amount,
    bytes calldata transferData
  ) external {}

  function sync(
    address token
  ) external {}

  function sync(
    address token,
    uint256 tokenId
  ) external {}

  function settle() external payable returns (
    uint256 paid
  ) {}

  function transferTransientBalanceFrom(
    address sender,
    address receiver,
    Tag tag,
    uint256 amount
  ) external {}

  function dispatch(
    bytes calldata input
  ) external returns (
    int256 output0,
    int256 output1
  ) {}

  function swap(
    uint256 poolId,
    int256 amountSpecified,
    X59 logPriceLimit,
    uint256 zeroForOne,
    bytes calldata hookData
  ) external returns (
    int256 amount0,
    int256 amount1
  ) {}

  function storageAccess(
    bytes32 slot
  ) external view override returns (bytes32) {}

  function storageAccess(
    bytes32 startSlot,
    uint256 nSlots
  ) external view override returns (bytes32[] memory) {}

  function storageAccess(
    bytes32[] calldata slots
  ) external view override returns (bytes32[] memory) {}

  function transientAccess(
    bytes32 slot
  ) external view override returns (bytes32) {}

  function transientAccess(
    bytes32 startSlot,
    uint256 nSlots
  ) external view override returns (bytes32[] memory) {}

  function transientAccess(
    bytes32[] calldata slots
  ) external view override returns (bytes32[] memory) {}
}