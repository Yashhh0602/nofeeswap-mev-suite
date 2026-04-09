// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {TransientAccess} from "@core/TransientAccess.sol";
import {IUnlockCallback} from "@core/callback/IUnlockCallback.sol";
import {doubleBalanceSlot} from "@core/utilities/Storage.sol";
import {transientBalanceSlot} from "@core/utilities/Transient.sol";
import {IOperator} from "./interfaces/IOperator.sol";

// bytes4(keccak256('SafeMathError()'));
bytes4 constant SafeMathErrorSelector = 0xf87815b3;

// bytes4(keccak256('InvalidJumpDestination()'));
bytes4 constant InvalidJumpDestinationSelector = 0x5b7ccd90;

// bytes4(keccak256('transientAccess(bytes32)'));
bytes4 constant transientAccessSelector = 0x834178fe;

// bytes4(keccak256('balanceOf(address)'));
bytes4 constant balanceOfERC20Selector = 0x70a08231;

// bytes4(keccak256('balanceOf(address,uint256)'));
bytes4 constant balanceOfMultiTokenSelector = 0x00fdd58e;

// bytes4(keccak256('allowance(address,address)'));
bytes4 constant allowanceERC20Selector = 0xdd62ed3e;

// bytes4(keccak256('allowance(address,address,address)'));
bytes4 constant allowancePermit2Selector = 0x927da105;

// bytes4(keccak256('allowance(address,uint256,uint256)'));
bytes4 constant allowanceERC6909Selector = 0x598af9e7;

// bytes4(keccak256('isOperator(address,address)'));
bytes4 constant isOperatorERC6909Selector = 0xb6363cf2;

// bytes4(keccak256('isApprovedForAll(address,address)'));
bytes4 constant isApprovedForAllERC1155Selector = 0xe985e9c5;

// bytes4(keccak256('storageAccess(bytes32)'));
bytes4 constant storageAccessSelector = 0x1352ea35;

// bytes4(keccak256('deposit()'));
bytes4 constant depositSelector = 0xd0e30db0;

// bytes4(keccak256('withdraw(uint256)'));
bytes4 constant withdrawSelector = 0x2e1a7d4d;

// bytes4(keccak256('
//    permit(address,((address,uint160,uint48,uint48),address,uint256),bytes)
// '));
bytes4 constant permitSelector = 0x2b67b570;

// bytes4(keccak256('
//    permit(address,((address,uint160,uint48,uint48)[],address,uint256),bytes)
// '));
bytes4 constant permitBatchSelector = 0x2a2d80d1;

// bytes4(keccak256('transferFrom(address,address,uint256)'));
bytes4 constant transferFromERC20Selector = 0x23b872dd;

// bytes4(keccak256('transferFrom(address,address,uint160,address)'));
bytes4 constant transferFromPermit2Selector = 0x36c78516;

// bytes4(keccak256('transferFrom(address,address,uint256,uint256)'));
bytes4 constant transferFromERC6909Selector = 0xfe99049a;

// bytes4(keccak256(
//    'safeTransferFrom(address,address,uint256,uint256,bytes)'
// ));
bytes4 constant safeTransferFromERC1155Selector = 0xf242432a;

// bytes4(keccak256('clear(uint256,uint256)'));
bytes4 constant clearSelector = 0x41ee903e;

// bytes4(keccak256('take(address,address,uint256)'));
bytes4 constant takeTokenSelector = 0x0b0d9c09;

// bytes4(keccak256('take(address,uint256,address,uint256)'));
bytes4 constant takeERC6909Selector = 0x0720b584;

// bytes4(keccak256('take(address,uint256,address,uint256,bytes)'));
bytes4 constant takeERC1155Selector = 0x2b7f670f;

// bytes4(keccak256('sync(address)'));
bytes4 constant syncTokenSelector = 0xa5841194;

// bytes4(keccak256('sync(address,uint256)'));
bytes4 constant syncMultiTokenSelector = 0xef4fcafa;

// bytes4(keccak256('settle()'));
bytes4 constant settleSelector = 0x11da60b4;

// bytes4(keccak256(
//   'transferTransientBalanceFrom(address,address,uint256,uint256)'
// ));
bytes4 constant transferTransientBalanceFromSelector = 0xda954559;

// bytes4(keccak256('modifyBalance(address,uint256,int256)'));
bytes4 constant modifySingleBalanceSelector = 0xbea556c9;

// bytes4(keccak256('modifyBalance(address,uint256,uint256,int256,int256)'));
bytes4 constant modifyDoubleBalanceSelector = 0x49dff3ab;

// bytes4(keccak256('swap(uint256,int256,int256,uint256,bytes)'));
bytes4 constant swapSelector = 0x32269698;

// bytes4(keccak256('dispatch(bytes)'));
bytes4 constant dispatchSelector = 0xab7fff18;

// bytes4(keccak256(
//   'modifyPosition(uint256,int256,int256,address,int256,bytes)'
// ));
bytes4 constant modifyPositionSelector = 0x0e42e0c4;

// bytes4(keccak256('donate(uint256,uint256,bytes)'));
bytes4 constant donateSelector = 0x62fc9e53;

// bytes4(keccak256('quoteModifyPosition(uint256,int256,int256,uint256)'));
bytes4 constant quoteModifyPositionSelector = 0x8d847de5;

// bytes4(keccak256('quoteDonate(uint256,uint256)'));
bytes4 constant quoteDonateSelector = 0x06625fb5;

