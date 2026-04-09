// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {getPoolId} from "./Memory.sol";
import {Index} from "./Index.sol";
import {X47} from "./X47.sol";
import {X59} from "./X59.sol";
import {Tag} from "./Tag.sol";
import {
  AlreadyUnlocked,
  ProtocolIsLocked,
  PoolIsLocked,
  DeploymentFailed,
  CannotRedeployStaticParamsAndKernelExternally,
  NativeTokenCannotBeSynced,
  CannotMintAfterBurning
} from "./Errors.sol";

/// @notice Writes a single slot on transient storage.
/// @param transientSlot the slot to be populated.
/// @param value the content.
function writeTransient(uint256 transientSlot, uint256 value) {
  assembly {
    tstore(transientSlot, value)
  }
}

/// @notice Writes a single slot on transient storage.
/// @param transientSlot the slot to be populated.
/// @param value the content.
function writeTransient(uint256 transientSlot, int256 value) {
  assembly {
    tstore(transientSlot, value)
  }
}

/// @notice Writes a single slot on transient storage.
/// @param transientSlot the slot to be populated.
/// @param value the content.
function writeTransient(uint256 transientSlot, X47 value) {
  assembly {
    tstore(transientSlot, value)
  }
}

/// @notice Writes a single slot on transient storage.
/// @param transientSlot the slot to be populated.
/// @param value the content.
function writeTransient(uint256 transientSlot, Index value) {
  assembly {
    tstore(transientSlot, value)
  }
}

/// @notice Writes a single slot on transient storage.
/// @param transientSlot the slot to be populated.
/// @param account the content.
function writeTransient(uint256 transientSlot, address account) {
  assembly {
    tstore(
      transientSlot,
      and(account, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    )
  }
}

/// @notice Reads a single slot from storage.
/// @param transientSlot the slot to be read.
/// @return value the content.
function readUint256Transient(
  uint256 transientSlot
) view returns (uint256 value) {
  assembly {
    value := tload(transientSlot)
  }
}

/// @notice Reads a single slot from storage.
/// @param transientSlot the slot to be read.
/// @return value the content.
function readInt256Transient(
  uint256 transientSlot
) view returns (int256 value) {
  assembly {
    value := tload(transientSlot)
  }
}

/// @notice Reads a single slot from storage.
/// @param transientSlot the slot to be read.
/// @return value the content.
function readX47Transient(
  uint256 transientSlot
) view returns (X47 value) {
  assembly {
    value := tload(transientSlot)
  }
}

/// @notice Reads a single slot from storage.
/// @param transientSlot the slot to be read.
/// @return value the content.
function readIndexTransient(
  uint256 transientSlot
) view returns (Index value) {
  assembly {
    value := tload(transientSlot)
  }
}

/// @notice Reads a single slot from storage.
/// @param transientSlot the slot to be read.
/// @return account the content.
function readAddressTransient(
  uint256 transientSlot
) view returns (address account) {
  assembly {
    account := tload(transientSlot)
  }
}

/////////////////////////////////////////////////////////// Unlocker and caller

// uint256(keccak256("unlockTarget")) - 1
uint256 constant unlockTargetSlot = 
  0x08AFE526398486E38896D620563771687E7D20A3B0D01F72483EEB2E7D93A48E;

// uint256(keccak256("caller")) - 1
uint256 constant callerSlot = 
  0xD71F1CF4F9D9F82EF0F0A7247563F6632677ADA0E0F8F0D8734B4D2327DA39E9;

/// @notice Populates 'unlockTarget' and 'caller' slots in transient storage.
///
/// @param unlockTarget The first input of the method 'INofeeswap.unlock'.
/// @param caller The address which has called 'INofeeswap.unlock'.
function unlockProtocol(address unlockTarget, address caller) {
  // Checks if the protocol is already unlocked.
  address currentCaller = readAddressTransient(callerSlot);
  require(currentCaller == address(0), AlreadyUnlocked(currentCaller));

  // Writes 'unlockTarget' on the dedicated transient storage slot.
  writeTransient(unlockTargetSlot, unlockTarget);

  // Writes 'caller' on the dedicated transient storage slot.
  writeTransient(callerSlot, caller);
}

/// @notice Clears 'unlockTarget' and 'caller' slots in transient storage.
function lockProtocol() {
  // Clears the transient storage slot dedicated to 'unlockTarget'.
  writeTransient(unlockTargetSlot, address(0));

  // Clears the transient storage slot dedicated to 'caller'.
  writeTransient(callerSlot, address(0));
}

/// @notice Determines whether the protocol's 'caller' slot is populated.
function isProtocolUnlocked() view {
  require(readAddressTransient(callerSlot) != address(0), ProtocolIsLocked());
}

/// @notice Gives the pool's 'locker' slot.
function getPoolLockSlot() pure returns (uint256 transientSlot) {
  uint256 poolId = getPoolId();
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //    0                               32                              64
    //    |                               |                               |
    //    +-------------------------------+-------------------------------+
    //    |             poolId            |        unlockTargetSlot       |
    //    +-------------------------------+-------------------------------+
    //

    // Populates the second memory slot.
    mstore(32, unlockTargetSlot)

    // Populates the first memory slot.
    mstore(0, poolId)

    // Calculates the resulting hash.
    transientSlot := keccak256(0, 64)
  }
}

