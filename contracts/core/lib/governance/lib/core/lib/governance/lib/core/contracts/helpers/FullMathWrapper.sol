// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import '../utilities/FullMath.sol';

/// @title This contract exposes the functions of 'FullMath.sol' for testing
/// purposes.
contract FullMathWrapper {
  function add512(
    uint256 a0,
    uint256 a1,
    uint256 b0,
    uint256 b1
  ) public returns (
    uint256 r0,
    uint256 r1
  ) {
    return FullMathLibrary.add512(a0, a1, b0, b1);
  }

  function sub512(
    uint256 a0,
    uint256 a1,
    uint256 b0,
    uint256 b1
  ) public returns (
    uint256 r0,
    uint256 r1
  ) {
    return FullMathLibrary.sub512(a0, a1, b0, b1);
  }

  function mul512(
    uint256 a,
    uint256 b
  ) public returns (
    uint256 prod0, 
    uint256 prod1
  ) {
    return FullMathLibrary.mul512(a, b);
  }

  function cheapMulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) public returns (
    uint256 result
  ) {
    return FullMathLibrary.cheapMulDiv(a, b, denominator);
  }

  function modularInverse(
    uint256 value
  ) public returns (
    uint256 inverse
  ) {
    return FullMathLibrary.modularInverse(value);
  }

  function mul768(
    uint256 a,
    uint256 b,
    uint256 c
  ) public returns (
    uint256 q0,
    uint256 q1,
    uint256 q2
  ) {
    return FullMathLibrary.mul768(a, b, c);
  }

  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 c,
    uint256 d,
    bool roundUp
  ) public returns (
    uint256 result
  ) {
    return FullMathLibrary.mulDiv(a, b, c, d, roundUp);
  }

  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 c,
    uint256 d,
    uint256 e,
    bool roundUp
  ) public returns (
    uint256 result,
    bool overflow
  ) {
    return FullMathLibrary.mulDiv(a, b, c, d, e, roundUp);
  }

  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) public returns (
    uint256 result
  ) {
    return FullMathLibrary.mulDiv(a, b, denominator);
  }

  function mulDivRoundUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) public returns (
    uint256 result
  ) {
    return FullMathLibrary.mulDivRoundUp(a, b, denominator);
  }

  function safeMulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) public returns (
    uint256 result
  ) {
    return FullMathLibrary.safeMulDiv(a, b, denominator);
  }

  function safeMulDivRoundUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) public returns (
    uint256 result
  ) {
    return FullMathLibrary.safeMulDivRoundUp(a, b, denominator);
  }
}