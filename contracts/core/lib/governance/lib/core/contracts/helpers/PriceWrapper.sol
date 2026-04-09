// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Price.sol";

/// @title This contract exposes the internal functions of 'Price.sol' for 
/// testing purposes.
contract PriceWrapper {
  using PriceLibrary for uint256;

  function storePrice(
    X59 logPrice
  ) public returns (
    X59 logResult,
    X216 sqrtResult,
    X216 sqrtInverseResult
  ) {
    uint256 pricePointer;
    assembly {
      pricePointer := mload(0x40)
      mstore(0x40, add(pricePointer, 64))
    }
    pricePointer.storePrice(logPrice);
    logResult = pricePointer.log();
    sqrtResult = pricePointer.sqrt(false);
    sqrtInverseResult = pricePointer.sqrt(true);
  }

  function storePrice(
    X59 logPrice,
    X216 sqrtPrice,
    X216 sqrtInversePrice
  ) public returns (
    X59 logResult,
    X216 sqrtResult,
    X216 sqrtInverseResult
  ) {
    uint256 pricePointer;
    assembly {
      pricePointer := mload(0x40)
      mstore(0x40, add(pricePointer, 64))
    }
    pricePointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
    logResult = pricePointer.log();
    sqrtResult = pricePointer.sqrt(false);
    sqrtInverseResult = pricePointer.sqrt(true);
  }

  function storePrice(
    X15 heightPrice,
    X59 logPrice,
    X216 sqrtPrice,
    X216 sqrtInversePrice
  ) public returns (
    X15 heightResult,
    X59 logResult,
    X216 sqrtResult,
    X216 sqrtInverseResult
  ) {
    uint256 pricePointer;
    assembly {
      pricePointer := add(mload(0x40), 2)
      mstore(0x40, add(pricePointer, 64))
    }
    pricePointer.storePrice(heightPrice, logPrice, sqrtPrice, sqrtInversePrice);
    heightResult = pricePointer.height();
    logResult = pricePointer.log();
    sqrtResult = pricePointer.sqrt(false);
    sqrtInverseResult = pricePointer.sqrt(true);
  }

  function height(
    X15 value
  ) public returns (
    X15 result
  ) {
    uint256 pricePointer;
    assembly {
      pricePointer := mload(0x40)
      mstore(0x40, add(pricePointer, 64))
      mstore(pricePointer, shl(240, value))
      pricePointer := add(pricePointer, 2)
    }
    result = pricePointer.height();
  }

  function log(
    X59 value
  ) public returns (
    X59 result
  ) {
    uint256 pricePointer;
    assembly {
      pricePointer := mload(0x40)
      mstore(0x40, add(pricePointer, 64))
      mstore(pricePointer, shl(192, value))
    }
    result = pricePointer.log();
  }

  function sqrt(
    X216 value,
    bool inverse
  ) public returns (
    X216 result
  ) {
    uint256 pricePointer;
    assembly {
      pricePointer := mload(0x40)
      mstore(0x40, add(pricePointer, 64))
      mstore(add(pricePointer, add(8, mul(27, inverse))), shl(40, value))
    }
    result = pricePointer.sqrt(inverse);
  }

  function copyPrice(
    X59 logPrice,
    X216 sqrtPrice,
    X216 sqrtInversePrice
  ) public returns (
    X59 logResult,
    X216 sqrtResult,
    X216 sqrtInverseResult
  ) {
    uint256 pricePointer0;
    uint256 pricePointer1;
    assembly {
      pricePointer0 := mload(0x40)
      mstore(0x40, add(pricePointer0, 64))
      pricePointer1 := mload(0x40)
      mstore(0x40, add(pricePointer1, 64))
    }
    pricePointer1.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
    pricePointer0.copyPrice(pricePointer1);
    logResult = pricePointer0.log();
    sqrtResult = pricePointer0.sqrt(false);
    sqrtInverseResult = pricePointer0.sqrt(true);
  }

  function copyPriceWithHeight(
    X15 heightPrice,
    X59 logPrice,
    X216 sqrtPrice,
    X216 sqrtInversePrice
  ) public returns (
    X15 heightResult,
    X59 logResult,
    X216 sqrtResult,
    X216 sqrtInverseResult
  ) {
    uint256 pricePointer0;
    uint256 pricePointer1;
    assembly {
      pricePointer0 := mload(0x40)
      mstore(0x40, add(pricePointer0, 64))
      pricePointer0 := add(pricePointer0, 2)
      pricePointer1 := mload(0x40)
      mstore(0x40, add(pricePointer1, 64))
      mstore(pricePointer1, shl(240, heightPrice))
      pricePointer1 := add(pricePointer1, 2)
    }
    pricePointer1.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
    pricePointer0.copyPriceWithHeight(pricePointer1);
    heightResult = pricePointer0.height();
    logResult = pricePointer0.log();
    sqrtResult = pricePointer0.sqrt(false);
    sqrtInverseResult = pricePointer0.sqrt(true);
  }

  function segment(
    X59 b0,
    X59 b1,
    X15 c0,
    X15 c1
  ) public returns (
    X59 b0Result,
    X59 b1Result,
    X15 c0Result,
    X15 c1Result
  ) {
    uint256 pricePointer;
    assembly {
      pricePointer := mload(0x40)
      mstore(0x40, add(pricePointer, 128))
      mstore(pricePointer, or(shl(240, c0), shl(176, b0)))
      mstore(add(pricePointer, 64), or(shl(240, c1), shl(176, b1)))
      pricePointer := add(pricePointer, 2)
    }
    (b0Result, b1Result, c0Result, c1Result) = pricePointer.segment();
  }
}