/// @notice Safeguard against tampering with any pool which is being used.
///
/// @param transientSlot The transient storage to be checked and populated.
function lockPool(uint256 transientSlot) {
  // First we check whether the slot is already populated.
  require(readUint256Transient(transientSlot) == 0, PoolIsLocked(getPoolId()));

  // If not, we populate it with 'type(uint256).max'.
  writeTransient(transientSlot, type(uint256).max);
}

/// @notice Clears the pool lock.
///
/// @param transientSlot The transient storage to be cleared.
function unlockPool(uint256 transientSlot) {
  writeTransient(transientSlot, uint256(0));
}

//////////////////////////////////////////////////////////////// nonzeroAmounts

// uint256(keccak256("nonzeroAmounts")) - 1
uint256 constant nonzeroAmountsSlot = 
  0x5D43E4CD1A16168A103E08DC189528D374B6E2BD5C612E94553D728C80030103;

/// @notice Reads 'nonzeroAmounts' slot.
function readNonzeroAmounts() view returns (uint256 nonzeroAmounts) {
  nonzeroAmounts = readUint256Transient(nonzeroAmountsSlot);
}

/// @notice Increments 'nonzeroAmounts' slot.
function incrementNonzeroAmounts() {
  unchecked {
    // The addition is safe because the value may never exceed
    // 'type(uint256).max'.
    writeTransient(nonzeroAmountsSlot, readNonzeroAmounts() + 1);
  }
}

/// @notice Decrements 'nonzeroAmounts' slot.
/// Underflow should be avoided externally.
function decrementNonzeroAmounts() {
  unchecked {
    // The addition is safe because the value may never exceed
    // 'type(uint256).max'.
    writeTransient(nonzeroAmountsSlot, readNonzeroAmounts() - 1);
  }
}

////////////////////////////////////////////////////////////// transientBalance

// uint96(uint256(keccak256("transientBalance"))) - 1
uint96 constant transientBalanceSlot = 0xDC0DA6920D198E2EEDF81EF6;

/// @notice This function returns the transient slot referring to the account's 
/// transient balance of 'tag'.
///
/// @param owner Balance owner.
/// @param tag The corresponding tag.
/// @return transientSlot The transient slot containing the balance.
function getTransientBalanceSlot(
  address owner,
  Tag tag
) pure returns (uint256 transientSlot) {
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //  0                               32          52                     64
    //  |                               |           |                      |
    //  +-------------------------------+-----------+----------------------+
    //  |              tag              |   owner   | transientBalanceSlot |
    //  +-------------------------------+-----------+----------------------+
    //

    // Populates the least significant 12 bytes of the memory slot 1 (from 52
    // to 64).
    mstore(32, transientBalanceSlot) // 32 = 62 - 32

    // Populates the most significant 20 bytes of the memory slot 1 (from 32 to
    // 52).
    mstore(20, owner) // 20 = 52 - 32

    // Populates the entire memory slot 0.
    mstore(0, tag) // 0 = 32 - 32

    // Calculates the resulting hash.
    transientSlot := keccak256(0, 64)
  }
}

/// @notice Given access to owner's transient balance.
///
/// @param owner Balance owner.
/// @param tag The corresponding tag.
function transientBalance(
  address owner,
  Tag tag
) view returns (int256 amount) {
  amount = readInt256Transient(getTransientBalanceSlot(owner, tag));
}

