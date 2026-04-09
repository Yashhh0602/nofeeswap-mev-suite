// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

// Nofeeswap's hook calldata layout.
//
// Each 'uint16' value is a calldata pointer referring to the corresponding 
// value in calldata. This file is generated using 'Memory.py'.
// The getter functions can be used by hook contracts to access each value
// from calldata.
//
// The explanation for each parameter is given in 'Memory.sol'.

import {_hookSelector_} from "../utilities/Memory.sol";
import {Tag} from "../utilities/Tag.sol";
import {Index} from "../utilities/Index.sol";
import {X15} from "../utilities/X15.sol";
import {X23} from "../utilities/X23.sol";
import {X47} from "../utilities/X47.sol";
import {X59} from "../utilities/X59.sol";
import {X111} from "../utilities/X111.sol";
import {X127} from "../utilities/X127.sol";
import {X208} from "../utilities/X208.sol";
import {X216} from "../utilities/X216.sol";
import {Curve} from "../utilities/Curve.sol";
import {Kernel} from "../utilities/Kernel.sol";

uint16 constant _hookSelectorCalldata_ = 0;
uint16 constant _hookInputHeaderCalldata_ = 4;
uint16 constant _hookInputByteCountCalldata_ = 36;
uint16 constant _msgSenderCalldata_ = 68;
uint16 constant _poolIdCalldata_ = 88;

uint16 constant _swapInputCalldata_ = 120;
uint16 constant _crossThresholdCalldata_ = 120;
uint16 constant _amountSpecifiedCalldata_ = 136;
uint16 constant _logPriceLimitCalldata_ = 168;
uint16 constant _logPriceLimitOffsettedCalldata_ = 200;

uint16 constant _swapParamsCalldata_ = 208;
uint16 constant _zeroForOneCalldata_ = 208;
uint16 constant _exactInputCalldata_ = 209;
uint16 constant _integralLimitCalldata_ = 210;
uint16 constant _integralLimitIntervalCalldata_ = 237;
uint16 constant _amount0Calldata_ = 264;
uint16 constant _amount1Calldata_ = 296;
uint16 constant _backCalldata_ = 328;
uint16 constant _nextCalldata_ = 390;
uint16 constant _backGrowthMultiplierCalldata_ = 452;
uint16 constant _nextGrowthMultiplierCalldata_ = 484;

uint16 constant _intervalCalldata_ = 516;
uint16 constant _directionCalldata_ = 516;
uint16 constant _indexCurveCalldata_ = 517;
uint16 constant _indexKernelTotalCalldata_ = 519;
uint16 constant _indexKernelForwardCalldata_ = 521;
uint16 constant _logPriceLimitOffsettedWithinIntervalCalldata_ = 523;
uint16 constant _currentCalldata_ = 531;
uint16 constant _originCalldata_ = 593;
uint16 constant _beginCalldata_ = 655;
uint16 constant _endCalldata_ = 717;
uint16 constant _targetCalldata_ = 779;
uint16 constant _overshootCalldata_ = 841;
uint16 constant _total0Calldata_ = 905;
uint16 constant _total1Calldata_ = 969;
uint16 constant _forward0Calldata_ = 1033;
uint16 constant _forward1Calldata_ = 1097;
uint16 constant _incomingCurrentToTargetCalldata_ = 1159;
uint16 constant _currentToTargetCalldata_ = 1186;
uint16 constant _currentToOriginCalldata_ = 1213;
uint16 constant _currentToOvershootCalldata_ = 1240;
uint16 constant _targetToOvershootCalldata_ = 1267;
uint16 constant _originToOvershootCalldata_ = 1294;
uint16 constant _endOfIntervalCalldata_ = 1321;

uint16 constant _accruedParamsCalldata_ = 1321;
uint16 constant _accrued0Calldata_ = 1321;
uint16 constant _accrued1Calldata_ = 1353;
uint16 constant _poolRatio0Calldata_ = 1385;
uint16 constant _poolRatio1Calldata_ = 1388;

uint16 constant _pointersCalldata_ = 1391;
uint16 constant _kernelCalldata_ = 1391;
uint16 constant _curveCalldata_ = 1423;
uint16 constant _hookDataCalldata_ = 1455;
uint16 constant _kernelLengthCalldata_ = 1487;
uint16 constant _curveLengthCalldata_ = 1489;
uint16 constant _hookDataByteCountCalldata_ = 1491;

uint16 constant _dynamicParamsCalldata_ = 1493;
uint16 constant _staticParamsStoragePointerExtensionCalldata_ = 1493;
uint16 constant _staticParamsStoragePointerCalldata_ = 1525;
uint16 constant _logPriceCurrentCalldata_ = 1527;
uint16 constant _sharesTotalCalldata_ = 1535;
uint16 constant _growthCalldata_ = 1551;
uint16 constant _integral0Calldata_ = 1567;
uint16 constant _integral1Calldata_ = 1594;

