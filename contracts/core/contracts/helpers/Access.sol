// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {IStorageAccess} from "../interfaces/IStorageAccess.sol";
import {
  _dynamicParams_,
  _staticParams_,
  _endOfStaticParams_,
  _spacing_,
  getTag0,
  getTag1,
  getSqrtOffset,
  getSqrtInverseOffset,
  getOutgoingMax,
  getOutgoingMaxModularInverse,
  getIncomingMax,
  getPoolGrowthPortion,
  getMaxPoolGrowthPortion,
  getProtocolGrowthPortion,
  getPendingKernelLength,
  getStaticParamsStoragePointerExtension,
  getGrowth,
  getIntegral0,
  getIntegral1,
  getSharesTotal,
  getStaticParamsStoragePointer,
  getLogPriceCurrent
} from "../utilities/Memory.sol";
import {
  readStaticParams,
  getStaticParamsStorageAddress,
  readKernelLength,
  readKernel,
  getDynamicParamsSlot,
  getCurveSlot,
  getAccruedParamsSlot,
  getGrowthMultiplierSlot,
  getSharesDeltaSlot,
  protocolSlot,
  sentinelSlot,
  getPoolOwnerSlot,
  getDoubleBalanceSlot,
  getSharesGrossSlot
} from "../utilities/Storage.sol";
import {PriceLibrary} from "../utilities/Price.sol";
import {Kernel} from "../utilities/Kernel.sol";
import {Index} from "../utilities/Index.sol";
import {Tag} from "../utilities/Tag.sol";
import {X23} from "../utilities/X23.sol";
import {X47} from "../utilities/X47.sol";
import {X59} from "../utilities/X59.sol";
import {X111} from "../utilities/X111.sol";
import {X127} from "../utilities/X127.sol";
import {X208} from "../utilities/X208.sol";
import {X216} from "../utilities/X216.sol";

using PriceLibrary for uint16;