/// @notice Updates the given owner's transient balance.
///
/// @param owner Balance owner.
/// @param tag The corresponding tag.
/// @param amount The amount to be added/subtracted.
function updateTransientBalance(
  address owner,
  Tag tag,
  int256 amount
) {
  if (amount == 0) return;

  // The transient slot hosting the corresponding balance is calculated.
  uint256 transientSlot = getTransientBalanceSlot(owner, tag);

  // The current balance is read.
  int256 currentBalance = readInt256Transient(transientSlot);

  // The current balance is modified.
  int256 nextBalance = currentBalance + amount;

  // If 'nextBalance' is zero, then 'nonzeroAmounts' should be decremented.
  // If 'currentBalance' is zero, then 'nonzeroAmounts' should be incremented.
  if (nextBalance == 0) decrementNonzeroAmounts();
  else if (currentBalance == 0) incrementNonzeroAmounts();

  // The content of 'transientSlot' is now updated.
  writeTransient(transientSlot, nextBalance);
}

/////////////////////////////////////////////////////////////////////// reserve

// uint256(keccak256("token")) - 1
uint256 constant tokenSlot = 
  0x9B9B0454CADCB5884DD3FAA6BA975DA4D2459AA3F11D31291A25A8358F84946C;

// uint256(keccak256("tokenId")) - 1
uint256 constant tokenIdSlot = 
  0x53DC9BF46BEBDCA9BE947EE80674B58899973AAC1948A8396714431DA6D4F166;

// uint256(keccak256("reserve")) - 1
uint256 constant reserveSlot = 
  0xF712C2FA585715E22C7FCC833629CE4482AD96496ECD08F3A14847183C4EF4ED;

/// @notice This function returns the content of 'token', 'tokenId', and
/// 'reserve' slots.
///
/// @return token The token address whose reserve is synced.
/// @return tokenId The token id whose reserve is synced.
/// @return reserve The reserve amount.
/// @return multiToken Whether the reserve is a multi-token.
function readReserve() view returns (
  address token,
  uint256 tokenId,
  uint256 reserve,
  bool multiToken
) {
  // The content of 'tokenSlot' is read from transient storage.
  uint256 content = readUint256Transient(tokenSlot);

  // The least significant 160 bits host 'token'.
  token = address(uint160(content & type(uint160).max));

  // Native balance should not be read from transient storage.
  if (token != address(0)) {
    // The most significant 96 bits are nonzero if and only if
    // 'multiToken == true'.
    multiToken = (content >> 160) > 0;

    if (multiToken) {
      // 'tokenId' is read from the dedicated space in transient storage.
      tokenId = readUint256Transient(tokenIdSlot);
    }

    // 'reserve' value is read from the dedicated space in transient storage.
    reserve = readUint256Transient(reserveSlot);
  }
}

/// @notice This function populates the content of 'token' slot.
///
/// @param token The token address whose reserve is synced.
/// @param multiToken Whether the reserve is a multi-token.
function writeReserveToken(
  address token,
  bool multiToken
) {
  // The native token is not settled via the 'sync/settle' mechanism.
  require(token != address(0), NativeTokenCannotBeSynced());

  // The least significant 160 bits host 'token'.
  // The most significant 96 bits are nonzero if and only if
  // 'multiToken == true'.
  writeTransient(
    tokenSlot,
    (
      uint256(uint160(token)) & uint256(type(uint160).max)
    ) | (
      multiToken ? (uint256(type(uint96).max) << 160) : 0
    )
  );
}

/// @notice This function populates the content of 'tokenId' slot.
///
/// @param tokenId The token id whose reserve is synced.
function writeReserveTokenId(
  uint256 tokenId
) {
  // The dedicated space in transient storage is populated with 'tokenId'.
  writeTransient(tokenIdSlot, tokenId);
}

/// @notice This function populates the content of 'reserve' slot.
///
/// @param reserve The reserve amount.
function writeReserveValue(
  uint256 reserve
) {
  // The dedicated space in transient storage is populated with the 'reserve'
  // value.
  writeTransient(reserveSlot, reserve);
}

//////////////////////////////////////////////////////////////// burnt position

// uint128(uint256(keccak256("burntPosition"))) - 1
uint128 constant burntPositionSlot = 0x1605FC00905ADEB7C36AAFA65ECDD6BD;

