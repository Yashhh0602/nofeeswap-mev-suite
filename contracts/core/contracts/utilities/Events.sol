// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {ISentinel} from "../interfaces/ISentinel.sol";
import {INofeeswap} from "../interfaces/INofeeswap.sol";
import {
  _staticParams_,
  _modifyPositionInput_,
  _endOfModifyPosition_,
  _poolGrowthPortion_,
  _maxPoolGrowthPortion_,
  _growth_,
  getPoolId,
  getTag0,
  getTag1,
  getHookData,
  getCurve,
  getCurveLength
} from "./Memory.sol";
import {getProtocolOwner} from "./Storage.sol";
import {KernelCompact} from "./KernelCompact.sol";
import {Tag} from "./Tag.sol";
import {Curve} from "./Curve.sol";
import {Index} from "./Index.sol";
import {X47} from "./X47.sol";

function emitTransferEvent(
  address caller,
  address from,
  address to,
  Tag tag,
  uint256 amount
) {
  emit INofeeswap.Transfer(caller, from, to, tag, amount);
}

function emitOperatorSetEvent(
  address owner,
  address operator,
  bool approved
) {
  emit INofeeswap.OperatorSet(owner, operator, approved);
}

function emitApprovalEvent(
  address owner,
  address spender,
  Tag tag,
  uint256 amount
) {
  emit INofeeswap.Approval(owner, spender, tag, amount);
}

function emitModifyDoubleBalanceEvent(
  address caller,
  address owner,
  Tag tag,
  int256 increment,
  uint256 balance
) {
  emit INofeeswap.ModifyDoubleBalanceEvent(
    caller,
    owner,
    tag,
    increment,
    balance
  );
}

function emitPoolCollectionEvent(
  uint256 poolId,
  address owner,
  uint256 amount0,
  uint256 amount1
) {
  emit INofeeswap.PoolCollection(poolId, owner, amount0, amount1);
}

function emitProtocolCollectionEvent(
  uint256 poolId,
  uint256 amount0,
  uint256 amount1
) {
  emit INofeeswap.ProtocolCollection(poolId, amount0, amount1);
}

function emitModifyProtocolEvent(
  uint256 newProtocol
) {
  emit INofeeswap.ModifyProtocol(getProtocolOwner(newProtocol), newProtocol);
}

function emitModifySentinelEvent(
  ISentinel oldSentinel,
  ISentinel newSentinel
) {
  emit INofeeswap.ModifySentinel(oldSentinel, newSentinel);
}

function emitModifyPoolOwnerEvent(
  uint256 poolId,
  address oldOwner,
  address newOwner
) {
  emit INofeeswap.ModifyPoolOwner(poolId, oldOwner, newOwner);
}

function emitInitializeEvent() {
  uint256 poolId = getPoolId();
  Tag tag0 = getTag0();
  Tag tag1 = getTag1();
  uint256 hookData = getHookData();
  bytes32 selector = INofeeswap.Initialize.selector;
  assembly {
    // The byte count of the data to be emitted which does not include the abi
    // offset and length slot.
    // The subtraction is safe because 'hookData' is always ahead of
    // '_staticParams_' per 'Calldata.sol'.
    let size := sub(hookData, _staticParams_)
    
    // This slot should be populated with the abi offset. Hence, we cache its
    // current content so that it can be written back. Then we store a '0x20'
    // abi offset for the data to be emitted.
    // The subtractions are safe because both values are constants.
    let content0 := mload(sub(_staticParams_, 64))
    mstore(sub(_staticParams_, 64), 0x20)

    // This slot should be populated with 'size'. Hence, we cache its current
    // content so that it can be written back. Then we store a 'size'.
    // The subtractions are safe because both values are constants.
    let content1 := mload(sub(_staticParams_, 32))
    mstore(sub(_staticParams_, 32), size)

    // The number of bytes to be emitted should be divisible by '32'. If
    // '32 * ceiling(size / 32)' goes beyond 'size', then the extra bytes
    // should be equal to zero. Hence, we cache the content of this slot, so
    // that it can be restored after being zeroed. We then write zero in this
    // slot.
    let content2 := mload(hookData)
    mstore(hookData, 0)

    // Here, we calculate '32 * ceiling(size / 32)' which is the actual number
    // of bytes to be given as input to 'log4'.
    let module := mod(size, 0x20)
    if gt(module, 0) {
      size := add(sub(size, module), 0x20)
    }

    log4(
      // During initialization, 'staticParams', 'kernel', 'kernelCompact',
      // 'curve', and 'hookData' appear in this order in memory. Hence, the
      // beginning of event data is '_staticParams_' which points to the start
      // of 'staticParams' and the end of event data is 'hookData' which points
      // to the end of 'curve'. '64' is subtracted in order to include the abi
      // offset and 'size' slots.
      sub(_staticParams_, 64),
      // As argued above, 'hookData - _staticParams_' is the number of bytes to
      // be emitted. '64' is added in order to include the abi offset and
      // 'size' slots.
      add(size, 64),
      selector,
      poolId,
      tag0,
      tag1
    )

    // Now we restore all of the cached content.
    mstore(sub(_staticParams_, 64), content0)    
    mstore(sub(_staticParams_, 32), content1)
    mstore(hookData, content2)
  }
}

