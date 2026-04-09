// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {
  _swapInput_,
  _endOfStaticParams_,
  _hookInputByteCount_,
  _zeroForOne_,
  setMsgSender,
  setPoolId,
  setSqrtOffset,
  setSqrtInverseOffset,
  setTag0,
  setTag1,
  setPoolGrowthPortion,
  setCurve,
  setHookData,
  setHookDataByteCount,
  setFreeMemoryPointer,
  setHookInputByteCount,
  setKernel,
  setLogPriceMin,
  setLogPriceMax,
  setLogPriceMinOffsetted,
  setLogPriceMaxOffsetted,
  setShares,
  setAmountSpecified,
  setLogPriceLimit,
  setCrossThreshold
} from "./Memory.sol";
import {getLogOffsetFromPoolId, derivePoolId} from "./PoolId.sol";
import {Index} from "./Index.sol";
import {X47, oneX47} from "./X47.sol";
import {
  X59,
  zeroX59,
  minLogOffset,
  maxLogOffset,
  sixteenX59,
  thirtyTwoX59
} from "./X59.sol";
import {X127} from "./X127.sol";
import {Tag} from "./Tag.sol";
import {Curve} from "./Curve.sol";
import {Kernel} from "./Kernel.sol";
import {KernelCompact} from "./KernelCompact.sol";
import {readStorage, getDynamicParamsSlot} from "./Storage.sol";
import {
  PoolExists,
  LogOffsetOutOfRange,
  TagsOutOfOrder,
  InvalidGrowthPortion,
  LogPriceOutOfRange,
  InvalidNumberOfShares,
  CurveLengthIsZero,
  PoolIdCannotBeZero,
  HookDataTooLong
} from "./Errors.sol";