uint16 constant _deploymentCreationCodeCalldata_ = 1621;

uint16 constant _staticParamsCalldata_ = 1632;
uint16 constant _tag0Calldata_ = 1632;
uint16 constant _tag1Calldata_ = 1664;
uint16 constant _sqrtOffsetCalldata_ = 1696;
uint16 constant _sqrtInverseOffsetCalldata_ = 1728;
uint16 constant _spacingCalldata_ = 1760;
uint16 constant _outgoingMaxCalldata_ = 1822;
uint16 constant _outgoingMaxModularInverseCalldata_ = 1849;
uint16 constant _incomingMaxCalldata_ = 1881;
uint16 constant _poolGrowthPortionCalldata_ = 1908;
uint16 constant _maxPoolGrowthPortionCalldata_ = 1914;
uint16 constant _protocolGrowthPortionCalldata_ = 1920;
uint16 constant _pendingKernelLengthCalldata_ = 1926;
uint16 constant _endOfStaticParamsCalldata_ = 1928;

uint16 constant _modifyPositionInputCalldata_ = 120;
uint16 constant _logPriceMinOffsettedCalldata_ = 120;
uint16 constant _logPriceMaxOffsettedCalldata_ = 128;
uint16 constant _sharesCalldata_ = 136;
uint16 constant _logPriceMinCalldata_ = 168;
uint16 constant _logPriceMaxCalldata_ = 200;
uint16 constant _positionAmount0Calldata_ = 232;
uint16 constant _positionAmount1Calldata_ = 264;
uint16 constant _endOfModifyPositionCalldata_ = 296;

function getHookSelectorFromCalldata() pure returns (
  uint32 hookSelectorCalldata
) {
  assembly {
    hookSelectorCalldata := shr(224, calldataload(_hookSelectorCalldata_))
  }
}

function getHookInputHeaderFromCalldata() pure returns (
  uint256 hookInputHeaderCalldata
) {
  assembly {
    hookInputHeaderCalldata := calldataload(_hookInputHeaderCalldata_)
  }
}

function getHookInputByteCountFromCalldata() pure returns (
  uint256 hookInputByteCountCalldata
) {
  assembly {
    hookInputByteCountCalldata := calldataload(_hookInputByteCountCalldata_)
  }
}

function getMsgSenderFromCalldata() pure returns (
  address msgSenderCalldata
) {
  assembly {
    msgSenderCalldata := shr(96, calldataload(_msgSenderCalldata_))
  }
}

function getPoolIdFromCalldata() pure returns (
  uint256 poolIdCalldata
) {
  assembly {
    poolIdCalldata := calldataload(_poolIdCalldata_)
  }
}

function getCrossThresholdFromCalldata() pure returns (
  uint256 crossThresholdCalldata
) {
  assembly {
    crossThresholdCalldata := shr(128, calldataload(_crossThresholdCalldata_))
  }
}

function getAmountSpecifiedFromCalldata() pure returns (
  X127 amountSpecifiedCalldata
) {
  assembly {
    amountSpecifiedCalldata := calldataload(_amountSpecifiedCalldata_)
  }
}

function getLogPriceLimitFromCalldata() pure returns (
  X59 logPriceLimitCalldata
) {
  assembly {
    logPriceLimitCalldata := calldataload(_logPriceLimitCalldata_)
  }
}

function getLogPriceLimitOffsettedFromCalldata() pure returns (
  X59 logPriceLimitOffsettedCalldata
) {
  assembly {
    logPriceLimitOffsettedCalldata := 
      shr(192, calldataload(_logPriceLimitOffsettedCalldata_))
  }
}

function getZeroForOneFromCalldata() pure returns (
  bool zeroForOneCalldata
) {
  assembly {
    zeroForOneCalldata := shr(255, calldataload(_zeroForOneCalldata_))
  }
}

function getExactInputFromCalldata() pure returns (
  bool exactInputCalldata
) {
  assembly {
    exactInputCalldata := shr(255, calldataload(_exactInputCalldata_))
  }
}

function getIntegralLimitFromCalldata() pure returns (
  X216 integralLimitCalldata
) {
  assembly {
    integralLimitCalldata := shr(40, calldataload(_integralLimitCalldata_))
  }
}

function getIntegralLimitIntervalFromCalldata() pure returns (
  X216 integralLimitIntervalCalldata
) {
  assembly {
    integralLimitIntervalCalldata := 
      shr(40, calldataload(_integralLimitIntervalCalldata_))
  }
}

function getAmount0FromCalldata() pure returns (
  X127 amount0Calldata
) {
  assembly {
    amount0Calldata := calldataload(_amount0Calldata_)
  }
}