/// @title This contract can unlock Nofeeswap protocol to perform a sequence of
/// actions.
contract Operator is IOperator, IUnlockCallback, TransientAccess {
  /// @notice Thrown when attempting to execute a call whose deadline is
  /// passed.
  error DeadlinePassed();

  /// @notice Thrown when attempting to access functionalities that are only
  /// available to Nofeeswap contract.
  error OnlyByNofeeswap(address attemptingAddress);

  address public immutable override nofeeswap;
  address public immutable override permit2;
  address public immutable override weth9;
  address public immutable override quoter;

  constructor(
    address _nofeeswap,
    address _permit2,
    address _weth9,
    address _quoter
  ) {
    nofeeswap = _nofeeswap;
    permit2 = _permit2;
    weth9 = _weth9;
    quoter = _quoter;
  }

  modifier onlyByNofeeswap() {
    require(msg.sender == nofeeswap, OnlyByNofeeswap(msg.sender));
    _;
  }

  /// @inheritdoc IUnlockCallback
  function unlockCallback(
    address caller,
    bytes calldata data
  ) external payable onlyByNofeeswap returns (
    bytes memory returnData
  ) {
    // calldata layout for 'unlockCallback' is as follows:
    //
    // unlockCallbackSelector     - from byte 0 (4 bytes)
    // payer                      - from byte 4 (32 bytes)
    // '0x40' header              - from byte 36 (32 bytes)
    // dataByteCount              - from byte 68 (32 bytes)
    // deadline                   - from byte 100 (4 bytes)
    // action[0]
    // action[1]
    // action[2]
    // ...

    // 'payer' and the deadline are read from calldata.
    address _payer_;
    uint256 endOfData;
    uint256 deadline;
    assembly {
      _payer_ := calldataload(4)
      endOfData := add(100, calldataload(68))
      deadline := shr(224, calldataload(100))
    }

    // The deadline is checked here.
    require(block.timestamp <= deadline, DeadlinePassed());

    // The address of the 'permit2' contract.
    address _permit2_ = permit2;

    // The address of the 'weth9' contract.
    address _weth9_ = weth9;

    // The address of the 'universalQuoter' contract.
    address _quoter_ = quoter;

    // A loop over all of the actions.
    uint256 _pointer_ = 104;
    while (_pointer_ < endOfData) {
      // The following module defines a number of functions and takes
      // advantage of inline assembly's 'switch - case' to run the actions
      // efficiently.
      assembly {
        function _load(length, pointer) -> value, nextPointer {
          value := shr(sub(256, shl(3, length)), calldataload(pointer))
          nextPointer := add(length, pointer)
        }

        function _load32(pointer) -> value, nextPointer {
          value := calldataload(pointer)
          nextPointer := add(32, pointer)
        }

        function _copy(destination, pointer, length) -> nextPointer {
          calldatacopy(destination, pointer, length)
          nextPointer := add(length, pointer)
        }

        function _decode2(length1, content) -> value0, value1 {
          value1 := and(sub(shl(shl(3, length1), 1), 1), content)
          value0 := shr(shl(3, length1), content)
        }

        function _decode3(
          length1,
          length2,
          content
        ) -> value0, value1, value2 {
          value2 := and(sub(shl(shl(3, length2), 1), 1), content)
          content := shr(shl(3, length2), content)
          value1 := and(sub(shl(shl(3, length1), 1), 1), content)
          value0 := shr(shl(3, length1), content)
        }

        function _verifyUnsigned(amountSlot) -> amount {
          amount := tload(amountSlot)
          if slt(amount, 0) {
            _safeMathRevert()
          }
        }

        function _safeMathRevert() {
          mstore(0, SafeMathErrorSelector)
          revert(0, 4)
        }

        function _jumpDestinationRevert() {
          mstore(0, InvalidJumpDestinationSelector)
          revert(0, 4)
        }

        function _removeOffset(limitOffsetted, poolId) -> limit {
          limit := add(
            sub(limitOffsetted, shl(63, 1)),
            mul(shl(59, 1), signextend(0, shr(180, poolId)))
          )
        }
        
        // abi.encodePacked(Action.PUSH0, uint8(valueSlot))
        function _push0(pointer) -> nextPointer {
          let valueSlot
          valueSlot, nextPointer := _load(1, pointer)
          tstore(valueSlot, 0)
        }

        // abi.encodePacked(
        //    Action Action.PUSH10,
        //    int80 value,
        //    uint8 valueSlot
        // )
        function _push10(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(11, pointer)
          let value, valueSlot := _decode2(1, content)
          tstore(valueSlot, signextend(9, value))
        }

        // abi.encodePacked(
        //    Action Action.PUSH16,
        //    int128 value,
        //    uint8 valueSlot
        // )
        function _push16(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(17, pointer)
          let value, valueSlot := _decode2(1, content)
          tstore(valueSlot, signextend(15, value))
        }

        // abi.encodePacked(
        //    Action Action.PUSH32,
        //    int256 value,
        //    uint8 valueSlot
        // )
        function _push32(pointer) -> nextPointer {
          let value, valueSlot
          value, nextPointer := _load32(pointer)
          valueSlot, nextPointer := _load(1, nextPointer)
          tstore(valueSlot, value)
        }

        // abi.encodePacked(
        //    Action Action.NEG,
        //    uint8 valueSlot,
        //    uint8 resultSlot
        // )
        function _neg(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(2, pointer)
          let valueSlot, resultSlot := _decode2(1, content)
          let value := tload(valueSlot)

          // Reverted if 'value == type(int256).min' which cannot be negated.
          if eq(value, shl(255, 1)) {
            _safeMathRevert()
          }
          tstore(resultSlot, sub(0, value))
        }

        // abi.encodePacked(
        //    Action Action.ADD,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _add(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)
          let value0 := tload(value0Slot)
          let value1 := tload(value1Slot)
          let result := add(value0, value1)

          // The following requirement is satisfied if and only if 'result'
          // does not overflow or underflow. Because,
          // - overflow implies that both 'value0' and 'value1' are positive
          //   but 'result' is negative which contradicts the following
          //   requirement.
          // - underflow implies that both 'value0' and 'value1' are negative
          //   but 'result' is positive which contradicts the following
          //   requirement as well.
          // - Lastly, in case of no overflow/underflow, the following
          //   requirement is trivial.
          if iszero(eq(slt(value1, 0), slt(result, value0))) {
            _safeMathRevert()
          }
          tstore(resultSlot, result)
        }

        // abi.encodePacked(
        //    Action Action.SUB,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _sub(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)
          let value0 := tload(value0Slot)
          let value1 := tload(value1Slot)
          let result := sub(value0, value1)

          // The following requirement is satisfied if and only if 'result'
          // does not overflow or underflow. Because,
          // - overflow implies that both 'value0' and '0 - value1' are
          //   positive but 'result' is negative which contradicts the
          //   following requirement.
          // - underflow implies that both 'value0' and '0 - value1' are
          //   negative but 'result' is positive which contradicts the
          //   following requirement as well.
          // - Lastly, in case of no overflow/underflow, the following
          //   requirement is trivial.
          if iszero(eq(sgt(value1, 0), slt(result, value0))) {
            _safeMathRevert()
          }
          tstore(resultSlot, result)
        }

        // abi.encodePacked(
        //    Action Action.MIN,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _min(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)
          let value0 := tload(value0Slot)
          let value1 := tload(value1Slot)

          tstore(
            resultSlot,
            add(value0, mul(slt(value1, value0), sub(value1, value0)))
          )
        }

        // abi.encodePacked(
        //    Action Action.MAX,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _max(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)
          let value0 := tload(value0Slot)
          let value1 := tload(value1Slot)

          tstore(
            resultSlot,
            add(value0, mul(sgt(value1, value0), sub(value1, value0)))
          )
        }

        // abi.encodePacked(
        //    Action Action.MUL,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _mul(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)
          let value0 := tload(value0Slot)
          let value1 := tload(value1Slot)
          let result := mul(value0, value1)

          if gt(value0, 0) {
            if iszero(eq(sdiv(result, value0), value1)) {
              _safeMathRevert()
            }
          }
          tstore(resultSlot, result)
        }

        function _safeDivision(value0, value1) {
          if iszero(value1) {
            _safeMathRevert()
          }
          if eq(value0, shl(255, 1)) {
            if eq(value1, not(0)) {
              _safeMathRevert()
            }
          }
        }

        // abi.encodePacked(
        //    Action Action.DIV,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _div(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)
          let value0 := tload(value0Slot)
          let value1 := tload(value1Slot)

          _safeDivision(value0, value1)
          tstore(resultSlot, sdiv(value0, value1))
        }

        // abi.encodePacked(
        //    Action Action.DIV_ROUND_DOWN,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _divRoundDown(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)
          let value0 := tload(value0Slot)
          let value1 := tload(value1Slot)

          _safeDivision(value0, value1)
          tstore(
            resultSlot,
            sub(
              sdiv(value0, value1),
              and(
                eq(slt(value0, 0), sgt(value1, 0)),
                gt(smod(value0, value1), 0)
              )
            )
          )
        }

        // abi.encodePacked(
        //    Action Action.DIV_ROUND_UP,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _divRoundUp(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)
          let value0 := tload(value0Slot)
          let value1 := tload(value1Slot)

          _safeDivision(value0, value1)
          tstore(
            resultSlot,
            add(
              sdiv(value0, value1),
              and(
                eq(slt(value0, 0), slt(value1, 0)),
                gt(smod(value0, value1), 0)
              )
            )
          )
        }

        // abi.encodePacked(
        //    Action Action.LT,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _lt(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)

          tstore(resultSlot, slt(tload(value0Slot), tload(value1Slot)))
        }

        // abi.encodePacked(
        //    Action Action.EQ,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _eq(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)

          tstore(resultSlot, eq(tload(value0Slot), tload(value1Slot)))
        }

        // abi.encodePacked(
        //    Action Action.LTEQ,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _lteq(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)

          tstore(resultSlot, iszero(sgt(tload(value0Slot), tload(value1Slot))))
        }

        // abi.encodePacked(
        //    Action Action.ISZERO,
        //    uint8 valueSlot,
        //    uint8 resultSlot
        // )
        function _iszero(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(2, pointer)
          let valueSlot, resultSlot := _decode2(1, content)

          tstore(resultSlot, iszero(tload(valueSlot)))
        }

        // abi.encodePacked(
        //    Action Action.AND,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _and(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)

          tstore(resultSlot, and(tload(value0Slot), tload(value1Slot)))
        }

        // abi.encodePacked(
        //    Action Action.OR,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _or(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)

          tstore(resultSlot, or(tload(value0Slot), tload(value1Slot)))
        }

        // abi.encodePacked(
        //    Action Action.XOR,
        //    uint8 value0Slot,
        //    uint8 value1Slot,
        //    uint8 resultSlot
        // )
        function _xor(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let value0Slot, value1Slot, resultSlot := _decode3(1, 1, content)

          tstore(resultSlot, xor(tload(value0Slot), tload(value1Slot)))
        }

        // abi.encodePacked(
        //    Action Action.JUMP,
        //    uint16 destination
        //    uint8 conditionSlot
        // )
        function _jump(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let destination, conditionSlot := _decode2(1, content)
          if tload(conditionSlot) {
            destination := add(104, destination)
            if iszero(eq(shr(248, calldataload(destination)), 20)) {
              _jumpDestinationRevert()
            }
            nextPointer := destination
          }
        }

        // abi.encodePacked(
        //    Action Action.READ_TRANSIENT_BALANCE,
        //    Tag tag,
        //    address owner,
        //    uint8 resultSlot
        // )
        function _readTransientBalance(pointer) -> nextPointer {
          let tag
          tag, nextPointer := _load32(pointer)
          let content
          content, nextPointer := _load(21, nextPointer)
          let owner, resultSlot := _decode2(1, content)

          // We populate the first two memory slots from right to left:
          //
          //  0                           32          52                     64
          //  |                           |           |                      |
          //  +---------------------------+-----------+----------------------+
          //  |            tag            |   owner   | transientBalanceSlot |
          //  +---------------------------+-----------+----------------------+
          //

          // Populates the least significant 12 bytes of the memory slot 1
          // (from 52 to 64).
          mstore(32, transientBalanceSlot) // 32 = 62 - 32

          // Populates the most significant 20 bytes of the memory slot 1 (from
          // 32 to 52).
          mstore(20, owner) // 20 = 52 - 32

          // Populates the entire memory slot 0.
          mstore(0, tag) // 0 = 32 - 32

          // Calculates the resulting hash.
          let transientSlot := keccak256(0, 64)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).transientAccess(transientSlot)'
          //
          // To this end, the following 36 bytes of calldata are written in
          // memory.
          //
          //    0                         4               36
          //    |                         |               |
          //    +-------------------------+---------------+
          //    | transientAccessSelector | transientSlot |
          //    +-------------------------+---------------+
          //
          mstore(0, transientAccessSelector)
          mstore(4, transientSlot)
          pop(call(gas(), caller(), 0, 0, 36, 0, 32))
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.READ_BALANCE_OF_NATIVE,
        //    address owner,
        //    uint8 resultSlot
        // )
        function _readBalanceOfNative(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(21, pointer)
          let owner, resultSlot := _decode2(1, content)

          switch eq(owner, address())
          case 0 {
            tstore(resultSlot, balance(owner))
          }
          case 1 {
            tstore(resultSlot, selfbalance())
          }
        }

        // abi.encodePacked(
        //    Action Action.READ_BALANCE_OF_ERC20,
        //    address token,
        //    address owner,
        //    uint8 successSlot,
        //    uint8 resultSlot
        // )
        function _readBalanceOfERC20(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let owner, successSlot, resultSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'IERC20(token).balanceOf(owner)'
          //
          // To this end, the following 36 bytes of calldata are written in
          // memory.
          //
          //    0                        4       36
          //    |                        |       |
          //    +------------------------+-------+
          //    | balanceOfERC20Selector | owner |
          //    +------------------------+-------+
          //
          mstore(0, balanceOfERC20Selector)
          mstore(4, owner)
          tstore(successSlot, call(gas(), token, 0, 0, 36, 0, 32))
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.READ_BALANCE_OF_MULTITOKEN,
        //    address token,
        //    uint256 id,
        //    address owner,
        //    uint8 successSlot,
        //    uint8 resultSlot
        // )
        function _readBalanceOfMultiToken(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let id
          id, nextPointer := _load32(nextPointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let owner, successSlot, resultSlot := _decode3(1, 1, content)

          // The following lines invoke either of:
          //
          //    'IERC6909(token).balanceOf(owner, id)'
          //    'IERC1155(token).balanceOf(owner, id)'
          //
          // To this end, the following 68 bytes of calldata are written in
          // memory.
          //
          //   128                           132     164  196
          //    |                             |       |    |
          //    +-----------------------------+-------+----+
          //    | balanceOfMultiTokenSelector | owner | id |
          //    +-----------------------------+-------+----+
          //
          mstore(128, balanceOfMultiTokenSelector)
          mstore(132, owner)
          mstore(164, id)
          tstore(successSlot, call(gas(), token, 0, 128, sub(196, 128), 0, 32))
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.READ_ALLOWANCE_ERC20,
        //    address token,
        //    address owner,
        //    address spender,
        //    uint8 successSlot,
        //    uint8 resultSlot
        // )
        function _readAllowanceERC20(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let owner
          owner, nextPointer := _load(20, nextPointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let spender, successSlot, resultSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'IERC20(token).allowance(owner, spender)'
          //
          // To this end, the following 68 bytes of calldata are written in
          // memory.
          //
          //   128                      132     164       196
          //    |                        |       |         |
          //    +------------------------+-------+---------+
          //    | allowanceERC20Selector | owner | spender |
          //    +------------------------+-------+---------+
          //
          mstore(128, allowanceERC20Selector)
          mstore(132, owner)
          mstore(164, spender)
          tstore(successSlot, call(gas(), token, 0, 128, sub(196, 128), 0, 32))
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.READ_ALLOWANCE_PERMIT2,
        //    address token,
        //    address owner,
        //    address spender,
        //    uint8 resultSlot
        // )
        function _readAllowancePermit2(_permit2, pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let owner
          owner, nextPointer := _load(20, nextPointer)
          let content
          content, nextPointer := _load(21, nextPointer)
          let spender, resultSlot := _decode2(1, content)

          // The following lines invoke:
          //
          //    'IPermit2(permit2).allowance(owner, token, spender)'
          //
          // To this end, the following 100 bytes of calldata are written in
          // memory.
          //
          //   128                        132     164     196       228
          //    |                          |       |       |         |
          //    +--------------------------+-------+-------+---------+
          //    | allowancePermit2Selector | owner | token | spender |
          //    +--------------------------+-------+-------+---------+
          //
          mstore(128, allowancePermit2Selector)
          mstore(132, owner)
          mstore(164, token)
          mstore(196, spender)
          pop(call(gas(), _permit2, 0, 128, sub(228, 128), 0, 32))
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.READ_ALLOWANCE_ERC6909,
        //    address token,
        //    uint256 id,
        //    address owner,
        //    address spender,
        //    uint8 successSlot,
        //    uint8 resultSlot
        // )
        function _readAllowanceERC6909(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let id
          id, nextPointer := _load(32, nextPointer)
          let owner
          owner, nextPointer := _load(20, nextPointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let spender, successSlot, resultSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'IERC6909(token).allowance(owner, spender, id)'
          //
          // To this end, the following 100 bytes of calldata are written in
          // memory.
          //
          //   128                        132     164       196  228
          //    |                          |       |         |    |
          //    +--------------------------+-------+---------+----+
          //    | allowanceERC6909Selector | owner | spender | id |
          //    +--------------------------+-------+---------+----+
          //
          mstore(128, allowanceERC6909Selector)
          mstore(132, owner)
          mstore(164, spender)
          mstore(196, id)
          tstore(successSlot, call(gas(), token, 0, 128, sub(228, 128), 0, 32))
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.READ_IS_OPERATOR_ERC6909,
        //    address token,
        //    address owner,
        //    address spender,
        //    uint8 successSlot,
        //    uint8 resultSlot
        // )
        function _readIsOperatorERC6909(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let owner
          owner, nextPointer := _load(20, nextPointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let spender, successSlot, resultSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'IERC6909(token).isOperator(owner, spender)'
          //
          // To this end, the following 68 bytes of calldata are written in
          // memory.
          //
          //   128                         132     164       196
          //    |                           |       |         |
          //    +---------------------------+-------+---------+
          //    | isOperatorERC6909Selector | owner | spender |
          //    +---------------------------+-------+---------+
          //
          mstore(128, isOperatorERC6909Selector)
          mstore(132, owner)
          mstore(164, spender)
          tstore(successSlot, call(gas(), token, 0, 128, sub(196, 128), 0, 32))
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.READ_IS_APPROVED_FOR_ALL_ERC1155,
        //    address token,
        //    address owner,
        //    address spender,
        //    uint8 successSlot,
        //    uint8 resultSlot
        // )
        function _readIsApprovedForAllERC1155(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let owner
          owner, nextPointer := _load(20, nextPointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let spender, successSlot, resultSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'IERC1155(token).isApprovedForAll(owner, spender)'
          //
          // To this end, the following 68 bytes of calldata are written in
          // memory.
          //
          //   128                               132     164       196
          //    |                                 |       |         |
          //    +---------------------------------+-------+---------+
          //    | isApprovedForAllERC1155Selector | owner | spender |
          //    +---------------------------------+-------+---------+
          //
          mstore(128, isApprovedForAllERC1155Selector)
          mstore(132, owner)
          mstore(164, spender)
          tstore(successSlot, call(gas(), token, 0, 128, sub(196, 128), 0, 32))
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.READ_DOUBLE_BALANCE,
        //    Tag tag0,
        //    Tag tag1,
        //    address owner,
        //    uint8 value0Slot,
        //    uint8 value1Slot
        // )
        function _readDoubleBalance(pointer) -> nextPointer {
          let tag0
          tag0, nextPointer := _load(32, pointer)
          let tag1
          tag1, nextPointer := _load(32, nextPointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let owner, value0Slot, value1Slot := _decode3(1, 1, content)

          // We populate the first three memory slots from right to left:
          //
          // 128          160          192           212                 224
          //  |            |            |             |                   |
          //  +------------+------------+-------------+-------------------+
          //  |    tag0    |    tag1    |    owner    | doubleBalanceSlot |
          //  +------------+------------+-------------+-------------------+
          //
          mstore(192, doubleBalanceSlot) // 192 = 224 - 32
          mstore(180, owner) // 180 = 212 - 32
          mstore(160, tag1) // 160 = 192 - 32
          mstore(128, tag0) // 128 = 160 - 32

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).storageAccess(storageSlot)'
          //
          // To this end, the following 36 bytes of calldata are written in
          // memory.
          //
          //    0                       4             36
          //    |                       |             |
          //    +-----------------------+-------------+
          //    | storageAccessSelector | storageSlot |
          //    +-----------------------+-------------+
          //
          mstore(0, storageAccessSelector)
          mstore(4, keccak256(128, 96))
          pop(call(gas(), caller(), 0, 0, 36, 0, 32))
          let doubleBalance := mload(0)
          tstore(value0Slot, and(doubleBalance, sub(shl(128, 1), 1)))
          tstore(value1Slot, shr(128, doubleBalance))
        }

        // abi.encodePacked(
        //    Action Action.WRAP_NATIVE,
        //    uint8 valueSlot,
        //    uint8 successSlot
        // )
        function _wrapNative(_weth9, pointer) -> nextPointer {
          let content
          content, nextPointer := _load(2, pointer)
          let valueSlot, successSlot := _decode2(1, content)

          // The following lines invoke:
          //
          //    'IWETH9(weth9){value: value}.deposit()'
          //
          // To this end, the following 4 bytes of calldata are written in
          // memory.
          //
          //    0                 4
          //    |                 |
          //    +-----------------+
          //    | depositSelector |
          //    +-----------------+
          //
          mstore(0, depositSelector)
          tstore(
            successSlot,
            call(gas(), _weth9, _verifyUnsigned(valueSlot), 0, 4, 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.UNWRAP_NATIVE,
        //    uint8 amountSlot,
        //    uint8 successSlot
        // )
        function _unwrapNative(_weth9, pointer) -> nextPointer {
          let content
          content, nextPointer := _load(2, pointer)
          let amountSlot, successSlot := _decode2(1, content)

          // The following lines invoke:
          //
          //    'IWETH9(weth9).withdraw(amount)'
          //
          // To this end, the following 36 bytes of calldata are written in
          // memory.
          //
          //    0                  4        36
          //    |                  |        |
          //    +------------------+--------+
          //    | withdrawSelector | amount |
          //    +------------------+--------+
          //
          mstore(0, withdrawSelector)
          mstore(4, _verifyUnsigned(amountSlot))
          tstore(successSlot, call(gas(), _weth9, 0, 0, 36, 0, 0))
        }

        // abi.encodePacked(
        //    Action Action.PERMIT_PERMIT2,
        //    address owner,
        //    uint48 nonce,
        //    uint8 amountSlot,
        //    address token,
        //    uint48 expiration,
        //    uint48 signatureDeadline,
        //    address spender,
        //    uint8 successSlot,
        //    uint8 signatureByteCount,
        //    bytes signature
        // )
        function _permitPermit2(_permit2, pointer) -> nextPointer {
          // The following lines invoke:
          //
          //    'IPermit2(permit2).permit(
          //        owner,
          //        IPermit2.PermitSingle({
          //          details: IPermit2.PermitDetails({
          //            token: token,
          //            amount: amount,
          //            expiration: expiration,
          //            nonce: nonce
          //          }),
          //          spender: spender,
          //          sigDeadline: uint256(signatureDeadline)
          //        }),
          //        signature
          //     )'
          //
          // To this end, the following bytes of calldata are written in
          // memory.
          //
          // 128              132     164     196      228          260     292
          //  |                |       |       |        |            |       |
          //  +----------------+-------+-------+--------+------------+-------+
          //  | permitSelector | owner | token | amount | expiration | nonce |
          //  +----------------+-------+-------+--------+------------+-------+
          //
          // 292       324                 356     388                  420
          //  |         |                   |       |                    |
          //  +---------+-------------------+-------+--------------------+
          //  | spender | signatureDeadline | 0x100 | signatureByteCount |
          //  +---------+-------------------+-------+--------------------+
          //
          // 420
          //  |
          //  +-----------+
          //  | signature |
          //  +-----------+
          //
          mstore(128, permitSelector)
          mstore(356, 0x100)

          let content
          {
            content, nextPointer := _load(27, pointer)
            let owner, nonce, amountSlot := _decode3(6, 1, content)
            let amount := tload(amountSlot)
            if gt(amount, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
              _safeMathRevert()
            }
            mstore(132, owner)
            mstore(196, amount)
            mstore(260, nonce)
          }

          {
            content, nextPointer := _load32(nextPointer)
            let token, expiration, signatureDeadline := _decode3(6, 6, content)
            mstore(164, token)
            mstore(228, expiration)
            mstore(324, signatureDeadline)
          }

          {
            content, nextPointer := _load(22, nextPointer)
            let spender, successSlot, signatureByteCount := 
              _decode3(1, 1, content)
            mstore(292, spender)
            mstore(388, signatureByteCount)
            nextPointer := _copy(420, nextPointer, signatureByteCount)
            tstore(
              successSlot,
              call(
                gas(),
                _permit2,
                0,
                128,
                add(sub(420, 128), signatureByteCount),
                0,
                0
              )
            )
          }
        }

        // abi.encodePacked(
        //    Action Action.PERMIT_BATCH_PERMIT2,
        //    address owner,
        //    uint48 signatureDeadline,
        //    uint8 signatureByteCount,
        //    address spender,
        //    uint8 successSlot,
        //    uint8 numberOfPermissions,
        //    abi.encodePacked(
        //      abi.encodePacked(
        //        address token[0],
        //        uint8 amountSlot[0],
        //        uint40 expiration[0],
        //        uint48 nonce[0]
        //      ),
        //      abi.encodePacked(
        //        address token[0],
        //        uint8 amountSlot[0],
        //        uint40 expiration[0],
        //        uint48 nonce[0]
        //      ),
        //
        //      .
        //      .
        //      .
        //
        //      abi.encodePacked(
        //        address token[numberOfPermissions - 1],
        //        uint8 amountSlot[numberOfPermissions - 1],
        //        uint40 expiration[numberOfPermissions - 1],
        //        uint48 nonce[numberOfPermissions - 1]
        //      ),
        //    ),
        //    bytes signature
        // )
        function _permitBatchPermit2(_permit2, pointer) -> nextPointer {
          // The following lines invoke:
          //
          //    'IPermit2(permit2).permit(
          //        owner,
          //        IPermit2.PermitBatch({
          //          details: [
          //            IPermit2.PermitDetails({
          //              token: token[0],
          //              amount: amount[0],
          //              expiration: uint48(expiration[0]),
          //              nonce: nonce[0]
          //            }),
          //            IPermit2.PermitDetails({
          //              token: token[1],
          //              amount: amount[1],
          //              expiration: uint48(expiration[1]),
          //              nonce: nonce[1]
          //            }),
          //
          //             .
          //             .
          //             .
          //
          //            IPermit2.PermitDetails({
          //              token: token[numberOfPermissions - 1],
          //              amount: amount[numberOfPermissions - 1],
          //              expiration: uint48(expiration[numberOfPermissions - 1]),
          //              nonce: nonce[numberOfPermissions - 1]
          //            })
          //          ],
          //          spender: spender,
          //          sigDeadline: uint256(signatureDeadline)
          //        }),
          //        signature
          //      )'
          //
          // To this end, the following bytes of calldata are written in
          // memory.
          //
          // 128                   132     164    196
          //  |                     |       |      |
          //  +---------------------+-------+------+
          //  | permitBatchSelector | owner | 0x60 |
          //  +---------------------+-------+------+
          //
          // 196                               228    260       292
          //  |                                 |      |         |
          //  +---------------------------------+------+---------+
          //  | 224 + 128 * numberOfPermissions | 0x60 | spender |
          //  +---------------------------------+------+---------+
          //
          // 292           324                   356
          //  |             |                     |
          //  +-------------+---------------------+
          //  | sigDeadline | numberOfPermissions |
          //  +-------------+---------------------+
          //
          // 356        388         420             452        484
          //  |          |           |               |          |
          //  +----------+-----------+---------------+----------+
          //  | token[1] | amount[1] | expiration[1] | nonce[1] |
          //  +----------+-----------+---------------+----------+
          //
          // 484        516         548             580        612
          //  |          |           |               |          |
          //  +----------+-----------+---------------+----------+
          //  | token[2] | amount[2] | expiration[2] | nonce[2] |
          //  +----------+-----------+---------------+----------+
          //
          //      .
          //      .
          //      .
          //
          // 228 + 128 * n                                     356 + 128 * n
          //  |                                                 |
          //  +----------+-----------+---------------+----------+
          //  | token[n] | amount[n] | expiration[n] | nonce[n] |
          //  +----------+-----------+---------------+----------+
          //
          // 356 + 128 * n        388 + 128 * n
          //  |                    |
          //  +--------------------+-----------+
          //  | signatureByteCount | signature |
          //  +--------------------+-----------+
          //
          mstore(128, permitBatchSelector)
          mstore(164, 0x60)
          mstore(228, 0x60)

          let content, signatureByteCount
          {
            content, nextPointer := _load(27, pointer)
            let owner, signatureDeadline
            owner, signatureDeadline, signatureByteCount := 
              _decode3(6, 1, content)
            mstore(132, owner)
            mstore(292, signatureDeadline)
          }

          let successSlot, startSignatureMemory
          {
            content, nextPointer := _load(22, nextPointer)
            let spender, numberOfPermissions
            spender, successSlot, numberOfPermissions := 
              _decode3(1, 1, content)
            startSignatureMemory := add(356, shl(7, numberOfPermissions))
            mstore(196, sub(startSignatureMemory, 132))
            mstore(260, spender)
            mstore(324, numberOfPermissions)
          }

          let memoryPointer := 356
          for {} lt(memoryPointer, startSignatureMemory) {} {
            content, nextPointer := _load32(nextPointer)
            {
              let token, amountSlot
              token, amountSlot, content := _decode3(1, 11, content)
              let amount := tload(amountSlot)
              if gt(amount, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
                _safeMathRevert()
              }
              mstore(memoryPointer, token)
              memoryPointer := add(memoryPointer, 32)
              mstore(memoryPointer, amount)
              memoryPointer := add(memoryPointer, 32)
            }
            {
              let expiration, nonce := _decode2(6, content)
              mstore(memoryPointer, expiration)
              memoryPointer := add(memoryPointer, 32)
              mstore(memoryPointer, nonce)
              memoryPointer := add(memoryPointer, 32)
            }
          }
          mstore(memoryPointer, signatureByteCount)
          memoryPointer := add(memoryPointer, 32)
          nextPointer := _copy(memoryPointer, nextPointer, signatureByteCount)
          memoryPointer := add(memoryPointer, signatureByteCount)

          tstore(
            successSlot,
            call(gas(), _permit2, 0, 128, sub(memoryPointer, 128), 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.TRANSFER_NATIVE,
        //    address to,
        //    uint8 amountSlot,
        //    uint8 successSlot
        // )
        function _transferNative(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(22, pointer)
          let to, amountSlot, successSlot := _decode3(1, 1, content)

          tstore(
            successSlot,
            call(gas(), to, _verifyUnsigned(amountSlot), 0, 0, 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.TRANSFER_FROM_PAYER_ERC20,
        //    address token,
        //    uint8 amountSlot,
        //    address to,
        //    uint8 successSlot,
        //    uint8 resultSlot,
        // )
        function _transferFromPayerERC20(payer, pointer) -> nextPointer {
          let content
          content, nextPointer := _load(21, pointer)
          let token, amountSlot := _decode2(1, content)
          content, nextPointer := _load(22, nextPointer)
          let to, successSlot, resultSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'IERC20(token).transferFrom(payer, to, amount)'
          //
          // To this end, the following 100 bytes of calldata are written in
          // memory.
          //
          //   128                         132     164  196      228
          //    |                           |       |    |        |
          //    +---------------------------+-------+----+--------+
          //    | transferFromERC20Selector | payer | to | amount |
          //    +---------------------------+-------+----+--------+
          //
          mstore(128, transferFromERC20Selector)
          mstore(132, payer)
          mstore(164, to)
          mstore(196, _verifyUnsigned(amountSlot))
          tstore(successSlot, call(gas(), token, 0, 128, sub(228, 128), 0, 32))
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.TRANSFER_FROM_PAYER_PERMIT2,
        //    address to,
        //    uint8 amountSlot,
        //    address token,
        //    uint8 successSlot,
        // )
        function _transferFromPayerPermit2(
          _permit2,
          payer,
          pointer
        ) -> nextPointer {
          let content
          content, nextPointer := _load(21, pointer)
          let to, amountSlot := _decode2(1, content)
          content, nextPointer := _load(21, nextPointer)
          let token, successSlot := _decode2(1, content)

          // The following lines invoke:
          //
          //    'IPermit2(permit2).transferFrom(payer, to, amount, token)'
          //
          // To this end, the following 100 bytes of calldata are written in
          // memory.
          //
          //   128                           132     164  196      228     260
          //    |                             |       |    |        |       |
          //    +-----------------------------+-------+----+--------+-------+
          //    | transferFromPermit2Selector | payer | to | amount | token |
          //    +-----------------------------+-------+----+--------+-------+
          //
          mstore(128, transferFromPermit2Selector)
          mstore(132, payer)
          mstore(164, to)
          mstore(196, _verifyUnsigned(amountSlot))
          mstore(228, token)
          tstore(
            successSlot,
            call(gas(), _permit2, 0, 128, sub(260, 128), 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.TRANSFER_FROM_PAYER_ERC6909,
        //    address token,
        //    uint256 id,
        //    address to,
        //    uint8 amountSlot,
        //    uint8 successSlot,
        //    uint8 resultSlot
        // )
        function _transferFromPayerERC6909(payer, pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let id
          id, nextPointer := _load32(nextPointer)
          let content
          content, nextPointer := _load(23, nextPointer)
          let to
          to, content := _decode2(3, content)
          let amountSlot, successSlot, resultSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'IERC6909(token).transferFrom(payer, to, id, amount)'
          //
          // To this end, the following 132 bytes of calldata are written in
          // memory.
          //
          //   128                           132     164  196  228      260
          //    |                             |       |    |    |        |
          //    +-----------------------------+-------+----+----+--------+
          //    | transferFromERC6909Selector | payer | to | id | amount |
          //    +-----------------------------+-------+----+----+--------+
          //
          mstore(128, transferFromERC6909Selector)
          mstore(132, payer)
          mstore(164, to)
          mstore(196, id)
          mstore(228, _verifyUnsigned(amountSlot))
          tstore(successSlot, call(gas(), token, 0, 128, sub(260, 128), 0, 32))
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.SAFE_TRANSFER_FROM_PAYER_ERC1155,
        //    address token,
        //    uint256 id,
        //    address to,
        //    uint8 amountSlot,
        //    uint8 successSlot,
        //    uint24 dataByteCount,
        //    bytes data
        // )
        function _safeTransferFromPayerERC1155(payer, pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let id
          id, nextPointer := _load32(nextPointer)
          let content
          content, nextPointer := _load(25, nextPointer)
          let to
          to, content := _decode2(5, content)
          let amountSlot, successSlot, dataByteCount := _decode3(1, 3, content)

          // The following lines invoke:
          //
          //    'IERC1155(token).safeTransferFrom(payer, to, id, amount, data)'
          //
          // To this end, the following content is written in memory as
          // calldata.
          //
          // 128                               132     164  196  228      260
          //  |                                 |       |    |    |        |
          //  +---------------------------------+-------+----+----+--------+
          //  | safeTransferFromERC1155Selector | payer | to | id | amount |
          //  +---------------------------------+-------+----+----+--------+
          //
          // 260    292             324
          //  |      |               |
          //  +------+---------------+------+
          //  | 0xA0 | dataByteCount | data |
          //  +------+---------------+------+
          //
          mstore(128, safeTransferFromERC1155Selector)
          mstore(132, payer)
          mstore(164, to)
          mstore(196, id)
          mstore(228, _verifyUnsigned(amountSlot))
          mstore(260, 0xA0) // ABI header for 'data'
          mstore(292, dataByteCount)
          nextPointer := _copy(324, nextPointer, dataByteCount)
          tstore(
            successSlot,
            call(gas(), token, 0, 128, add(sub(324, 128), dataByteCount), 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.CLEAR,
        //    Tag tag,
        //    uint8 amountSlot
        //    uint8 successSlot
        // )
        function _clear(pointer) -> nextPointer {
          let tag
          tag, nextPointer := _load32(pointer)
          let content
          content, nextPointer := _load(2, nextPointer)
          let amountSlot, successSlot := _decode2(1, content)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).clear(tag, amount)'
          //
          // To this end, the following 68 bytes of calldata are written in
          // memory.
          //
          //   128             132   164      196
          //    |               |     |        |
          //    +---------------+-----+--------+
          //    | clearSelector | tag | amount |
          //    +---------------+-----+--------+
          //
          mstore(128, clearSelector)
          mstore(132, tag)
          mstore(164, _verifyUnsigned(amountSlot))
          tstore(
            successSlot,
            call(gas(), caller(), 0, 128, sub(196, 128), 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.TAKE_TOKEN,
        //    address token,
        //    address to,
        //    uint8 amountSlot,
        //    uint8 successSlot
        // )
        function _takeToken(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let to, amountSlot, successSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).take(token, to, amount)'
          //
          // To this end, the following 100 bytes of calldata are written in
          // memory.
          //
          //   128                 132     164  196      228
          //    |                   |       |    |        |
          //    +-------------------+-------+----+--------+
          //    | takeTokenSelector | token | to | amount |
          //    +-------------------+-------+----+--------+
          //
          mstore(128, takeTokenSelector)
          mstore(132, token)
          mstore(164, to)
          mstore(196, _verifyUnsigned(amountSlot))
          tstore(
            successSlot,
            call(gas(), caller(), 0, 128, sub(228, 128), 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.TAKE_ERC6909,
        //    address token,
        //    uint256 id,
        //    address to,
        //    uint8 amountSlot,
        //    uint8 successSlot
        // )
        function _takeERC6909(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let id
          id, nextPointer := _load32(nextPointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let to, amountSlot, successSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).take(token, id, to, amount)'.
          //
          // To this end, the following 132 bytes of calldata are written in
          // memory.
          //
          //   128                   132     164  196  228      260
          //    |                     |       |    |    |        |
          //    +---------------------+-------+----+----+--------+
          //    | takeERC6909Selector | token | id | to | amount |
          //    +---------------------+-------+----+----+--------+
          //
          mstore(128, takeERC6909Selector)
          mstore(132, token)
          mstore(164, id)
          mstore(196, to)
          mstore(228, _verifyUnsigned(amountSlot))
          tstore(
            successSlot,
            call(gas(), caller(), 0, 128, sub(260, 128), 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.TAKE_ERC1155,
        //    address token,
        //    uint256 id,
        //    address to,
        //    uint8 amountSlot,
        //    uint8 successSlot,
        //    uint24 dataByteCount,
        //    bytes data
        // )
        function _takeERC1155(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let id
          id, nextPointer := _load32(nextPointer)
          let content
          content, nextPointer := _load(25, nextPointer)
          let to
          to, content := _decode2(5, content)
          let amountSlot, successSlot, dataByteCount := _decode3(1, 3, content)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).take(token, id, to, amount, data)'
          //
          // To this end, the following content is written in memory as
          // calldata.
          //
          //  128                   132     164  196  228      260    292
          //   |                     |       |    |    |        |      |
          //   +---------------------+-------+----+----+--------+------+
          //   | takeERC1155Selector | token | id | to | amount | 0xA0 |
          //   +---------------------+-------+----+----+--------+------+
          //
          //  292             324
          //   |               |
          //   +---------------+------+
          //   | dataByteCount | data |
          //   +---------------+------+
          //
          mstore(128, takeERC1155Selector)
          mstore(132, token)
          mstore(164, id)
          mstore(196, to)
          mstore(228, _verifyUnsigned(amountSlot))
          mstore(260, 0xA0) // ABI header for 'data'
          mstore(292, dataByteCount)
          nextPointer := _copy(324, nextPointer, dataByteCount)
          tstore(
            successSlot,
            call(
              gas(),
              caller(),
              0,
              128,
              add(sub(324, 128), dataByteCount),
              0,
              0
            )
          )
        }

        // abi.encodePacked(
        //    Action Action.SYNC_TOKEN,
        //    address token
        // )
        function _syncToken(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).sync(token)'
          //
          // To this end, the following 36 bytes of calldata are written in
          // memory.
          //
          //    0                   4       36
          //    |                   |       |
          //    +-------------------+-------+
          //    | syncTokenSelector | token |
          //    +-------------------+-------+
          //
          mstore(0, syncTokenSelector)
          mstore(4, token)
          pop(call(gas(), caller(), 0, 0, 36, 0, 0))
        }

        // abi.encodePacked(
        //    Action Action.SYNC_MULTITOKEN,
        //    address token,
        //    uint256 id
        // )
        function _syncMultiToken(pointer) -> nextPointer {
          let token
          token, nextPointer := _load(20, pointer)
          let id
          id, nextPointer := _load32(nextPointer)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).sync(token, id)'
          //
          // To this end, the following 68 bytes of calldata are written in
          // memory.
          //
          //   128                      132     164  196
          //    |                        |       |    |
          //    +------------------------+-------+----+
          //    | syncMultiTokenSelector | token | id |
          //    +------------------------+-------+----+
          //
          mstore(128, syncMultiTokenSelector)
          mstore(132, token)
          mstore(164, id)
          pop(call(gas(), caller(), 0, 128, sub(196, 128), 0, 0))
        }

        // abi.encodePacked(
        //    Action Action.SETTLE,
        //    uint8 valueSlot,
        //    uint8 successSlot
        //    uint8 resultSlot
        // )
        function _settle(pointer) -> nextPointer {
          let content
          content, nextPointer := _load(3, pointer)
          let valueSlot, successSlot, resultSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender){value: value}.settle()'
          //
          // To this end, the following 4 bytes of calldata are written in
          // memory.
          //
          //    0                4
          //    |                |
          //    +----------------+
          //    | settleSelector |
          //    +----------------+
          //
          mstore(0, settleSelector)
          tstore(
            successSlot,
            call(gas(), caller(), _verifyUnsigned(valueSlot), 0, 4, 0, 32)
          )
          tstore(resultSlot, mload(0))
        }

        // abi.encodePacked(
        //    Action Action.TRANSFER_TRANSIENT_BALANCE,
        //    Tag tag,
        //    address receiver,
        //    uint8 amountSlot,
        //    uint8 successSlot
        // )
        function _transferTransientBalanceFrom(payer, pointer) -> nextPointer {
          let tag
          tag, nextPointer := _load32(pointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let receiver, amountSlot, successSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).transferTransientBalanceFrom(
          //        payer,
          //        receiver,
          //        tag,
          //        amount
          //     )'.
          //
          // To this end, the following 132 bytes of calldata are written in
          // memory.
          //
          //   128                                    132     164        196
          //    |                                      |       |          |
          //    +--------------------------------------+-------+----------+
          //    | transferTransientBalanceFromSelector | payer | receiver |
          //    +--------------------------------------+-------+----------+
          //
          //   196   228      260
          //    |     |        |
          //    +-----+--------+
          //    | tag | amount |
          //    +-----+--------+
          //
          mstore(128, transferTransientBalanceFromSelector)
          mstore(132, payer)
          mstore(164, receiver)
          mstore(196, tag)
          mstore(228, _verifyUnsigned(amountSlot))
          tstore(
            successSlot,
            call(gas(), caller(), 0, 128, sub(260, 128), 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.MODIFY_SINGLE_BALANCE,
        //    Tag tag,
        //    uint8 amountSlot,
        //    uint8 successSlot
        // )
        function _modifySingleBalance(payer, pointer) -> nextPointer {
          let tag
          tag, nextPointer := _load32(pointer)
          let content
          content, nextPointer := _load(2, nextPointer)
          let amountSlot, successSlot := _decode2(1, content)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).modifyBalance(payer, tag, amount)'.
          //
          // To this end, the following 100 bytes of calldata are written in
          // memory.
          //
          //   128                           132     164   196      228
          //    |                             |       |     |        |
          //    +-----------------------------+-------+-----+--------+
          //    | modifySingleBalanceSelector | payer | tag | amount |
          //    +-----------------------------+-------+-----+--------+
          //
          mstore(128, modifySingleBalanceSelector)
          mstore(132, payer)
          mstore(164, tag)
          mstore(196, tload(amountSlot))
          tstore(
            successSlot,
            call(gas(), caller(), 0, 128, sub(228, 128), 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.MODIFY_DOUBLE_BALANCE,
        //    Tag tag0,
        //    Tag tag1,
        //    uint8 amount0Slot,
        //    uint8 amount1Slot,
        //    uint8 successSlot
        // )
        function _modifyDoubleBalance(payer, pointer) -> nextPointer {
          let tag0
          tag0, nextPointer := _load32(pointer)
          let tag1
          tag1, nextPointer := _load32(nextPointer)
          let content
          content, nextPointer := _load(3, nextPointer)
          let amount0Slot, amount1Slot, successSlot := _decode3(1, 1, content)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).modifyBalance(
          //        payer,
          //        tag0,
          //        tag1,
          //        amount0,
          //        amount1
          //     )'.
          //
          // To this end, the following 164 bytes of calldata are written in
          // memory.
          //
          // 128                           132     164    196    228       260
          //  |                             |       |      |      |         |
          //  +-----------------------------+-------+------+------+---------+
          //  | modifyDoubleBalanceSelector | payer | tag0 | tag1 | amount0 |
          //  +-----------------------------+-------+------+------+---------+
          //
          // 260       292
          //  |         |
          //  +---------+
          //  | amount1 |
          //  +---------+
          //
          mstore(128, modifyDoubleBalanceSelector)
          mstore(132, payer)
          mstore(164, tag0)
          mstore(196, tag1)
          mstore(228, tload(amount0Slot))
          mstore(260, tload(amount1Slot))
          tstore(
            successSlot,
            call(gas(), caller(), 0, 128, sub(292, 128), 0, 0)
          )
        }

        // abi.encodePacked(
        //    Action Action.SWAP,
        //    uint256 poolId,
        //    uint8 amountSpecifiedSlot,
        //    uint64 limitOffsetted,
        //    uint8 zeroForOne,
        //    uint8 crossThresholdSlot,
        //    uint8 successSlot,
        //    uint8 amount0Slot,
        //    uint8 amount1Slot,
        //    uint16 hookDataBytesCount,
        //    bytes hookData
        // )
        function _swap(target, pointer) -> nextPointer {
          // The following lines invoke:
          //
          //    'target.swap(
          //        poolId,
          //        amountSpecified,
          //        limit,
          //        (crossThreshold << 128) | zeroForOne,
          //        hookData
          //     )'.
          //
          // To this end, the following content is written in memory as
          // calldata.
          //
          // 128            132      164               196     228          260
          //  |              |        |                 |       |            |
          //  +--------------+--------+-----------------+-------+------------+
          //  | swapSelector | poolId | amountSpecified | limit | zeroForOne |
          //  +--------------+--------+-----------------+-------+------------+
          //
          // 260    292                  324
          //  |      |                    |
          //  +------+--------------------+----------+
          //  | 0xA0 | hookDataBytesCount | hookData |
          //  +------+--------------------+----------+
          //
          mstore(128, swapSelector)

          let content
          {
            let poolId
            poolId, nextPointer := _load32(pointer)
            content, nextPointer := _load(16, nextPointer)
            let amountSpecifiedSlot, limitOffsetted
            amountSpecifiedSlot, limitOffsetted, content := 
              _decode3(8, 7, content)
            mstore(132, poolId)
            mstore(164, tload(amountSpecifiedSlot))
            mstore(196, _removeOffset(limitOffsetted, poolId))
          }

          {
            let zeroForOne, crossThresholdSlot
            zeroForOne, crossThresholdSlot, content := _decode3(1, 5, content)
            let crossThreshold := tload(crossThresholdSlot)
            if gt(crossThreshold, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
              _safeMathRevert()
            }
            mstore(228, or(shl(128, crossThreshold), zeroForOne))
          }

          mstore(260, 0xA0) // ABI header for 'hookData'

          {
            let successSlot, amount0Slot
            successSlot, amount0Slot, content := _decode3(1, 3, content)
            let amount1Slot, hookDataBytesCount := _decode2(2, content)
            mstore(292, hookDataBytesCount)
            nextPointer := _copy(324, nextPointer, hookDataBytesCount)
            tstore(
              successSlot,
              call(
                gas(),
                target,
                0,
                128,
                add(sub(324, 128), hookDataBytesCount),
                0,
                64
              )
            )
            tstore(amount0Slot, mload(0))
            tstore(amount1Slot, mload(32))
          }
        }

        // abi.encodePacked(
        //    Action Action.MODIFY_POSITION,
        //    uint256 poolId,
        //    uint64 qMinOffsetted,
        //    uint64 qMaxOffsetted,
        //    uint8 sharesSlot,
        //    uint8 successSlot,
        //    uint8 amount0Slot,
        //    uint8 amount1Slot,
        //    uint16 hookDataBytesCount,
        //    bytes hookData
        // )
        function _modifyPosition(pointer) -> nextPointer {
          let poolId
          poolId, nextPointer := _load32(pointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let qMinOffsetted, qMaxOffsetted
          qMinOffsetted, qMaxOffsetted, content := _decode3(8, 6, content)
          let sharesSlot, successSlot
          sharesSlot, successSlot, content := _decode3(1, 4, content)
          let amount0Slot, amount1Slot, hookDataBytesCount :=
            _decode3(1, 2, content)

          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).dispatch(
          //        abi.encodeWithSelector(
          //            INofeeswapDelegatee.modifyPosition.selector,
          //            poolId,
          //            qMin,
          //            qMax,
          //            shares,
          //            hookData
          //        )
          //     )'.
          //
          // To this end, the following content is written in memory as
          // calldata.
          //
          // 128                132    164                        196
          //  |                  |      |                          |
          //  +------------------+------+--------------------------+
          //  | dispatchSelector | 0x20 | 196 + hookDataBytesCount |
          //  +------------------+------+--------------------------+
          //
          // 196                      200      232    264    296      328
          //  |                        |        |      |      |        |
          //  +------------------------+--------+------+------+--------+
          //  | modifyPositionSelector | poolId | qMin | qMax | shares |
          //  +------------------------+--------+------+------+--------+
          //
          // 328    360                  392
          //  |      |                    |
          //  +------+--------------------+----------+
          //  | 0xA0 | hookDataBytesCount | hookData |
          //  +------+--------------------+----------+
          //
          mstore(128, dispatchSelector)
          mstore(132, 0x20)
          mstore(164, add(196, hookDataBytesCount))
          mstore(196, modifyPositionSelector)
          mstore(200, poolId)
          mstore(232, _removeOffset(qMinOffsetted, poolId))
          mstore(264, _removeOffset(qMaxOffsetted, poolId))
          mstore(296, tload(sharesSlot))
          mstore(328, 0xA0)
          mstore(360, hookDataBytesCount)
          nextPointer := _copy(392, nextPointer, hookDataBytesCount)
          tstore(
            successSlot,
            call(
              gas(),
              caller(),
              0,
              128,
              add(sub(392, 128), hookDataBytesCount),
              0,
              64
            )
          )
          tstore(amount0Slot, mload(0))
          tstore(amount1Slot, mload(32))
        }

        // abi.encodePacked(
        //    Action Action.DONATE,
        //    uint256 poolId,
        //    uint8 sharesSlot,
        //    uint8 successSlot,
        //    uint8 amount0Slot,
        //    uint8 amount1Slot,
        //    uint16 hookDataBytesCount,
        //    bytes hookData
        // )
        function _donate(pointer) -> nextPointer {
          let poolId
          poolId, nextPointer := _load32(pointer)
          let content
          content, nextPointer := _load(6, nextPointer)
          let sharesSlot, successSlot
          sharesSlot, successSlot, content := _decode3(1, 4, content)
          let amount0Slot, amount1Slot, hookDataBytesCount := 
            _decode3(1, 2, content)
          
          // The following lines invoke:
          //
          //    'INofeeswap(msg.sender).dispatch(
          //        abi.encodeWithSelector(
          //            INofeeswapDelegatee.donate.selector,
          //            poolId,
          //            shares,
          //            hookData
          //        )
          //     )'.
          //
          // To this end, the following content is written in memory as
          // calldata.
          //
          // 128                132    164                        196
          //  |                  |      |                          |
          //  +------------------+------+--------------------------+
          //  | dispatchSelector | 0x20 | 132 + hookDataBytesCount |
          //  +------------------+------+--------------------------+
          //
          // 196              200      232      264    296                  328
          //  |                |        |        |      |                    |
          //  +----------------+--------+--------+------+--------------------+
          //  | donateSelector | poolId | shares | 0x60 | hookDataBytesCount |
          //  +----------------+--------+--------+------+--------------------+
          //
          // 328
          //  |
          //  +----------+
          //  | hookData |
          //  +----------+
          //
          mstore(128, dispatchSelector)
          mstore(132, 0x20)
          mstore(164, add(132, hookDataBytesCount))
          mstore(196, donateSelector)
          mstore(200, poolId)
          mstore(232, _verifyUnsigned(sharesSlot))
          mstore(264, 0x60)
          mstore(296, hookDataBytesCount)
          nextPointer := _copy(328, nextPointer, hookDataBytesCount)
          tstore(
            successSlot,
            call(
              gas(),
              caller(),
              0,
              128,
              add(sub(328, 128), hookDataBytesCount),
              0,
              64
            )
          )
          tstore(amount0Slot, mload(0))
          tstore(amount1Slot, mload(32))
        }

        // abi.encodePacked(
        //    Action Action.QUOTE_MODIFY_POSITION,
        //    uint256 poolId,
        //    uint64 qMinOffsetted,
        //    uint64 qMaxOffsetted,
        //    uint8 sharesSlot,
        //    uint8 successSlot,
        //    uint8 amount0Slot,
        //    uint8 amount1Slot,
        //    uint16 hookDataBytesCount,
        //    bytes hookData
        // )
        function _quoteModifyPosition(quoter, pointer) -> nextPointer {
          let poolId
          poolId, nextPointer := _load32(pointer)
          let content
          content, nextPointer := _load(22, nextPointer)
          let qMinOffsetted, qMaxOffsetted
          qMinOffsetted, qMaxOffsetted, content := _decode3(8, 6, content)
          let sharesSlot, successSlot
          sharesSlot, successSlot, content := _decode3(1, 4, content)
          let amount0Slot, amount1Slot, hookDataBytesCount :=
            _decode3(1, 2, content)

          // The following lines invoke:
          //
          //    'IQuoter(quoter).modifyPosition(
          //        poolId,
          //        qMin,
          //        qMax,
          //        shares,
          //        hookData
          //     )'.
          //
          // To this end, the following content is written in memory as
          // calldata.
          //
          // 128                      132      164    196    228      260
          //  |                        |        |      |      |        |
          //  +------------------------+--------+------+------+--------+
          //  | modifyPositionSelector | poolId | qMin | qMax | shares |
          //  +------------------------+--------+------+------+--------+
          //
          // 260    292                  324
          //  |      |                    |
          //  +------+--------------------+----------+
          //  | 0xA0 | hookDataBytesCount | hookData |
          //  +------+--------------------+----------+
          //
          mstore(128, modifyPositionSelector)
          mstore(132, poolId)
          mstore(164, _removeOffset(qMinOffsetted, poolId))
          mstore(196, _removeOffset(qMaxOffsetted, poolId))
          mstore(228, tload(sharesSlot))
          mstore(260, 0xA0)
          mstore(292, hookDataBytesCount)
          nextPointer := _copy(324, nextPointer, hookDataBytesCount)
          tstore(
            successSlot,
            call(
              gas(),
              quoter,
              0,
              128,
              add(sub(324, 128), hookDataBytesCount),
              0,
              64
            )
          )
          tstore(amount0Slot, mload(0))
          tstore(amount1Slot, mload(32))
        }

        // abi.encodePacked(
        //    Action Action.QUOTE_DONATE,
        //    uint256 poolId,
        //    uint8 sharesSlot,
        //    uint8 successSlot,
        //    uint8 amount0Slot,
        //    uint8 amount1Slot,
        //    uint16 hookDataBytesCount,
        //    bytes hookData
        // )
        function _quoteDonate(quoter, pointer) -> nextPointer {
          let poolId
          poolId, nextPointer := _load32(pointer)
          let content
          content, nextPointer := _load(6, nextPointer)
          let sharesSlot, successSlot
          sharesSlot, successSlot, content := _decode3(1, 4, content)
          let amount0Slot, amount1Slot, hookDataBytesCount := 
            _decode3(1, 2, content)
          
          // The following lines invoke:
          //
          //    'IQuoter(quoter).donate(
          //        poolId,
          //        shares,
          //        hookData
          //     )'.
          //
          // To this end, the following content is written in memory as
          // calldata.
          //
          // 128              132      164      196    228                  260
          //  |                |        |        |      |                    |
          //  +----------------+--------+--------+------+--------------------+
          //  | donateSelector | poolId | shares | 0x60 | hookDataBytesCount |
          //  +----------------+--------+--------+------+--------------------+
          //
          // 260
          //  |
          //  +----------+
          //  | hookData |
          //  +----------+
          //
          mstore(128, donateSelector)
          mstore(132, poolId)
          mstore(164, _verifyUnsigned(sharesSlot))
          mstore(196, 0x60)
          mstore(228, hookDataBytesCount)
          nextPointer := _copy(260, nextPointer, hookDataBytesCount)
          tstore(
            successSlot,
            call(
              gas(),
              quoter,
              0,
              128,
              add(sub(260, 128), hookDataBytesCount),
              0,
              64
            )
          )
          tstore(amount0Slot, mload(0))
          tstore(amount1Slot, mload(32))
        }

        // abi.encodePacked(
        //    Action Action.QUOTER_TRANSIENT_ACCESS,
        //    bytes32 transientSlot,
        //    uint8 resultSlot
        // )
        function _quoterTransientAccess(quoter, pointer) -> nextPointer {
          let transientSlot, resultSlot
          transientSlot, nextPointer := _load32(pointer)
          resultSlot, nextPointer := _load(1, nextPointer)
          
          // The following lines invoke:
          //
          //    'TransientAccess(quoter).transientAccess(transientSlot)'.
          //
          // To this end, the following content is written in memory as
          // calldata.
          //
          //  0                         4               36
          //  |                         |               |
          //  +-------------------------+---------------+
          //  | transientAccessSelector | transientSlot |
          //  +-------------------------+---------------+
          //
          mstore(0, transientAccessSelector)
          mstore(4, transientSlot)
          pop(call(gas(), quoter, 0, 0, 36, 0, 32))
          tstore(resultSlot, mload(0))
        }

        // The type of action is loaded from calldata.
        let action
        action, _pointer_ := _load(1, _pointer_)
        switch action
        case 1 {
          _pointer_ := _push10(_pointer_)
        }
        case 4 {
          _pointer_ := _neg(_pointer_)
        }
        case 52 {
          _pointer_ := _swap(caller(), _pointer_)
        }
        case 13 {
          _pointer_ := _lt(_pointer_)
        }
        case 16 {
          _pointer_ := _iszero(_pointer_)
        }
        case 20 {
          // jumpdest does nothing.
        }
        case 21 {
          _pointer_ := _jump(_pointer_)
        }
        case 0 {
          _pointer_ := _push0(_pointer_)
        }
        case 50 {
          _pointer_ := _modifySingleBalance(_payer_, _pointer_)
        }
        case 51 {
          _pointer_ := _modifyDoubleBalance(_payer_, _pointer_)
        }
        case 42 {
          _pointer_ := _takeToken(_pointer_)
        }        
        case 45 {
          _pointer_ := _syncToken(_pointer_)
        }
        case 47 {
          _pointer_ := _settle(_pointer_)
        }
        case 37 {
          _pointer_ := _transferFromPayerERC20(_payer_, _pointer_)
        }
        case 36 {
          _pointer_ := _transferNative(_pointer_)
        }
        case 38 {
          _pointer_ := _transferFromPayerPermit2(_permit2_, _payer_, _pointer_)
        }
        case 34 {
          _pointer_ := _permitPermit2(_permit2_, _pointer_)
        }
        case 35 {
          _pointer_ := _permitBatchPermit2(_permit2_, _pointer_)
        }
        case 41 {
          _pointer_ := _clear(_pointer_)
        }
        case 32 {
          _pointer_ := _wrapNative(_weth9_, _pointer_)
        }
        case 33 {
          _pointer_ := _unwrapNative(_weth9_, _pointer_)
        }
        case 53 {
          _pointer_ := _modifyPosition(_pointer_)
        }
        case 39 {
          _pointer_ := _transferFromPayerERC6909(_payer_, _pointer_)
        }
        case 43 {
          _pointer_ := _takeERC6909(_pointer_)
        }
        case 48 {
          _pointer_ := _transferTransientBalanceFrom(address(), _pointer_)
        }
        case 49 {
          _pointer_ := _transferTransientBalanceFrom(_payer_, _pointer_)
        }
        case 2 {
          _pointer_ := _push16(_pointer_)
        }
        case 55 {
          _pointer_ := _swap(_quoter_, _pointer_)
        }
        case 56 {
          _pointer_ := _quoteModifyPosition(_quoter_, _pointer_)
        }
        case 5 {
          _pointer_ := _add(_pointer_)
        }
        case 6 {
          _pointer_ := _sub(_pointer_)
        }
        case 7 {
          _pointer_ := _min(_pointer_)
        }
        case 8 {
          _pointer_ := _max(_pointer_)
        }
        case 9 {
          _pointer_ := _mul(_pointer_)
        }
        case 11 {
          _pointer_ := _divRoundDown(_pointer_)
        }
        case 12 {
          _pointer_ := _divRoundUp(_pointer_)
        }
        case 10 {
          _pointer_ := _div(_pointer_)
        }
        case 22 {
          _pointer_ := _readTransientBalance(_pointer_)
        }
        case 23 {
          _pointer_ := _readBalanceOfNative(_pointer_)
        }
        case 24 {
          _pointer_ := _readBalanceOfERC20(_pointer_)
        }
        case 31 {
          _pointer_ := _readDoubleBalance(_pointer_)
        }
        case 26 {
          _pointer_ := _readAllowanceERC20(_pointer_)
        }
        case 27 {
          _pointer_ := _readAllowancePermit2(_permit2_, _pointer_)
        }
        case 25 {
          _pointer_ := _readBalanceOfMultiToken(_pointer_)
        }
        case 28 {
          _pointer_ := _readAllowanceERC6909(_pointer_)
        }
        case 29 {
          _pointer_ := _readIsOperatorERC6909(_pointer_)
        }
        case 14 {
          _pointer_ := _eq(_pointer_)
        }
        case 15 {
          _pointer_ := _lteq(_pointer_)
        }
        case 17 {
          _pointer_ := _and(_pointer_)
        }
        case 18 {
          _pointer_ := _or(_pointer_)
        }
        case 19 {
          _pointer_ := _xor(_pointer_)
        }
        case 54 {
          _pointer_ := _donate(_pointer_)
        }
        case 57 {
          _pointer_ := _quoteDonate(_quoter_, _pointer_)
        }
        case 58 {
          _pointer_ := _quoterTransientAccess(_quoter_, _pointer_)
        }
        case 46 {
          _pointer_ := _syncMultiToken(_pointer_)
        }
        case 40 {
          _pointer_ := _safeTransferFromPayerERC1155(_payer_, _pointer_)
        }
        case 44 {
          _pointer_ := _takeERC1155(_pointer_)
        }
        case 30 {
          _pointer_ := _readIsApprovedForAllERC1155(_pointer_)
        }
        case 3 {
          _pointer_ := _push32(_pointer_)
        }
        default {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }

    assembly {
      if gt(selfbalance(), 0) {
        if iszero(call(gas(), _payer_, selfbalance(), 0, 0, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
      return(0, 0)
    }
  }

  receive() external payable {}
}