// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

/// @dev Nofeeswap's storage layout.

import {
  _hookInputByteCount_,
  _dynamicParams_,
  _staticParams_,
  _endOfStaticParams_,
  _deploymentCreationCode_,
  _spacing_,
  getPoolId,
  getPoolRatio0,
  getPoolRatio1,
  getAccrued0,
  getAccrued1,
  getShares,
  getLogPriceMinOffsetted,
  getLogPriceMaxOffsetted,
  getGrowth,
  getStaticParamsStoragePointer,
  getStaticParamsStoragePointerExtension,
  getCurve,
  getCurveLength,
  getLogPriceCurrent,
  getKernelLength,
  getKernel,
  getPoolGrowthPortion,
  getMaxPoolGrowthPortion,
  getPendingKernelLength,
  setMaxPoolGrowthPortion,
  setProtocolGrowthPortion,
  setPoolRatio0,
  setPoolRatio1,
  setAccrued0,
  setAccrued1,
  setStaticParamsStoragePointer,
  setStaticParamsStoragePointerExtension,
  setCurveLength,
  setDeploymentCreationCode,
  setKernelLength,
  setPoolGrowthPortion,
  setCurve,
  setFreeMemoryPointer,
  setHookInputByteCount
} from "./Memory.sol";
import {ISentinel} from "../interfaces/ISentinel.sol";
import {invokeSentinelGetGrowthPortions} from "./SentinelCalls.sol";
import {PriceLibrary} from "./Price.sol";
import {Curve} from "./Curve.sol";
import {Kernel} from "./Kernel.sol";
import {Index, zeroIndex, oneIndex, twoIndex, max} from "./Index.sol";
import {Tag} from "./Tag.sol";
import {X23} from "./X23.sol";
import {X47, oneX47, min} from "./X47.sol";
import {X59} from "./X59.sol";
import {zeroX111} from "./X111.sol";
import {X127, zeroX127, accruedMax} from "./X127.sol";
import {X208, zeroX208, exp8X208} from "./X208.sol";
import {X216, oneX216} from "./X216.sol";
import {emitTransferEvent} from "./Events.sol";
import {
  InsufficientPermission,
  AccruedGrowthPortionOverflow,
  SharesGrossOverflow,
  PoolDoesNotExist,
  DeploymentFailed,
  BalanceOverflow,
  InsufficientBalance
} from "./Errors.sol";

using PriceLibrary for uint16;

/// @notice Writes a single slot on storage.
/// @param storageSlot the slot to be populated.
/// @param value the content.
function writeStorage(uint256 storageSlot, uint256 value) {
  assembly {
    sstore(storageSlot, value)
  }
}

/// @notice Reads a single slot from storage.
/// @param storageSlot the slot to be read.
/// @return value the content.
function readStorage(uint256 storageSlot) view returns (uint256 value) {
  assembly {
    value := sload(storageSlot)
  }
}

/////////////////////////////////////////////////// Protocol and Sentinel slots

// uint256(keccak256("protocol")) - 1
uint256 constant protocolSlot = 
  0xFB342FA999FEA16067B1F01BAF96673F31A25F2B1443E6754D93FC40B57E8DF1;

// uint256(keccak256("sentinel")) - 1
uint256 constant sentinelSlot = 
  0xD0716769B9821201D69D150FACFD6F46F5FD95AC252F6ECCB21B7560A01E078B;

/// @notice Writes 'maxPoolGrowthPortion', 'protocolGrowthPortion', and 
/// protocol's owner in one storage slot.
/// @param protocol the content to be written on 'protocolSlot', i.e.,
///
///   'protocol == (
///      (X47.unwrap(maxPoolGrowthPortion) << 208) | 
///      (X47.unwrap(protocolGrowthPortion) << 160) | 
///      uint256(uint160(owner))
///    )'.
///
function writeProtocol(uint256 protocol) {
  writeStorage(protocolSlot, protocol);
}

/// @notice Reads the content of protocol's slot.
/// @return protocol The content of protocol's slot.
function readProtocol() view returns (
  uint256 protocol
) {
  return readStorage(protocolSlot);
}

/// @notice Determines protocol's owner from the content of protocol's slot.
/// @param protocol The content of protocol's slot.
/// @return protocolOwner The protocol owner.
function getProtocolOwner(
  uint256 protocol
) pure returns (
  address protocolOwner
) {
  //
  //            6 bytes                 6 bytes             20 bytes
  //    +----------------------+-----------------------+---------------+
  //    | maxPoolGrowthPortion | protocolGrowthPortion | protocolOwner |
  //    +----------------------+-----------------------+---------------+
  //
  return address(uint160(protocol));
}

/// @notice Determines 'maxPoolGrowthPortion' and 'protocolGrowthPortion' from
/// the content of protocol's slot.
/// @param protocol The content of protocol's slot.
/// @return maxPoolGrowthPortion This value imposes a cap on the portion of the
/// marginal growth that goes to the pool owner followed by the protocol.
/// @return protocolGrowthPortion This value dictates the portion of the growth
/// that goes to the protocol.
function getGrowthPortions(
  uint256 protocol
) pure returns (
  X47 maxPoolGrowthPortion,
  X47 protocolGrowthPortion
) {
  //
  //            6 bytes                 6 bytes             20 bytes
  //    +----------------------+-----------------------+---------------+
  //    | maxPoolGrowthPortion | protocolGrowthPortion | protocolOwner |
  //    +----------------------+-----------------------+---------------+
  //
  assembly {
    maxPoolGrowthPortion := shr(208, protocol)
    protocolGrowthPortion := and(shr(160, protocol), 0xFFFFFFFFFFFF)
  }
}

/// @notice Populates the Sentinel slot.
/// @param sentinel The Sentinel contract to be written on storage.
function writeSentinel(ISentinel sentinel) {
  assembly {
    sstore(sentinelSlot, sentinel)
  }
}

/// @notice Reads the Sentinel slot.
/// @return sentinel The Sentinel contract read from storage.
function readSentinel() view returns (ISentinel sentinel) {
  assembly {
    sentinel := sload(sentinelSlot)
  }
}

/// @notice This function reads 'maxPoolGrowthPortion' and 
/// 'protocolGrowthPortion' from the Sentinel contract or the protocol slot. The
/// Sentinel contract provides the growth portions based on a snapshot of the
/// memory. If the portions are not set for that pool at Sentinel, it returns 
/// an infeasible response larger than 'oneX47' and then the default value from
/// the protocol slot is read.
function readGrowthPortions() {
  // First, the Sentinel contract is invoked (it it exists).
  (
    X47 maxPoolGrowthPortion,
    X47 protocolGrowthPortion
  ) = invokeSentinelGetGrowthPortions();

  // If any of the two given values are infeasible, then the protocol slot is
  // read and the resulting values from the Sentinel contract are overwritten.
  if (maxPoolGrowthPortion > oneX47 || protocolGrowthPortion > oneX47) {
    // 'maxPoolGrowthPortionProtocol' and 'protocolGrowthPortionProtocol' are
    // read from the protocol slot.
    (
      X47 maxPoolGrowthPortionProtocol,
      X47 protocolGrowthPortionProtocol
    ) = getGrowthPortions(readProtocol());

    // If 'maxPoolGrowthPortion' from the Sentinel contract is infeasible, then
    // 'maxPoolGrowthPortionProtocol' is chosen.
    if (maxPoolGrowthPortion > oneX47) {
      maxPoolGrowthPortion = maxPoolGrowthPortionProtocol;
    }

    // If 'protocolGrowthPortion' from the Sentinel contract is infeasible,
    // then 'protocolGrowthPortionProtocol' is chosen.
    if (protocolGrowthPortion > oneX47) {
      protocolGrowthPortion = protocolGrowthPortionProtocol;
    }
  }

  // The resulting growth portions are set in memory.
  setMaxPoolGrowthPortion(maxPoolGrowthPortion);
  setProtocolGrowthPortion(protocolGrowthPortion);
}

