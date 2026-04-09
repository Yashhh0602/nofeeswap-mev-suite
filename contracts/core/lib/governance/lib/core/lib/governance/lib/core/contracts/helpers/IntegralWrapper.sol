// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Integral.sol";

/// @title This contract exposes the internal functions of 'Integral.sol' for 
/// testing purposes.
contract IntegralWrapper {
  using IntegralLibrary for X216;
  using IntegralLibrary for uint256;
  using PriceLibrary for uint256;

  function shift(
    X216 integralValue,
    X59 logPrice0,
    X59 logPrice1,
    bool left
  ) public returns (
    X216 result
  ) {
    uint256 pointer0;
    uint256 pointer1;
    assembly {
      pointer0 := mload(0x40)
      mstore(0x40, add(pointer0, 124))
      pointer1 := add(pointer0, 62)
    }
    pointer0.storePrice(logPrice0);
    pointer1.storePrice(logPrice1);
    return integralValue.shift(pointer0, pointer1, left);
  }

  function integral(
    X216 integralValue
  ) public returns (
    X216 result
  ) {
    uint256 pointer;
    assembly {
      pointer := mload(0x40)
      mstore(0x40, add(pointer, 32))
      mstore(pointer, shl(40, integralValue))
    }
    result = pointer.integral();
  }

  function setIntegral(
    X216 integralValue
  ) public returns (
    X216 result
  ) {
    uint256 pointer;
    assembly {
      pointer := mload(0x40)
      mstore(0x40, add(pointer, 32))
      mstore(pointer, shl(40, integralValue))
    }
    pointer.setIntegral(integralValue);
    result = pointer.integral();
  }

  function incrementIntegral(
    X216 integralValue,
    X216 increment
  ) public returns (
    X216 result
  ) {
    uint256 pointer;
    assembly {
      pointer := mload(0x40)
      mstore(0x40, add(pointer, 32))
      mstore(pointer, shl(40, integralValue))
    }
    pointer.incrementIntegral(increment);
    result = pointer.integral();
  }

  function decrementIntegral(
    X216 integralValue,
    X216 decrement
  ) public returns (
    X216 result
  ) {
    uint256 pointer;
    assembly {
      pointer := mload(0x40)
      mstore(0x40, add(pointer, 32))
      mstore(pointer, shl(40, integralValue))
    }
    pointer.decrementIntegral(decrement);
    result = pointer.integral();
  }

  function evaluate(
    X59 b0,
    X59 b1,
    X15 c0,
    X15 c1,
    X59 target
  ) public returns (
    X216 result
  ) {
    uint256 pointer;
    assembly {
      pointer := mload(0x40)
      mstore(0x40, add(pointer, 128))
      mstore(pointer, add(shl(240, c0), shl(176, b0)))
      mstore(add(pointer, 64), add(shl(240, c1), shl(176, b1)))
      pointer := add(pointer, 2)
    }
    (X216 chunk0, X216 chunk1) = target.exp();
    uint256 pricePointer;
    assembly {
      pricePointer := mload(0x40)
      mstore(0x40, add(pricePointer, 64))
      chunk1 := add(shl(216, chunk0), chunk1)
      chunk0 := add(shl(192, target), shr(24, chunk0))
      mstore(pricePointer, chunk0)
      mstore(add(pricePointer, 30), chunk1)
    }
    result = pointer.evaluate(pricePointer);
  }

  function outgoing(
    X59 b0,
    X59 b1,
    X15 c0,
    X15 c1,
    X59 from,
    X59 to
  ) public returns (
    X216 result
  ) {
    uint256 pointer;
    assembly {
      pointer := mload(0x40)
      mstore(0x40, add(pointer, 128))
      mstore(pointer, add(shl(240, c0), shl(176, b0)))
      mstore(add(pointer, 64), add(shl(240, c1), shl(176, b1)))
      pointer := add(pointer, 2)
    }

    uint256 fromPointer;
    (X216 chunk0, X216 chunk1) = from.exp();
    assembly {
      fromPointer := mload(0x40)
      mstore(0x40, add(fromPointer, 64))
      chunk1 := add(shl(216, chunk0), chunk1)
      chunk0 := add(shl(192, from), shr(24, chunk0))
      mstore(fromPointer, chunk0)
      mstore(add(fromPointer, 30), chunk1)
    }

    uint256 toPointer;
    (chunk0, chunk1) = to.exp();
    assembly {
      toPointer := mload(0x40)
      mstore(0x40, add(toPointer, 64))
      chunk1 := add(shl(216, chunk0), chunk1)
      chunk0 := add(shl(192, to), shr(24, chunk0))
      mstore(toPointer, chunk0)
      mstore(add(toPointer, 30), chunk1)
    }
    
    result = pointer.outgoing(fromPointer, toPointer);
  }

  function incoming(
    X59 b0,
    X59 b1,
    X15 c0,
    X15 c1,
    X59 from,
    X59 to
  ) public returns (
    X216 result
  ) {
    uint256 pointer;
    assembly {
      pointer := mload(0x40)
      mstore(0x40, add(pointer, 128))
      mstore(pointer, add(shl(240, c0), shl(176, b0)))
      mstore(add(pointer, 64), add(shl(240, c1), shl(176, b1)))
      pointer := add(pointer, 2)
    }

    uint256 fromPointer;
    (X216 chunk0, X216 chunk1) = from.exp();
    assembly {
      fromPointer := mload(0x40)
      mstore(0x40, add(fromPointer, 64))
      chunk1 := add(shl(216, chunk0), chunk1)
      chunk0 := add(shl(192, from), shr(24, chunk0))
      mstore(fromPointer, chunk0)
      mstore(add(fromPointer, 30), chunk1)
    }

    uint256 toPointer;
    (chunk0, chunk1) = to.exp();
    assembly {
      toPointer := mload(0x40)
      mstore(0x40, add(toPointer, 64))
      chunk1 := add(shl(216, chunk0), chunk1)
      chunk0 := add(shl(192, to), shr(24, chunk0))
      mstore(toPointer, chunk0)
      mstore(add(toPointer, 30), chunk1)
    }
    
    result = pointer.incoming(fromPointer, toPointer);
  }
}