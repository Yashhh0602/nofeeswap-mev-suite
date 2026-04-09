// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {
  IERC1155Receiver
} from "@openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import {INofeeswap} from "./interfaces/INofeeswap.sol";
import {StorageAccess} from "./StorageAccess.sol";
import {TransientAccess} from "./TransientAccess.sol";
import {IUnlockCallback} from "./callback/IUnlockCallback.sol";
import {Tag, TagLibrary, native} from "./utilities/Tag.sol";
import {zeroIndex} from "./utilities/Index.sol";
import {zeroX127} from "./utilities/X127.sol";
import {X59} from "./utilities/X59.sol";
import {
  _back_,
  _next_,
  getPoolId,
  getPendingKernelLength,
  getAmount0,
  getAmount1,
  getTag0,
  getTag1,
  getAmountSpecified,
  getLogPriceLimitOffsetted,
  getLogPriceCurrent,
  getZeroForOne,
  getIntegralLimit,
  getIntegralLimitInterval,
  setBackGrowthMultiplier,
  setNextGrowthMultiplier
} from "./utilities/Memory.sol";
import {isGrowthPortion} from "./utilities/GrowthPortion.sol";
import {
  readStorage,
  writeStorage,
  getSingleBalanceSlot,
  getDoubleBalanceSlot,
  getAllowanceSlot,
  getIsOperatorSlot,
  updateAllowance,
  writeProtocol,
  readAccruedParams,
  readPoolData,
  writeDynamicParams,
  writeAccruedParams,
  writeCurve,
  readGrowthMultiplier,
  writeDoubleBalance,
  readDoubleBalance,
  incrementBalance,
  decrementBalance,
  getGrowthMultiplierSlot
} from "./utilities/Storage.sol";
import {
  updateTransientBalance,
  isProtocolUnlocked,
  unlockProtocol,
  lockProtocol,
  readNonzeroAmounts,
  readReserve,
  writeReserveToken,
  writeReserveTokenId,
  writeReserveValue,
  unlockPool,
  lockPool,
  transientBalance,
  getPoolLockSlot
} from "./utilities/Transient.sol";
import {TokenLibrary} from "./utilities/Token.sol";
import {PriceLibrary} from "./utilities/Price.sol";
import {SafeCastLibrary} from "./utilities/SafeCast.sol";
import {readSwapInput} from "./utilities/Calldata.sol";
import {
  setSwapParams,
  swapWithin,
  transition,
  cross,
  updateKernel
} from "./utilities/Swap.sol";
import {
  isPreSwap,
  isMidSwap,
  isPostSwap,
  invokePreSwap,
  invokeMidSwap,
  invokePostSwap
} from "./utilities/Hooks.sol";
import {
  emitModifyDoubleBalanceEvent,
  emitTransferEvent,
  emitOperatorSetEvent,
  emitApprovalEvent,
  emitSwapEvent
} from "./utilities/Events.sol";
import {
  MsgValueIsNonZero,
  InsufficientBalance,
  BalanceOverflow,
  TagsOutOfOrder,
  NoDelegateCall,
  OutstandingAmount,
  CannotTransferToAddressZero,
  NotEqualToTransientBalance
} from "./utilities/Errors.sol";

using PriceLibrary for uint16;
using TokenLibrary for address;
using TagLibrary for address;
using SafeCastLibrary for uint256;

