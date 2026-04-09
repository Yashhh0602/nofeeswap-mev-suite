// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {setPoolId} from "../utilities/Memory.sol";
import "../utilities/Transient.sol";

/// @title This contract exposes the internal functions of 'Transient.sol' for 
/// testing purposes.
contract TransientWrapper {
  function _unlockTargetSlot() public returns (
    uint256 transientSlot
  ) {
    return unlockTargetSlot;
  }

  function _callerSlot() public returns (
    uint256 transientSlot
  ) {
    return callerSlot;
  }

  function _lockUnlockProtocol(
    address unlockTarget,
    address caller
  ) public returns (
    address unlockTargetResult0,
    address callerResult0,
    address unlockTargetResult1,
    address callerResult1
  ) {
    unlockProtocol(unlockTarget, caller);
    assembly {
      unlockTargetResult0 := tload(unlockTargetSlot)
      callerResult0 := tload(callerSlot)
    }

    lockProtocol();
    assembly {
      unlockTargetResult1 := tload(unlockTargetSlot)
      callerResult1 := tload(callerSlot)
    }
  }

  function _isProtocolUnlocked(
    address unlockTarget,
    address caller
  ) public {
    unlockProtocol(unlockTarget, caller);
    isProtocolUnlocked();
  }

  function _getPoolLockSlot(
    uint256 poolId
  ) public returns (
    uint256 transientSlot
  ) {
    setPoolId(poolId);
    return getPoolLockSlot();
  }

  function _lockPoolRevert(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    uint256 poolLockSlot = getPoolLockSlot();
    lockPool(poolLockSlot);
    lockPool(poolLockSlot);
  }

  function _lockUnlockPool(
    uint256 poolId
  ) public returns (
    uint256 content0,
    uint256 content1
  ) {
    setPoolId(poolId);
    uint256 poolLockSlot = getPoolLockSlot();
    lockPool(poolLockSlot);
    uint256 transientSlot = getPoolLockSlot();
    assembly {
      content0 := tload(transientSlot)
    }
    unlockPool(poolLockSlot);
    assembly {
      content1 := tload(transientSlot)
    }
  }

  function _nonzeroAmountsSlot() public returns (
    uint256 transientSlot
  ) {
    return nonzeroAmountsSlot;
  }

  function _readNonzeroAmounts(
    uint256 increment,
    uint256 decrement
  ) public returns (
    uint256 nonzeroAmounts
  ) {
    for (uint256 ii = 0; ii < increment; ++ii) {
      incrementNonzeroAmounts();
    }
    for (uint256 ii = 0; ii < decrement; ++ii) {
      decrementNonzeroAmounts();
    }
    return readNonzeroAmounts();
  }

  function _transientBalanceSlot() public returns (
    uint256 transientSlot
  ) {
    return transientBalanceSlot;
  }

  function _getTransientBalanceSlot(
    address owner,
    Tag tag
  ) public returns (
    uint256 transientSlot
  ) {
    return getTransientBalanceSlot(owner, tag);
  }

  function _updateGetTransientBalance(
    address[] calldata owners,
    Tag[] calldata tags,
    int256[] calldata amounts
  ) public returns (
    int256[] memory ,
    uint256
  ) {
    uint256 length = owners.length;

    for (uint256 ii = 0; ii < length; ++ii) {
      updateTransientBalance(owners[ii], tags[ii], amounts[ii]);
    }

    int256[] memory results = new int256[](length);

    for (uint256 ii = 0; ii < length; ++ii) {
      results[ii] = transientBalance(owners[ii], tags[ii]);
    }

    return (results, readNonzeroAmounts());
  }

  function _tokenSlot() public returns (
    uint256 transientSlot
  ) {
    return tokenSlot;
  }

  function _tokenIdSlot() public returns (
    uint256 transientSlot
  ) {
    return tokenIdSlot;
  }

  function _reserveSlot() public returns (
    uint256 transientSlot
  ) {
    return reserveSlot;
  }

  function _writeReadReserve(
    address token,
    uint256 tokenId,
    uint256 reserve,
    bool multiToken
  ) public returns (
    address tokenResult,
    uint256 tokenIdResult,
    uint256 reserveResult,
    bool multiTokenResult
  ) {
    writeReserveToken(token, multiToken);
    writeReserveTokenId(tokenId);
    writeReserveValue(reserve);
    (
      tokenResult,
      tokenIdResult,
      reserveResult,
      multiTokenResult
    ) = readReserve();
  }

  function _burntPositionSlot() public returns (
    uint256 transientSlot
  ) {
    return burntPositionSlot;
  }

  function _checkBurntPosition(
    uint256 poolId,
    X59 qMin,
    X59 qMax,
    int256 shares,
    uint256 transientSlot
  ) public returns (
    uint256 content
  ) {
    checkBurntPosition(poolId, qMin, qMax, shares);
    return readUint256Transient(transientSlot);
  }

  function _checkBurntPositionBurnMint(
    uint256 poolId,
    X59 qMin,
    X59 qMax,
    int256 shares,
    uint256 transientSlot
  ) public returns (
    uint256 content
  ) {
    checkBurntPosition(poolId, qMin, qMax, 0 - shares);
    checkBurntPosition(poolId, qMin, qMax, shares);
    return readUint256Transient(transientSlot);
  }

  function _redeployStaticParamsAndKernelSlot() public returns (
    uint256 transientSlot
  ) {
    return redeployStaticParamsAndKernelSlot;
  }

  function _redeployStaticParamsAndKernel(
    uint256 poolId,
    uint256 sourcePointer,
    uint256 targetPointer,
    X47 poolGrowthPortion,
    X47 maxPoolGrowthPortion,
    X47 protocolGrowthPortion,
    Index pendingKernelLength
  ) public returns (
    uint256 poolIdResult,
    uint256 sourcePointerResult,
    uint256 targetPointerResult,
    X47 poolGrowthPortionResult,
    X47 maxPoolGrowthPortionResult,
    X47 protocolGrowthPortionResult,
    Index pendingKernelLengthResult,
    bool testValue
  ) {
    writeRedeployStaticParamsAndKernel(
      poolId,
      sourcePointer,
      targetPointer,
      poolGrowthPortion,
      maxPoolGrowthPortion,
      protocolGrowthPortion,
      pendingKernelLength
    );

    testValue = test;

    (
      poolIdResult,
      sourcePointerResult,
      targetPointerResult,
      poolGrowthPortionResult,
      maxPoolGrowthPortionResult,
      protocolGrowthPortionResult,
      pendingKernelLengthResult
    ) = readRedeployStaticParamsAndKernel();

    test = false;
  }

  function _clearRedeployStaticParamsAndKernel(
    uint256 poolId,
    uint256 sourcePointer,
    uint256 targetPointer,
    X47 poolGrowthPortion,
    X47 maxPoolGrowthPortion,
    X47 protocolGrowthPortion,
    Index pendingKernelLength
  ) public returns (
    uint256 poolIdResult,
    uint256 sourcePointerResult,
    uint256 targetPointerResult,
    X47 poolGrowthPortionResult,
    X47 maxPoolGrowthPortionResult,
    X47 protocolGrowthPortionResult,
    Index pendingKernelLengthResult,
    bool testValue
  ) {
    writeRedeployStaticParamsAndKernel(
      poolId,
      sourcePointer,
      targetPointer,
      poolGrowthPortion,
      maxPoolGrowthPortion,
      protocolGrowthPortion,
      pendingKernelLength
    );

    testValue = test;

    readRedeployStaticParamsAndKernel();

    assembly {
      let transientSlot := sub(redeployStaticParamsAndKernelSlot, 1)
      poolIdResult := tload(transientSlot)

      transientSlot := sub(transientSlot, 1)
      sourcePointerResult := tload(transientSlot)

      transientSlot := sub(transientSlot, 1)
      targetPointerResult := tload(transientSlot)

      transientSlot := sub(transientSlot, 1)
      poolGrowthPortionResult := tload(transientSlot)

      transientSlot := sub(transientSlot, 1)
      maxPoolGrowthPortionResult := tload(transientSlot)

      transientSlot := sub(transientSlot, 1)
      protocolGrowthPortionResult := tload(transientSlot)

      transientSlot := sub(transientSlot, 1)
      pendingKernelLengthResult := tload(transientSlot)
    }

    test = false;
  }

  function _redeployStaticParamsAndKernelReverts() public {
    readRedeployStaticParamsAndKernel();
  }

  function dispatch(
    bytes calldata input
  ) external returns (
    int256 output0,
    int256 output1
  ) {
    assembly {
      let callDataCopySize := calldataload(36)
      calldatacopy(0, 68, callDataCopySize)
      if iszero(
        delegatecall(gas(), address(), 0, callDataCopySize, 0, 64)
      ) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
      return(0, 64)
    }
  }

  bool test;

  function redeployStaticParamsAndKernel() external {
    test = true;
  }
}