function getAmount1FromCalldata() pure returns (
  X127 amount1Calldata
) {
  assembly {
    amount1Calldata := calldataload(_amount1Calldata_)
  }
}

function getBackGrowthMultiplierFromCalldata() pure returns (
  X208 backGrowthMultiplierCalldata
) {
  assembly {
    backGrowthMultiplierCalldata := 
      calldataload(_backGrowthMultiplierCalldata_)
  }
}

function getNextGrowthMultiplierFromCalldata() pure returns (
  X208 nextGrowthMultiplierCalldata
) {
  assembly {
    nextGrowthMultiplierCalldata := 
      calldataload(_nextGrowthMultiplierCalldata_)
  }
}

function getDirectionFromCalldata() pure returns (
  bool directionCalldata
) {
  assembly {
    directionCalldata := shr(255, calldataload(_directionCalldata_))
  }
}

function getIndexCurveFromCalldata() pure returns (
  Index indexCurveCalldata
) {
  assembly {
    indexCurveCalldata := shr(240, calldataload(_indexCurveCalldata_))
  }
}

function getLogPriceLimitOffsettedWithinIntervalFromCalldata() pure returns (
  X59 logPriceLimitOffsettedWithinIntervalCalldata
) {
  assembly {
    logPriceLimitOffsettedWithinIntervalCalldata := 
      shr(192, calldataload(_logPriceLimitOffsettedWithinIntervalCalldata_))
  }
}

function getAccrued0FromCalldata() pure returns (
  X127 accrued0Calldata
) {
  assembly {
    accrued0Calldata := calldataload(_accrued0Calldata_)
  }
}

function getAccrued1FromCalldata() pure returns (
  X127 accrued1Calldata
) {
  assembly {
    accrued1Calldata := calldataload(_accrued1Calldata_)
  }
}

function getPoolRatio0FromCalldata() pure returns (
  X23 poolRatio0Calldata
) {
  assembly {
    poolRatio0Calldata := shr(232, calldataload(_poolRatio0Calldata_))
  }
}

function getPoolRatio1FromCalldata() pure returns (
  X23 poolRatio1Calldata
) {
  assembly {
    poolRatio1Calldata := shr(232, calldataload(_poolRatio1Calldata_))
  }
}

function getKernelFromCalldata() pure returns (
  Kernel kernelCalldata
) {
  assembly {
    kernelCalldata := sub(calldataload(_kernelCalldata_), _hookSelector_)
  }
}

function getCurveFromCalldata() pure returns (
  Curve curveCalldata
) {
  assembly {
    curveCalldata := sub(calldataload(_curveCalldata_), _hookSelector_)
  }
}

function getHookDataFromCalldata() pure returns (
  uint256 hookDataCalldata
) {
  assembly {
    hookDataCalldata := sub(calldataload(_hookDataCalldata_), _hookSelector_)
  }
}

function getKernelLengthFromCalldata() pure returns (
  Index kernelLengthCalldata
) {
  assembly {
    kernelLengthCalldata := shr(240, calldataload(_kernelLengthCalldata_))
  }
}

function getCurveLengthFromCalldata() pure returns (
  Index curveLengthCalldata
) {
  assembly {
    curveLengthCalldata := shr(240, calldataload(_curveLengthCalldata_))
  }
}

function getHookDataByteCountFromCalldata() pure returns (
  uint16 hookDataByteCountCalldata
) {
  assembly {
    hookDataByteCountCalldata := 
      shr(240, calldataload(_hookDataByteCountCalldata_))
  }
}

function getStaticParamsStoragePointerExtensionFromCalldata() pure returns (
  uint256 staticParamsStoragePointerExtensionCalldata
) {
  assembly {
    staticParamsStoragePointerExtensionCalldata := 
      calldataload(_staticParamsStoragePointerExtensionCalldata_)
  }
}

function getGrowthFromCalldata() pure returns (
  X111 growthCalldata
) {
  assembly {
    growthCalldata := shr(128, calldataload(_growthCalldata_))
  }
}

function getIntegral0FromCalldata() pure returns (
  X216 integral0Calldata
) {
  assembly {
    integral0Calldata := shr(40, calldataload(_integral0Calldata_))
  }
}

function getIntegral1FromCalldata() pure returns (
  X216 integral1Calldata
) {
  assembly {
    integral1Calldata := shr(40, calldataload(_integral1Calldata_))
  }
}

function getSharesTotalFromCalldata() pure returns (
  uint256 sharesTotalCalldata
) {
  assembly {
    sharesTotalCalldata := shr(128, calldataload(_sharesTotalCalldata_))
  }
}

function getStaticParamsStoragePointerFromCalldata() pure returns (
  uint16 staticParamsStoragePointerCalldata
) {
  assembly {
    staticParamsStoragePointerCalldata := 
      shr(240, calldataload(_staticParamsStoragePointerCalldata_))
  }
}