////////////////////////////////////////////////////////// Single balance slots

// uint96(uint256(keccak256("singleBalance"))) - 1
uint96 constant singleBalanceSlot = 0x3C244899B5FA3E971383AC4B;

/// @notice This function returns the storage slot referring to
/// 'balanceOf(owner, tag)'.
/// @param owner Balance owner.
/// @param tag The corresponding tag.
/// @return storageSlot The storage slot containing 'balanceOf(owner, tag)'.
function getSingleBalanceSlot(
  address owner,
  Tag tag
) pure returns (
  uint256 storageSlot
) {
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //    0                               32          52                  64
    //    |                               |           |                   |
    //    +-------------------------------+-----------+-------------------+
    //    |              tag              |   owner   | singleBalanceSlot |
    //    +-------------------------------+-----------+-------------------+
    //

    // Populates the least significant 12 bytes of the memory slot 1 (from 52
    // to 64).
    mstore(32, singleBalanceSlot) // 32 = 64 - 32

    // Populates the most significant 20 bytes of the memory slot 1 (from 32 to
    // 52).
    mstore(20, owner) // 20 = 52 - 32

    // Populates the entire memory slot 0.
    mstore(0, tag) // 0 = 32 - 32

    // Calculates the resulting hash.
    storageSlot := keccak256(0, 64)
  }
}

/// @notice Increments a single balance slot.
///
/// 'amount' should be less than '2 ** 255'.
///
/// @param owner Balance owner.
/// @param tag The corresponding tag.
/// @param amount The increment amount.
function incrementBalance(
  address owner,
  Tag tag,
  uint256 amount
) {
  uint256 storageSlot = getSingleBalanceSlot(owner, tag);
  unchecked {
    // The addition is safe, because the current content of the 'storageSlot'
    // does not exceed 'type(uint128).max' and 'amount < 2 ** 255'.
    uint256 newBalance = readStorage(storageSlot) + amount;
    require(newBalance <= type(uint128).max, BalanceOverflow(newBalance));
    writeStorage(storageSlot, newBalance);
  }
  emitTransferEvent(msg.sender, address(0), owner, tag, amount);
}

/// @notice Decrements a single balance slot.
///
/// @param owner Balance owner.
/// @param tag The corresponding tag.
/// @param absoluteValue The decrement amount.
function decrementBalance(
  address owner,
  Tag tag,
  uint256 absoluteValue
) {
  uint256 storageSlot = getSingleBalanceSlot(owner, tag);
  uint256 balance = readStorage(storageSlot);
  updateAllowance(owner, tag, absoluteValue);
  require(balance >= absoluteValue, InsufficientBalance(owner, tag));
  unchecked {
    // The subtraction is safe due to the prior check.
    writeStorage(storageSlot, balance - absoluteValue);
  }
  emitTransferEvent(msg.sender, owner, address(0), tag, absoluteValue);
}

////////////////////////////////////////////////////////// Double balance slots

// uint96(uint256(keccak256("doubleBalance"))) - 1
uint96 constant doubleBalanceSlot = 0xC8F78086C3211E71A328E7F5;

/// @notice This function returns the storage slot pointing to owner's double
/// balance of tags 0 and 1. This storage slot contains a balance for both
/// tokens which can be used to save gas.
///
/// @param owner Balance owner.
/// @param tag0 The corresponding tag0.
/// @param tag1 The corresponding tag1.
/// @return storageSlot The storage slot containing the double balance of
/// 'tag0' and 'tag1'.
function getDoubleBalanceSlot(
  address owner,
  Tag tag0,
  Tag tag1
) pure returns (uint256 storageSlot) {
  assembly {
    // We populate the first three memory slots from right to left:
    //
    //    0              32             64              84                  96
    //    |              |              |               |                   |
    //    +--------------+--------------+---------------+-------------------+
    //    |     tag0     |     tag1     |     owner     | doubleBalanceSlot |
    //    +--------------+--------------+---------------+-------------------+
    //
    let freeMemoryPointer := mload(0x40)
    mstore(64, doubleBalanceSlot) // 64 = 96 - 32
    mstore(52, owner) // 52 = 84 - 32
    mstore(32, tag1) // 32 = 64 - 32
    mstore(0, tag0) // 32 = 32 - 32
    storageSlot := keccak256(0, 96)
    mstore(0x40, freeMemoryPointer)
  }
}

