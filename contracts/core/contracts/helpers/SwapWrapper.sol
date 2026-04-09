// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Swap.sol";
import {zeroIndex, oneIndex} from "../utilities/Index.sol";
import {zeroX59} from "../utilities/X59.sol";
import {Kernel} from "../utilities/Kernel.sol";
import {Curve} from "../utilities/Curve.sol";
import {epsilonX216} from "../utilities/X216.sol";
import {
  writeStorage,
  writeStaticParams,
  _staticParams_
} from "../utilities/Storage.sol";
import {
  _currentToTarget_,
  _incomingCurrentToTarget_,
  _endOfStaticParams_,
  setPoolId,
  setKernel,
  setCurve,
  setSqrtOffset,
  setSqrtInverseOffset,
  setLogPriceLimit,
  setOutgoingMax,
  setIncomingMax,
  setCrossThreshold,
  setLogPriceLimitOffsettedWithinInterval,
  setPoolGrowthPortion,
  setProtocolGrowthPortion,
  setOutgoingMaxModularInverse,
  setIntegralLimit,
  getIntegralLimit,
  getIntegralLimitInterval,
  getKernelLength,
  setPendingKernelLength,
  getCurveLength,
  setCurveLength
} from "../utilities/Memory.sol";
import {FullMathLibrary} from "../utilities/FullMath.sol";