/// @notice This function checks the corresponding transient slot which
/// indicate weather a specific position has been burnt within the present
/// transaction.
///
/// @param poolId The pool identifier hosting this liquidity position.
/// @param qMin Equal to '(2 ** 59) * (16 + log(pMin / pOffset))' where 'pMin'
/// is the left position boundary.
/// @param qMax Equal to '(2 ** 59) * (16 + log(pMax / pOffset))' where 'pMax'
/// is the right position boundary.
/// @param shares The number of shares to be added/removed.
function checkBurntPosition(
  uint256 poolId,
  X59 qMin,
  X59 qMax,
  int256 shares
) {
  uint256 transientSlot;
  assembly {
    // We populate the first two memory slots from right to left:
    //
    //  0                                 32     40     48                  64
    //  |                                 |      |      |                   |
    //  +---------------------------------+------+------+-------------------+
    //  |              poolId             | qMin | qMax | burntPositionSlot |
    //  +---------------------------------+------+------+-------------------+
    //

    // Populates the least significant 16 bytes of the memory slot 1 (from 48
    // to 64).
    mstore(32, burntPositionSlot) // 32 = 64 - 32

    // Populates the bytes 40 to 48 of memory.
    mstore(16, qMax) // 16 = 48 - 32

    // Populates the most significant 8 bytes of the memory slot 1 (from 40 to
    // 48).
    mstore(8, qMin) // 0 = 40 - 32

    // Populates the entire memory slot 0.
    mstore(0, poolId) // 0 = 32 - 32

    // Calculates the resulting hash and reads the corresponding transient
    // storage slot.
    transientSlot := keccak256(0, 64)
  }

  if (shares > 0) {
    require(
      readUint256Transient(transientSlot) == 0,
      CannotMintAfterBurning(poolId, qMin, qMax)
    );
  } else {
    writeTransient(transientSlot, type(uint256).max);
  }
}

///////////////////////////////////// Static parameters and kernel redeployment
// uint256(keccak256("redeployStaticParamsAndKernel")) - 1
uint256 constant redeployStaticParamsAndKernelSlot = 
  0xA16A3CB3A8861AD97EB93808D8EFBB8A4A4B6EC0C8563D6DA823A8190F8645EB;

/// @notice Populates 'redeployStaticParamsAndKernelSlot' slots in transient
/// storage.
///
/// @param poolId The 'poolId' whose static parameters to be redeployed.
/// @param sourcePointer The current static parameters are read using this
/// storage pointer.
/// @param targetPointer The updated static parameters are written on this
/// storage pointer.
/// @param poolGrowthPortion The updated value for 'poolGrowthPortion'.
/// @param maxPoolGrowthPortion The updated value for 'maxPoolGrowthPortion'.
/// @param protocolGrowthPortion The updated value for 'protocolGrowthPortion'.
/// @param pendingKernelLength The updated value for 'pendingKernelLength'.
function writeRedeployStaticParamsAndKernel(
  uint256 poolId,
  uint256 sourcePointer,
  uint256 targetPointer,
  X47 poolGrowthPortion,
  X47 maxPoolGrowthPortion,
  X47 protocolGrowthPortion,
  Index pendingKernelLength
) {
  // This content of this slot in transient storage serves as an indication
  // that the redeploy parameters are written.
  writeTransient(redeployStaticParamsAndKernelSlot, type(uint256).max);

  unchecked {
    // The dedicated space in transient storage is populated by 'poolId'.
    writeTransient(
      redeployStaticParamsAndKernelSlot - 1,
      poolId
    );

    // The dedicated space in transient storage is populated with
    // 'sourcePointer'.
    writeTransient(
      redeployStaticParamsAndKernelSlot - 2,
      sourcePointer
    );

    // The dedicated space in transient storage is populated with
    // 'targetPointer'.
    writeTransient(
      redeployStaticParamsAndKernelSlot - 3,
      targetPointer
    );

    // The dedicated space in transient storage is populated with
    // 'poolGrowthPortion'.
    writeTransient(
      redeployStaticParamsAndKernelSlot - 4,
      poolGrowthPortion
    );

    // The dedicated space in transient storage is populated with
    // 'maxPoolGrowthPortion'.
    writeTransient(
      redeployStaticParamsAndKernelSlot - 5,
      maxPoolGrowthPortion
    );

    // The dedicated space in transient storage is populated with
    // 'protocolGrowthPortion'.
    writeTransient(
      redeployStaticParamsAndKernelSlot - 6,
      protocolGrowthPortion
    );

    // The dedicated space in transient storage is populated with
    // 'pendingKernelLength'.
    writeTransient(
      redeployStaticParamsAndKernelSlot - 7,
      pendingKernelLength
    );
  }

  bytes4 selector0 = bytes4(keccak256('dispatch(bytes)'));
  bytes4 selector1 = bytes4(keccak256('redeployStaticParamsAndKernel()'));
  bool success;
  assembly {
    // The following lines invoke:
    //
    //    'INofeeswapDelegatee(address(this)).dispatch(
    //        INofeeswapDelegatee.redeployStaticParamsAndKernel().selector
    //     )'
    //
    // To this end, the following 72 bytes of calldata are written in memory.
    //
    //    0           4      36     68          72
    //    |           |      |      |           |
    //    +-----------+------+------+-----------+
    //    | selector0 | 0x20 | 0x04 | selector1 |
    //    +-----------+------+------+-----------+
    //
    let freeMemoryPointer := mload(0x40)
    mstore(40, shr(224, selector1))
    mstore(36, 4)
    mstore(4, 32)
    mstore(0, selector0)
    success := delegatecall(gas(), address(), 0, 72, 0, 0)
    mstore(0x40, freeMemoryPointer)
  }
  require(success, DeploymentFailed());
}