/// @notice This function returns the content of the double balance slot which
/// is pointed to by 'storageSlot'.
///
/// @param storageSlot The storage slot containing the double balance of 'tag0'
/// and 'tag1'.
/// @return amount0 The amount of tag0.
/// @return amount1 The amount of tag1.
function readDoubleBalance(
  uint256 storageSlot
) view returns (
  uint256 amount0,
  uint256 amount1
) {
  uint256 pairBalance = readStorage(storageSlot);
  assembly {
    amount0 := and(pairBalance, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    amount1 := shr(128, pairBalance)
  }
}

/// @notice This function populates the double balance slot which is pointed to
/// by 'storageSlot'.
///
/// @param storageSlot The storage slot to be populated.
/// @param amount0 The amount of tag0.
/// @param amount1 The amount of tag1.
function writeDoubleBalance(
  uint256 storageSlot,
  uint256 amount0,
  uint256 amount1
) {
  require(amount0 <= type(uint128).max, BalanceOverflow(amount0));
  require(amount1 <= type(uint128).max, BalanceOverflow(amount1));
  writeStorage(storageSlot, (amount1 << 128) | amount0);
}

///////////////////////////////////////////////////////// LP total supply slots

// uint128(uint256(keccak256("totalSupply"))) - 1
uint128 constant totalSupplySlot = 0x5daca5ccc655360fa5ccacf9c267936c;

/// @notice This function increments/decrements total supply associated with
/// LP positions.
///
/// @param poolId The pool identifier hosting this liquidity position.
/// @param qMin Equal to '(2 ** 59) * (16 + log(pMin / pOffset))'.
/// @param qMax Equal to '(2 ** 59) * (16 + log(pMax / pOffset))'.
/// @param shares The number of shares to be added/subtracted.
function updateTotalSupply(
  uint256 poolId,
  X59 qMin,
  X59 qMax,
  int256 shares
) {
  // We populate the first two memory slots from right to left:
  //
  //    0        32     40     48                64
  //    |        |      |      |                 |
  //    +--------+------+------+-----------------+
  //    | poolId | qMin | qMax | totalSupplySlot |
  //    +--------+------+------+-----------------+
  //
  uint256 storageSlot;
  assembly {
    mstore(32, totalSupplySlot) // 32 = 64 - 32
    mstore(16, qMax) // 16 = 48 - 32
    mstore(8, qMin) // 8 = 40 - 32
    mstore(0, poolId) // 0 = 32 - 32
    storageSlot := keccak256(0, 64)
  }
  uint256 totalSupply = readStorage(storageSlot);
  assembly {
    totalSupply := add(totalSupply, shares)
  }
  require(totalSupply <= type(uint128).max, BalanceOverflow(totalSupply));
  writeStorage(storageSlot, totalSupply);
}

//////////////////////////////////////////////////////////////// Operator slots

// uint96(uint256(keccak256("isOperator"))) - 1
uint96 constant isOperatorSlot = 0xE442B523D9447037E4923F5B;

/// @notice This function returns the storage slot referring to
/// 'isOperator(owner, spender)'.
///
/// @param owner Balance owner.
/// @param spender The spender whose allowance to be read.
/// @return storageSlot The storage slot which records whether the 'spender'
/// is an operator for the 'owner' or not.
function getIsOperatorSlot(
  address owner,
  address spender
) pure returns (uint256 storageSlot) {
  // We populate the first two memory slots from right to left:
  //
  //    12              32              52               64
  //    |               |               |                |
  //    +---------------+---------------+----------------+
  //    |    spender    |     owner     | isOperatorSlot |
  //    +---------------+---------------+----------------+
  //
  assembly {
    mstore(32, isOperatorSlot) // 32 = 64 - 32
    mstore(20, owner) // 20 = 52 - 32
    mstore(0, spender) // 0 = 32 - 32
    storageSlot := keccak256(12, 52) // 52 = 64 - 12
  }
}

/////////////////////////////////////////////////////////////// Allowance slots

// uint96(uint256(keccak256("allowance"))) - 1
uint96 constant allowanceSlot = 0x34105B980BA117BD0C29FE0;

/// @notice This function returns the storage slot pointing to
/// 'allowance(owner, spender, tag)'.
///
/// @param owner Balance owner.
/// @param spender The spender whose allowance to be read.
/// @param tag The corresponding tag.
/// @return storageSlot The storage slot to be calculated.
function getAllowanceSlot(
  address owner,
  address spender,
  Tag tag
) pure returns (
  uint256 storageSlot
) {
  // We populate the first three memory slots from right to left:
  //
  //    0             32              52              72              84
  //    |             |               |               |               |
  //    +-------------+---------------+---------------+---------------+
  //    |     tag     |    spender    |     owner     | allowanceSlot |
  //    +-------------+---------------+---------------+---------------+
  //
  assembly {
    let freeMemoryPointer := mload(0x40)
    mstore(52, allowanceSlot) // 52 = 84 - 32
    mstore(40, owner) // 40 = 72 - 32
    mstore(20, spender) // 20 = 52 - 32
    mstore(0, tag) // 0 = 32 - 32
    storageSlot := keccak256(0, 84)
    mstore(0x40, freeMemoryPointer)
  }
}

/// @notice This function updates ERC-6909 allowance after each expenditure
/// performed by a spender.
///
/// @param owner Balance owner.
/// @param tag The corresponding tag.
/// @param amount The amount to be decremented from allowance.
function updateAllowance(
  address owner,
  Tag tag,
  uint256 amount
) {
  // If 'owner' is equal to 'spender', then we do not need to decrement any
  // allowance value.
  if (owner != msg.sender) {
    // If 'owner' is the operator, then we do not need to decrement any
    // allowance value either.
    if (readStorage(getIsOperatorSlot(owner, msg.sender)) == 0) {
      uint256 storageSlot = getAllowanceSlot(owner, msg.sender, tag);
      uint256 senderAllowance = readStorage(storageSlot);
      require(
        senderAllowance >= amount,
        InsufficientPermission(msg.sender, tag)
      );
      if (senderAllowance != type(uint256).max) {
        unchecked {
          // The subtraction is safe due to the prior check.
          writeStorage(storageSlot, senderAllowance - amount);
        }
      }
    }
  }
}

////////////////////////////////////////////////////////////// Pool owner slots

// uint128(uint256(keccak256("poolOwner"))) - 1
uint128 constant poolOwnerSlot = 0x68E919334073168F7B6F6D0178986A64;

/// @notice This function returns the storage slot referring to the owner of
/// a pool.
///
/// @param poolId The 'poolId' whose owner slot to be derived.
/// @return storageSlot The storage slot containing the pool owner.
function getPoolOwnerSlot(
  uint256 poolId
) pure returns (uint256 storageSlot) {
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //    0              32              48
    //    |              |               |
    //    +--------------+---------------+
    //    |    poolId    | poolOwnerSlot |
    //    +--------------+---------------+
    //
    mstore(16, poolOwnerSlot) // 16 = 48 - 32
    mstore(0, poolId)
    storageSlot := keccak256(0, 48)
  }
}

/// @notice Returns the owner of a given pool.
///
/// @param storageSlot The storage slot containing the pool owner.
/// @return poolOwner The pool owner to be returned.
function readPoolOwner(
  uint256 storageSlot
) view returns (address poolOwner) {
  return address(uint160(readStorage(storageSlot)));
}

/// @notice Writes the owner of a given pool on storage.
///
/// @param storageSlot The storage slot to be populated.
/// @param poolOwner The pool owner to be written on the 'storageSlot'.
function writePoolOwner(
  uint256 storageSlot,
  address poolOwner
) {
  writeStorage(storageSlot, uint256(uint160(poolOwner)));
}

////////////////////////////////////////////////////// Accrued parameters slots

// uint128(uint256(keccak256("accruedParams"))) - 1
uint128 constant accruedParamsSlot = 0x5E1C6265E3E30CEA650443FB20EF1EF9;

/// @notice This function returns the storage slot containing to the pool's
/// accrued growth portions.
///
/// @param poolId The 'poolId' whose owner slot to be derived.
/// @return storageSlot The storage slot containing the pool owner.
function getAccruedParamsSlot(
  uint256 poolId
) pure returns (uint256 storageSlot) {
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //    0              32                  48
    //    |              |                   |
    //    +--------------+-------------------+
    //    |    poolId    | accruedParamsSlot |
    //    +--------------+-------------------+
    //
    mstore(16, accruedParamsSlot) // 16 = 48 - 32
    mstore(0, poolId)
    storageSlot := keccak256(0, 48)
  }
}

/// @notice This function reads the pool's accrued growth portions from storage
/// and sets them in the appropriate memory locations:
///
/// poolRatio0 (24 bits): the ratio of accrued value0 belonging to the pool.
/// poolRatio1 (24 bits): the ratio of accrued value1 belonging to the pool.
/// accrued0 (104 bits): total accrued in tag0 owed to both pool and protocol.
/// accrued1 (104 bits): total accrued in tag1 owed to both pool and protocol.
///
/// The above values are encoded tightly in the following order:
///
///         3 bytes          3 bytes          13 bytes         13 bytes
///    +----------------+----------------+----------------+----------------+
///    |   poolRatio1   |   poolRatio0   |    accrued1    |    accrued0    |
///    +----------------+----------------+----------------+----------------+
///
function readAccruedParams() view {
  X23 poolRatio0;
  X23 poolRatio1;
  X127 accrued0;
  X127 accrued1;
  uint256 accruedSlot = readStorage(getAccruedParamsSlot(getPoolId()));
  assembly {
    poolRatio0 := and(shr(208, accruedSlot), 0xFFFFFF)
    poolRatio1 := shr(232, accruedSlot)
    accrued0 := shl(127, and(accruedSlot, 0xFFFFFFFFFFFFFFFFFFFFFFFFFF))
    accrued1 := shl(23, and(
      accruedSlot,
      shl(104, 0xFFFFFFFFFFFFFFFFFFFFFFFFFF)
    ))
  }
  setPoolRatio0(poolRatio0);
  setPoolRatio1(poolRatio1);
  setAccrued0(accrued0);
  setAccrued1(accrued1);
}