/// @notice Reads the inputs of the external function 'initialize' and places
/// each in the appropriate memory location. Then, the free memory pointer is
/// set.
/// @return kernelCompact The memory pointer for the given 'kernelCompact'.
/// Observe that 'kernel', 'kernelCompact', 'curve', and 'hookData' are loaded
/// in memory in this order. Hence, the place of 'kernelCompact' is not
/// constant and depends on the size of 'kernel'.
function readInitializeInput() view returns (KernelCompact kernelCompact) {
  // Calldata layout for 'initialize' is as follows:
  //
  // '0x00': 'INofeeswapDelegatee.initialize.selector'
  // '0x04': 'unsaltedPoolId'
  // '0x24': 'tag0'
  // '0x44': 'tag1'
  // '0x64': 'poolGrowthPortion'
  // '0x84': 'calldata pointer to the beginning of kernelCompactArray - 0x04'
  // '0xA4': 'calldata pointer to the beginning of curveArray - 0x04'
  // '0xC4': 'calldata pointer to the beginning of hookData - 0x04'
  // '0x04 + calldataload(0x84)': 'kernelCompactArray'
  // '0x04 + calldataload(0xA4)': 'curveArray'
  // '0x04 + calldataload(0xC4)': 'hookData'

  // 'msg.sender' is placed in memory to be passed to hook via calldata.
  setMsgSender(msg.sender);

  {
    // 'unsaltedPoolId' is read from calldata and used to derive poolId which
    // will be placed in memory.
    uint256 poolId;
    {
      uint256 unsaltedPoolId;
      assembly {
        unsaltedPoolId := calldataload(4)
      }
      poolId = derivePoolId(unsaltedPoolId);
    }
    setPoolId(poolId);

    // Check 'poolId != 0'.
    require(poolId != 0, PoolIdCannotBeZero());

    // Verifies whether the pool already exists or not.
    require(
      // The first slot of dynamic parameters contains the 'logPriceCurrent'
      // which is always nonzero after initialization.
      readStorage(getDynamicParamsSlot(poolId)) == 0,
      PoolExists(poolId)
    );

    // Throws if 'qOffset' is out of range.
    X59 qOffset = getLogOffsetFromPoolId(poolId);
    require(qOffset > minLogOffset, LogOffsetOutOfRange(qOffset));
    require(qOffset < maxLogOffset, LogOffsetOutOfRange(qOffset));

    // 'sqrtOffset' and 'sqrtInverseOffset' are calculated and stored in
    // memory.
    setSqrtOffset(qOffset.logToSqrtOffset());
    // The subtraction is safe due to the prior check.
    setSqrtInverseOffset((zeroX59 - qOffset).logToSqrtOffset());
  }

  {
    // 'tag0' is read from calldata and placed in memory.
    Tag tag0;
    assembly {
      tag0 := calldataload(36)
    }
    setTag0(tag0);

    // 'tag1' is read from calldata and placed in memory.
    Tag tag1;
    assembly {
      tag1 := calldataload(68)
    }
    setTag1(tag1);

    // Throws if the two tags are out of order.
    require(tag1 > tag0, TagsOutOfOrder(tag0, tag1));
  }

  {
    // 'poolGrowthPortion' is read from calldata and placed in memory.
    X47 poolGrowthPortion;
    assembly {
      poolGrowthPortion := calldataload(100)
    }
    // Throws if 'poolGrowthPortion' is greater than 'oneX47'.
    require(
      poolGrowthPortion <= oneX47,
      InvalidGrowthPortion(poolGrowthPortion)
    );
    setPoolGrowthPortion(poolGrowthPortion);
  }

  {
    // This is the pointer referring to the start of the kernel in memory.
    Kernel kernel;

    // This value refers to the start of 'kernelCompactArray' in calldata.
    uint256 kernelCompactStart;

    // The byte count of 'kernelCompact'.
    uint256 kernelCompactByteCount;

    assembly {
      kernelCompactStart := add(0x04, calldataload(0x84))

      // kernel starts immediately after static parameters in memory.
      kernel := _endOfStaticParams_

      // The number of bytes to be occupied by 'kernelCompact'.
      kernelCompactByteCount := shl(5, calldataload(kernelCompactStart))

      // Each breakpoint occupies 80-bits in 'kernelCompact'.
      // Each breakpoint occupies 512-bits in 'kernel'.
      // Hence, '512 * calldataload(kernelCompactStart) / 80' is an upper 
      // bound on the number of slots to be occupied by 'kernel'.
      // And, '32 * (512 * calldataload(kernelCompactStart) / 80)' is an upper
      // bound on the number of bytes to be occupied by 'kernel'.
      // Since 'kernelCompact' comes immediately after 'kernel' in memory, we
      // need to set its memory pointer accordingly.
      kernelCompact := add(kernel, shl(5, div(kernelCompactByteCount, 5)))
    }
    setKernel(kernel);

    {
      // This is the pointer referring to the start of the curve sequence in
      // memory.
      Curve curve;

      // This value refers to the start of 'curveArray' in calldata.
      uint256 curveStart;

      // The byte count of the curve sequence.
      uint256 curveByteCount;

      assembly {
        curveStart := add(0x04, calldataload(0xA4))

        // 'curve' appears after 'kernelCompact' in memory.
        curve := add(kernelCompact, kernelCompactByteCount)

        // The number of bytes to be occupied by 'curve'.
        curveByteCount := shl(5, calldataload(curveStart))
      }
      require(curveByteCount >= 32, CurveLengthIsZero());
      setCurve(curve);

      {
        // This is the pointer referring to the start of hookData in memory.
        uint256 hookData;
        
        // The byte count of 'hookData'.
        uint256 hookDataByteCount;

        // The total number of bytes of the memory snapshot to be used as
        // input for the hook contract.
        uint256 hookInputByteCount;
        
        // The free memory pointer which is set at the end.
        uint256 freeMemoryPointer;

        assembly {
          // This value refers to the start of 'hookData' in calldata (the
          // length slot).
          let hookDataStart := add(0x04, calldataload(0xC4))

          // 'hookData' appears after 'curve' in memory.
          // 8 bytes are added to seperate the curve sequence from hook data.
          hookData := add(add(curve, curveByteCount), 8)

          // The number of bytes to be occupied by 'hookData'.
          hookDataByteCount := calldataload(hookDataStart)

          // 'freeMemoryPointer' appears after 'hookData' in memory.
          freeMemoryPointer := add(hookData, hookDataByteCount)

          // The total number of bytes to be given to the hook as input.
          // 32 is subtracted to exclude the '_hookInputByteCount_' slot.
          hookInputByteCount := 
            sub(sub(freeMemoryPointer, _hookInputByteCount_), 32)

          // Data is copied from calldata to memory.
          calldatacopy(
            kernelCompact,
            // The length slot of 'kernelCompactArray' is excluded.
            add(kernelCompactStart, 32),
            kernelCompactByteCount
          )
          calldatacopy(
            curve,
            // The length slot of 'curveArray' is excluded.
            add(curveStart, 32),
            curveByteCount
          )
          calldatacopy(
            hookData,
            // The length slot of 'hookData' is excluded.
            add(hookDataStart, 32),
            hookDataByteCount
          )
        }
        setHookData(hookData);
        require(
          hookDataByteCount <= type(uint16).max,
          HookDataTooLong(hookDataByteCount)
        );
        setHookDataByteCount(uint16(hookDataByteCount));
        setHookInputByteCount(hookInputByteCount);
        setFreeMemoryPointer(freeMemoryPointer);
      }
    }
  }
}

