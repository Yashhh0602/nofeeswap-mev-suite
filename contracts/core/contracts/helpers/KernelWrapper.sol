// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Kernel.sol";

/// @title This contract exposes the internal functions of 'Kernel.sol' for 
/// testing purposes.
contract KernelWrapper {
  function _member(
    Kernel kernel,
    uint256[] calldata kernelArray
  ) public {
    uint256 kernelLength;
    X15[] memory height;
    X59[] memory logShift;
    X216[] memory sqrtShift;
    X216[] memory sqrtInverseShift;
    assembly {
      let kernelArrayStart := calldataload(36)
      let kernelArrayLength := calldataload(add(4, kernelArrayStart))
      let kernelArrayByteCount := shl(5, kernelArrayLength)

      calldatacopy(
        kernel,
        add(36, kernelArrayStart),
        kernelArrayByteCount
      )

      kernelLength := add(div(kernelArrayLength, 2), 1)

      height := add(kernel, kernelArrayByteCount)
      logShift := add(height, mul(32, add(kernelLength, 1)))
      sqrtShift := add(logShift, mul(32, add(kernelLength, 1)))
      sqrtInverseShift := add(sqrtShift, mul(32, add(kernelLength, 1)))

      mstore(height, kernelLength)
      mstore(logShift, kernelLength)
      mstore(sqrtShift, kernelLength)
      mstore(sqrtInverseShift, kernelLength)

      mstore(0x40, add(sqrtInverseShift, mul(32, add(kernelLength, 1))))
    }

    for (uint256 kk = 0; kk < kernelLength; ++kk) {
      (
        height[kk],
        logShift[kk],
        sqrtShift[kk],
        sqrtInverseShift[kk]
      ) = kernel.member(Index.wrap(kk));
    }

    assembly {
      log1(add(height, 32), mul(32, kernelLength), 0)
      log1(add(logShift, 32), mul(32, kernelLength), 1)
      log1(add(sqrtShift, 32), mul(32, kernelLength), 2)
      log1(add(sqrtInverseShift, 32), mul(32, kernelLength), 3)
    }
  }

  function _impose(
    Kernel kernel,
    uint256 resultant,
    uint256 basePrice,
    Index index,
    bool left,
    uint256 memberContent0,
    uint256 memberContent1,
    uint256 basePriceContent0,
    uint256 basePriceContent1
  ) public returns (
    uint256 resultantContent0,
    uint256 resultantContent1
  ) {
    assembly {
      mstore(sub(basePrice, 2), basePriceContent0)
      mstore(add(basePrice, 30), basePriceContent1)

      let pointer := add(kernel, sub(shl(6, index), 62))
      mstore(sub(pointer, 2), memberContent0)
      mstore(add(pointer, 30), memberContent1)
    }

    kernel.impose(resultant, basePrice, index, left);

    assembly {
      resultantContent0 := mload(sub(resultant, 2))
      resultantContent1 := mload(add(resultant, 30))
    }
  }
}