/// @notice The accounting of tags in nofeeswap's singleton is compliant with
/// ERC-6909 multi-token specifications. A tag may correspond to the native and
/// ERC-20 tokens as well as ERC-1155, ERC-6909, and LP multi-tokens.
contract Nofeeswap is INofeeswap, StorageAccess, TransientAccess {
  address immutable nofeeswap;
  address immutable delegatee;
  
  constructor(address _delegatee, address admin) {
    nofeeswap = address(this);
    delegatee = _delegatee;
    writeProtocol(uint256(uint160(admin)) & type(uint160).max);
  }

  /// @inheritdoc INofeeswap
  function supportsInterface(
    bytes4 interfaceId
  ) external pure override returns (bool) {
    // ERC165 Interface ID for ERC165
    // ERC165 Interface ID for ERC6909
    return interfaceId == 0x01ffc9a7 || interfaceId == 0x0f632fb3;
  }

  /// @inheritdoc INofeeswap
  function balanceOf(
    address owner,
    Tag tag
  ) external view override returns (
    uint256 amount
  ) {
    return readStorage(getSingleBalanceSlot(owner, tag));
  }

  /// @inheritdoc INofeeswap
  function allowance(
    address owner,
    address spender,
    Tag tag
  ) external view override returns (
    uint256 amount
  ) {
    return readStorage(getAllowanceSlot(owner, spender, tag));
  }

  /// @inheritdoc INofeeswap
  function isOperator(
    address owner,
    address spender
  ) external view override returns (
    bool status
  ) {
    return readStorage(getIsOperatorSlot(owner, spender)) > 0;
  }

  /// @inheritdoc INofeeswap
  function transfer(
    address receiver,
    Tag tag,
    uint256 amount
  ) external override returns (
    bool success
  ) {
    _transfer(msg.sender, receiver, tag, amount);
    return true;
  }

  /// @inheritdoc INofeeswap
  function transferFrom(
    address sender,
    address receiver,
    Tag tag,
    uint256 amount
  ) external override returns (
    bool success
  ) {
    // Sender's allowance is modified.
    updateAllowance(sender, tag, amount);
    _transfer(sender, receiver, tag, amount);
    return true;
  }

  /// @inheritdoc INofeeswap
  function approve(
    address spender,
    Tag tag,
    uint256 amount
  ) external override returns (
    bool success
  ) {
    writeStorage(getAllowanceSlot(msg.sender, spender, tag), amount);
    emitApprovalEvent(msg.sender, spender, tag, amount);
    return true;
  }

  /// @inheritdoc INofeeswap
  function setOperator(
    address spender,
    bool approved
  ) external override returns (
    bool success
  ) {
    writeStorage(getIsOperatorSlot(msg.sender, spender), approved ? 1 : 0);
    emitOperatorSetEvent(msg.sender, spender, approved);
    return true;
  }

  /// @inheritdoc INofeeswap
  function modifyBalance(
    address owner,
    Tag tag,
    int256 amount
  ) external override {
    isProtocolUnlocked();

    if (amount >= 0) {
      // The casting is safe due to the prior check.
      incrementBalance(owner, tag, uint256(amount));
    } else {
      uint256 absoluteValue;
      // The subtraction is safe and leads to a positive value due to the
      // prior check.
      assembly {
        absoluteValue := sub(0, amount)
      }
      decrementBalance(owner, tag, absoluteValue);
    }

    updateTransientBalance(msg.sender, tag, amount);
  }

  /// @inheritdoc INofeeswap
  function modifyBalance(
    address owner,
    Tag tag0,
    Tag tag1,
    int256 amount0,
    int256 amount1
  ) external override {
    isProtocolUnlocked();

    require(tag1 > tag0, TagsOutOfOrder(tag0, tag1));

    uint256 slot = getDoubleBalanceSlot(owner, tag0, tag1);
    (uint256 amount0Current, uint256 amount1Current) = readDoubleBalance(slot);

    if (amount0 >= 0) {
      unchecked {
        // The addition is safe because 'amount0 < 2 ** 255' and 
        // 'amount0Current < 2 ** 128'.
        amount0Current += uint256(amount0);
      }
    } else {
      uint256 absoluteValue;
      // The subtraction is safe and leads to a positive value due to the
      // prior check.
      assembly {
        absoluteValue := sub(0, amount0)
      }
      updateAllowance(owner, tag0, absoluteValue);
      require(
        amount0Current >= absoluteValue,
        InsufficientBalance(owner, tag0)
      );
      unchecked {
        // The subtraction is safe due to the prior check.
        amount0Current -= absoluteValue;
      }
    }

    if (amount1 >= 0) {
      unchecked {
        // The addition is safe because 'amount1 < 2 ** 255' and 
        // 'amount1Current < 2 ** 128'.
        amount1Current += uint256(amount1);
      }
    } else {
      uint256 absoluteValue;
      // The subtraction is safe and leads to a positive value due to the
      // prior check.
      assembly {
        absoluteValue := sub(0, amount1)
      }
      updateAllowance(owner, tag1, absoluteValue);
      require(
        amount1Current >= absoluteValue,
        InsufficientBalance(owner, tag1)
      );
      unchecked {
        // The subtraction is safe due to the prior check.
        amount1Current -= absoluteValue;
      }
    }

    writeDoubleBalance(slot, amount0Current, amount1Current);

    updateTransientBalance(msg.sender, tag0, amount0);
    updateTransientBalance(msg.sender, tag1, amount1);

    if (amount0 != 0) {
      emitModifyDoubleBalanceEvent(
        msg.sender,
        owner,
        tag0,
        amount0,
        amount0Current
      );
    }
    if (amount1 != 0) {
      emitModifyDoubleBalanceEvent(
        msg.sender,
        owner,
        tag1,
        amount1,
        amount1Current
      );
    }
  }

  /// @inheritdoc INofeeswap
  function unlock(
    address unlockTarget,
    bytes calldata data
  ) external payable override returns (
    bytes memory result
  ) {
    unlockProtocol(unlockTarget, msg.sender);

    // The following lines invoke:
    //
    //    'IUnlockCallback(unlockTarget).unlockCallback(msg.sender, data)'
    //
    // To this end, the following bytes of calldata are written in memory:
    //
    //  0                                         4            36     68
    //  |                                         |            |      |
    //  +-----------------------------------------+------------+------+
    //  | IUnlockCallback.unlockCallback.selector | msg.sender | 0x40 |
    //  +-----------------------------------------+------------+------+
    //
    //  68        100
    //  |          |
    //  +----------+------+
    //  | dataSize | data |
    //  +----------+------+
    //
    bytes4 selector = IUnlockCallback.unlockCallback.selector;
    assembly {
      // The beginning of the calldata in memory to be sent to 'unlockTarget'.
      // 'IUnlockCallback.unlockCallback.selector'
      mstore(128, selector)

      // 'msg.sender' of this context is communicated to the next.
      mstore(132, caller())

      // ABI header for 'data'
      mstore(164, 0x40)

      // Pointer to the length slot of the array 'data' in calldata.
      let dataStart := add(calldataload(36), 4)

      // Byte count of the array 'data' in calldata.
      let dataByteCount := calldataload(dataStart)

      // The data array is read from 
      calldatacopy(196, dataStart, add(dataByteCount, 32))

      if iszero(
        call(
          gas(),
          // 'unlockTarget'
          calldataload(4),
          // The entirety of 'msg.value' is transferred to 'unlockTarget'.
          callvalue(),
          // The beginning of the calldata in memory to be sent to
          // 'unlockTarget'.
          128,
          // 100 == 4 'IUnlockCallback.unlockCallback.selector'
          //      + 32 'msg.sender'
          //      + 32 'header'
          //      + 32 'dataSize'
          add(dataByteCount, 100),
          // 'returndata' is later relayed to the prior context.
          0,
          0
        )
      ) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    require(readNonzeroAmounts() == 0, OutstandingAmount());

    lockProtocol();

    assembly {
      returndatacopy(0, 0, returndatasize())
      return(0, returndatasize())
    }
  }

  /// @inheritdoc INofeeswap
  function clear(
    Tag tag,
    uint256 amount
  ) external override {
    isProtocolUnlocked();
    int256 inputAmount = amount.toInt256();
    int256 balance = transientBalance(msg.sender, tag);
    unchecked {
      require(inputAmount + balance == 0, NotEqualToTransientBalance(balance));
    }
    updateTransientBalance(msg.sender, tag, inputAmount);
  }

  /// @inheritdoc INofeeswap
  function take(
    address token,
    address to,
    uint256 amount
  ) external override {
    isProtocolUnlocked();
    updateTransientBalance(msg.sender, token.tag(), amount.toInt256());
    token.transfer(to, amount);
  }

  /// @inheritdoc INofeeswap
  function take(
    address token,
    uint256 tokenId,
    address to,
    uint256 amount
  ) external override {
    isProtocolUnlocked();
    updateTransientBalance(msg.sender, token.tag(tokenId), amount.toInt256());
    token.transfer(tokenId, to, amount);
  }

  /// @inheritdoc INofeeswap
  function take(
    address token,
    uint256 tokenId,
    address to,
    uint256 amount,
    bytes calldata transferData
  ) external override {
    isProtocolUnlocked();
    updateTransientBalance(msg.sender, token.tag(tokenId), amount.toInt256());
    token.transfer(tokenId, to, amount, transferData);
  }

  /// @inheritdoc INofeeswap
  function sync(
    address token
  ) external override {
    writeReserveToken(token, false);
    writeReserveValue(token.balanceOfSelf());
  }

  /// @inheritdoc INofeeswap
  function sync(
    address token,
    uint256 tokenId
  ) external override {
    writeReserveToken(token, true);
    writeReserveTokenId(tokenId);
    writeReserveValue(token.balanceOfSelf(tokenId));
  }

  /// @inheritdoc INofeeswap
  function settle() external payable override returns (
    uint256 paid
  ) {
    isProtocolUnlocked();

    (
      address token,
      uint256 tokenId,
      uint256 syncedBalance,
      bool multiToken
    ) = readReserve();

    Tag tag;
    if (token == address(0)) {
      tag = native;
      paid = msg.value;
    } else {
      require(msg.value == 0, MsgValueIsNonZero(msg.value));
      uint256 currentBalance;
      (tag, currentBalance) = multiToken ? (
        token.tag(tokenId),
        token.balanceOfSelf(tokenId)
      ) : (
        token.tag(),
        token.balanceOfSelf()
      );
      paid = currentBalance - syncedBalance;
      writeReserveValue(currentBalance);
    }

    updateTransientBalance(msg.sender, tag, 0 - paid.toInt256());
  }

  /// @inheritdoc INofeeswap
  function transferTransientBalanceFrom(
    address sender,
    address receiver,
    Tag tag,
    uint256 amount
  ) external override {
    isProtocolUnlocked();

    // Sender's allowance is modified.
    updateAllowance(sender, tag, amount);

    int256 inputAmount = amount.toInt256();
    updateTransientBalance(sender, tag, inputAmount);
    unchecked {
      updateTransientBalance(receiver, tag, 0 - inputAmount);
    }
  }

  /// @inheritdoc INofeeswap
  function dispatch(
    bytes calldata input
  ) external override returns (
    int256 output0,
    int256 output1
  ) {
    address _delegatee = delegatee;
    assembly {
      // Pointer to the length slot of the array 'input' in calldata.
      let inputStart := add(calldataload(4), 4)

      // Byte count of the array 'input' in calldata.
      let inputByteCount := calldataload(inputStart)

      // Delegate call input is copied from calldata to memory.
      calldatacopy(128, add(inputStart, 32), inputByteCount)
      
      // A delegate call is made to 'NofeeswapDelegatee.sol'.
      // If reverted, the reason is relayed to the caller.
      if iszero(
        delegatecall(
          gas(),
          _delegatee,
          // The beginning of the calldata in memory to be sent to 'delegatee'.
          128,
          inputByteCount,
          // 64 bytes of return data are copied in scratch space to be
          // returned.
          0,
          64
        )
      ) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }

      // Output is relayed to the caller.
      return(0, 64)
    }
  }

  /// @inheritdoc INofeeswap
  function swap(
    uint256 poolId,
    int256 amountSpecified,
    X59 logPriceLimit,
    uint256 zeroForOne,
    bytes calldata hookData
  ) external override returns (
    int256 amount0,
    int256 amount1
  ) {
    require(address(this) == nofeeswap, NoDelegateCall(address(this)));

    isProtocolUnlocked();

    // Reads input parameters from calldata and sets them in appropriate memory
    // locations.
    readSwapInput();

    // Pre swap hook is invoked next.
    if (isPreSwap()) invokePreSwap();

    // Safeguard against reentrancy.
    uint256 poolLockSlot = getPoolLockSlot();
    lockPool(poolLockSlot);
    
    // Dynamic parameters, static parameters, kernel, and curve are read next.
    readPoolData();

    // If there is a nonzero growth portion, then accrued parameters should be
    // read from storage as well.
    if (isGrowthPortion()) readAccruedParams();

    // Swap parameters are calculated and set in memory.
    setSwapParams();

    // Mid swap hook is invoked next.
    if (isMidSwap()) invokeMidSwap();

    // In this case, we can return without swapping.
    if (
      (getLogPriceLimitOffsetted() == getLogPriceCurrent())
       ||
      (getAmountSpecified() == zeroX127)
    ) {
      unlockPool(poolLockSlot);
      return (0, 0);
    }

    bool transitioned;
    while (true) {
      // Once we reach the end of the current interval, we transition.
      if (getLogPriceCurrent() == _next_.log()) {
        // If there is pending kernel, then the kernel should be updated along
        // with other static parameters.
        if (getPendingKernelLength() != zeroIndex) updateKernel();

        // If not yet transitioned, we need to read the two growth ratios for
        // the first time.
        if (!transitioned) {
          setBackGrowthMultiplier(readGrowthMultiplier(
            getGrowthMultiplierSlot(getPoolId(), _back_.log())
          ));
          setNextGrowthMultiplier(readGrowthMultiplier(
            getGrowthMultiplierSlot(getPoolId(), _next_.log())
          ));
        }

        // Transition and modify the 'transitioned' flag accordingly.
        transition();
        transitioned = true;
      }

      // If the swap is large enough and we are at the beginning of an interval,
      // then we need to cross. Otherwise we swap within the current interval.
      if (
        (getLogPriceCurrent() != _back_.log())
          || 
        (getIntegralLimit() < getIntegralLimitInterval())
          ||
        (getZeroForOne() != (getLogPriceLimitOffsetted() <= _next_.log()))
      ) {
        if (swapWithin()) break;
      } else {
        if (cross()) break;
      }

      // Once either of the following limits are met, the loop is broken.
      if (getLogPriceCurrent() == getLogPriceLimitOffsetted()) break;
      if (getAmountSpecified() == zeroX127) break;
    }

    // Dynamic parameters, accrued growth portions and the curve are written on
    // storage.
    writeDynamicParams();
    if (isGrowthPortion()) writeAccruedParams();
    writeCurve();

    // The two amounts are cast as integers.
    amount0 = getAmount0().toIntegerRoundUp();
    amount1 = getAmount1().toIntegerRoundUp();

    // Transient balances are updated accordingly.
    updateTransientBalance(msg.sender, getTag0(), amount0);
    updateTransientBalance(msg.sender, getTag1(), amount1);

    // The lock is cleared to open the pool for other actions.
    unlockPool(poolLockSlot);

    // An event is emitted.
    emitSwapEvent();

    // Post swap hook is invoked next.
    if (isPostSwap()) invokePostSwap();
  }

  /// @notice See ERC1155TokenReceiver specifications.
  function onERC1155Received(
    address ,
    address ,
    uint256 ,
    uint256 ,
    bytes calldata
  ) external pure returns (bytes4) {
    return IERC1155Receiver.onERC1155Received.selector;
  }

  /// @notice See ERC1155TokenReceiver specifications.
  function onERC1155BatchReceived(
    address ,
    address ,
    uint256[] calldata ,
    uint256[] calldata ,
    bytes calldata
  ) external pure returns (bytes4) {
    return IERC1155Receiver.onERC1155BatchReceived.selector;
  }

  function _transfer(
    address sender,
    address receiver,
    Tag tag,
    uint256 amount
  ) private {
    require(receiver != address(0), CannotTransferToAddressZero());

    // Sender's balance slot is modified.
    uint256 slot = getSingleBalanceSlot(sender, tag);
    uint256 balance = readStorage(slot);
    require(balance >= amount, InsufficientBalance(sender, tag));
    unchecked {
      // The subtraction is safe due to the prior check.
      writeStorage(slot, balance - amount);
    }

    // Receiver's balance slot is modified.
    slot = getSingleBalanceSlot(receiver, tag);
    balance = readStorage(slot);
    unchecked {
      require(
        // The subtraction is safe because 
        // 'amount <= balance <= type(uint128).max'.
        balance <= type(uint128).max - amount,
        BalanceOverflow(balance + amount)
      );
      // The addition is safe and does not exceed 128-bits because of the
      // prior check.
      writeStorage(slot, balance + amount);
    }

    emitTransferEvent(msg.sender, sender, receiver, tag, amount);
  }
}