/// @notice Reads inputs of the external function 'modifyPosition' and places
/// each in the appropriate memory location.
function readModifyPositionInput() view {
  // Calldata layout for 'modifyPosition' is as follows:
  //
  // '0x00': 'INofeeswapDelegatee.modifyPosition.selector'
  // '0x04': 'poolId'
  // '0x24': 'logPriceMin'
  // '0x44': 'logPriceMax'
  // '0x64': 'shares'
  // '0x84': 'calldata pointer to the beginning of hookData - 0x04'
  // '0x04 + calldataload(0x84)': 'hookData'

  // 'msg.sender' is placed in memory to be passed to hook as calldata.
  setMsgSender(msg.sender);

  {
    // 'poolId' is read from calldata and placed in memory.
    uint256 poolId;
    assembly {
      poolId := calldataload(4)
    }
    setPoolId(poolId);

    // Normalized log price values are calculated next.
    X59 shift = getLogOffsetFromPoolId(poolId) - sixteenX59;

    // 'logPriceMin' is read from calldata and placed in memory.
    X59 logPriceMin;
    assembly {
      logPriceMin := calldataload(36)
    }
    setLogPriceMin(logPriceMin);
    X59 qMin = logPriceMin - shift;
    require(qMin > zeroX59, LogPriceOutOfRange(logPriceMin));
    require(qMin < thirtyTwoX59, LogPriceOutOfRange(logPriceMin));
    setLogPriceMinOffsetted(qMin);

    // 'logPriceMax' is read from calldata and placed in memory.
    X59 logPriceMax;
    assembly {
      logPriceMax := calldataload(68)
    }
    setLogPriceMax(logPriceMax);
    X59 qMax = logPriceMax - shift;
    require(qMax > zeroX59, LogPriceOutOfRange(logPriceMax));
    require(qMax < thirtyTwoX59, LogPriceOutOfRange(logPriceMax));
    setLogPriceMaxOffsetted(qMax);
  }

  {
    // The number of shares to be minted/burned is read from calldata capped by
    // '-type(int128).max' and '+type(int128).max', and placed in memory.
    int256 shares;
    assembly {
      shares := calldataload(100)
    }
    // Checks the number of shares.
    require(shares <= type(int128).max, InvalidNumberOfShares(shares));
    require(shares >= 0 - type(int128).max, InvalidNumberOfShares(shares));
    require(shares != 0, InvalidNumberOfShares(shares));
    setShares(shares);
  }

  {
    // This is the pointer referring to the start of the curve sequence in
    // memory.
    Curve curve;

    // This is the pointer referring to the start of hookData in memory.
    uint256 hookData;

    // The byte count of 'hookData'.
    uint256 hookDataByteCount;

    // The total number of bytes of the memory snapshot to be used as input for
    // the hook contract.
    uint256 hookInputByteCount;

    // The free memory pointer which is set at the end.
    uint256 freeMemoryPointer;

    assembly {
      // This value refers to the start of 'hookData' in calldata (the length
      // slot).
      let hookDataStart := add(0x04, calldataload(0x84))

      // 32 bytes are reserved for the first slot of the curve sequence and no
      // member of kernel is loaded.
      curve := _endOfStaticParams_

      // 'hookData' appears immediately after.
      hookData := add(_endOfStaticParams_, 32)

      // The number of bytes to be occupied by 'hookData'.
      hookDataByteCount := calldataload(hookDataStart)

      // 'freeMemoryPointer' appears after 'hookData' in memory.
      freeMemoryPointer := add(hookData, hookDataByteCount)

      // The total number of bytes to be given to the hook as input.
      hookInputByteCount := 
        sub(sub(freeMemoryPointer, _hookInputByteCount_), 32)

      // Data is copied from calldata to memory.
      calldatacopy(
        hookData,
        // The length slot of 'hookData' is excluded.
        add(hookDataStart, 32),
        hookDataByteCount
      )
    }
    setCurve(curve);
    setHookData(hookData);
    require(
      hookDataByteCount <= type(uint16).max,
      HookDataTooLong(hookDataByteCount)
    );
    setHookDataByteCount(uint16(hookDataByteCount));
    setHookInputByteCount(hookInputByteCount);
    setFreeMemoryPointer(freeMemoryPointer);
  }
}