/// @notice This function writes pool's accrued growth portions to storage from
/// memory.
function writeAccruedParams() {
  X127 accrued0 = getAccrued0();
  require(accrued0 >= zeroX127, AccruedGrowthPortionOverflow(accrued0));
  require(accrued0 <= accruedMax, AccruedGrowthPortionOverflow(accrued0));

  X127 accrued1 = getAccrued1();
  require(accrued1 >= zeroX127, AccruedGrowthPortionOverflow(accrued1));
  require(accrued1 <= accruedMax, AccruedGrowthPortionOverflow(accrued1));

  X23 poolRatio0 = getPoolRatio0();
  X23 poolRatio1 = getPoolRatio1();

  uint256 accruedSlot = getAccruedParamsSlot(getPoolId());
  uint256 accrued;
  assembly {
    accrued := or(
      or(shl(232, poolRatio1), shl(208, poolRatio0)),
      or(shl(104, shr(127, accrued1)), shr(127, accrued0))
    )
  }
  writeStorage(accruedSlot, accrued);
}

/////////////////////////////////////////////////////// Growth multiplier slots

// uint64(uint256(keccak256("growthMultiplier"))) - 1
uint64 constant growthMultiplierSlot = 0x1447E579411C2C93;

/// @notice This function returns the storage slot containing the pool's growth
/// multiplier at the given interval boundary, i.e.,
/// 'growthMultiplier[qBoundary]'.
///
/// @param poolId The corresponding poolId.
/// @param qBoundary The interval boundary whose corresponding growth
/// multiplier slot is to be derived.
/// @return storageSlot The storage slot containing the growth multiplier.
function getGrowthMultiplierSlot(
  uint256 poolId,
  X59 qBoundary
) pure returns (uint256 storageSlot) {
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //    0                32                   40                     48
    //    |                |                    |                      |
    //    +----------------+--------------------+----------------------+
    //    |     poolId     |      qBoundary     | growthMultiplierSlot |
    //    +----------------+--------------------+----------------------+
    //
    mstore(16, growthMultiplierSlot) // 16 = 48 - 32
    mstore(8, qBoundary) // 8 = 40 - 32
    mstore(0, poolId) // 0 = 32 - 32
    storageSlot := keccak256(0, 48)
  }
}

/// @notice Reads the growth multiplier from 'storageSlot'.
///
/// @param storageSlot The storage slot hosting the growth multiplier.
/// @return growthMultiplier The growth multiplier to be returned.
function readGrowthMultiplier(
  uint256 storageSlot
) view returns (
  X208 growthMultiplier
) {
  assembly {
    growthMultiplier := sload(storageSlot)
  }
}

/// @notice This function calculates the following default value of
/// 'growthMultiplier[qBoundary]' for a given spaced 'qBoundary' with the
/// assumption that "qUpper <= qBoundary":
///
///                                     +oo
///                                    -----
///    growthMultiplier[qBoundary]     \       - (qBoundary + j * qSpacing) / 2
///  '----------------------------- == /     e
///              2 ** 208              -----
///                                    j = 0
///
///       - qBoundary / 2
///     e
///   ---------------------- ==
///          - qSpacing / 2
///    1 - e
///
///                                - 8 - qBoundary / 2
///     + 8         (2 ** 216) * e
///   e     * -------------------------------------------- ==
///                                        - qSpacing / 2
///            (2 ** 216) - (2 ** 216) * e
///
///                                - 8 - qBoundary / 2
///    exp8X208     (2 ** 216) * e
///   ---------- * ------------------------------------ '.
///    2 ** 208      oneX216 - _spacing_.sqrt(false)
///
/// This is because the boundary is touched for the first time and the growth 
/// for every single interval on its right side is equal to '1'.
///
/// 'qBoundary' should be positive and less than '2 ** 64'.
///
/// @param qBoundary The interval boundary whose corresponding growth
/// multiplier is to be derived.
/// @return growthMultiplier The growth multiplier to be returned.
function calculateGrowthMultiplier0(
  X59 qBoundary
) pure returns (
  X208 growthMultiplier
) {
  // The requirements of 'exp' are satisfied here due to the input 
  // requirement of the present function.
  (X216 sqrtPrice, ) = qBoundary.exp();

  // 'mulDiv' is safe because both the 'numerator' and 'denominator' are
  // nonnegative and also, the output does not exceed 256-bits. More
  // precisely:
  //
  //                     - qBoundary / 2
  //                   e
  //   '(2 ** 208) * ---------------------- ==
  //                        - qSpacing / 2
  //                  1 - e
  //
  //                                  + 8
  //                                e
  //    (2 ** 208) * ----------------------------------- < 2 ** 256'
  //                        - minLogSpacing / (2 ** 60)
  //                  1 - e
  //
  growthMultiplier = exp8X208.mulDiv(
    sqrtPrice,
    oneX216 - _spacing_.sqrt(false)
  );
}

/// @notice This function calculates the following default value of
/// 'growthMultiplier[qBoundary]' for a given spaced 'qBoundary' with the
/// assumption that "qBoundary <= qLower":
///
///                                     +oo
///                                    -----
///    growthMultiplier[qBoundary]     \       + (qBoundary - j * qSpacing) / 2
///  '----------------------------- == /     e
///              2 ** 208              -----
///                                    j = 0
///
///       + qBoundary / 2
///     e
///   ---------------------- ==
///          - qSpacing / 2
///    1 - e
///
///                                - 8 + qBoundary / 2
///     + 8         (2 ** 216) * e
///   e     * -------------------------------------------- ==
///                                        - qSpacing / 2
///            (2 ** 216) - (2 ** 216) * e
///
///                                - 8 + qBoundary / 2
///    exp8X208     (2 ** 216) * e
///   ---------- * ------------------------------------ '.
///    2 ** 208      oneX216 - _spacing_.sqrt(false)
///
/// This is because the boundary is touched for the first time and the growth 
/// for every single interval on its right side is equal to '1'.
/// 
/// 'qBoundary' should be positive and less than '2 ** 64'.
///
/// @param qBoundary The interval boundary whose corresponding growth
/// multiplier is to be derived.
/// @return growthMultiplier The growth multiplier to be returned.
function calculateGrowthMultiplier1(
  X59 qBoundary
) pure returns (
  X208 growthMultiplier
) {
  // The requirements of 'exp' are satisfied here due to the input 
  // requirement of the present function.
  (, X216 sqrtInversePrice) = qBoundary.exp();

  // 'mulDiv' is safe because both the 'numerator' and 'denominator' are
  // nonnegative and also, the output does not exceed 256-bits. More
  // precisely:
  //
  //                     + qBoundary / 2
  //                   e
  //   '(2 ** 208) * ---------------------- ==
  //                        - qSpacing / 2
  //                  1 - e
  //
  //                                  + 8
  //                                e
  //    (2 ** 208) * ----------------------------------- < 2 ** 256'
  //                        - minLogSpacing / (2 ** 60)
  //                  1 - e
  //
  growthMultiplier = exp8X208.mulDiv(
    sqrtInversePrice,
    oneX216 - _spacing_.sqrt(false)
  );
}