/// @title This contract exposes the internal functions of 'Swap.sol' for 
/// testing purposes.
contract SwapWrapper {
  using PriceLibrary for uint16;
  using IntegralLibrary for uint16;

  function _calculateIntegralLimitInterval(
    bool exactInput,
    bool zeroForOne,
    X59 back,
    X59 next,
    X216 outgoingMax,
    X216 incomingMax
  ) public returns (
    X216 integralLimitInterval
  ) {
    setExactInput(exactInput);
    setZeroForOne(zeroForOne);
    _back_.storePrice(back);
    _next_.storePrice(next);
    setOutgoingMax(outgoingMax);
    setIncomingMax(incomingMax);

    calculateIntegralLimitInterval();

    return getIntegralLimitInterval();
  }

  function _updateAmounts(
    bool exactInput,
    bool zeroForOne,
    X127 amount0,
    X127 amount1,
    X127 amountSpecified,
    X127 outgoingAmount,
    X127 incomingAmount
  ) public returns (
    X127 amount0Updated,
    X127 amount1Updated,
    X127 amountSpecifiedUpdated
  ) {
    setExactInput(exactInput);
    setZeroForOne(zeroForOne);
    setAmount0(amount0);
    setAmount1(amount1);
    setAmountSpecified(amountSpecified);

    updateAmounts(outgoingAmount, incomingAmount);

    return (getAmount0(), getAmount1(), getAmountSpecified());
  }

  function _setSwapParams(
    uint256 zeroForOne,
    uint256 poolId,
    uint256 curveContent,
    X59 logPriceLimit,
    X127 amountSpecified,
    X216 outgoingMax,
    X216 incomingMax,
    X111 growth,
    uint256 sharesTotal
  ) public {
    assembly {
      mstore8(_zeroForOne_, zeroForOne)
    }

    setPoolId(poolId);
    
    {
      Curve curve;
      assembly {
        curve := _endOfStaticParams_
        mstore(curve, curveContent)
      }
      setCurve(curve);
    }

    setLogPriceCurrent(getCurve().member(twoIndex));

    setLogPriceLimit(logPriceLimit);

    setAmountSpecified(amountSpecified);

    setOutgoingMax(outgoingMax);

    setIncomingMax(incomingMax);

    setGrowth(growth);

    setSharesTotal(sharesTotal);

    _spacing_.storePrice(
      max(
        getCurve().member(zeroIndex), getCurve().member(oneIndex)
      ) - min(
        getCurve().member(zeroIndex), getCurve().member(oneIndex)
      )
    );

    {
      X59 qOffset = getLogOffsetFromPoolId(poolId);
      setSqrtOffset(qOffset.logToSqrtOffset());
      setSqrtInverseOffset((zeroX59 - qOffset).logToSqrtOffset());
    }

    setSwapParams();

    {
      assembly {
        log1(0, _endOfStaticParams_, 0xA)
      }
    }
  }

  function _swapWithin(
    uint256[18] calldata values,
    uint256[] calldata kernelArray,
    uint256[] calldata curveArray
  ) public returns (
    bool exactAmount
  ) {
    setPoolId(values[0]);

    {
      X111 growth;
      uint256 content = values[1];
      assembly {
        growth := content
      }
      setGrowth(growth);
    }

    {
      X216 integral0;
      uint256 content = values[2];
      assembly {
        integral0 := content
      }
      setIntegral0(integral0);
    }

    {
      X216 integral1;
      uint256 content = values[3];
      assembly {
        integral1 := content
      }
      setIntegral1(integral1);
    }

    setSharesTotal(values[4]);

    {
      X216 outgoingMax;
      uint256 content = values[5];
      assembly {
        outgoingMax := content
      }
      setOutgoingMax(outgoingMax);
    }

    {
      X47 poolGrowthPortion;
      uint256 content = values[6];
      assembly {
        poolGrowthPortion := content
      }
      setPoolGrowthPortion(poolGrowthPortion);
    }

    {
      X47 protocolGrowthPortion;
      uint256 content = values[7];
      assembly {
        protocolGrowthPortion := content
      }
      setProtocolGrowthPortion(protocolGrowthPortion);
    }

    {
      X127 accrued0;
      uint256 content = values[8];
      assembly {
        accrued0 := content
      }
      setAccrued0(accrued0);
    }

    {
      X127 accrued1;
      uint256 content = values[9];
      assembly {
        accrued1 := content
      }
      setAccrued1(accrued1);
    }

    {
      X23 poolRatio0;
      uint256 content = values[10];
      assembly {
        poolRatio0 := content
      }
      setPoolRatio0(poolRatio0);
    }

    {
      X23 poolRatio1;
      uint256 content = values[11];
      assembly {
        poolRatio1 := content
      }
      setPoolRatio1(poolRatio1);
    }

    {
      X127 amount0;
      uint256 content = values[12];
      assembly {
        amount0 := content
      }
      setAmount0(amount0);
    }

    {
      X127 amount1;
      uint256 content = values[13];
      assembly {
        amount1 := content
      }
      setAmount1(amount1);
    }

    {
      X127 amountSpecified;
      uint256 content = values[14];
      assembly {
        amountSpecified := content
      }
      setAmountSpecified(amountSpecified);
    }

    {
      X59 logPriceLimitOffsetted;
      uint256 content = values[15];
      assembly {
        logPriceLimitOffsetted := content
      }
      setLogPriceLimitOffsetted(
        logPriceLimitOffsetted
      );
    }

    setCrossThreshold(values[16]);

    {
      Index curveLength;
      uint256 content = values[17];
      assembly {
        curveLength := content
      }
      setCurveLength(curveLength);
    }

    {
      Kernel kernel;
      Curve curve;
      Index kernelLength;
      assembly {
        kernel := _endOfStaticParams_
        let kernelArrayStart := calldataload(580)
        let kernelArrayLength := calldataload(add(4, kernelArrayStart))
        let kernelArrayByteCount := shl(5, kernelArrayLength)
        calldatacopy(
          kernel,
          add(36, kernelArrayStart),
          kernelArrayByteCount
        )
        kernelLength := add(div(kernelArrayLength, 2), 1)

        curve := add(kernel, kernelArrayByteCount)
        let curveArrayStart := calldataload(612)
        let curveArrayLength := calldataload(add(4, curveArrayStart))
        let curveArrayByteCount := shl(5, curveArrayLength)
        calldatacopy(
          curve,
          add(36, curveArrayStart),
          curveArrayByteCount
        )

        mstore(0x40, add(curve, curveArrayByteCount))
      }
      setKernel(kernel);
      setCurve(curve);
      setKernelLength(kernelLength);
      setLogPriceCurrent(curve.member(getCurveLength() - oneIndex));
    }

    setExactInput(getAmountSpecified() > zeroX127);

    setZeroForOne(
      getLogPriceLimitOffsetted() < getLogPriceCurrent()
    );

    setSqrtOffset(getLogOffsetFromPoolId(getPoolId()).logToSqrtOffset());
    setSqrtInverseOffset(
      (zeroX59 - getLogOffsetFromPoolId(getPoolId())).logToSqrtOffset()
    );

    {
      X216 outgoingMax = getOutgoingMax();
      uint256 outgoingMaxLargestOddFactor;
      assembly {
        outgoingMaxLargestOddFactor := div(
          outgoingMax,
          and(sub(0, outgoingMax), outgoingMax)
        )
      }
      setOutgoingMaxModularInverse(
        FullMathLibrary.modularInverse(outgoingMaxLargestOddFactor)
      );
    }

    _next_.storePrice(
      getZeroForOne() ? 
      min(getCurve().member(zeroIndex), getCurve().member(oneIndex)) :
      max(getCurve().member(zeroIndex), getCurve().member(oneIndex))
    );

    setIntegralLimit(oneX216 - epsilonX216);
    setIntegralLimitInterval(oneX216 - epsilonX216);

    exactAmount = swapWithin();

    X59 overshoot = getCurve().member(getCurveLength() - twoIndex);

    assembly {
      log2(0, _endOfStaticParams_, overshoot, 0xA)
    }
  }

  function _cross(
    uint256[19] calldata values
  ) public returns (
    bool halt
  ) {
    setPoolId(values[0]);

    {
      X111 growth;
      uint256 content = values[1];
      assembly {
        growth := content
      }
      setGrowth(growth);
    }

    {
      X216 integral0;
      uint256 content = values[2];
      assembly {
        integral0 := content
      }
      setIntegral0(integral0);
    }

    {
      X216 integral1;
      uint256 content = values[3];
      assembly {
        integral1 := content
      }
      setIntegral1(integral1);
    }

    setSharesTotal(values[4]);

    {
      X216 outgoingMax;
      uint256 content = values[5];
      assembly {
        outgoingMax := content
      }
      setOutgoingMax(outgoingMax);
    }

    {
      X216 incomingMax;
      uint256 content = values[6];
      assembly {
        incomingMax := content
      }
      setIncomingMax(incomingMax);
    }

    {
      X47 poolGrowthPortion;
      uint256 content = values[7];
      assembly {
        poolGrowthPortion := content
      }
      setPoolGrowthPortion(poolGrowthPortion);
    }

    {
      X47 protocolGrowthPortion;
      uint256 content = values[8];
      assembly {
        protocolGrowthPortion := content
      }
      setProtocolGrowthPortion(protocolGrowthPortion);
    }

    {
      X127 accrued0;
      uint256 content = values[9];
      assembly {
        accrued0 := content
      }
      setAccrued0(accrued0);
    }

    {
      X127 accrued1;
      uint256 content = values[10];
      assembly {
        accrued1 := content
      }
      setAccrued1(accrued1);
    }

    {
      X23 poolRatio0;
      uint256 content = values[11];
      assembly {
        poolRatio0 := content
      }
      setPoolRatio0(poolRatio0);
    }

    {
      X23 poolRatio1;
      uint256 content = values[12];
      assembly {
        poolRatio1 := content
      }
      setPoolRatio1(poolRatio1);
    }

    {
      X127 amount0;
      uint256 content = values[13];
      assembly {
        amount0 := content
      }
      setAmount0(amount0);
    }

    {
      X127 amount1;
      uint256 content = values[14];
      assembly {
        amount1 := content
      }
      setAmount1(amount1);
    }

    {
      X127 amountSpecified;
      uint256 content = values[15];
      assembly {
        amountSpecified := content
      }
      setAmountSpecified(amountSpecified);
    }

    setCrossThreshold(values[16]);

    {
      X59 back;
      uint256 content = values[17];
      assembly {
        back := content
      }
      _back_.storePrice(back);
    }

    {
      X59 next;
      uint256 content = values[18];
      assembly {
        next := content
      }
      _next_.storePrice(next);
    }

    {
      Curve curve;
      assembly {
        curve := _endOfStaticParams_
        mstore(0x40, add(curve, 32))
      }
      setCurve(curve);
    }

    setExactInput(getAmountSpecified() > zeroX127);

    setZeroForOne(_next_.log() < _back_.log());

    setSqrtOffset(getLogOffsetFromPoolId(getPoolId()).logToSqrtOffset());
    setSqrtInverseOffset(
      (zeroX59 - getLogOffsetFromPoolId(getPoolId())).logToSqrtOffset()
    );

    {
      X216 outgoingMax = getOutgoingMax();
      uint256 outgoingMaxLargestOddFactor;
      assembly {
        outgoingMaxLargestOddFactor := div(
          outgoingMax,
          and(sub(0, outgoingMax), outgoingMax)
        )
      }
      setOutgoingMaxModularInverse(
        FullMathLibrary.modularInverse(outgoingMaxLargestOddFactor)
      );
    }

    halt = cross();

    assembly {
      log1(0, _endOfStaticParams_, 0xA)
    }
  }

  function _transition(
    uint256[12] calldata values
  ) public {
    setPoolId(values[0]);

    {
      X216 outgoingMax;
      uint256 content = values[1];
      assembly {
        outgoingMax := content
      }
      setOutgoingMax(outgoingMax);
    }

    {
      X216 incomingMax;
      uint256 content = values[2];
      assembly {
        incomingMax := content
      }
      setIncomingMax(incomingMax);
    }

    {
      X59 back;
      uint256 content = values[3];
      assembly {
        back := content
      }
      _back_.storePrice(back);
    }

    {
      X59 next;
      uint256 content = values[4];
      assembly {
        next := content
      }
      _next_.storePrice(next);
    }

    {
      X111 growth;
      uint256 content = values[5];
      assembly {
        growth := content
      }
      setGrowth(growth);
    }

    setSharesTotal(values[6]);

    {
      X127 amountSpecified;
      uint256 content = values[7];
      assembly {
        amountSpecified := content
      }
      setAmountSpecified(amountSpecified);
    }

    {
      X208 backGrowthMultiplier;
      uint256 content = values[8];
      assembly {
        backGrowthMultiplier := content
      }
      setBackGrowthMultiplier(backGrowthMultiplier);
    }

    {
      X208 nextGrowthMultiplier;
      uint256 content = values[9];
      assembly {
        nextGrowthMultiplier := content
      }
      setNextGrowthMultiplier(nextGrowthMultiplier);
    }

    {
      X208 growthMultiplier;
      uint256 content = values[10];
      assembly {
        growthMultiplier := content
      }
      writeGrowthMultiplier(
        getGrowthMultiplierSlot(
          getPoolId(),
          _next_.log() + _next_.log() - _back_.log()
        ),
        growthMultiplier
      );
    }

    writeStorage(getSharesDeltaSlot(getPoolId(), _next_.log()), values[11]);

    _spacing_.storePrice(
      max(_back_.log(), _next_.log()) - min(_back_.log(), _next_.log())
    );

    setExactInput(getAmountSpecified() > zeroX127);

    setZeroForOne(_next_.log() < _back_.log());

    setSqrtOffset(getLogOffsetFromPoolId(getPoolId()).logToSqrtOffset());
    setSqrtInverseOffset(
      (zeroX59 - getLogOffsetFromPoolId(getPoolId())).logToSqrtOffset()
    );

    {
      X216 outgoingMax = getOutgoingMax();
      uint256 outgoingMaxLargestOddFactor;
      assembly {
        outgoingMaxLargestOddFactor := div(
          outgoingMax,
          and(sub(0, outgoingMax), outgoingMax)
        )
      }
      setOutgoingMaxModularInverse(
        FullMathLibrary.modularInverse(outgoingMaxLargestOddFactor)
      );
    }

    transition();

    X59 member0 = getCurve().member(zeroIndex);
    X59 member1 = getCurve().member(oneIndex);
    assembly {
      log3(0, _endOfStaticParams_, member0, member1, 0xA)
    }
  }

  function _updateKernel(
    uint256 poolId,
    uint256 storagePointer,
    Index kernelLength0,
    Index kernelLength1,
    bytes calldata staticContent0,
    bytes calldata staticContent1
  ) public {
    setPoolId(poolId);
    
    setKernelLength(kernelLength0);

    uint256 start;
    uint256 byteCount;

    assembly {
      start := add(36, calldataload(132))
      byteCount := calldataload(add(4, calldataload(132)))
      calldatacopy(_staticParams_, start, byteCount)
    }
    setPendingKernelLength(kernelLength1);
    writeStaticParams(storagePointer);
    assembly {
      mcopy(_staticParams_, add(start, byteCount), byteCount)
    }
    setKernelLength(kernelLength1);
    assembly {
      start := add(36, calldataload(164))
      byteCount := calldataload(add(4, calldataload(164)))
      calldatacopy(_staticParams_, start, byteCount)
    }
    writeStaticParams(storagePointer + 1);
    assembly {
      mcopy(_staticParams_, add(start, byteCount), byteCount)
    }

    Kernel kernel;
    assembly {
      kernel := _endOfStaticParams_
    }
    setKernel(kernel);
    readStaticParams(
      getStaticParamsStorageAddress(address(this), poolId, storagePointer)
    );
    readKernel(
      kernel,
      getStaticParamsStorageAddress(address(this), poolId, storagePointer),
      kernelLength0
    );
    setStaticParamsStoragePointerExtension(storagePointer);

    updateKernel();
    Index length = getKernelLength();
    storagePointer = getStaticParamsStoragePointerExtension();
    assembly {
      log2(
        _staticParams_,
        add(
          sub(_endOfStaticParams_, _staticParams_),
          mul(64, sub(length, 1))
        ),
        length,
        storagePointer
      )
    }
  }
}