/// @notice Reads inputs of the external function 'donate' and places each in
/// the appropriate memory location.
function readDonateInput() view {
  // Calldata layout for 'donate' is as follows:
  //
  // '0x00': 'INofeeswapDelegatee.donate.selector'
  // '0x04': 'poolId'
  // '0x24': 'shares'
  // '0x44': 'calldata pointer to the beginning of hookData - 0x04'
  // '0x04 + calldataload(0x44)': 'hookData'

  // 'msg.sender' is placed in memory to be passed to hook as calldata.
  setMsgSender(msg.sender);

  {
    // 'poolId' is read from calldata and placed in memory.
    uint256 poolId;
    assembly {
      poolId := calldataload(4)
    }
    setPoolId(poolId);
  }

  {
    // The number of shares to be minted/burned is read from calldata capped by
    // '+type(int128).max', and placed in memory.
    int256 shares;
    assembly {
      shares := calldataload(36)
    }
    require(shares <= type(int128).max, InvalidNumberOfShares(shares));
    require(shares > 0, InvalidNumberOfShares(shares));
    setShares(shares);
  }

  {
    // This is the pointer referring to the start of the curve sequence in
    // memory.
    Curve curve;

    // This is the pointer referring to the start of hookData in memory.
    uint256 hookData;

    // The byte count of 'hookData'.
    uint256 hookDataByteCount;

    // The total number of bytes of the memory snapshot to be used as input for
    // the hook contract.
    uint256 hookInputByteCount;

    // The free memory pointer which is set at the end.
    uint256 freeMemoryPointer;

    assembly {
      // This value refers to the start of 'hookData' in calldata (the length
      // slot).
      let hookDataStart := add(0x04, calldataload(0x44))

      // 32 bytes are reserved for the first slot of the curve sequence and no
      // member of kernel is loaded.
      curve := _endOfStaticParams_

      // 'hookData' appears immediately after.
      hookData := add(_endOfStaticParams_, 32)

      // The number of bytes to be occupied by 'hookData'.
      hookDataByteCount := calldataload(hookDataStart)

      // 'freeMemoryPointer' appears after 'hookData' in memory.
      freeMemoryPointer := add(hookData, hookDataByteCount)

      // The total number of bytes to be given to the hook as input.
      hookInputByteCount := 
        sub(sub(freeMemoryPointer, _hookInputByteCount_), 32)

      // Data is copied from calldata to memory.
      calldatacopy(
        hookData,
        // The length slot of 'hookData' is excluded.
        add(hookDataStart, 32),
        hookDataByteCount
      )
    }
    setCurve(curve);
    setHookData(hookData);
    require(
      hookDataByteCount <= type(uint16).max,
      HookDataTooLong(hookDataByteCount)
    );
    setHookDataByteCount(uint16(hookDataByteCount));
    setHookInputByteCount(hookInputByteCount);
    setFreeMemoryPointer(freeMemoryPointer);
  }
}

