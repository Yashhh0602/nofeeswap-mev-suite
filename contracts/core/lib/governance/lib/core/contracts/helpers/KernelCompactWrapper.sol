// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/KernelCompact.sol";
import {_spacing_, setKernel, setKernelLength} from "../utilities/Memory.sol";

/// @title This contract exposes the internal functions of 'KernelCompact.sol'
/// for testing purposes.
contract KernelCompactWrapper {
  using PriceLibrary for uint16;

  function _member(
    KernelCompact kernelCompact,
    uint256 kernelCompactLength,
    uint256[] calldata kernelCompactArray
  ) public {
    X15[] memory height;
    X59[] memory logShift;
    assembly {
      let kernelCompactArrayStart := calldataload(68)
      let kernelCompactArrayLength := calldataload(
        add(4, kernelCompactArrayStart)
      )
      let kernelCompactArrayByteCount := shl(5, kernelCompactArrayLength)

      calldatacopy(
        kernelCompact,
        add(36, kernelCompactArrayStart),
        kernelCompactArrayByteCount
      )

      height := add(kernelCompact, kernelCompactArrayByteCount)
      logShift := add(height, mul(32, add(kernelCompactLength, 1)))

      mstore(height, kernelCompactLength)
      mstore(logShift, kernelCompactLength)

      mstore(0x40, add(logShift, mul(32, add(kernelCompactLength, 1))))
    }

    for (uint256 kk = 0; kk < kernelCompactLength; ++kk) {
      (height[kk], logShift[kk]) = kernelCompact.member(Index.wrap(kk));
    }

    assembly {
      log1(add(height, 32), mul(32, kernelCompactLength), 0)
      log1(add(logShift, 32), mul(32, kernelCompactLength), 1)
    }
  }

  function _expand(
    KernelCompact kernelCompact,
    uint256 kernelCompactLength,
    uint256[] calldata kernelCompactArray
  ) public {
    Kernel kernel;
    assembly {
      let kernelCompactArrayStart := calldataload(68)
      let kernelCompactArrayLength := calldataload(
        add(4, kernelCompactArrayStart)
      )
      let kernelCompactArrayByteCount := shl(5, kernelCompactArrayLength)

      calldatacopy(
        kernelCompact,
        add(36, kernelCompactArrayStart),
        kernelCompactArrayByteCount
      )

      kernel := add(kernelCompact, kernelCompactArrayByteCount)

      mstore(0x40, add(kernel, mul(64, sub(kernelCompactLength, 1))))
    }

    setKernel(kernel);
    setKernelLength(Index.wrap(kernelCompactLength));
    kernelCompact.expand();

    assembly {
      log1(kernel, mul(64, sub(kernelCompactLength, 1)), 0)
    }
  }

  function _validate(
    KernelCompact kernelCompact,
    X59 qSpacing,
    uint256[] calldata kernelCompactArray
  ) public returns (
    Index kernelCompactLength
  ) {
    assembly {
      let kernelCompactArrayStart := calldataload(68)
      let kernelCompactArrayLength := calldataload(
        add(4, kernelCompactArrayStart)
      )
      let kernelCompactArrayByteCount := shl(5, kernelCompactArrayLength)

      calldatacopy(
        kernelCompact,
        add(36, kernelCompactArrayStart),
        kernelCompactArrayByteCount
      )

      mstore(0x40, add(kernelCompact, kernelCompactArrayByteCount))
    }

    _spacing_.storePrice(qSpacing);
    kernelCompact.validate();
    kernelCompactLength = getKernelLength();
  }
}