function emitModifyPositionEvent() {
  uint256 poolId = getPoolId();
  bytes32 selector = INofeeswap.ModifyPosition.selector;
  assembly {
    // The number of bytes to be emitted should be divisible by '32'. Since
    // '32 * ceiling((_endOfModifyPosition_ - _modifyPositionInput_) / 32)'
    // goes beyond '_endOfModifyPosition_ - _modifyPositionInput_', the extra
    // bytes should be equal to zero. Hence, we cache the content of this slot,
    // so that it can be restored after being zeroed. We then write zero in
    // this slot.
    let content := mload(_endOfModifyPosition_)
    mstore(_endOfModifyPosition_, 0)

    log3(
      // As described in 'Memory.sol', in order to include all of the above
      // seven parameters, the beginning of event data should be
      // '_modifyPositionInput_' and the end of event data should be
      // '_endOfModifyPosition_'.
      _modifyPositionInput_,
      // As argued above, '_endOfModifyPosition_ - _modifyPositionInput_' is
      // the number of bytes to be emitted.
      // '16' is added because we want the number of bytes to be emitted to be
      // divisible by '32'.
      add(sub(_endOfModifyPosition_, _modifyPositionInput_), 16),
      selector,
      poolId,
      caller()
    )

    // Now we restore the cached content.
    mstore(_endOfModifyPosition_, content)
  }
}

function emitDonateEvent() {
  uint256 poolId = getPoolId();
  bytes32 selector = INofeeswap.Donate.selector;
  assembly {
    // We copy zeros to the end of 'growth' and emit the total '32' bytes.
    let content := mload(add(_growth_, 16))
    mstore(add(_growth_, 16), 0)

    // As described in 'Memory.sol', the pointer '_growth_' points to the
    // memory slot whose most significant '128' bits host 'growth'. Hence,
    // the beginning of event data should be '_growth_' and the size of event
    // data should be exactly '32' bytes.
    log3(_growth_, 32, selector, poolId, caller())

    // Now we restore the cached content.
    mstore(add(_growth_, 16), content)
  }
}

function emitSwapEvent() {
  uint256 poolId = getPoolId();
  Curve curve = getCurve();
  Index curveLength = getCurveLength();
  bytes32 selector = INofeeswap.Swap.selector;
  assembly {
    // The end of the curve sequence is calculated.
    let endOfCurve := add(curve, shl(3, curveLength))

    // We copy 'growth' to the end of 'curve' and emit the total '32' bytes.
    let content := mload(endOfCurve)
    mcopy(endOfCurve, _growth_, 16)

    log3(
      // The subtraction is safe because the curve sequence has at least '2'
      // members at all times.
      //
      // Each member of the curve sequence is '64 bits == 8 bytes' which is why
      // we shift 'curveLength - 2' by '3' bits (i.e., we are multiplying this
      // value by '8 == 2 ** 3'). We load the memory slot whose most
      // significant 128 bits host the last two members of the curve sequence.
      //
      //       ------------------------------------------------------------
      //       | 64 bits overshoot | 64 bits target | 128 additional bits |
      //       +-----------------------------------------------------------
      //       |
      //    pointer == curve + ((curveLength - 2) << 3)
      //
      // The addition is safe because we do not exceed the length of the curve
      // sequence.
      sub(endOfCurve, 16),
      // 32 bytes is 128 bits which covers exactly two members of the curve
      // sequence and the 'growth' that we have just copied.
      32,
      selector,
      poolId,
      caller()
    )

    // Now we restore the cached content.
    mstore(endOfCurve, content)
  }
}

