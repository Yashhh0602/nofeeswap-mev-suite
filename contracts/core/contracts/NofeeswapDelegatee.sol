// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {INofeeswapDelegatee} from "./interfaces/INofeeswapDelegatee.sol";
import {ISentinel} from "./interfaces/ISentinel.sol";
import {
  readInitializeInput,
  readModifyPositionInput,
  readDonateInput,
  readCollectInput,
  readModifyKernelInput,
  readModifyPoolGrowthPortionInput,
  readUpdateGrowthPortionsInput
} from "./utilities/Calldata.sol";
import {
  _endOfStaticParams_,
  getPoolId,
  getCurve,
  getShares,
  getStaticParamsStoragePointerExtension,
  getLogPriceMinOffsetted,
  getLogPriceMaxOffsetted,
  getTag0,
  getTag1,
  getSharesTotal,
  getLogPriceCurrent,
  getIntegral0,
  getIntegral1,
  getGrowth,
  getShares,
  getAccrued0,
  getPoolRatio0,
  getAccrued1,
  getPoolRatio1,
  getPendingKernelLength,
  getPoolGrowthPortion,
  getMaxPoolGrowthPortion,
  getProtocolGrowthPortion,
  getLogPriceMin,
  getLogPriceMax,
  setPoolGrowthPortion,
  setMaxPoolGrowthPortion,
  setProtocolGrowthPortion,
  setPendingKernelLength,
  setStaticParamsStoragePointerExtension,
  setAccrued1,
  setPoolRatio1,
  setAccrued0,
  setPoolRatio0,
  setSharesTotal,
  setPoolId,
  setGrowth,
  setKernel,
  setKernelLength,
  setLogPriceCurrent,
  setCurveLength,
  setPositionAmount0,
  setPositionAmount1
} from "./utilities/Memory.sol";
import {
  isProtocolUnlocked,
  lockPool,
  unlockPool,
  updateTransientBalance,
  readRedeployStaticParamsAndKernel,
  writeRedeployStaticParamsAndKernel,
  getPoolLockSlot,
  checkBurntPosition
} from "./utilities/Transient.sol";
import {
  readGrowthPortions,
  writeGrowthMultipliers,
  writeCurve,
  writeStaticParams,
  writeDynamicParams,
  writeStorage,
  getPoolOwnerSlot,
  readProtocol,
  getProtocolOwner,
  getGrowthPortions,
  writeProtocol,
  readDynamicParams,
  readStaticParams,
  readBoundaries,
  modifySharesDelta,
  readGrowthMultiplier0,
  readGrowthMultiplier1,
  readAccruedParams,
  writeAccruedParams,
  readSentinel,
  writeSentinel,
  readPoolOwner,
  writePoolOwner,
  incrementBalance,
  getKernelLength,
  readStaticParamsAndKernel,
  getStaticParamsStorageAddress,
  updateTotalSupply
} from "./utilities/Storage.sol";
import {
  calculateMaxIntegrals,
  calculateIntegrals
} from "./utilities/Interval.sol";
import {Index} from "./utilities/Index.sol";
import {
  validateFlags,
  isPreInitialize,
  isPostInitialize,
  isPreMint,
  isMidMint,
  isPostMint,
  isPreBurn,
  isMidBurn,
  isPostBurn,
  isPreDonate,
  isMidDonate,
  isPostDonate,
  isPreModifyKernel,
  isMidModifyKernel,
  isPostModifyKernel,
  isMutableKernel,
  isDonateAllowed,
  isMutablePoolGrowthPortion,
  invokePreInitialize,
  invokePostInitialize,
  invokePreMint,
  invokePreBurn,
  invokeMidMint,
  invokeMidBurn,
  invokePostMint,
  invokePostBurn,
  invokeMidDonate,
  invokePostDonate,
  invokePreDonate,
  invokePostDonate,
  invokePreModifyKernel,
  invokeMidModifyKernel,
  invokePostModifyKernel
} from "./utilities/Hooks.sol";
import {Tag, TagLibrary} from "./utilities/Tag.sol";
import {
  isGrowthPortion,
  calculateGrowthPortion
} from "./utilities/GrowthPortion.sol";
import {updateGrowth} from "./utilities/Growth.sol";
import {
  emitInitializeEvent,
  emitModifyProtocolEvent,
  emitModifyPositionEvent,
  emitDonateEvent,
  emitModifySentinelEvent,
  emitModifyPoolOwnerEvent,
  emitProtocolCollectionEvent,
  emitPoolCollectionEvent,
  emitModifyKernelEvent,
  emitModifyPoolGrowthPortionEvent,
  emitUpdateGrowthPortionsEvent
} from "./utilities/Events.sol";
import {
  invokeAuthorizeInitialization,
  invokeAuthorizeModificationOfPoolGrowthPortion
} from "./utilities/SentinelCalls.sol";
import {
  safeOutOfRangeAmount,
  safeInRangeAmount
} from "./utilities/Amount.sol";
import {zeroIndex} from "./utilities/Index.sol";
import {X23, zeroX23, oneX23} from "./utilities/X23.sol";
import {X47, oneX47, min} from "./utilities/X47.sol";
import {X59, thirtyTwoX59} from "./utilities/X59.sol";
import {oneX111} from "./utilities/X111.sol";
import {X127} from "./utilities/X127.sol";
import {KernelCompact} from "./utilities/KernelCompact.sol";
import {Kernel} from "./utilities/Kernel.sol";
import {
  AdminCannotBeAddressZero,
  OnlyByProtocol,
  OnlyByPoolOwner,
  InvalidGrowthPortion,
  LogPriceMinIsNotSpaced,
  LogPriceMaxIsNotSpaced,
  LogPricesOutOfOrder,
  LogPriceMaxIsInBlankArea,
  LogPriceMinIsInBlankArea,
  DonateIsNotAllowed,
  CannotDonateToEmptyInterval,
  ImmutableKernel,
  ImmutablePoolGrowthPortion,
  NoDelegateCall
} from "./utilities/Errors.sol";