/// @notice Clears 'redeployStaticParamsAndKernelSlot' slots in transient
/// storage.
///
/// @param poolId The 'poolId' whose static parameters to be redeployed.
/// @param sourcePointer The current static parameters are read using this
/// storage pointer.
/// @param targetPointer The updated static parameters are written on this
/// storage pointer.
/// @param poolGrowthPortion The updated value for 'poolGrowthPortion'.
/// @param maxPoolGrowthPortion The updated value for 'maxPoolGrowthPortion'.
/// @param protocolGrowthPortion The updated value for 'protocolGrowthPortion'.
/// @param pendingKernelLength The updated value for 'pendingKernelLength'.
function readRedeployStaticParamsAndKernel() returns (
  uint256 poolId,
  uint256 sourcePointer,
  uint256 targetPointer,
  X47 poolGrowthPortion,
  X47 maxPoolGrowthPortion,
  X47 protocolGrowthPortion,
  Index pendingKernelLength
) {
  unchecked {
    // The content of 'redeployStaticParamsAndKernelSlot' is read from
    // transient storage and should not be equal to zero indicating that
    // redeploy parameters are written and the call is from 'address(this)'.
    require(
      readUint256Transient(redeployStaticParamsAndKernelSlot) > 0,
      CannotRedeployStaticParamsAndKernelExternally()
    );
    
    // 'poolId' is read from the dedicated space in transient storage.
    poolId = readUint256Transient(redeployStaticParamsAndKernelSlot - 1);

    // 'sourcePointer' is read from the dedicated space in transient storage.
    sourcePointer = readUint256Transient(
      redeployStaticParamsAndKernelSlot - 2
    );

    // 'targetPointer' is read from the dedicated space in transient storage.
    targetPointer = readUint256Transient(
      redeployStaticParamsAndKernelSlot - 3
    );

    // 'poolGrowthPortion' is read from the dedicated space in transient
    // storage.
    poolGrowthPortion = readX47Transient(
      redeployStaticParamsAndKernelSlot - 4
    );

    // 'maxPoolGrowthPortion' is read from the dedicated space in transient
    // storage.
    maxPoolGrowthPortion = readX47Transient(
      redeployStaticParamsAndKernelSlot - 5
    );

    // 'protocolGrowthPortion' is read from the dedicated space in transient
    // storage.
    protocolGrowthPortion = readX47Transient(
      redeployStaticParamsAndKernelSlot - 6
    );

    // 'pendingKernelLength' is read from the dedicated space in transient
    // storage.
    pendingKernelLength = readIndexTransient(
      redeployStaticParamsAndKernelSlot - 7
    );

    // All of the redeploy parameters are cleared from transient storage.
    writeTransient(redeployStaticParamsAndKernelSlot, uint256(0));
    writeTransient(redeployStaticParamsAndKernelSlot - 1, uint256(0));
    writeTransient(redeployStaticParamsAndKernelSlot - 2, uint256(0));
    writeTransient(redeployStaticParamsAndKernelSlot - 3, uint256(0));
    writeTransient(redeployStaticParamsAndKernelSlot - 4, uint256(0));
    writeTransient(redeployStaticParamsAndKernelSlot - 5, uint256(0));
    writeTransient(redeployStaticParamsAndKernelSlot - 6, uint256(0));
    writeTransient(redeployStaticParamsAndKernelSlot - 7, uint256(0));
  }
}