/// @notice This function returns 'growthMultiplier[qBoundary]' for a given
/// spaced 'qBoundary' with the assumption that "qUpper <= qBoundary". If 
/// 'growthMultiplier[qBoundary]' is never set on storage, the function returns
/// the default value.
///
/// 'qBoundary' should be positive and less than '2 ** 64'.
///
/// @param qBoundary The interval boundary whose corresponding growth
/// multiplier is to be derived.
/// @return growthMultiplier The growth multiplier to be returned.
function readGrowthMultiplier0(
  X59 qBoundary
) returns (
  X208 growthMultiplier
) {
  // The storage slot containing 'growthMultiplier[qBoundary]' is derived.
  uint256 storageSlot = getGrowthMultiplierSlot(getPoolId(), qBoundary);

  // 'growthMultiplier[qBoundary]' is read from storage.
  growthMultiplier = readGrowthMultiplier(storageSlot);

  // If 'growthMultiplier[qBoundary]' is not set before, then it should be
  // calculated, written on storage and returned.
  if (growthMultiplier == zeroX208) {
    // The default value for 'growthMultiplier[qBoundary]' is calculated.
    growthMultiplier = calculateGrowthMultiplier0(qBoundary);

    // The calculation for 'growthMultiplier[qBoundary]' is written on storage.
    writeGrowthMultiplier(storageSlot, growthMultiplier);
  }
}

/// @notice This function returns 'growthMultiplier[qBoundary]' for a given
/// spaced 'qBoundary' with the assumption that "qBoundary <= qLower". If 
/// 'growthMultiplier[qBoundary]' is never set on storage, the function returns
/// the default value.
///
/// 'qBoundary' should be positive and less than '2 ** 64'.
///
/// @param qBoundary The interval boundary whose corresponding growth
/// multiplier is to be derived.
/// @return growthMultiplier The growth multiplier to be returned.
function readGrowthMultiplier1(
  X59 qBoundary
) returns (
  X208 growthMultiplier
) {
  // The storage slot containing 'growthMultiplier[qBoundary]' is derived.
  uint256 storageSlot = getGrowthMultiplierSlot(getPoolId(), qBoundary);

  // 'growthMultiplier[qBoundary]' is read from storage.
  growthMultiplier = readGrowthMultiplier(storageSlot);

  // If 'growthMultiplier[qBoundary]' is not set before, then it should be
  // calculated, written on storage and returned.
  if (growthMultiplier == zeroX208) {
    // The default value for 'growthMultiplier[qBoundary]' is calculated.
    growthMultiplier = calculateGrowthMultiplier1(qBoundary);

    // The calculated for 'growthMultiplier[qBoundary]' is written on storage.
    writeGrowthMultiplier(storageSlot, growthMultiplier);
  }
}

/// @notice This function writes the given 'growthMultiplier' in the given
///  'storageSlot'.
///
/// @param storageSlot The storage slot on which the growth multiplier is
/// written.
/// @param growthMultiplier The growth multiplier to be written.
function writeGrowthMultiplier(
  uint256 storageSlot,
  X208 growthMultiplier
) {
  assembly {
    sstore(storageSlot, growthMultiplier)
  }
}

/// @notice This function writes 'growthMultiplier' values for the boundaries
/// of the first active interval.
///
/// @param qLower The left boundary of the active liquidity interval
/// @param qUpper The right boundary of the active liquidity interval
///
/// 'qLower' and 'qUpper' should be positive and less than '2 ** 64'.
///
function writeGrowthMultipliers(
  X59 qLower,
  X59 qUpper
) {
  uint256 poolId = getPoolId();

  // The default value for 'growthMultiplier[qLower]' is calculated and written
  // in the appropriate storage slot.
  writeGrowthMultiplier(
    getGrowthMultiplierSlot(poolId, qLower),
    calculateGrowthMultiplier1(qLower)
  );

  // The default value for 'growthMultiplier[qUpper]' is calculated and written
  // in the appropriate storage slot.
  writeGrowthMultiplier(
    getGrowthMultiplierSlot(poolId, qUpper),
    calculateGrowthMultiplier0(qUpper)
  );
}

////////////////////////////////////////////////////////////////// Shares slots

// uint128(uint256(keccak256("sharesGross"))) - 1
uint128 constant sharesGrossSlot = 0xA20D6232B6352D00ABC0D966E2BCFB8A;

/// @notice This function returns the storage slot hosting the total number of
/// shares across every single interval of a pool.
///
/// @param poolId The 'poolId' whose owner slot to be derived.
/// @return storageSlot The storage slot containing the pool owner.
function getSharesGrossSlot(
  uint256 poolId
) pure returns (
  uint256 storageSlot
) {
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //    0                32                         48
    //    |                |                          |
    //    +----------------+--------------------------+
    //    |     poolId     |      sharesGrossSlot     |
    //    +----------------+--------------------------+
    //
    mstore(16, sharesGrossSlot)
    mstore(0, poolId)
    storageSlot := keccak256(0, 48)
  }
}

// uint64(uint256(keccak256("sharesDelta"))) - 1
uint64 constant sharesDeltaSlot = 0xD7CB7A927A838D41;

/// @notice This function returns the storage slot containing the pool's shares
/// delta at the given interval boundary, i.e., 'sharesDelta[qBoundary]'.
///
/// @param poolId The corresponding poolId.
/// @param qBoundary The interval boundary whose corresponding shares delta
/// slot is to be derived.
/// @return storageSlot The storage slot containing the shares delta.
function getSharesDeltaSlot(
  uint256 poolId,
  X59 qBoundary
) pure returns (
  uint256 storageSlot
) {
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //    0                32                   40                48
    //    |                |                    |                 |
    //    +----------------+--------------------+-----------------+
    //    |     poolId     |      qBoundary     | sharesDeltaSlot |
    //    +----------------+--------------------+-----------------+
    //
    mstore(16, sharesDeltaSlot)
    mstore(8, qBoundary)
    mstore(0, poolId)
    storageSlot := keccak256(0, 48)
  }
}

/// @notice Reads shares delta from 'storageSlot'.
///
/// @param storageSlot The storage slot hosting the shares delta.
/// @return sharesDelta The shares delta to be returned.
function readSharesDelta(
  uint256 storageSlot
) view returns (
  int256 sharesDelta
) {
  assembly {
    sharesDelta := sload(storageSlot)
  }
}

