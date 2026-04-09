// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {
  _staticParams_,
  _endOfStaticParams_,
  _freeMemoryPointer_,
  setPoolId,
  getMaxPoolGrowthPortion,
  getProtocolGrowthPortion,
  getStaticParamsStoragePointerExtension,
  getGrowth,
  getIntegral0,
  getIntegral1,
  getSharesTotal,
  getStaticParamsStoragePointer,
  getLogPriceCurrent,
  setLogPriceCurrent,
  setSharesTotal,
  setIntegral0,
  setIntegral1,
  setGrowth,
  setLogPriceMinOffsetted,
  setLogPriceMaxOffsetted,
  setShares,
  setKernel
} from "../utilities/Memory.sol";
import {X111} from "../utilities/X111.sol";
import "../utilities/Storage.sol";

/// @title This contract exposes the internal functions of 'Storage.sol' for 
/// testing purposes.
contract StorageWrapper {
  using PriceLibrary for uint16;

  function _protocolSlot() public returns (
    uint256 storageSlot
  ) {
    return protocolSlot;
  }

  function _sentinelSlot() public returns (
    uint256 storageSlot
  ) {
    return sentinelSlot;
  }

  function _writeProtocol(
    uint256 protocol
  ) public returns (
    uint256 protocolResult
  ) {
    writeProtocol(protocol);
    return readStorage(protocolSlot);
  }

  function _readProtocol(
    uint256 protocol
  ) public returns (
    uint256 result
  ) {
    writeProtocol(protocol);
    return readProtocol();
  }

  function _getProtocolOwner(
    uint256 protocol
  ) public returns (
    address result
  ) {
    return getProtocolOwner(protocol);
  }

  function _getGrowthPortions(
    uint256 protocol
  ) public returns (
    X47 maxPoolGrowthPortion,
    X47 protocolGrowthPortion
  ) {
    return getGrowthPortions(protocol);
  }

  function _writeSentinel(
    ISentinel sentinel
  ) public returns (
    uint256 sentinelResult
  ) {
    writeSentinel(sentinel);
    return readStorage(sentinelSlot);
  }

  function _readSentinel(
    ISentinel sentinel
  ) public returns (
    ISentinel sentinelResult
  ) {
    writeStorage(sentinelSlot, uint256(uint160(address(sentinel))));
    return readSentinel();
  }

  function _readGrowthPortions(
    ISentinel sentinel,
    uint256 protocol
  ) public returns (
    X47 maxPoolGrowthPortion,
    X47 protocolGrowthPortion
  ) {
    writeSentinel(sentinel);
    writeProtocol(protocol);
    readGrowthPortions();
    return (getMaxPoolGrowthPortion(), getProtocolGrowthPortion());
  }

  function _singleBalanceSlot() public returns (
    uint256 storageSlot
  ) {
    return singleBalanceSlot;
  }

  function _getSingleBalanceSlot(
    address owner,
    Tag tag
  ) public returns (
    uint256 storageSlot
  ) {
    return getSingleBalanceSlot(owner, tag);
  }

  function _incrementBalance(
    uint256 currentBalance,
    address owner,
    Tag tag,
    uint256 amount
  ) public returns (
    uint256 newBalance
  ) {
    writeStorage(getSingleBalanceSlot(owner, tag), currentBalance);
    incrementBalance(owner, tag, amount);
    return readStorage(getSingleBalanceSlot(owner, tag));
  }

  function _decrementBalance(
    uint256 currentBalance,
    bool currentIsOperator,
    uint256 currentAllowance,
    address owner,
    Tag tag,
    uint256 amount
  ) public returns (
    uint256 newBalance,
    uint256 newAllowance
  ) {
    writeStorage(getSingleBalanceSlot(owner, tag), currentBalance);
    writeStorage(
      getIsOperatorSlot(owner, msg.sender),
      currentIsOperator ? 1 : 0
    );
    writeStorage(getAllowanceSlot(owner, msg.sender, tag), currentAllowance);
    decrementBalance(owner, tag, amount);
    return (
      readStorage(getSingleBalanceSlot(owner, tag)),
      readStorage(getAllowanceSlot(owner, msg.sender, tag))
    );
  }

  function _doubleBalanceSlot() public returns (
    uint256 storageSlot
  ) {
    return doubleBalanceSlot;
  }

  function _getDoubleBalanceSlot(
    address owner,
    Tag tag0,
    Tag tag1
  ) public returns (
    uint256 storageSlot
  ) {
    return getDoubleBalanceSlot(owner, tag0, tag1);
  }

  function _readDoubleBalance(
    uint256 storageSlot,
    uint256 content
  ) public returns (
    uint256 amount0,
    uint256 amount1
  ) {
    writeStorage(storageSlot, content);
    return readDoubleBalance(storageSlot);
  }

  function _writeDoubleBalance(
    uint256 storageSlot,
    uint256 amount0,
    uint256 amount1
  ) public returns (
    uint256 content
  ) {
    writeDoubleBalance(storageSlot, amount0, amount1);
    return readStorage(storageSlot);
  }

  function _totalSupplySlot() public returns (
    uint256 storageSlot
  ) {
    return totalSupplySlot;
  }

  function _updateTotalSupply(
    uint256 storageSlot,
    uint256 totalSupply,
    uint256 poolId,
    X59 qMin,
    X59 qMax,
    int256 shares
  ) public returns (
    uint256 newTotalSupply
  ) {
    writeStorage(storageSlot, totalSupply);
    updateTotalSupply(poolId, qMin, qMax, shares);
    return readStorage(storageSlot);
  }

  function _isOperatorSlot() public returns (
    uint256 storageSlot
  ) {
    return isOperatorSlot;
  }
  
  function _getIsOperatorSlot(
    address owner,
    address spender
  ) public returns (
    uint256 storageSlot
  ) {
    return getIsOperatorSlot(owner, spender);
  }

  function _allowanceSlot() public returns (
    uint256 storageSlot
  ) {
    return allowanceSlot;
  }
  
  function _getAllowanceSlot(
    address owner,
    address spender,
    Tag tag
  ) public returns (
    uint256 storageSlot
  ) {
    return getAllowanceSlot(owner, spender, tag);
  }

  function _updateAllowance(
    bool currentIsOperator,
    uint256 currentAllowance,
    address owner,
    Tag tag,
    uint256 amount
  ) public returns (
    uint256 newAllowance
  ) {
    writeStorage(
      getIsOperatorSlot(owner, msg.sender),
      currentIsOperator ? 1 : 0
    );
    writeStorage(getAllowanceSlot(owner, msg.sender, tag), currentAllowance);
    updateAllowance(owner, tag, amount);
    return readStorage(getAllowanceSlot(owner, msg.sender, tag));
  }

  function _poolOwnerSlot() public returns (
    uint256 storageSlot
  ) {
    return poolOwnerSlot;
  }

  function _getPoolOwnerSlot(
    uint256 poolId
  ) public returns (
    uint256 storageSlot
  ) {
    return getPoolOwnerSlot(poolId);
  }

  function _readPoolOwner(
    uint256 storageSlot,
    address poolOwner
  ) public returns (
    address poolOwnerResult
  ) {
    writeStorage(storageSlot, uint256(uint160(poolOwner)));
    return readPoolOwner(storageSlot);
  }

  function _writePoolOwner(
    uint256 storageSlot,
    address poolOwner
  ) public returns (
    uint256 content
  ) {
    writePoolOwner(storageSlot, poolOwner);
    return readStorage(storageSlot);
  }

  function _accruedParamsSlot() public returns (
    uint256 storageSlot
  ) {
    return accruedParamsSlot;
  }

  function _getAccruedParamsSlot(
    uint256 poolId
  ) public returns (
    uint256 storageSlot
  ) {
    return getAccruedParamsSlot(poolId);
  }

  function _readAccruedParams(
    uint256 poolId,
    uint256 content
  ) public returns (
    X23 poolRatio0,
    X23 poolRatio1,
    X127 accrued0,
    X127 accrued1
  ) {
    writeStorage(getAccruedParamsSlot(poolId), content);
    setPoolId(poolId);
    readAccruedParams();
    return (
      getPoolRatio0(),
      getPoolRatio1(),
      getAccrued0(),
      getAccrued1()
    );
  }

  function _writeAccruedParams(
    uint256 poolId,
    X23 poolRatio0,
    X23 poolRatio1,
    X127 accrued0,
    X127 accrued1
  ) public returns (
    uint256 content
  ) {
    setPoolId(poolId);
    setPoolRatio0(poolRatio0);
    setPoolRatio1(poolRatio1);
    setAccrued0(accrued0);
    setAccrued1(accrued1);
    writeAccruedParams();
    return readStorage(getAccruedParamsSlot(poolId));
  }

  function _growthMultiplierSlot() public returns (
    uint256 storageSlot
  ) {
    return growthMultiplierSlot;
  }

  function _getGrowthMultiplierSlot(
    uint256 poolId,
    X59 qBoundary
  ) public returns (
    uint256 storageSlot
  ) {
    return getGrowthMultiplierSlot(poolId, qBoundary);
  }

  function _readGrowthMultiplier(
    uint256 storageSlot,
    uint256 content
  ) public returns (
    X208 growthMultiplier
  ) {
    writeStorage(storageSlot, content);
    return readGrowthMultiplier(storageSlot);
  }

  function _calculateGrowthMultiplier0(
    X59 qSpacing,
    X59 qBoundary
  ) public returns (
    X208 growthMultiplier
  ) {
    _spacing_.storePrice(qSpacing);
    return calculateGrowthMultiplier0(qBoundary);
  }

  function _calculateGrowthMultiplier1(
    X59 qSpacing,
    X59 qBoundary
  ) public returns (
    X208 growthMultiplier
  ) {
    _spacing_.storePrice(qSpacing);
    return calculateGrowthMultiplier1(qBoundary);
  }

  function _calculateGrowthMultiplier0(
    uint256 poolId,
    X59 qSpacing,
    X59 qBoundary,
    X208 growthMultiplier
  ) public returns (
    X208 growthMultiplierResult,
    X208 growthMultiplierStorage
  ) {
    setPoolId(poolId);
    _spacing_.storePrice(qSpacing);
    writeGrowthMultiplier(
      getGrowthMultiplierSlot(poolId, qBoundary),
      growthMultiplier
    );
    growthMultiplierResult = readGrowthMultiplier0(qBoundary);
    growthMultiplierStorage = readGrowthMultiplier(
      getGrowthMultiplierSlot(poolId, qBoundary)
    );
  }

  function _calculateGrowthMultiplier1(
    uint256 poolId,
    X59 qSpacing,
    X59 qBoundary,
    X208 growthMultiplier
  ) public returns (
    X208 growthMultiplierResult,
    X208 growthMultiplierStorage
  ) {
    setPoolId(poolId);
    _spacing_.storePrice(qSpacing);
    writeGrowthMultiplier(
      getGrowthMultiplierSlot(poolId, qBoundary),
      growthMultiplier
    );
    growthMultiplierResult = readGrowthMultiplier1(qBoundary);
    growthMultiplierStorage = readGrowthMultiplier(
      getGrowthMultiplierSlot(poolId, qBoundary)
    );
  }

  function _writeGrowthMultiplier(
    uint256 storageSlot,
    X208 growthMultiplier
  ) public returns (
    uint256 content
  ) {
    writeGrowthMultiplier(storageSlot, growthMultiplier);
    return readStorage(storageSlot);
  }
  
  function _writeGrowthMultipliers(
    uint256 poolId,
    X59 qSpacing,
    X59 qLower,
    X59 qUpper
  ) public returns (
    X208 growthMultiplierLowerResult,
    X208 growthMultiplierUpperResult
  ) {
    setPoolId(poolId);
    _spacing_.storePrice(qSpacing);
    writeGrowthMultipliers(qLower, qUpper);
    return (
      readGrowthMultiplier(getGrowthMultiplierSlot(getPoolId(), qLower)),
      readGrowthMultiplier(getGrowthMultiplierSlot(getPoolId(), qUpper))
    );
  }

  function _sharesGrossSlot() public returns (
    uint256 storageSlot
  ) {
    return sharesGrossSlot;
  }

  function _getSharesGrossSlot(
    uint256 poolId
  ) public returns (
    uint256 storageSlot
  ) {
    return getSharesGrossSlot(poolId);
  }

  function _sharesDeltaSlot() public returns (
    uint256 storageSlot
  ) {
    return sharesDeltaSlot;
  }

  function _getSharesDeltaSlot(
    uint256 poolId,
    X59 qBoundary
  ) public returns (
    uint256 storageSlot
  ) {
    return getSharesDeltaSlot(poolId, qBoundary);
  }

  function _readSharesDelta(
    uint256 storageSlot,
    uint256 content
  ) public returns (
    int256 sharesDelta
  ) {
    writeStorage(storageSlot, content);
    return readSharesDelta(storageSlot);
  }

  function _modifySharesDelta(
    uint256 poolId,
    uint256 sharesGross,
    int256 shares,
    int256 sharesDeltaMin,
    int256 sharesDeltaMax,
    X59 qMin,
    X59 qMax,
    X59 qSpacing
  ) public returns (
    uint256 sharesGrossNew,
    int256 sharesDeltaMinNew,
    int256 sharesDeltaMaxNew
  ) {
    setPoolId(poolId);
    setShares(shares);
    writeStorage(getSharesGrossSlot(poolId), sharesGross);
    setLogPriceMinOffsetted(qMin);
    setLogPriceMaxOffsetted(qMax);
    _spacing_.storePrice(qSpacing);
    writeStorage(getSharesDeltaSlot(poolId, qMin), uint256(sharesDeltaMin));
    writeStorage(getSharesDeltaSlot(poolId, qMax), uint256(sharesDeltaMax));
    modifySharesDelta();
    return (
      readStorage(getSharesGrossSlot(poolId)),
      int256(readStorage(getSharesDeltaSlot(poolId, qMin))),
      int256(readStorage(getSharesDeltaSlot(poolId, qMax)))
    );
  }

  function _dynamicParamsSlot() public returns (
    uint256 storageSlot
  ) {
    return dynamicParamsSlot;
  }

  function _getDynamicParamsSlot(
    uint256 poolId
  ) public returns (
    uint256 storageSlot
  ) {
    return getDynamicParamsSlot(poolId);
  }

  function _readDynamicParams(
    uint256 poolId,
    uint256 content0,
    uint256 content1,
    uint256 content2,
    uint256 content3
  ) public returns (
    uint256 staticParamsStoragePointerExtension,
    uint16 staticParamsStoragePointer,
    X59 logPriceCurrent,
    uint256 sharesTotal,
    X111 growth,
    X216 integral0,
    X216 integral1
  ) {
    setPoolId(poolId);
    uint256 storageSlot = getDynamicParamsSlot(poolId);
    writeStorage(storageSlot, content0);
    writeStorage(storageSlot + 1, content1);
    writeStorage(storageSlot + 2, content2);
    writeStorage(storageSlot - 1, content3);
    readDynamicParams();
    return (
      getStaticParamsStoragePointerExtension(),
      getStaticParamsStoragePointer(),
      getLogPriceCurrent(),
      getSharesTotal(),
      getGrowth(),
      getIntegral0(),
      getIntegral1()
    );
  }

  function _writeDynamicParams(
    uint256 poolId,
    uint256 staticParamsStoragePointerExtension,
    uint16 staticParamsStoragePointer,
    X59 logPriceCurrent,
    uint256 sharesTotal,
    X111 growth,
    X216 integral0,
    X216 integral1
  ) public returns (
    uint256 content0,
    uint256 content1,
    uint256 content2,
    uint256 content3
  ) {
    setPoolId(poolId);
    setStaticParamsStoragePointerExtension(
      staticParamsStoragePointerExtension
    );
    setStaticParamsStoragePointer(staticParamsStoragePointer);
    setLogPriceCurrent(logPriceCurrent);
    setSharesTotal(sharesTotal);
    setGrowth(growth);
    setIntegral0(integral0);
    setIntegral1(integral1);
    writeDynamicParams();
    uint256 storageSlot = getDynamicParamsSlot(poolId);
    return (
      readStorage(storageSlot),
      readStorage(storageSlot + 1),
      readStorage(storageSlot + 2),
      readStorage(storageSlot - 1)
    );
  }

  function _curveSlot() public returns (
    uint256 storageSlot
  ) {
    return curveSlot;
  }

  function _getCurveSlot(
    uint256 poolId
  ) public returns (
    uint256 storageSlot
  ) {
    return getCurveSlot(poolId);
  }

  function _readBoundaries(
    uint256 poolId,
    uint256 content
  ) public returns (
    X59 qLower,
    X59 qUpper
  ) {
    setPoolId(poolId);
    writeStorage(getCurveSlot(poolId), content);
    return readBoundaries();
  }

  function _readCurve(
    uint256 poolId,
    X59 qCurrent,
    uint256[] calldata curveArray
  ) public returns (
    X59[] memory curveMembers,
    Index curveLength
  ) {
    setPoolId(poolId);
    setLogPriceCurrent(qCurrent);
    uint256 storageSlot = getCurveSlot(poolId);
    for (uint256 kk = 0; kk < curveArray.length; ++kk) {
      writeStorage(storageSlot, curveArray[kk]);
      ++storageSlot;
    }
    Curve curve = Curve.wrap(_endOfStaticParams_);
    setCurve(curve);
    curveLength = readCurve();
    assembly {
      curveMembers := add(curve, mul(8, curveLength))
      mstore(curveMembers, curveLength)
    }
    for (uint256 kk = 0; kk < Index.unwrap(curveLength); ++kk) {
      curveMembers[kk] = curve.member(Index.wrap(kk));
    }
  }

  function _writeCurve(
    uint256 poolId,
    Index curveLength,
    uint256[] calldata curveArray
  ) public returns (
    uint256[] memory curveArrayResult
  ) {
    setPoolId(poolId);
    setCurveLength(curveLength);
    Curve curve;
    assembly {
      curve := _endOfStaticParams_
      calldatacopy(
        _endOfStaticParams_,
        add(36, calldataload(68)),
        mul(8, curveLength)
      )
      curveArrayResult := add(
        add(_endOfStaticParams_, 32),
        mul(8, curveLength)
      )
      mstore(curveArrayResult, calldataload(add(4, calldataload(68))))
    }
    setCurve(curve);
    writeCurve();
    uint256 storageSlot = getCurveSlot(poolId);
    for (uint256 kk = 0; kk < curveArrayResult.length; ++kk) {
      curveArrayResult[kk] = readStorage(storageSlot);
      ++storageSlot;
    }
  }

  function _writeStaticParams(
    uint256 poolId,
    Index kernelLength,
    uint256 storagePointer,
    uint160 storageAddress,
    bytes calldata content
  ) public returns (
    bytes memory contentResult
  ) {
    setPoolId(poolId);
    setKernelLength(kernelLength);
    assembly {
      calldatacopy(
        _staticParams_,
        add(36, calldataload(132)),
        calldataload(add(4, calldataload(132)))
      )
    }
    writeStaticParams(storagePointer);
    Index length = getKernelLength();
    assembly {
      contentResult := add(
        _staticParams_,
        calldataload(add(4, calldataload(132)))
      )
      mstore(contentResult, extcodesize(storageAddress))
      extcodecopy(
        storageAddress,
        add(contentResult, 32),
        0,
        extcodesize(storageAddress)
      )
    }
  }

  function _getStaticParamsStorageAddress(
    uint256 poolId,
    uint256 storagePointer
  ) public returns (
    address storageAddress
  ) {
    setPoolId(poolId);
    return getStaticParamsStorageAddress(storagePointer);
  }

  function _getStaticParamsStorageAddress(
    address nofeeswap,
    uint256 poolId,
    uint256 storagePointer
  ) public returns (
    address storageAddress
  ) {
    return getStaticParamsStorageAddress(nofeeswap, poolId, storagePointer);
  }

  function _readStaticParams(
    bytes calldata content
  ) public returns (
    bytes memory contentResult
  ) {
    address storageAddress;
    assembly {
      mstore8(128, 0x63)
      mstore(129, shl(224, sub(calldatasize(), 67)))
      mstore8(133, 0x80)
      mstore8(134, 0x60)
      mstore8(135, 0x0E)
      mstore8(136, 0x60)
      mstore8(137, 0x00)
      mstore8(138, 0x39)
      mstore8(139, 0x60)
      mstore8(140, 0x00)
      mstore8(141, 0xF3)
      mstore(142, 0x00)
      calldatacopy(143, 68, sub(calldatasize(), 68))
      storageAddress := create(0, 128, sub(calldatasize(), 53))
    }
    readStaticParams(storageAddress);
    assembly {
      contentResult := sub(_staticParams_, 32)
      mstore(contentResult, sub(_endOfStaticParams_, _staticParams_))
    }
  }

  function _readStaticParamsAndKernel(
    bytes calldata content
  ) public returns (
    bytes memory contentResult
  ) {
    Kernel kernel;
    assembly {
      kernel := _endOfStaticParams_
    }
    setKernel(kernel);
    address storageAddress;
    assembly {
      mstore8(128, 0x63)
      mstore(129, shl(224, sub(calldatasize(), 67)))
      mstore8(133, 0x80)
      mstore8(134, 0x60)
      mstore8(135, 0x0E)
      mstore8(136, 0x60)
      mstore8(137, 0x00)
      mstore8(138, 0x39)
      mstore8(139, 0x60)
      mstore8(140, 0x00)
      mstore8(141, 0xF3)
      mstore(142, 0x00)
      calldatacopy(143, 68, sub(calldatasize(), 68))
      storageAddress := create(0, 128, sub(calldatasize(), 53))
    }
    readStaticParamsAndKernel(storageAddress);
    Index kernelLength = getKernelLength();
    assembly {
      contentResult := sub(_staticParams_, 32)
      mstore(
        contentResult,
        add(
          sub(_endOfStaticParams_, _staticParams_),
          mul(64, sub(kernelLength, 1))
        )
      )
    }
  }

  function _readKernelLength(
    bytes calldata content
  ) public returns (
    Index length
  ) {
    address storageAddress;
    assembly {
      mstore8(128, 0x63)
      mstore(129, shl(224, sub(calldatasize(), 67)))
      mstore8(133, 0x80)
      mstore8(134, 0x60)
      mstore8(135, 0x0E)
      mstore8(136, 0x60)
      mstore8(137, 0x00)
      mstore8(138, 0x39)
      mstore8(139, 0x60)
      mstore8(140, 0x00)
      mstore8(141, 0xF3)
      mstore(142, 0x00)
      calldatacopy(143, 68, sub(calldatasize(), 68))
      storageAddress := create(0, 128, sub(calldatasize(), 53))
    }
    return readKernelLength(storageAddress);
  }

  function _readKernel(
    bytes calldata content
  ) public returns (
    bytes memory contentResult
  ) {
    Kernel kernel;
    assembly {
      kernel := _endOfStaticParams_
    }
    setKernel(kernel);
    address storageAddress;
    assembly {
      mstore8(128, 0x63)
      mstore(129, shl(224, sub(calldatasize(), 67)))
      mstore8(133, 0x80)
      mstore8(134, 0x60)
      mstore8(135, 0x0E)
      mstore8(136, 0x60)
      mstore8(137, 0x00)
      mstore8(138, 0x39)
      mstore8(139, 0x60)
      mstore8(140, 0x00)
      mstore8(141, 0xF3)
      mstore(142, 0x00)
      calldatacopy(143, 68, sub(calldatasize(), 68))
      storageAddress := create(0, 128, sub(calldatasize(), 53))
    }
    Index kernelLength = readKernelLength(storageAddress);
    readKernel(kernel, storageAddress, kernelLength);
    assembly {
      contentResult := sub(_endOfStaticParams_, 32)
      mstore(
        contentResult,
        mul(64, sub(kernelLength, 1))
      )
    }
  }

  function _readPoolData0(
    uint256 poolId,
    Index kernelLength,
    uint256 storagePointer,
    uint256[4] calldata dynamicContent,
    uint256[] calldata curveArray,
    bytes calldata staticContent
  ) public {
    uint256 storageSlot = getDynamicParamsSlot(poolId);
    writeStorage(storageSlot, dynamicContent[0]);
    writeStorage(storageSlot + 1, dynamicContent[1]);
    writeStorage(storageSlot + 2, dynamicContent[2]);
    writeStorage(storageSlot - 1, dynamicContent[3]);
    storageSlot = getCurveSlot(poolId);
    for (uint256 kk = 0; kk < curveArray.length; ++kk) {
      writeStorage(storageSlot, curveArray[kk]);
      ++storageSlot;
    }
    setPoolId(poolId);
    setKernelLength(kernelLength);
    assembly {
      calldatacopy(
        _staticParams_,
        add(36, calldataload(260)),
        calldataload(add(4, calldataload(260)))
      )
    }
    writeStaticParams(storagePointer);
  }

  function _readPoolData1(
    uint256 poolId,
    Kernel kernel
  ) public returns (
    bytes memory contentResult
  ) {
    setPoolId(poolId);
    setKernel(kernel);
    readPoolData();
    assembly {
      contentResult := 0
      mstore(0, sub(mload(_freeMemoryPointer_), 32))
    }
  }
}