function emitModifyKernelEvent() {
  uint256 poolId = getPoolId();
  bytes32 selector = INofeeswap.ModifyKernel.selector;
  uint256 hookData = getHookData();
  assembly {
    // The byte count of the data to be emitted which does not include the abi
    // offset and length slot.
    // The subtraction is safe because 'hookData' is always ahead of
    // '_staticParams_' per 'Calldata.sol'.
    let size := sub(hookData, _staticParams_)
    
    // This slot should be populated with the abi offset. Hence, we cache its
    // current content so that it can be written back. Then we store a '0x20'
    // abi offset for the data to be emitted.
    // The subtractions are safe because both values are constants.
    let content0 := mload(sub(_staticParams_, 64))
    mstore(sub(_staticParams_, 64), 0x20)

    // This slot should be populated with 'size'. Hence, we cache its current
    // content so that it can be written back. Then we store a 'size.
    // The subtractions are safe because both values are constants.
    let content1 := mload(sub(_staticParams_, 32))
    mstore(sub(_staticParams_, 32), size)

    // The number of bytes to be emitted should be divisible by '32'. If
    // '32 * ceiling(size / 32)' goes beyond 'size', then the extra bytes
    // should be equal to zero. Hence, we cache the content of this slot, so
    // that it can be restored after being zeroed. We then write zero in this
    // slot.
    let content2 := mload(hookData)
    mstore(hookData, 0)

    // Here, we calculate '32 * ceiling(size / 32)' which is the actual number
    // of bytes to be given as input to 'log4'.
    let module := mod(size, 0x20)
    if gt(module, 0) {
      size := add(sub(size, module), 0x20)
    }

    log3(
      // During modifyKernel, 'staticParams', 'kernel', 'kernelCompact', and
      // 'hookData' appear in this order in memory. Hence, the beginning of
      // event data is '_staticParams_' which points to the start of
      // 'staticParams' and the end of event data is 'hookData' which points
      // to the end of 'kernelCompact'. '64' is subtracted in order to include
      // the abi offset and 'size' slots.
      sub(_staticParams_, 64),
      // As argued above, 'hookData - _staticParams_' is the number of bytes to
      // be emitted. '64' is added in order to include the abi offset and
      // 'size' slots.
      add(size, 64),      
      selector,
      poolId,
      caller()
    )

    // Now we restore all of the cached content.
    mstore(sub(_staticParams_, 64), content0)    
    mstore(sub(_staticParams_, 32), content1)
    mstore(hookData, content2)
  }
}

function emitModifyPoolGrowthPortionEvent() {
  uint256 poolId = getPoolId();
  bytes32 selector = INofeeswap.ModifyPoolGrowthPortion.selector;
  assembly {
    // We copy zeros to the end of 'poolGrowthPortion' and emit the total '32'
    // bytes.
    let content := mload(add(_poolGrowthPortion_, 6))
    mstore(add(_poolGrowthPortion_, 6), 0)

    // As described in 'Memory.sol', the pointer '_poolGrowthPortion_' points
    // to the memory slot whose most significant '48' bits host
    // 'poolGrowthPortion'. Hence, the beginning of event data should be
    // '_poolGrowthPortion_' and the size of event data should be exactly '32'
    // bytes.
    log3(_poolGrowthPortion_, 32, selector, poolId, caller())

    // Now we restore the cached content.
    mstore(add(_poolGrowthPortion_, 6), content)
  }
}

function emitUpdateGrowthPortionsEvent() {
  uint256 poolId = getPoolId();
  bytes32 selector = INofeeswap.UpdateGrowthPortions.selector;
  assembly {
    // We copy zeros to the end of 'protocolGrowthPortion' and emit the total
    // '32' bytes.
    let content := mload(add(_maxPoolGrowthPortion_, 12))
    mstore(add(_maxPoolGrowthPortion_, 12), 0)

    // As described in 'Memory.sol', the pointer '_maxPoolGrowthPortion_'
    // points to the memory slot whose most significant '48' bits host
    // 'maxPoolGrowthPortion'. The next '48' bits that appear immediately after
    // 'maxPoolGrowthPortion' host 'protocolGrowthPortion'. Hence, the
    // beginning of event data should be '_maxPoolGrowthPortion_' and the size
    // of event data should be exactly '32' bytes.
    log3(_maxPoolGrowthPortion_, 32, selector, poolId, caller())

    // Now we restore the cached content.
    mstore(add(_maxPoolGrowthPortion_, 12), content)
  }
}