function getLogPriceCurrentFromCalldata() pure returns (
  X59 logPriceCurrentCalldata
) {
  assembly {
    logPriceCurrentCalldata := 
      shr(192, calldataload(_logPriceCurrentCalldata_))
  }
}

function getDeploymentCreationCodeFromCalldata() pure returns (
  uint256 deploymentCreationCodeCalldata
) {
  assembly {
    deploymentCreationCodeCalldata := 
      shr(168, calldataload(_deploymentCreationCodeCalldata_))
  }
}

function getTag0FromCalldata() pure returns (
  Tag tag0Calldata
) {
  assembly {
    tag0Calldata := calldataload(_tag0Calldata_)
  }
}

function getTag1FromCalldata() pure returns (
  Tag tag1Calldata
) {
  assembly {
    tag1Calldata := calldataload(_tag1Calldata_)
  }
}

function getSqrtOffsetFromCalldata() pure returns (
  X127 sqrtOffsetCalldata
) {
  assembly {
    sqrtOffsetCalldata := calldataload(_sqrtOffsetCalldata_)
  }
}

function getSqrtInverseOffsetFromCalldata() pure returns (
  X127 sqrtInverseOffsetCalldata
) {
  assembly {
    sqrtInverseOffsetCalldata := calldataload(_sqrtInverseOffsetCalldata_)
  }
}

function getOutgoingMaxFromCalldata() pure returns (
  X216 outgoingMaxCalldata
) {
  assembly {
    outgoingMaxCalldata := shr(40, calldataload(_outgoingMaxCalldata_))
  }
}

function getOutgoingMaxModularInverseFromCalldata() pure returns (
  uint256 outgoingMaxModularInverseCalldata
) {
  assembly {
    outgoingMaxModularInverseCalldata := 
      calldataload(_outgoingMaxModularInverseCalldata_)
  }
}

function getIncomingMaxFromCalldata() pure returns (
  X216 incomingMaxCalldata
) {
  assembly {
    incomingMaxCalldata := shr(40, calldataload(_incomingMaxCalldata_))
  }
}

function getPoolGrowthPortionFromCalldata() pure returns (
  X47 poolGrowthPortionCalldata
) {
  assembly {
    poolGrowthPortionCalldata := 
      shr(208, calldataload(_poolGrowthPortionCalldata_))
  }
}

function getMaxPoolGrowthPortionFromCalldata() pure returns (
  X47 maxPoolGrowthPortionCalldata
) {
  assembly {
    maxPoolGrowthPortionCalldata := 
      shr(208, calldataload(_maxPoolGrowthPortionCalldata_))
  }
}

function getProtocolGrowthPortionFromCalldata() pure returns (
  X47 protocolGrowthPortionCalldata
) {
  assembly {
    protocolGrowthPortionCalldata := 
      shr(208, calldataload(_protocolGrowthPortionCalldata_))
  }
}

function getPendingKernelLengthFromCalldata() pure returns (
  Index pendingKernelLengthCalldata
) {
  assembly {
    pendingKernelLengthCalldata := 
      shr(240, calldataload(_pendingKernelLengthCalldata_))
  }
}

function getLogPriceMinOffsettedFromCalldata() pure returns (
  X59 logPriceMinOffsettedCalldata
) {
  assembly {
    logPriceMinOffsettedCalldata := 
      shr(192, calldataload(_logPriceMinOffsettedCalldata_))
  }
}

function getLogPriceMaxOffsettedFromCalldata() pure returns (
  X59 logPriceMaxOffsettedCalldata
) {
  assembly {
    logPriceMaxOffsettedCalldata := 
      shr(192, calldataload(_logPriceMaxOffsettedCalldata_))
  }
}

function getSharesFromCalldata() pure returns (
  int256 sharesCalldata
) {
  assembly {
    sharesCalldata := calldataload(_sharesCalldata_)
  }
}

function getLogPriceMinFromCalldata() pure returns (
  X59 logPriceMinCalldata
) {
  assembly {
    logPriceMinCalldata := calldataload(_logPriceMinCalldata_)
  }
}

function getLogPriceMaxFromCalldata() pure returns (
  X59 logPriceMaxCalldata
) {
  assembly {
    logPriceMaxCalldata := calldataload(_logPriceMaxCalldata_)
  }
}

function getPositionAmount0FromCalldata() pure returns (
  int256 positionAmount0Calldata
) {
  assembly {
    positionAmount0Calldata := calldataload(_positionAmount0Calldata_)
  }
}

function getPositionAmount1FromCalldata() pure returns (
  int256 positionAmount1Calldata
) {
  assembly {
    positionAmount1Calldata := calldataload(_positionAmount1Calldata_)
  }
}