/// @notice Reads the inputs of the external function 'modifyKernel' and
/// places each in the appropriate memory location.
/// @return kernelCompact The memory pointer for the given 'kernelCompact'.
/// Observe that 'kernel', 'kernelCompact', 'curve', and 'hookData' are loaded
/// in memory in this order. Hence, the place of 'kernelCompact' is not
/// constant and depends on the size of 'kernel'.
function readModifyKernelInput() view returns (KernelCompact kernelCompact) {
  // Calldata layout for 'modifyKernel' is as follows:
  //
  // '0x00': 'INofeeswapDelegatee.modifyKernel.selector'
  // '0x04': 'poolId'
  // '0x24': 'calldata pointer to the beginning of kernelCompactArray - 0x04'
  // '0x44': 'calldata pointer to the beginning of hookData - 0x04'
  // '0x04 + calldataload(0x24)': 'kernelCompactArray'
  // '0x04 + calldataload(0x44)': 'hookData'

  // 'msg.sender' is placed in memory to be passed to hook as calldata.
  setMsgSender(msg.sender);

  // 'poolId' is read from calldata and placed in memory.
  uint256 poolId;
  assembly {
    poolId := calldataload(4)
  }
  setPoolId(poolId);

  // This is the pointer referring to the start of the kernel in memory.
  Kernel kernel;

  // This value refers to the start of 'kernelCompactArray' in calldata.
  uint256 kernelCompactStart;

  // The byte count of 'kernelCompact'.
  uint256 kernelCompactByteCount;

  assembly {
    kernelCompactStart := add(0x04, calldataload(0x24))

    // kernel starts immediately after static parameters in memory.
    kernel := _endOfStaticParams_

    // The number of bytes to be occupied by 'kernelCompact'.
    kernelCompactByteCount := shl(5, calldataload(kernelCompactStart))

    // Each breakpoint occupies 80-bits in kernelCompact.
    // Each breakpoint occupies 512-bits in kernel.
    // Hence, '512 * calldataload(kernelCompactStart) / 80' is an upper 
    // bound for the number of slots to be occupied by 'kernel'.
    // And, '32 * (512 * calldataload(kernelCompactStart) / 80)' is an upper
    // bound for the number of bytes to be occupied by 'kernel'.
    // Since 'kernelCompact' comes immediately after 'kernel' in memory, we
    // need to set its memory pointer accordingly:
    kernelCompact := add(kernel, shl(5, div(kernelCompactByteCount, 5)))
  }
  setKernel(kernel);

  // This is the pointer referring to the start of hookData in memory.
  uint256 hookData;
  
  // The byte count of 'hookData'.
  uint256 hookDataByteCount;

  // The total number of bytes of the memory snapshot to be used as input for
  // the hook contract.
  uint256 hookInputByteCount;
  
  // The free memory pointer which is set at the end.
  uint256 freeMemoryPointer;

  assembly {
    // This value refers to the start of 'hookData' in calldata (the length
    // slot).
    let hookDataStart := add(0x04, calldataload(0x44))

    // 'hookData' appears after 'kernelCompact' in memory.
    hookData := add(kernelCompact, kernelCompactByteCount)

    // The number of bytes to be occupied by 'hookData'.
    hookDataByteCount := calldataload(hookDataStart)

    // 'freeMemoryPointer' appears after 'hookData' in memory.
    freeMemoryPointer := add(hookData, hookDataByteCount)

    // The total number of bytes to be given to the hook as input.
    // 32 is subtracted to exclude the '_hookInputByteCount_' slot.
    hookInputByteCount := 
      sub(sub(freeMemoryPointer, _hookInputByteCount_), 32)

    // Data is copied from calldata to memory.
    calldatacopy(
      kernelCompact,
      // The length slot of 'kernelCompactArray' is excluded.
      add(kernelCompactStart, 32),
      kernelCompactByteCount
    )
    calldatacopy(
      hookData,
      // The length slot of 'hookData' is excluded.
      add(hookDataStart, 32),
      hookDataByteCount
    )
  }
  setHookData(hookData);
  require(
    hookDataByteCount <= type(uint16).max,
    HookDataTooLong(hookDataByteCount)
  );
  setHookDataByteCount(uint16(hookDataByteCount));
  setHookInputByteCount(hookInputByteCount);
  setFreeMemoryPointer(freeMemoryPointer);
}