/// @title Access
/// @dev This auxiliary contract allows us to fetch pool parameters from
/// nofeeswap contract.
contract Access {
  /// @notice This function reads nofeeswap's protocol slot.
  /// @param nofeeswap 'nofeeswap' contract address
  function _readProtocol(
    IStorageAccess nofeeswap
  ) external view returns (
    uint256 protocol
  ) {
    bytes32 slot = nofeeswap.storageAccess(
      bytes32(protocolSlot)
    );
    assembly {
      protocol := slot
    }
  }

  /// @notice This function reads nofeeswap's sentinel slot.
  /// @param nofeeswap 'nofeeswap' contract address
  function _readSentinel(
    IStorageAccess nofeeswap
  ) external view returns (
    address sentinel
  ) {
    bytes32 slot = nofeeswap.storageAccess(
      bytes32(sentinelSlot)
    );
    assembly {
      sentinel := slot
    }
  }

  /// @notice This function reads a double balance slot from storage.
  function _readDoubleBalance(
    IStorageAccess nofeeswap,
    address owner,
    Tag tag0,
    Tag tag1
  ) external view returns (
    uint256 doubleBalance
  ) {
    bytes32 slot = nofeeswap.storageAccess(
      bytes32(getDoubleBalanceSlot(owner, tag0, tag1))
    );
    assembly {
      doubleBalance := slot
    }
  }

  /// @notice This function reads pool's owner slot from storage.
  /// @param nofeeswap 'nofeeswap' contract address
  /// @param poolId pool identifier
  function _readPoolOwner(
    IStorageAccess nofeeswap,
    uint256 poolId
  ) external view returns (
    address owner
  ) {
    bytes32 slot = nofeeswap.storageAccess(
      bytes32(getPoolOwnerSlot(poolId))
    );
    assembly {
      owner := slot
    }
  }

  /// @notice This function reads pool's accrued growth portions from storage.
  /// @param nofeeswap 'nofeeswap' contract address
  /// @param poolId pool identifier
  /// @return poolRatio0 the ratio of accrued value0 belonging to the pool.
  /// @return poolRatio1 the ratio of accrued value1 belonging to the pool.
  /// @return accrued0 total accrued in tag0 owed to both pool and protocol.
  /// @return accrued1 total accrued in tag1 owed to both pool and protocol.
  function _readAccruedParams(
    IStorageAccess nofeeswap,
    uint256 poolId
  ) external view returns (
    X23 poolRatio0,
    X23 poolRatio1,
    uint256 accrued0,
    uint256 accrued1
  ) {
    bytes32 slot = nofeeswap.storageAccess(
      bytes32(getAccruedParamsSlot(poolId))
    );
    assembly {
      poolRatio0 := and(shr(208, slot), 0xFFFFFF)
      poolRatio1 := shr(232, slot)
      accrued0 := and(slot, 0xFFFFFFFFFFFFFFFFFFFFFFFFFF)
      accrued1 := and(shr(104, slot), 0xFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
  }

  /// @notice This function returns 'growthMultiplier[_logPrice]'.
  /// @param nofeeswap 'nofeeswap' contract address
  /// @param poolId pool identifier
  function _readGrowthMultiplier(
    IStorageAccess nofeeswap,
    uint256 poolId,
    X59 logPrice
  ) external view returns (
    X208 growthMultiplier
  ) {
    bytes32 slot = nofeeswap.storageAccess(
      bytes32(getGrowthMultiplierSlot(poolId, logPrice))
    );
    assembly {
      growthMultiplier := slot
    }
  }

  /// @notice This function returns 'sharesDelta[_logPrice]'.
  /// @param nofeeswap 'nofeeswap' contract address
  /// @param poolId pool identifier
  function _readSharesGross(
    IStorageAccess nofeeswap,
    uint256 poolId
  ) external view returns (
    int256 sharesGross
  ) {
    bytes32 slot = nofeeswap.storageAccess(
      bytes32(getSharesGrossSlot(poolId))
    );
    assembly {
      sharesGross := slot
    }
  }

  /// @notice This function returns 'sharesDelta[_logPrice]'.
  /// @param nofeeswap 'nofeeswap' contract address
  /// @param poolId pool identifier
  function _readSharesDelta(
    IStorageAccess nofeeswap,
    uint256 poolId,
    X59 logPrice
  ) external view returns (
    int256 sharesDelta
  ) {
    bytes32 slot = nofeeswap.storageAccess(
      bytes32(getSharesDeltaSlot(poolId, logPrice))
    );
    assembly {
      sharesDelta := slot
    }
  }

  /// @notice Gives on-chain access to nofeeswap's pools dynamic parameters.
  /// @param nofeeswap 'nofeeswap' contract address
  /// @param poolId pool identifier
  function _readDynamicParams(
    IStorageAccess nofeeswap,
    uint256 poolId
  ) external view returns (
    uint256 staticParamsStoragePointerExtension,
    uint16 staticParamsStoragePointer,
    X59 logPriceCurrent,
    uint256 sharesTotal,
    X111 growth,
    X216 integral0,
    X216 integral1
  ) {
    bytes32 slot = 
      nofeeswap.storageAccess(bytes32(getDynamicParamsSlot(poolId) - 1));
    assembly {
      mstore(_dynamicParams_, slot)
    }

    slot = nofeeswap.storageAccess(bytes32(getDynamicParamsSlot(poolId)));
    assembly {
      mstore(add(_dynamicParams_, 32), slot)
    }

    slot = nofeeswap.storageAccess(bytes32(getDynamicParamsSlot(poolId) + 1));
    assembly {
      mstore(add(_dynamicParams_, 64), slot)
    }

    slot = nofeeswap.storageAccess(bytes32(getDynamicParamsSlot(poolId) + 2));
    assembly {
      mstore(add(_dynamicParams_, 96), slot)
    }

    staticParamsStoragePointerExtension = 
      getStaticParamsStoragePointerExtension();
    staticParamsStoragePointer = getStaticParamsStoragePointer();
    logPriceCurrent = getLogPriceCurrent();
    sharesTotal = getSharesTotal();
    growth = getGrowth();
    integral0 = getIntegral0();
    integral1 = getIntegral1();
  }

  ///// @notice Gives on-chain access to nofeeswap's pools curve.
  ///// @param nofeeswap 'nofeeswap' contract address
  ///// @param poolId pool identifier
  function _readCurve(
    IStorageAccess nofeeswap,
    uint256 poolId,
    X59 logPriceCurrent
  ) external returns (
    uint256[] memory
  ) {
    uint256 curveSlot = getCurveSlot(poolId);
    assembly {
      let length := 1
      let memoryPointer := 0x40
      mstore(0, 0x1352ea35)
      for {} 1 {} {
        mstore(0x20, curveSlot)
        pop(call(gas(), nofeeswap, 0, 0x1C, 0x24, 0x20, 0x20))
        let value := mload(0x20)
        mstore(memoryPointer, value)
        memoryPointer := add(memoryPointer, 0x20)
        let last := and(value, 0xFFFFFFFFFFFFFFFF)
        if eq(last, logPriceCurrent) { break }
        if eq(last, 0) { break }
        length := add(length, 1)
        curveSlot := add(curveSlot, 1)
      }
      mstore(0, 0x20)
      mstore(0x20, length)
      return(0, memoryPointer)
    }
  }

  /// @notice Gives on-chain access to nofeeswap's pools static parameters.
  /// @param nofeeswap 'nofeeswap' contract address
  /// @param poolId pool identifier
  /// @param pointer 'staticParamsStoragePointer' which is listed among dynamic
  /// parameters.
  function _readStaticParams0(
    address nofeeswap,
    uint256 poolId,
    uint256 pointer
  ) external view returns (
    Tag tag0,
    Tag tag1,
    X127 sqrtOffset,
    X127 sqrtInverseOffset,
    X216 sqrtSpacing,
    X216 sqrtInverseSpacing
  ) {
    readStaticParams(
      getStaticParamsStorageAddress(nofeeswap, poolId, pointer)
    );
    tag0 = getTag0();
    tag1 = getTag1();
    sqrtOffset = getSqrtOffset();
    sqrtInverseOffset = getSqrtInverseOffset();
    sqrtSpacing = _spacing_.sqrt(false);
    sqrtInverseSpacing = _spacing_.sqrt(true);
  }

  /// @notice Gives on-chain access to nofeeswap's pools static parameters.
  /// @param nofeeswap 'nofeeswap' contract address
  /// @param poolId pool identifier
  /// @param pointer 'staticParamsStoragePointer' which is listed among dynamic
  /// parameters.
  function _readStaticParams1(
    address nofeeswap,
    uint256 poolId,
    uint256 pointer
  ) external view returns (
    X216 outgoingMax,
    uint256 outgoingMaxModularInverse,
    X216 incomingMax,
    X47 poolGrowthPortion,
    X47 maxPoolGrowthPortion,
    X47 protocolGrowthPortion,
    Index pendingKernelLength
  ) {
    readStaticParams(
      getStaticParamsStorageAddress(nofeeswap, poolId, pointer)
    );
    outgoingMax = getOutgoingMax();
    outgoingMaxModularInverse = getOutgoingMaxModularInverse();
    incomingMax = getIncomingMax();
    poolGrowthPortion = getPoolGrowthPortion();
    maxPoolGrowthPortion = getMaxPoolGrowthPortion();
    protocolGrowthPortion = getProtocolGrowthPortion();
    pendingKernelLength = getPendingKernelLength();
  }

  /// @notice Gives on-chain access to nofeeswap's pools kernel.
  /// @param nofeeswap 'nofeeswap' contract address
  /// @param poolId pool identifier
  /// @param pointer 'staticParamsStoragePointer' which is listed among dynamic
  /// parameters.
  /// @return output kernel array.
  function _readKernel(
    address nofeeswap,
    uint256 poolId,
    uint256 pointer
  ) external view returns (
    uint256[] memory 
  ) {
    address storageAddress = getStaticParamsStorageAddress(
      nofeeswap,
      poolId,
      pointer
    );
    Index length = readKernelLength(storageAddress);
    Kernel kernel;
    assembly {
      kernel := 0x40
    }
    readKernel(
      kernel,
      getStaticParamsStorageAddress(nofeeswap, poolId, pointer),
      length
    );
    assembly {
      mstore(0x00, 0x20)
      mstore(0x20, shl(1, sub(length, 1)))
      return(0, shl(6, length))
    }
  }
}