/// @notice Gets the number of shares to be deposited/withdrawn as a result of
/// modifying a position from memory and adjusting 'sharesDelta' values in
/// storage accordingly.
function modifySharesDelta() {
  // 'poolId' and the number of shares to be added/subtracted are loaded from
  // the memory.
  uint256 poolId = getPoolId();
  int256 shares = getShares();

  // 'sharesDelta[logPriceMinOffsetted]' is adjusted.
  X59 logPriceMinOffsetted = getLogPriceMinOffsetted();
  uint256 storageSlot = getSharesDeltaSlot(poolId, logPriceMinOffsetted);
  assembly {
    sstore(storageSlot, add(sload(storageSlot), shares))
  }

  // 'sharesDelta[logPriceMaxOffsetted]' is adjusted.
  X59 logPriceMaxOffsetted = getLogPriceMaxOffsetted();
  storageSlot = getSharesDeltaSlot(poolId, logPriceMaxOffsetted);
  assembly {
    sstore(storageSlot, sub(sload(storageSlot), shares))
  }

  // The total number of shares across all intervals may never exceed
  // 'type(int128).max'. This is verified next.
  int256 sharesGross;
  storageSlot = getSharesGrossSlot(poolId);
  X59 qSpacing = _spacing_.log();
  assembly {
    sharesGross := add(
      sload(storageSlot),
      //
      //             logPriceMaxOffsetted - logPriceMinOffsetted
      //  'shares * ---------------------------------------------'
      //                               qSpacing
      mul(
        // 'qSpacing' is non-zero. Hence, division is safe.
        div(sub(logPriceMaxOffsetted, logPriceMinOffsetted), qSpacing),
        shares
      )
    )
    sstore(storageSlot, sharesGross)
  }

  require(sharesGross <= type(int128).max, SharesGrossOverflow(sharesGross));
}

//////////////////////////////////////////////////////////// Dynamic parameters

// uint128(uint256(keccak256("dynamicParams"))) - 1
uint128 constant dynamicParamsSlot = 0x6890D047AD8C870137858A70716B2C6B;

/// @notice This function returns the storage slot hosting the dynamic
/// parameters of a pool.
///
/// @param poolId The 'poolId' whose owner slot to be derived.
/// @return storageSlot The storage slot containing the pool owner.
function getDynamicParamsSlot(
  uint256 poolId
) pure returns (
  uint256 storageSlot
) {
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //    0                32                  48
    //    |                |                   |
    //    +----------------+-------------------+
    //    |     poolId     | dynamicParamsSlot |
    //    +----------------+-------------------+
    //
    mstore(16, dynamicParamsSlot)
    mstore(0, poolId)
    storageSlot := keccak256(0, 48)
  }
}

/// @notice This function reads pool's dynamic parameters from storage and sets
/// them in appropriate memory locations.
function readDynamicParams() view {
  // The storage slot hosting the dynamic parameters of the pool is derived.
  uint256 storageSlot = getDynamicParamsSlot(getPoolId());

  // Dynamic parameters are read from storage and stored in memory.
  assembly {
    mstore(add(_dynamicParams_, 32), sload(storageSlot))
    mstore(add(_dynamicParams_, 64), sload(add(storageSlot, 1)))
    mstore(add(_dynamicParams_, 96), sload(add(storageSlot, 2)))
  }

  // For an existing pool, 'growth' is always greater than or equal to
  // 'oneX111'. Hence, 'getGrowth() == zeroX111' indicates that the pool does
  // not exist.
  require(getGrowth() != zeroX111, PoolDoesNotExist(getPoolId()));

  // 'staticParamsStoragePointer == type(uint16).max' indicates that the
  // storage pointer for static parameters has overflowed and the storage slot
  // for 'staticParamsStoragePointerExtension' needs to be read.
  uint16 staticParamsStoragePointer = getStaticParamsStoragePointer();
  if (staticParamsStoragePointer == type(uint16).max) {
    assembly {
      mstore(_dynamicParams_, sload(sub(storageSlot, 1)))
    } 
  } else {
    setStaticParamsStoragePointerExtension(
      uint256(staticParamsStoragePointer)
    );
  }
}

/// @notice This function loads pool's dynamic parameters from the memory and
/// writes them on storage.
function writeDynamicParams() {
  // The storage slot hosting the dynamic parameters of the pool is derived.
  uint256 storageSlot = getDynamicParamsSlot(getPoolId());

  // 'staticParamsStoragePointer >= type(uint16).max' indicates that the
  // storage pointer for static parameters has overflowed and the storage slot
  // for 'staticParamsStoragePointerExtension' needs to be used.
  if (getStaticParamsStoragePointerExtension() >= type(uint16).max) {
    assembly {
      sstore(sub(storageSlot, 1), mload(_dynamicParams_))
    }
    setStaticParamsStoragePointer(type(uint16).max);
  } else {
    setStaticParamsStoragePointer(
      uint16(getStaticParamsStoragePointerExtension())
    );
  }

  // Next, the dynamic parameters are loaded from the memory and written on 
  // storage.
  assembly {
    sstore(storageSlot, mload(add(_dynamicParams_, 32)))
    sstore(add(storageSlot, 1), mload(add(_dynamicParams_, 64)))
    sstore(add(storageSlot, 2), mload(add(_dynamicParams_, 96)))
  }
}

/////////////////////////////////////////////////////////////////// Curve slots

// uint128(uint256(keccak256("curve"))) - 1
uint128 constant curveSlot = 0x3B2D91718DFB37F9969A1B0670A83E70;

/// @notice This function returns the storage slot hosting the curve sequence
/// of a pool.
///
/// @param poolId The 'poolId' whose owner slot to be derived.
/// @return storageSlot The storage slot containing the pool owner.
function getCurveSlot(
  uint256 poolId
) pure returns (
  uint256 storageSlot
) {
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //    0                32                  48
    //    |                |                   |
    //    +----------------+-------------------+
    //    |     poolId     |     curveSlot     |
    //    +----------------+-------------------+
    //
    mstore(16, curveSlot)
    mstore(0, poolId)
    storageSlot := keccak256(0, 48)
  }
}

/// @notice Reads 'qLower' and 'qUpper' boundaries of the current interval from
/// storage.
///
/// @return qLower The left boundary of the active liquidity interval
/// @return qUpper The right boundary of the active liquidity interval
function readBoundaries() view returns (
  X59 qLower,
  X59 qUpper
) {
  // Reads the first slot of the curve sequence from storage.
  uint256 firstSlot = readStorage(getCurveSlot(getPoolId()));
  
  Curve curve = getCurve();
  setCurveLength(twoIndex);
  
  assembly {
    mstore(curve, firstSlot)
  }
  
  qLower = curve.member(zeroIndex);
  qUpper = curve.member(oneIndex);
  (qLower, qUpper) = qLower < qUpper ? (qLower, qUpper) : (qUpper, qLower);
}