contract MockSentinel is ISentinel {
  X47 public maxPoolGrowthPortion;
  X47 public protocolGrowthPortion;
  bytes4 public authorizeInitializationSelector;
  bytes4 public authorizeModificationOfPoolGrowthPortionSelector;

  function setValues(
    X47 _maxPoolGrowthPortion,
    X47 _protocolGrowthPortion,
    bytes4 selector0,
    bytes4 selector1
  ) external {
    maxPoolGrowthPortion = _maxPoolGrowthPortion;
    protocolGrowthPortion = _protocolGrowthPortion;
    authorizeInitializationSelector = selector0;
    authorizeModificationOfPoolGrowthPortionSelector = selector1;
  }

  function getGrowthPortions(
    bytes calldata sentinelInput
  ) external returns (
    X47 _maxPoolGrowthPortion,
    X47 _protocolGrowthPortion
  ) {
    return (maxPoolGrowthPortion, protocolGrowthPortion);
  }

  function authorizeInitialization(
    bytes calldata sentinelInput
  ) external returns (bytes4 selector) {
    return authorizeInitializationSelector;
  }

  function authorizeModificationOfPoolGrowthPortion(
    bytes calldata sentinelInput
  ) external returns (bytes4 selector) {
    return authorizeModificationOfPoolGrowthPortionSelector;
  }
}