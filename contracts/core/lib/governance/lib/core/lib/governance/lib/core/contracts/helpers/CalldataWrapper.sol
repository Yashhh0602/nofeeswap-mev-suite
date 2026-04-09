// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Calldata.sol";
import {
  getFreeMemoryPointer,
  getHookInputByteCount,
  _hookInputByteCount_
} from "../utilities/Memory.sol";
import {writeStorage} from "../utilities/Storage.sol";

/// @title This contract exposes the internal functions of 'Calldata.sol' for 
/// testing purposes.
contract CalldataWrapper {
  function _readInitializeInput() public returns (
    KernelCompact kernelCompact
  ) {
    kernelCompact = readInitializeInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readModifyPositionInput() public {
    readModifyPositionInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readDonateInput() public {
    readDonateInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readModifyKernelInput() public returns (
    KernelCompact kernelCompact
  ) {
    kernelCompact = readModifyKernelInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readModifyPoolGrowthPortionInput() public {
    readModifyPoolGrowthPortionInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readUpdateGrowthPortionsInput() public {
    readUpdateGrowthPortionsInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readSwapInput() public {
    readSwapInput();
    uint256 hookInputByteCount = getHookInputByteCount();
    assembly {
      log1(
        0,
        add(add(_hookInputByteCount_, hookInputByteCount), 32),
        0
      )
    }
  }

  function _readCollectInput() public {
    readCollectInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }
}