/// @notice Reads the entire curve from storage and stores it in memory.
function readCurve() view returns (Index curveLength) {
  // Reads the first slot of the curve sequence from storage.
  uint256 storageSlot = getCurveSlot(getPoolId());

  // The memory pointer referring to the first member of the curve sequence is
  // loaded from the memory.
  Curve memoryPointer = getCurve();

  // Let 'l' denote the number of members in the curve sequence. Since, we
  // already know 'qCurrent' from dynamic parameters, we can determine 'l'
  // without having to load an entire length slot! In other words, we keep
  // reading members of the curve sequence from protocol's storage (four
  // members per slot) until we encounter 'qCurrent' which is already known
  // from dynamic parameters. Then, 'l' can be determined based on the position
  // of 'qCurrent' in the curve sequence.
  X59 qCurrent = getLogPriceCurrent();

  assembly {
    let value

    // The loop is broken whenever we encounter 'qCurrent'.
    for {} 0x1 {} {
      value := sload(storageSlot)

      // Examines if the most significant 64 bits are equal to 'qCurrent'.
      let member := shr(192, value)
      if eq(member, qCurrent) {
        curveLength := add(curveLength, 1)
        value := shl(192, member)
        break
      }

      // Examines if the second most significant 64 bits are equal to
      // 'qCurrent'.
      member := shr(128, value)
      if eq(and(member, 0xFFFFFFFFFFFFFFFF), qCurrent) {
        curveLength := add(curveLength, 2)
        value := shl(128, member)
        break
      }

      // Examines if the third most significant 64 bits are equal to
      // 'qCurrent'.
      member := shr(64, value)
      if eq(and(member, 0xFFFFFFFFFFFFFFFF), qCurrent) {
        curveLength := add(curveLength, 3)
        value := shl(64, member)
        break
      }

      curveLength := add(curveLength, 4)

      // Examines if the least significant 64 bits are equal to
      // 'qCurrent'.
      if eq(and(value, 0xFFFFFFFFFFFFFFFF), qCurrent) {
        break
      }

      // 'value' is stored in memory.
      mstore(memoryPointer, value)

      // 'storageSlot' is incremented.
      storageSlot := add(storageSlot, 1)

      // 'memoryPointer' is incremented by 32 bytes.
      memoryPointer := add(memoryPointer, 32)
    }

    // 'value' is stored in memory.
    mstore(memoryPointer, value)
  }
}

/// @notice Writes the current curve sequence on storage.
function writeCurve() {
  // Reads the first slot of the curve sequence from storage.
  uint256 storageSlot = getCurveSlot(getPoolId());

  // The memory pointer referring to the first member of the curve sequence is
  // loaded from the memory.
  Curve memoryPointer = getCurve();

  // The length of the current curve squence in memory is loaded.
  Index curveLength = getCurveLength();

  assembly {
    // The last storage slot for the curve sequence is read derived.
    let finalSlot := add(storageSlot, shr(2, sub(curveLength, 1)))

    // The first slot of the curve sequence is loaded from memory and written
    // on storage.
    sstore(storageSlot, mload(memoryPointer))

    // This loop continues until we encounter 'finalSlot'.
    for {} lt(storageSlot, finalSlot) {} {
      // 'storageSlot' is incremented.
      storageSlot := add(storageSlot, 1)

      // 'memoryPointer' is incremented by 32 bytes.
      memoryPointer := add(memoryPointer, 32)

      // The slot of the curve sequence which is pointed to by 'memoryPointer'
      // is loaded from the memory and is written on storage.
      sstore(storageSlot, mload(memoryPointer))
    }
  }
}

////////////////////////////////////////// Static parameters and kernel storage

/// @notice This function deploys a storage contract whose bytecode contains
/// the pool's static parameters.
///
/// @param storagePointer The pointer which is used to derive the address of
/// the storage smart contract.
function writeStaticParams(uint256 storagePointer) {
  uint256 poolId = getPoolId();
  address proxy;
  assembly {
    // The 32-byte storage pointer is derived by hashing the following 64
    // bytes:
    mstore(0, poolId)
    mstore(32, storagePointer)
    storagePointer := keccak256(0, 64)

    // Static parameters are stored in a 'storage contract' which is deployed
    // by a disposable 'proxy contract'. First the 'proxy contract' is
    // deployed.
    mstore(0x00, PROXY_CREATION_CODE)
    proxy := create2(0, 0x10, 0x10, storagePointer)
  }

  require(proxy != address(0), DeploymentFailed());

  // The total number of bytes to be written.
  Index length = getKernelLength();
  uint256 deploymentCreationCode;
  assembly {
    length := add(
      sub(_endOfStaticParams_, _staticParams_), // Length of static parameters.
      shl(6, sub(length, 1)) // Length of kernel.
    )
    // '1' is added to include the '00' padding bytes. Due the '1019' limit on
    // the size of kernel, the addition is always safe.
    deploymentCreationCode := or(DEPLOYMENT_CODE, shl(64, add(length, 1)))
  }
  setDeploymentCreationCode(deploymentCreationCode);

  // Data is written from memory to a new contract via the proxy.
  bool success;
  assembly {
    success := call(
      gas(),
      proxy,
      0,
      _deploymentCreationCode_,
      add(length, 11), // Because 'DEPLOYMENT_CODE' is 11 bytes.
      0,
      0
    )
  }

  require(success, DeploymentFailed());
}

/// @notice This function calculates the address of the storage contract
/// containing static parameters and kernel.
///
/// @param storagePointer The pointer which is used to derive the address of
/// the storage smart contract.
/// @return storageAddress The address of the storage contract whose bytecode
/// comprises static parameters and kernel.
function getStaticParamsStorageAddress(
  uint256 storagePointer
) view returns (
  address storageAddress
) {
  address nofeeswap;
  assembly {
    nofeeswap := address()
  }
  return getStaticParamsStorageAddress(
    nofeeswap,
    getPoolId(),
    storagePointer
  );
}

/// @notice This function calculates the address of the storage contract
/// containing static parameters and kernel.
///
/// @param nofeeswap The protocol's address.
/// @param poolId The corresponding 'poolId'.
/// @param storagePointer The pointer which is used to derive the address of
/// the storage smart contract.
/// @return storageAddress The address of the storage contract whose bytecode
/// comprises static parameters and kernel.
function getStaticParamsStorageAddress(
  address nofeeswap,
  uint256 poolId,
  uint256 storagePointer
) pure returns (
  address storageAddress
) {
  assembly {
    // The 32-byte storage pointer is derived by hashing the following 64:
    mstore(0, poolId)
    mstore(32, storagePointer)
    storagePointer := keccak256(0, 64)

    // Fetch free memory pointer so that we can use '0x40' as scratch space.
    let freeMemoryPointer := mload(0x40)

    // Pool static parameters are stored in a 'storage contract' which is 
    // deployed by a 'proxy contract'. First the 'proxy contract' address is
    // derived.
    // 'nofeeswap' address is written in first memory slot along with a '0xff'
    // prefix. The storage pointer and 'PROXY_CREATION_HASH' are written in
    // the second and third memory slots, respectively.
    mstore(0x00, nofeeswap)
    mstore8(0x0b, 0xff)
    mstore(0x20, storagePointer)
    mstore(0x40, PROXY_CREATION_HASH)

    // This 85 byte hash gives the 'proxy contract' address.
    mstore(0x14, keccak256(0x0b, 0x55))

    // Restores 'freeMemoryPointer'.
    mstore(0x40, freeMemoryPointer)

    // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of 0x94 ++ proxy ++ 0x01)
    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
    mstore(0x00, 0xd694)
    mstore8(0x34, 0x01)

    // Gives the 'storage contract' address.
    storageAddress := and(keccak256(0x1e, 0x17), shr(96, not(0)))
  }
}