/// @notice Reads inputs of the external function 'modifyPoolGrowthPortion' and
/// places each in the appropriate memory location.
function readModifyPoolGrowthPortionInput() view {
  // Calldata layout for 'modifyKernel' is as follows:
  //
  // '0x00': 'INofeeswapDelegatee.modifyPoolGrowthPortion.selector'
  // '0x04': 'poolId'
  // '0x24': 'poolGrowthPortion'

  // 'msg.sender' is placed in memory to be passed to sentinel as calldata.
  setMsgSender(msg.sender);

  // 'poolId' is read from calldata and placed in memory.
  uint256 poolId;
  assembly {
    poolId := calldataload(4)
  }
  setPoolId(poolId);

  {
    // 'poolGrowthPortion' is read from calldata and placed in memory.
    X47 poolGrowthPortion;
    assembly {
      poolGrowthPortion := calldataload(36)
    }
    require(
      poolGrowthPortion <= oneX47,
      InvalidGrowthPortion(poolGrowthPortion)
    );
    setPoolGrowthPortion(poolGrowthPortion);
  }

  // The total number of bytes of the memory snapshot to be used as input for
  // the sentinel contract.
  uint256 hookInputByteCount;
  assembly {
    // The total number of bytes to be given to the sentinel as input.
    hookInputByteCount := 
      sub(sub(_endOfStaticParams_, _hookInputByteCount_), 32)
  }
  setHookInputByteCount(hookInputByteCount);

  // Free memory appears immediately after staticParams.
  setFreeMemoryPointer(_endOfStaticParams_);
}

/// @notice Reads inputs of the external function 'updateGrowthPortions' and
/// places each in the appropriate memory location.
function readUpdateGrowthPortionsInput() pure {
  // Calldata layout for 'updateGrowthPortions' is as follows:
  //
  // '0x00': 'INofeeswapDelegatee.updateGrowthPortions.selector'
  // '0x04': 'poolId'

  // 'poolId' is read from calldata and placed in memory.
  uint256 poolId;
  assembly {
    poolId := calldataload(4)
  }
  setPoolId(poolId);

  // The total number of bytes of the memory snapshot to be used as input for
  // the sentinel contract.
  uint256 hookInputByteCount;
  assembly {
    // The total number of bytes to be given to the sentinel as input.
    hookInputByteCount := 
      sub(sub(_endOfStaticParams_, _hookInputByteCount_), 32)
  }
  setHookInputByteCount(hookInputByteCount);

  // Free memory appears immediately after staticParams.
  setFreeMemoryPointer(_endOfStaticParams_);
}