using TagLibrary for uint256;

contract NofeeswapDelegatee is INofeeswapDelegatee {
  address immutable nofeeswap;

  constructor(address _nofeeswap) {
    nofeeswap = _nofeeswap;
  }

  /// @notice Prevents delegate calls to nofeeswap protocol.
  modifier sentry() {
    require(address(this) == nofeeswap, NoDelegateCall(address(this)));
    _;
  }

  /// @inheritdoc INofeeswapDelegatee
  function initialize(
    uint256 unsaltedPoolId,
    Tag tag0,
    Tag tag1,
    X47 poolGrowthPortion,
    uint256[] calldata kernelCompactArray,
    uint256[] calldata curveArray,
    bytes calldata hookData
  ) external override sentry {
    // Reads input parameters from calldata and sets them in appropriate memory
    // locations. A memory pointer for 'kernelCompact' is returned. The free 
    // memory pointer is set by this function as well.
    KernelCompact kernelCompact = readInitializeInput();

    // Safeguard against attempting to initialize again via the
    // 'isPreInitialize' hook.
    uint256 poolLockSlot = getPoolLockSlot();
    unchecked {
      lockPool(poolLockSlot + 1);
    }

    // Pre initialize hook is invoked next.
    if (isPreInitialize()) invokePreInitialize();

    // Safeguard against all other operations except initialize.
    lockPool(poolLockSlot);

    // Validates 'poolId' by verifying flags and the hook address.
    validateFlags();

    // Reads 'maxPoolGrowthPortion' and 'protocolGrowthPortion' from the
    // Sentinel contract or storage.
    readGrowthPortions();

    // Sets 'oneX111' as the initial growth value for the current active
    // interval.
    setGrowth(oneX111);

    {
      // Validates the ordering of the given curve and returns the current 
      // active interval boundaries.
      (X59 qLower, X59 qUpper) = getCurve().validate();

      // 'kernelCompact' is validated and its length is determined. 
      kernelCompact.validate();

      // 'kernelCompact' is expanded into 'kernel' in its dedicated memory 
      // location.
      kernelCompact.expand();

      // 'outgoingMax' and 'incomingMax' are calculated as well as
      // 'outgoingMaxModularInverse'.
      calculateMaxIntegrals();

      // Growth multipliers for current interval boundaries are calculated and
      // written on storage.
      writeGrowthMultipliers(qLower, qUpper);
    }

    // This step calculates current values for 'integral0' and 'integral1'.
    calculateIntegrals();

    // Sentinel is invoked.
    invokeAuthorizeInitialization();
    invokeAuthorizeModificationOfPoolGrowthPortion();

    // All parameters are written on storage.
    writeCurve();
    writeStaticParams(0);
    writeDynamicParams();
    writeStorage(getPoolOwnerSlot(getPoolId()), uint256(uint160(msg.sender)));

    // The lock is cleared to open the pool for other actions.
    unlockPool(poolLockSlot);

    // Initialize event is emitted next.
    emitInitializeEvent();

    // Post initialize hook is invoked next.
    if (isPostInitialize()) invokePostInitialize();
  }

  /// @inheritdoc INofeeswapDelegatee
  function modifyPosition(
    uint256 poolId,
    X59 logPriceMin,
    X59 logPriceMax,
    int256 shares,
    bytes calldata hookData
  ) external override sentry returns (
    int256 amount0,
    int256 amount1
  ) {
    // Safeguard against reentrancy.
    isProtocolUnlocked();

    // Reads input parameters from calldata and sets them in appropriate memory
    // locations.
    readModifyPositionInput();

    // Pre mint/burn hook is invoked next.
    if (isPreMint()) {
      if (getShares() > 0) invokePreMint();
    }
    if (isPreBurn()) {
      if (getShares() < 0) invokePreBurn();
    }

    // Safeguard against reentrancy.
    uint256 poolLockSlot = getPoolLockSlot();
    lockPool(poolLockSlot);

    // Dynamic parameters are read from storage.
    readDynamicParams();

    // Static parameters are read excluding the kernel.
    readStaticParams(
      getStaticParamsStorageAddress(getStaticParamsStoragePointerExtension())
    );

    // Curve boundaries (the first two members) are read.
    (X59 qLower, X59 qUpper) = readBoundaries();

    // Boundaries of the current active interval are read using which 'qMin'
    // and 'qMax' are validated.
    X59 qMin = getLogPriceMinOffsetted();
    X59 qMax = getLogPriceMaxOffsetted();

    {
      X59 qSpacing = qUpper - qLower;
      require(
        qMin % qSpacing == qUpper % qSpacing,
        LogPriceMinIsNotSpaced(qMin)
      );
      require(
        qMax % qSpacing == qUpper % qSpacing,
        LogPriceMaxIsNotSpaced(qMax)
      );
      require(qMin < qMax, LogPricesOutOfOrder(qMin, qMax));
      require(qMax < thirtyTwoX59 - qSpacing, LogPriceMaxIsInBlankArea(qMax));
      require(qMin > qSpacing, LogPriceMinIsInBlankArea(qMin));
    }

    // Mid mint/burn hook is invoked next.
    if (isMidMint()) {
      if (getShares() >= 0) invokeMidMint();
    }
    if (isMidBurn()) {
      if (getShares() <= 0) invokeMidBurn();
    }

    // 'sharesDelta' is updated to reflect the number of shares to be
    // minted/burned.
    modifySharesDelta();

    // In each of the following scenarios, the incoming/outgoing values are
    // calculated accordingly.
    if (qUpper <= qMin) {
      amount0 = safeOutOfRangeAmount(
        // The subtraction is safe because by definition:
        // 'readGrowthMultiplierMin > readGrowthMultiplierMax'
        readGrowthMultiplier0(qMin) - readGrowthMultiplier0(qMax),
        false
      ).toIntegerRoundUp();
    } else if (qMax <= qLower) {
      amount1 = safeOutOfRangeAmount(
        // The subtraction is safe because by definition:
        // 'readGrowthMultiplierMax > readGrowthMultiplierMin'
        readGrowthMultiplier1(qMax) - readGrowthMultiplier1(qMin),
        true
      ).toIntegerRoundUp();
    } else {
      {
        X127 amount0Inside;
        if (getLogPriceCurrent() != qUpper) {
          amount0Inside = safeInRangeAmount(
            getIntegral0(),
            getGrowth().times(getShares()),
            false,
            true
          );
        }
        X127 amount0Outside = safeOutOfRangeAmount(
          // The subtraction is safe because by definition:
          // 'readGrowthMultiplierUpper > readGrowthMultiplierMax'
          readGrowthMultiplier0(qUpper) - readGrowthMultiplier0(qMax),
          false
        );
        amount0 = (amount0Inside & amount0Outside).toIntegerRoundUp();
      }

      {
        X127 amount1Inside;
        if (getLogPriceCurrent() != qLower) {
          amount1Inside = safeInRangeAmount(
            getIntegral1(),
            getGrowth().times(getShares()),
            true,
            true
          );
        }
        X127 amount1Outside = safeOutOfRangeAmount(
          // The subtraction is safe because by definition:
          // 'readGrowthMultiplierLower > readGrowthMultiplierMin'
          readGrowthMultiplier1(qLower) - readGrowthMultiplier1(qMin),
          true
        );
        amount1 = (amount1Inside & amount1Outside).toIntegerRoundUp();
      }

      // 'sharesTotal' should be updated and stored among other dynamic
      // parameters.
      setSharesTotal(uint256(int256(getSharesTotal()) + getShares()));

      // Since sharesTotal is modified, dynamic parameters need to be written. 
      writeDynamicParams();
    }

    // Transient balances are updated accordingly.
    unchecked {
      updateTransientBalance(
        msg.sender,
        getPoolId().tag(getLogPriceMin(), getLogPriceMax()),
        0 - getShares()
      );
    }
    updateTransientBalance(msg.sender, getTag0(), amount0);
    updateTransientBalance(msg.sender, getTag1(), amount1);

    // Cannot mint a position which is burnt in the same transaction.
    checkBurntPosition(getPoolId(), qMin, qMax, getShares());

    // Total supply of this LP position (see ERC6909 specifications).
    updateTotalSupply(getPoolId(), qMin, qMax, getShares());

    // The lock is cleared to open the pool for other actions.
    unlockPool(poolLockSlot);

    // An event is emitted.
    setPositionAmount0(amount0);
    setPositionAmount1(amount1);
    emitModifyPositionEvent();

    // Post mint/burn hook is invoked next.
    if (isPostMint()) {
      if (getShares() >= 0) invokePostMint();
    }
    if (isPostBurn()) {
      if (getShares() <= 0) invokePostBurn();
    }
  }

  /// @inheritdoc INofeeswapDelegatee
  function donate(
    uint256 poolId,
    uint256 shares,
    bytes calldata hookData
  ) external override sentry returns (
    int256 amount0,
    int256 amount1
  ) {
    // Safeguard against reentrancy.
    isProtocolUnlocked();

    // Reads input parameters from calldata and sets them in appropriate memory
    // locations.
    readDonateInput();

    // Checks the donate flag.
    require(isDonateAllowed(), DonateIsNotAllowed(getPoolId()));

    // Pre donate hook is invoked next.
    if (isPreDonate()) invokePreDonate();

    // Safeguard against reentrancy.
    uint256 poolLockSlot = getPoolLockSlot();
    lockPool(poolLockSlot);

    // Dynamic parameters are read from storage and we check whether pool exists
    readDynamicParams();
    require(getSharesTotal() != 0, CannotDonateToEmptyInterval());

    // Static parameters are read excluding the kernel.
    readStaticParams(
      getStaticParamsStorageAddress(getStaticParamsStoragePointerExtension())
    );

    // 'poolGrowthPortion' is capped by 'maxPoolGrowthPortion'.
    setPoolGrowthPortion(
      min(getPoolGrowthPortion(), getMaxPoolGrowthPortion())
    );

    // Accrued growth portions are read from storage.
    if (isGrowthPortion()) readAccruedParams();

    // Curve boundaries (the first two members) are read.
    (X59 lower, X59 upper) = readBoundaries();

    // Mid donate hook is invoked next.
    if (isMidDonate()) invokeMidDonate();

    // 'amount0' and 'amount1' are calculated next.
    X127 amount0X127;
    if (getLogPriceCurrent() != upper) {
      amount0X127 = safeInRangeAmount(
        getIntegral0(),
        getGrowth().times(getShares()),
        false,
        true
      );
    }
    X127 amount1X127;
    if (getLogPriceCurrent() != lower) {
      amount1X127 = safeInRangeAmount(
        getIntegral1(),
        getGrowth().times(getShares()),
        true,
        true
      );
    }

    //  Update the current growth value to
    // 'growth + growth * p * q * shares / sharesTotal' where
    // 'p = 1 - protocolGrowthPortion' and 'q = 1 - poolGrowthPortion'.
    setGrowth(updateGrowth(getGrowth(), getShares(), getSharesTotal()));
    
    // Accrued growth portions are updated next.
    if (isGrowthPortion()) {
      (X127 updatedAccrued0, X23 updatedPoolRatio0) = calculateGrowthPortion(
        amount0X127,
        getAccrued0(),
        getPoolRatio0()
      );
      setAccrued0(updatedAccrued0);
      setPoolRatio0(updatedPoolRatio0);

      (X127 updatedAccrued1, X23 updatedPoolRatio1) = calculateGrowthPortion(
        amount1X127,
        getAccrued1(),
        getPoolRatio1()
      );
      setAccrued1(updatedAccrued1);
      setPoolRatio1(updatedPoolRatio1);
    }

    // Dynamic parameters and accrued growth portions are stored.
    writeDynamicParams();
    if (isGrowthPortion()) writeAccruedParams();

    // Transient balances are updated accordingly.
    amount0 = amount0X127.toIntegerRoundUp();
    amount1 = amount1X127.toIntegerRoundUp();
    updateTransientBalance(msg.sender, getTag0(), amount0);
    updateTransientBalance(msg.sender, getTag1(), amount1);

    // The lock is cleared to open the pool for other actions.
    unlockPool(poolLockSlot);

    // An event is emitted.
    emitDonateEvent();

    // Post donate hook is invoked next.
    if (isPostDonate()) invokePostDonate();
  }

  /// @inheritdoc INofeeswapDelegatee
  function modifyKernel(
    uint256 poolId,
    uint256[] calldata kernelCompactArray,
    bytes calldata hookData
  ) external override sentry {
    // Reads input parameters from calldata and sets them in appropriate memory
    // locations. A pointer for 'kernelCompact' is returned.
    KernelCompact kernelCompact = readModifyKernelInput();

    // Check whether the kernel is mutable.
    require(isMutableKernel(), ImmutableKernel(getPoolId()));

    // Checks the pool owner.
    {
      address owner = readPoolOwner(getPoolOwnerSlot(getPoolId()));
      require(msg.sender == owner, OnlyByPoolOwner(msg.sender, owner));
    }

    // Pre modifyKernel hook is invoked next.
    if (isPreModifyKernel()) invokePreModifyKernel();

    // Safeguard against reentrancy.
    uint256 poolLockSlot = getPoolLockSlot();
    lockPool(poolLockSlot);

    // Read dynamic parameters from which we determine whether the pool exists.
    readDynamicParams();

    // Static parameters are read (excluding the current kernel).
    readStaticParams(
      getStaticParamsStorageAddress(getStaticParamsStoragePointerExtension())
    );

    {
      // Reads 'qLower' and 'qUpper' boundaries of the current interval from
      // storage.
      readBoundaries();

      // 'kernelCompact' is validated and its length is determined. 
      kernelCompact.validate();

      // 'kernelCompact' is expanded into 'kernel' in its dedicated memory 
      // location.
      kernelCompact.expand();

      // 'outgoingMax' and 'incomingMax' are calculated as well as
      // 'outgoingMaxModularInverse'.
      calculateMaxIntegrals();
    }

    // Mid modifyKernel hook is invoked next.
    if (isMidModifyKernel()) invokeMidModifyKernel();

    // If there is no pending kernel already,
    // - The current kernel will be deployed to 'pointer + 1' with a new
    //   'pendingKernelLength' value.
    // - The new kernel will be deployed to 'pointer + 2'.
    // If there is a pending kernel, then 'pointer + 1' is occupied. Hence:
    // - The current kernel will be deployed to 'pointer + 2' with a new
    //   'pendingKernelLength' value.
    // - The new kernel will be deployed to storage 'pointer + 3'.
    uint256 pointer = getStaticParamsStoragePointerExtension();
    uint256 nextPointer;
    unchecked {
      nextPointer = pointer + 1;
      if (getPendingKernelLength() > zeroIndex) ++nextPointer;

      // The current kernel is redeployed with a new 'pendingKernelLength'
      // value.
      writeRedeployStaticParamsAndKernel(
        getPoolId(),
        pointer,
        nextPointer,
        getPoolGrowthPortion(),
        getMaxPoolGrowthPortion(),
        getProtocolGrowthPortion(),
        getKernelLength()
      );
      setStaticParamsStoragePointerExtension(nextPointer);

      // The new kernel is deployed.
      setPendingKernelLength(zeroIndex);
      writeStaticParams(nextPointer + 1);
    }

    // Dynamic parameters are updated to include the new pointer.
    writeDynamicParams();

    // The lock is cleared to open the pool for other actions.
    unlockPool(poolLockSlot);

    // An event is emitted next.
    emitModifyKernelEvent();

    // Post modifyKernel hook is invoked next.
    if (isPostModifyKernel()) invokePostModifyKernel();
  }

  /// @inheritdoc INofeeswapDelegatee
  function modifyProtocol(
    uint256 protocol
  ) external override sentry {
    address owner = getProtocolOwner(readProtocol());
    require(msg.sender == owner, OnlyByProtocol(msg.sender, owner));
    require(
      getProtocolOwner(protocol) != address(0),
      AdminCannotBeAddressZero()
    );

    (
      X47 maxPoolGrowthPortion,
      X47 protocolGrowthPortion
    ) = getGrowthPortions(protocol);
    require(
      maxPoolGrowthPortion <= oneX47,
      InvalidGrowthPortion(maxPoolGrowthPortion)
    );
    require(
      protocolGrowthPortion <= oneX47,
      InvalidGrowthPortion(protocolGrowthPortion)
    );

    // The new protocol is written on storage.
    writeProtocol(protocol);

    // An event is fired.
    emitModifyProtocolEvent(protocol);
  }

  /// @inheritdoc INofeeswapDelegatee
  function modifySentinel(
    ISentinel sentinel
  ) external override sentry {
    address owner = getProtocolOwner(readProtocol());
    require(msg.sender == owner, OnlyByProtocol(msg.sender, owner));

    // The old sentinel contract is read from storage.
    ISentinel sentinelOld = readSentinel();

    // The new sentinel contract is written on storage.
    writeSentinel(sentinel);

    // An event is fired.
    emitModifySentinelEvent(sentinelOld, sentinel);
  }

  /// @inheritdoc INofeeswapDelegatee
  function modifyPoolOwner(
    uint256 poolId,
    address newOwner
  ) external override sentry {
    uint256 slot = getPoolOwnerSlot(poolId);
    address oldOwner = readPoolOwner(slot);
    require(msg.sender == oldOwner, OnlyByPoolOwner(msg.sender, oldOwner));
    require(newOwner != address(0), AdminCannotBeAddressZero());

    // The new pool owner is written on storage.
    writePoolOwner(slot, newOwner);

    // An event is fired.
    emitModifyPoolOwnerEvent(poolId, oldOwner, newOwner);
  }

  /// @inheritdoc INofeeswapDelegatee
  function modifyPoolGrowthPortion(
    uint256 poolId,
    X47 poolGrowthPortion
  ) external override sentry {
    // Places the input parameters in memory and sets the input for sentinel
    // call.
    readModifyPoolGrowthPortionInput();

    // Check whether the pool growth portion is mutable.
    require(
      isMutablePoolGrowthPortion(),
      ImmutablePoolGrowthPortion(getPoolId())
    );

    // Safeguard against reentrancy.
    uint256 poolLockSlot = getPoolLockSlot();
    lockPool(poolLockSlot);

    // Checks the pool owner.
    {
      address owner = readPoolOwner(getPoolOwnerSlot(getPoolId()));
      require(msg.sender == owner, OnlyByPoolOwner(msg.sender, owner));
    }

    // Read dynamic parameters from which we determine whether the pool exists.
    readDynamicParams();

    // The new value for the pool growth portion is cached.
    X47 poolGrowthPortionNew = getPoolGrowthPortion();

    // Static parameters are read (excluding the current kernel).
    readStaticParams(
      getStaticParamsStorageAddress(getStaticParamsStoragePointerExtension())
    );

    // The new value for the pool growth portion is placed in memory again.
    setPoolGrowthPortion(poolGrowthPortionNew);

    // The sentinel contract is invoked to authorize the new value for the pool
    // growth portion.
    invokeAuthorizeModificationOfPoolGrowthPortion();

    // If there is no pending kernel,
    // - The current static parameters and kernel will be deployed to 
    //   'pointer + 1'.
    // If there is a pending kernel, then 'pointer + 1' is occupied. Hence:
    // - The current static parameters and kernel will be deployed to 
    //   'pointer + 2'.
    // - The pending static parameters and kernel which is at 'pointer + 1' 
    //   will be deployed to 'pointer + 3'.
    uint256 pointer = getStaticParamsStoragePointerExtension();
    uint256 nextPointer;
    unchecked {
      nextPointer = pointer + 1;
      if (getPendingKernelLength() > zeroIndex) {
        writeRedeployStaticParamsAndKernel(
          getPoolId(),
          nextPointer,
          pointer + 3,
          poolGrowthPortionNew,
          getMaxPoolGrowthPortion(),
          getProtocolGrowthPortion(),
          zeroIndex
        );
        ++nextPointer;
      }
    }
    writeRedeployStaticParamsAndKernel(
      getPoolId(),
      pointer,
      nextPointer,
      poolGrowthPortionNew,
      getMaxPoolGrowthPortion(),
      getProtocolGrowthPortion(),
      getPendingKernelLength()
    );
    setStaticParamsStoragePointerExtension(nextPointer);

    // Dynamic parameters are updated to include the new pointer.
    writeDynamicParams();

    // The lock is cleared to open the pool for other actions.
    unlockPool(poolLockSlot);

    // An event is emitted next.
    emitModifyPoolGrowthPortionEvent();
  }

  /// @inheritdoc INofeeswapDelegatee
  function updateGrowthPortions(
    uint256 poolId
  ) external sentry {
    // Places the input parameters in memory and sets the input for sentinel
    // call.
    readUpdateGrowthPortionsInput();

    // Safeguard against reentrancy.
    uint256 poolLockSlot = getPoolLockSlot();
    lockPool(poolLockSlot);

    // Read dynamic parameters from which we determine whether the pool exists.
    readDynamicParams();

    // Static parameters are read (excluding the current kernel).
    readStaticParams(
      getStaticParamsStorageAddress(getStaticParamsStoragePointerExtension())
    );

    // The current values for growth portion values are cached.
    X47 maxPoolGrowthPortionCurrent = getMaxPoolGrowthPortion();
    X47 protocolGrowthPortionCurrent = getProtocolGrowthPortion();

    // Reads 'maxPoolGrowthPortion' and 'protocolGrowthPortion' from sentinel
    // contract or storage.
    readGrowthPortions();

    // If different, static parameters are redeployed to include the new
    // growth portion values.
    if (
      (maxPoolGrowthPortionCurrent != getMaxPoolGrowthPortion())
       ||
      (protocolGrowthPortionCurrent != getProtocolGrowthPortion())
    ) {
      // If there is no pending kernel,
      // - The current static parameters and kernel will be deployed to 
      //   'pointer + 1'.
      // If there is a pending kernel, then 'pointer + 1' is occupied. Hence:
      // - The current static parameters and kernel will be deployed to 
      //   'pointer + 2'.
      // - The pending static parameters and kernel which is at 'pointer + 1' 
      //   will be deployed to 'pointer + 3'.
      uint256 pointer = getStaticParamsStoragePointerExtension();
      uint256 nextPointer;
      unchecked {
        nextPointer = pointer + 1;
        if (getPendingKernelLength() > zeroIndex) {
          writeRedeployStaticParamsAndKernel(
            getPoolId(),
            nextPointer,
            pointer + 3,
            getPoolGrowthPortion(),
            getMaxPoolGrowthPortion(),
            getProtocolGrowthPortion(),
            zeroIndex
          );
          ++nextPointer;
        }
      }
      writeRedeployStaticParamsAndKernel(
        getPoolId(),
        pointer,
        nextPointer,
        getPoolGrowthPortion(),
        getMaxPoolGrowthPortion(),
        getProtocolGrowthPortion(),
        getPendingKernelLength()
      );
      setStaticParamsStoragePointerExtension(nextPointer);

      // Dynamic parameters are updated to include the new pointer.
      writeDynamicParams();
    }

    // The lock is cleared to open the pool for other actions.
    unlockPool(poolLockSlot);

    // An event is emitted next.
    emitUpdateGrowthPortionsEvent();
  }

  /// @inheritdoc INofeeswapDelegatee
  function collectPool(
    uint256 poolId
  ) external override sentry returns (
    uint256 amount0,
    uint256 amount1
  ) {
    // Reads input parameters from calldata and sets them in appropriate memory
    // locations.
    readCollectInput();

    // Safeguard against reentrancy.
    uint256 poolLockSlot = getPoolLockSlot();
    lockPool(poolLockSlot);

    // Pool parameters are read from storage.
    readDynamicParams();
    readStaticParams(
      getStaticParamsStorageAddress(getStaticParamsStoragePointerExtension())
    );
    readAccruedParams();

    // Pool's share of accrued growth portions are calculated.
    X127 accrued0 = getAccrued0().times(getPoolRatio0());
    X127 accrued1 = getAccrued1().times(getPoolRatio1());
    
    // Accrued parameters are updated and rewritten.
    // Subtractions are safe because 'poolRatio0' and 'poolRatio1' are not
    // greater than 'oneX23'.
    setAccrued0(getAccrued0() - accrued0);
    setAccrued1(getAccrued1() - accrued1);
    setPoolRatio0(zeroX23);
    setPoolRatio1(zeroX23);
    writeAccruedParams();

    // The resulting values are moved to the pool owner's single balance.
    amount0 = uint256(accrued0.toInteger());
    amount1 = uint256(accrued1.toInteger());
    address owner = readPoolOwner(getPoolOwnerSlot(getPoolId()));
    incrementBalance(owner, getTag0(), amount0);
    incrementBalance(owner, getTag1(), amount1);

    // The lock is cleared to open the pool for other actions.
    unlockPool(poolLockSlot);

    // An event is emitted next.
    emitPoolCollectionEvent(getPoolId(), owner, amount0, amount1);
  }

  /// @inheritdoc INofeeswapDelegatee
  function collectProtocol(
    uint256 poolId
  ) external override sentry returns (
    uint256 amount0,
    uint256 amount1
  ) {
    // Reads input parameters from calldata and sets them in appropriate memory
    // locations.
    readCollectInput();

    // Safeguard against reentrancy.
    uint256 poolLockSlot = getPoolLockSlot();
    lockPool(poolLockSlot);

    // Pool parameters are read from storage.
    readDynamicParams();
    readStaticParams(
      getStaticParamsStorageAddress(getStaticParamsStoragePointerExtension())
    );
    readAccruedParams();

    // Pool's share of accrued growth portions are calculated.
    // Subtractions are safe because 'poolRatio0' and 'poolRatio1' are not
    // greater than 'oneX23'.
    X127 accrued0 = getAccrued0().times(oneX23 - getPoolRatio0());
    X127 accrued1 = getAccrued1().times(oneX23 - getPoolRatio1());

    // Accrued parameters are updated and rewritten.
    // Subtractions are safe because 'poolRatio0' and 'poolRatio1' are not
    // greater than 'oneX23'.
    setAccrued0(getAccrued0() - accrued0);
    setAccrued1(getAccrued1() - accrued1);
    setPoolRatio0(oneX23);
    setPoolRatio1(oneX23);
    writeAccruedParams();

    // The resulting values are moved to protocol's single balance.
    amount0 = uint256(accrued0.toInteger());
    amount1 = uint256(accrued1.toInteger());
    address owner = getProtocolOwner(readProtocol());
    incrementBalance(owner, getTag0(), amount0);
    incrementBalance(owner, getTag1(), amount1);

    // The lock is cleared to open the pool for other actions.
    unlockPool(poolLockSlot);

    // An event is emitted next.
    emitProtocolCollectionEvent(getPoolId(), amount0, amount1);
  }

  /// @notice Redeploys static parameters and kernel through delegatecall to
  /// self.
  function redeployStaticParamsAndKernel() external sentry {
    (
      uint256 poolId,
      uint256 sourcePointer,
      uint256 targetPointer,
      X47 poolGrowthPortion,
      X47 maxPoolGrowthPortion,
      X47 protocolGrowthPortion,
      Index pendingKernelLength
    ) = readRedeployStaticParamsAndKernel();
    Kernel kernel;
    assembly {
      kernel := _endOfStaticParams_
    }
    setKernel(kernel);
    setPoolId(poolId);
    readStaticParamsAndKernel(getStaticParamsStorageAddress(sourcePointer));
    setPoolGrowthPortion(poolGrowthPortion);
    setMaxPoolGrowthPortion(maxPoolGrowthPortion);
    setProtocolGrowthPortion(protocolGrowthPortion);
    setPendingKernelLength(pendingKernelLength);
    writeStaticParams(targetPointer);
  }
}