/// @notice This function reads pool's static parameters from storageAddress 
/// and sets them in appropriate memory locations:
///
/// @param storageAddress The address of the storage contract whose bytecode
/// comprises static parameters and kernel.
function readStaticParams(
  address storageAddress
) view {
  assembly {
    extcodecopy(
      storageAddress,
      _staticParams_,
      1,
      sub(_endOfStaticParams_, _staticParams_)
    )
  }
}

/// @notice This function reads pool's static parameters and kernel, and sets
/// them in appropriate memory locations.
///
/// @param storageAddress The address of the storage contract whose bytecode
/// comprises static parameters and kernel.
function readStaticParamsAndKernel(
  address storageAddress
) view {
  readStaticParams(storageAddress);
  Index kernelLength = readKernelLength(storageAddress);
  setKernelLength(kernelLength);
  readKernel(getKernel(), storageAddress, kernelLength);
}

/// @notice This function reads kernel length.
///
/// @param storageAddress The address of the storage contract whose bytecode
/// comprises static parameters and kernel.
/// @return length The number of kernel breakpoints.
function readKernelLength(
  address storageAddress
) view returns (
  Index length
) {
  assembly {
    // The total number of bytes to be loaded.
    // Each breakpoint of the kernel is 64 bytes. The first breakpoint is 
    // omitted.
    length := add(
      shr(
        6,
        sub(
          sub(extcodesize(storageAddress), 1),
          sub(_endOfStaticParams_, _staticParams_)
        )
      ),
      1
    )
  }
}

/// @notice This function reads kernel from storageAddress and sets it in
/// the appropriate memory location.
///
/// @param kernel The memory pointer referring to the memory space which hosts
/// the list of kernel breakpoints.
/// @param storageAddress The address of the storage contract whose bytecode
/// comprises static parameters and kernel.
/// @param length The number of kernel breakpoints.
function readKernel(
  Kernel kernel,
  address storageAddress,
  Index length
) view {
  assembly {
    // Data is loaded from the 'storageAddress' to memory.
    extcodecopy(
      storageAddress,
      kernel,
      add(1, sub(_endOfStaticParams_, _staticParams_)),
      shl(6, sub(length, 1))
    )
  }
}

/// @notice Reads pool data and sets it in the appropriate memory location.
function readPoolData() view {
  readDynamicParams();

  // The address of the storage contract whose bytecode comprises static
  // parameters and kernel.
  address storageAddress = getStaticParamsStorageAddress(
    getStaticParamsStoragePointerExtension()
  );

  // Static paremters are read from the storage contract.
  readStaticParams(storageAddress);

  // 'poolGrowthPortion' is capped by 'maxPoolGrowthPortion'.
  setPoolGrowthPortion(
    min(getPoolGrowthPortion(), getMaxPoolGrowthPortion())
  );

  // The length of the kernel is determined.
  Index length = readKernelLength(storageAddress);
  setKernelLength(length);

  // Kernel breakpoints are read from the storage contract and stored in
  // memory.
  Kernel kernel = getKernel();
  readKernel(kernel, storageAddress, length);

  // If needed, additional space is reserved in memory for the pending kernel.
  length = max(length, getPendingKernelLength());

  // The memory pointer for the curve sequence is derived.
  Curve curve;
  assembly {
    curve := add(kernel, shl(6, sub(length, 1)))
  }
  setCurve(curve);

  // The curve sequence is read from storage and placed in memory.
  length = readCurve();
  setCurveLength(length);

  // The free memory pointer is set next.
  uint256 freeMemoryPointer;
  assembly {
    freeMemoryPointer := add(
      curve,
      shl(5, add(shr(2, sub(length, 1)), 2))
    )
  }
  setFreeMemoryPointer(freeMemoryPointer);

  // The byte count for the memory snapshot given to the hook contract is
  // derived next.
  uint256 hookInputByteCount;
  assembly {
    hookInputByteCount := 
      sub(sub(freeMemoryPointer, _hookInputByteCount_), 32)
  }
  setHookInputByteCount(hookInputByteCount);
}

// Modified from Philogy 
// <https://github.com/Philogy/sstore3/blob/main/src/SSTORE3_L.sol>
// Modified from Solady 
// <https://github.com/Vectorized/solady/blob/main/src/utils/CREATE3.sol>

// The proxy bytecode.
uint256 constant PROXY_CREATION_CODE = 0x67363D3D37363D3DF03D5260086018F3;
// 'keccak256(PROXY_CREATION_CODE)'.
bytes32 constant PROXY_CREATION_HASH = 
  0xF779EDCBDC615C777A4CB2BEE1BF733055AA41FF7247837D0CD548565F65D034;
// -------------------------------------------------------------------+
// Opcode      | Mnemonic         | Stack        | Memory             |
// -------------------------------------------------------------------|
// 36          | CALLDATASIZE     | cds          |                    |
// 3d          | RETURNDATASIZE   | 0 cds        |                    |
// 3d          | RETURNDATASIZE   | 0 0 cds      |                    |
// 37          | CALLDATACOPY     |              | [0..cds): calldata |
// 36          | CALLDATASIZE     | cds          | [0..cds): calldata |
// 3d          | RETURNDATASIZE   | 0 cds        | [0..cds): calldata |
// 3d          | RETURNDATASIZE   | 0 0 cds      | [0..cds): calldata |
// f0          | CREATE           | newContract  | [0..cds): calldata |
// -------------------------------------------------------------------|
// Opcode      | Mnemonic         | Stack        | Memory             |
// -------------------------------------------------------------------|
// 67 bytecode | PUSH8 bytecode   | bytecode     |                    |
// 3d          | RETURNDATASIZE   | 0 bytecode   |                    |
// 52          | MSTORE           |              | [0..8): bytecode   |
// 60 0x08     | PUSH1 0x08       | 0x08         | [0..8): bytecode   |
// 60 0x18     | PUSH1 0x18       | 0x18 0x08    | [0..8): bytecode   |
// f3          | RETURN           |              | [0..8): bytecode   |
// -------------------------------------------------------------------+


uint256 constant DEPLOYMENT_CODE = 0x61000080600a3d393df300;
// ------------------------------------------------------------------------+
//                                                                         |
// STORE DEPLOY START (11 bytes)                                           |
//                                                                         |
// ----+------------+------------------+--------------+--------------------+
// PC  | Opcode     | Mnemonic         | Stack        | Memory             |
// ----+------------+------------------+--------------+--------------------+
//                                                                         |
// ::::::::::: Deploy code (10 bytes). ::::::::::::::::::::::::::::::::::: |
// 0x0 | 61 ????    | PUSH2 length     | len          | -                  |
// 0x3 | 80         | DUP1             | len len      | -                  |
// 0x4 | 60 0a      | PUSH1 0x0a       | 10 len len   | -                  |
// 0x6 | 3d         | RETURNDATASIZE   | 0 10 len len | [0..len): runtime  |
// 0x7 | 39         | CODECOPY         | len          | [24..32): runtime  |
// 0x8 | 3d         | RETURNDATASIZE   | 0 len        | [24..32): runtime  |
// 0x9 | f3         | RETURN           |              | [24..32): runtime  |
//                                                                         |
// ::::::::::: Padding (1 byte). ::::::::::::::::::::::::::::::::::::::::: |
// 0x0 | 00         | STOP             |              | [24..32): runtime  |
// ----+------------+------------------+--------------+--------------------+