/// @notice Reads the inputs of the external function 'swap' and places each in
/// the appropriate memory location.
function readSwapInput() view {
  // Calldata layout for 'swap' is as follows:
  //
  // '0x00': 'INofeeswap.swap.selector'
  // '0x04': 'poolId'
  // '0x24': 'amountSpecified'
  // '0x44': 'logPriceLimit'
  // '0x64': 'zeroForOne'
  // '0x84': 'calldata pointer to the beginning of hookData - 0x04'
  // '0x04 + calldataload(0x84)': 'hookData'

  // 'msg.sender' is placed in memory to be passed to hook as calldata.
  setMsgSender(msg.sender);

  // 'poolId' is read from calldata and placed in memory.
  uint256 poolId;
  assembly {
    poolId := calldataload(4)
  }
  setPoolId(poolId);

  // 'amountSpecified' is read from calldata, capped by '-type(int128).max' and 
  // '+type(int128).max', transformed to X127, and placed in memory.
  X127 amountSpecified;
  assembly {
    amountSpecified := calldataload(36)
    if slt(amountSpecified, sub(0, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) {
      amountSpecified := sub(0, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
    if sgt(amountSpecified, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
      amountSpecified := 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    }
    amountSpecified := mul(amountSpecified, shl(127, 1))
  }
  setAmountSpecified(amountSpecified);

  // 'logPriceLimit' is read from calldata and placed in memory.
  X59 logPriceLimit;
  assembly {
    logPriceLimit := calldataload(68)
  }
  setLogPriceLimit(logPriceLimit);

  // 'crossThreshold' is read from calldata and placed in memory.
  uint256 crossThreshold;
  assembly {
    crossThreshold := shr(128, calldataload(100))
    if gt(crossThreshold, 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
      crossThreshold := 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    }
  }
  setCrossThreshold(crossThreshold);

  // 'zeroForOne' is read from calldata, capped by '2' and placed in memory.
  assembly {
    let zeroForOne := shr(128, calldataload(116))
    if gt(zeroForOne, 2) {
      zeroForOne := 2
    }
    mstore8(_zeroForOne_, zeroForOne)
  }

  {
    // This is the pointer referring to the start of the kernel in memory.
    Kernel kernel;

    // This is the pointer referring to the start of hookData in memory.
    uint256 hookData;

    // The byte count of 'hookData'.
    uint256 hookDataByteCount;

    // The total number of bytes of the memory snapshot to be used as input for
    // the hook contract.
    uint256 hookInputByteCount;

    assembly {
      // This value refers to the start of 'hookData' in calldata (the length
      // slot).
      let hookDataStart := add(0x04, calldataload(0x84))

      // 'hookData' appears immediately after static parameters.
      hookData := _endOfStaticParams_

      // The number of bytes to be occupied by 'hookData'.
      hookDataByteCount := calldataload(hookDataStart)

      // 'kernel' appears immediately after 'hookData'.
      kernel := add(hookData, hookDataByteCount)

      // The total number of bytes to be given to the 'preSwap' hook as input.
      // 32 is subtracted to exclude the '_hookInputByteCount_' slot.
      hookInputByteCount := sub(sub(kernel, _hookInputByteCount_), 32)

      // Data is copied from calldata to memory.
      calldatacopy(
        hookData,
        // The length slot of 'hookData' is excluded.
        add(hookDataStart, 32),
        hookDataByteCount
      )
    }
    setHookData(hookData);
    require(
      hookDataByteCount <= type(uint16).max,
      HookDataTooLong(hookDataByteCount)
    );
    setHookDataByteCount(uint16(hookDataByteCount));
    setHookInputByteCount(hookInputByteCount);
    setKernel(kernel);
  }
}

/// @notice Reads input of the external functions 'collectPool' and 
/// 'collectProtocol'.
function readCollectInput() pure {
  // Calldata layout is as follows:
  //
  // '0x00': function selector
  // '0x04': 'poolId'

  // 'poolId' is read from calldata and placed in memory.
  uint256 poolId;
  assembly {
    poolId := calldataload(4)
  }
  setPoolId(poolId);

  // Determines the largest used memory slot.
  setFreeMemoryPointer(_swapInput_);
}