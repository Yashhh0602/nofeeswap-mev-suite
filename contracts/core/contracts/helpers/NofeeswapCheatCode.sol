// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {Nofeeswap} from '../Nofeeswap.sol';
import {Index} from '../utilities/Index.sol';
import {
  _staticParams_,
  setPoolId,
  setKernelLength
} from '../utilities/Memory.sol';
import {writeStaticParams} from '../utilities/Storage.sol';

/// @title These contracts allows manipulation of 'Nofeeswap.sol' storage for 
/// testing purposes.
contract NofeeswapCheatCode is Nofeeswap {
  constructor(
    address _delegatee,
    address admin
  ) Nofeeswap(_delegatee, admin) {}

  function callManipulator(
    address manipulator,
    bytes calldata input
  ) external {
    assembly {
      let callDataCopySize := calldataload(68)
      calldatacopy(0, 100, callDataCopySize)
      pop(delegatecall(gas(), manipulator, 0, callDataCopySize, 0, 0))
    }
  }
}

contract Manipulator {
  function manipulate(
    bytes32 slot,
    bytes32 content
  ) external {
    assembly ("memory-safe") {
      sstore(slot, content)
    }
  }

  function deploy(
    uint256 poolId,
    Index kernelLength,
    uint256 storagePointer,
    bytes calldata content
  ) external {
    setPoolId(poolId);
    setKernelLength(kernelLength);
    assembly {
      calldatacopy(
        _staticParams_,
        add(36, calldataload(100)),
        calldataload(add(4, calldataload(100)))
      )
    }
    writeStaticParams(storagePointer);
  }
}