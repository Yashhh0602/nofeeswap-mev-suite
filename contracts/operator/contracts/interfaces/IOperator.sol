// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

/// @notice Interface for the Operator contract.
interface IOperator {
  /// @notice A sequence of compactly encoded instructions from the following
  /// list can be given to the operator contract to be executed in order.
  ///
  /// @param PUSH0 Clears a given transient storage slot of the operator. This
  /// action and its input should be encoded as follows:
  ///
  /// 'abi.encodePacked(Action Action.PUSH0, uint8 valueSlot)'
  ///
  /// @param valueSlot The transient storage slot to be zeroed.
  ///
  ///
  /// @param PUSH10 Populates a given transient storage slot of the operator
  /// with 'signextend(9, value)'. This action and its inputs should be encoded
  /// as follows:
  ///
  /// 'abi.encodePacked(Action Action.PUSH10, int80 value, uint8 valueSlot)'
  ///
  /// @param value The 80-bit signed integer to be sign-extended and stored.
  /// @param valueSlot The transient storage slot to be populated with the
  /// result.
  ///
  ///
  /// @param PUSH16 Populates a given transient storage slot of the operator
  /// with 'signextend(15, value)'. This action and its inputs should be
  /// encoded as follows:
  ///
  /// 'abi.encodePacked(Action Action.PUSH16, int128 value, uint8 valueSlot)'
  ///
  /// @param value The 128-bit signed integer to be sign-extended and stored.
  /// @param valueSlot The transient storage slot to be populated with the
  /// result.
  ///
  ///
  /// @param PUSH32 Populates an entire transient storage slot of the operator
  /// with 'value'. This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(Action Action.PUSH32, int256 value, uint8 valueSlot)'
  ///
  /// @param value The 256-bit signed integer to be stored.
  /// @param valueSlot The transient storage slot to be populated with value.
  ///
  ///
  /// @param NEG Negates the content of a transient storage slot and stores the
  /// result in another. This action and its inputs should be encoded as
  /// follows:
  ///
  /// 'abi.encodePacked(Action Action.NEG, uint8 valueSlot, uint8 resultSlot)'
  ///
  /// @param valueSlot The transient storage slot whose content to be negated.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param ADD Calculates 'add(tload(value0Slot), tload(value1Slot))' and
  /// stores the result in the transient storage slot 'resultSlot'. Throws in
  /// case of overflow or underflow. This action and its inputs should be
  /// encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.ADD,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the first value.
  /// @param value1Slot The transient storage slot containing the second value.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param SUB Calculates 'sub(tload(value0Slot), tload(value1Slot))' and
  /// stores the result in the transient storage slot 'resultSlot'. Throws in
  /// case of overflow or underflow. This action and its inputs should be
  /// encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.SUB,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the minuend.
  /// @param value1Slot The transient storage slot containing the subtrahend.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param MIN Finds the minimum of the signed integers 'tload(value0Slot)'
  /// and 'tload(value1Slot)', and stores the result in the transient storage
  /// slot 'resultSlot'. This action and its inputs should be encoded as
  /// follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.MIN,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the first value.
  /// @param value1Slot The transient storage slot containing the second value.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param MAX Finds the maximum of the signed integers 'tload(value0Slot)'
  /// and 'tload(value1Slot)', and stores the result in the transient storage
  /// slot 'resultSlot'. This action and its inputs should be encoded as
  /// follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.MAX,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing first value.
  /// @param value1Slot The transient storage slot containing second value.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param MUL Calculates 'mul(tload(value0Slot), tload(value1Slot))' and
  /// stores the result in the transient storage slot 'resultSlot'. Throws in
  /// case of overflow or underflow. This action and its inputs should be
  /// encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.MUL,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the multiplicand.
  /// @param value1Slot The transient storage slot containing the multiplier.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param DIV Calculates 'div(tload(value0Slot), tload(value1Slot))' and
  /// stores the result in the transient storage slot 'resultSlot', rounding
  /// towards the origin. Throws if
  ///
  /// 'value1 == 0' or
  /// 'value0 == type(int256).min && value1 == -1'.
  ///
  /// This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.DIV,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the numerator.
  /// @param value1Slot The transient storage slot containing the denominator.
  /// @return resultSlot The transient storage slot to host the division.
  ///
  ///
  /// @param DIV_ROUND_DOWN Divides 'tload(value0Slot)' by 'tload(value1Slot)',
  /// rounding toward '-oo' and stores the result in the transient storage slot
  /// 'resultSlot'. Throws if
  ///
  /// 'value1 == 0' or
  /// 'value0 == type(int256).min && value1 == -1'.
  ///
  /// This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.DIV_ROUND_DOWN,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the numerator.
  /// @param value1Slot The transient storage slot containing the denominator.
  /// @return resultSlot The transient storage slot to host the division.
  ///
  ///
  /// @param DIV_ROUND_UP Divides 'tload(value0Slot)' by 'tload(value1Slot)',
  /// rounding toward '+oo' and stores the result in the transient storage slot
  /// 'resultSlot'. Throws if
  ///
  /// 'value1 == 0' or
  /// 'value0 == type(int256).min && value1 == -1'.
  ///
  /// This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.DIV_ROUND_UP,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the numerator.
  /// @param value1Slot The transient storage slot containing the denominator.
  /// @return resultSlot The transient storage slot to host the division.
  ///
  ///
  /// @param LT Determines 'lt(tload(value0Slot), tload(value1Slot))' and
  /// stores the resulting boolean in the transient storage slot 'resultSlot'.
  /// This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.LT,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the first value.
  /// @param value1Slot The transient storage slot containing the second value.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param EQ Determines 'eq(tload(value0Slot), tload(value1Slot))' and
  /// stores the resulting boolean in the transient storage slot 'resultSlot'.
  /// This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.EQ,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the first value.
  /// @param value1Slot The transient storage slot containing the second value.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param LTEQ Determines 'iszero(gt(tload(value0Slot), tload(value1Slot)))'
  /// and stores the resulting boolean in the transient storage slot
  /// 'resultSlot'. This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.LTEQ,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the first value.
  /// @param value1Slot The transient storage slot containing the second value.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param ISZERO Determines 'iszero(tload(valueSlot))' and stores the
  /// resulting boolean in the transient storage slot 'resultSlot'. This action
  /// and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.ISZERO,
  ///     uint8 valueSlot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param valueSlot The transient storage slot containing 'value'.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param AND Determines 'and(tload(value0Slot), tload(value1Slot))' and
  /// stores the resulting bits in the transient storage slot 'resultSlot'.
  /// This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.AND,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the first value.
  /// @param value1Slot The transient storage slot containing the second value.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param OR Determines 'or(tload(value0Slot), tload(value1Slot))' and
  /// stores the resulting bits in the transient storage slot 'resultSlot'.
  /// This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.OR,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the first value.
  /// @param value1Slot The transient storage slot containing the second value.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param XOR Determines 'xor(tload(value0Slot), tload(value1Slot))' and
  /// stores the resulting bits in the transient storage slot 'resultSlot'.
  /// This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.XOR,
  ///     uint8 value0Slot,
  ///     uint8 value1Slot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param value0Slot The transient storage slot containing the first value.
  /// @param value1Slot The transient storage slot containing the second value.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param JUMPDEST Marks a valid destination for jumps and has no other
  /// effect. This operation should be encoded as follows:
  ///
  /// 'abi.encodePacked(Action Action.JUMPDEST)'
  ///
  ///
  /// @param JUMP If 'tload(conditionSlot)' is nonzero, jumps to the operation
  /// at byte 'destination'. Throws if 'destination' refers to anything but a
  /// 'JUMPDEST'. This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.JUMP,
  ///     uint16 destination,
  ///     uint8 conditionSlot
  ///  )'
  ///
  /// @param destination The jump destination which must be a 'JUMPDEST'.
  /// @param conditionSlot The transient storage slot containing the condition.
  ///
  ///
  /// @param READ_TRANSIENT_BALANCE Reads the transient balance of 'owner' in
  /// 'tag' by invoking:
  ///
  /// 'INofeeswap(nofeeswap).transientAccess(
  ///    keccak256(
  ///      abi.encodePacked(
  ///        tag,
  ///        owner,
  ///        uint96(uint256(keccak256("transientBalance"))) - 1
  ///      )
  ///    )
  ///  )'
  ///
  /// and storing the result in the transient storage slot 'resultSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.READ_TRANSIENT_BALANCE,
  ///     Tag tag,
  ///     address owner,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param tag The tag to be inquired.
  /// @param owner The transient balance owner.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param READ_BALANCE_OF_NATIVE Reads the native balance of 'owner' and
  /// stores the result in the transient storage slot 'resultSlot'. This action
  /// and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.READ_BALANCE_OF_NATIVE,
  ///     address owner,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param owner The balance owner.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param READ_BALANCE_OF_ERC20 Reads the ERC-20 balance of 'owner' by
  /// invoking the following low-level call:
  ///
  /// 'IERC20(token).balanceOf(owner)'
  ///
  /// and storing 'result' and 'success' in the transient storage slots 
  /// 'resultSlot' and 'successSlot', respectively. This action and its inputs
  /// should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.READ_BALANCE_OF_ERC20,
  ///     address token,
  ///     address owner,
  ///     uint8 successSlot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param token The ERC-20 token address.
  /// @param owner The balance owner.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return resultSlot The transient storage slot which will host 'result'.
  ///
  ///
  /// @param READ_BALANCE_OF_MULTITOKEN Reads the ERC-6909 or ERC-1155 balance
  /// of 'owner' with identifier 'id' by invoking either of the following
  /// low-level calls:
  ///
  /// 'IERC6909(token).balanceOf(owner, id)'
  /// 'IERC1155(token).balanceOf(owner, id)'
  ///
  /// and storing 'result' and 'success' in the transient storage slots 
  /// 'resultSlot' and 'successSlot', respectively. This action and its inputs
  /// should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.READ_BALANCE_OF_MULTITOKEN,
  ///     address token,
  ///     uint256 id,
  ///     address owner,
  ///     uint8 successSlot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param token The ERC-6909 or ERC-1155 token address.
  /// @param id The multi-token identifier.
  /// @param owner The balance owner.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return resultSlot The transient storage slot which will host 'result'.
  ///
  ///
  /// @param READ_ALLOWANCE_ERC20 Reads the ERC-20 allowance granted by 'owner'
  /// to 'spender' by invoking the following low-level call:
  ///
  /// 'IERC20(token).allowance(owner, spender)'
  ///
  /// and storing 'result' and 'success' in the transient storage slots 
  /// 'resultSlot' and 'successSlot', respectively. This action and its inputs
  /// should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.READ_ALLOWANCE_ERC20,
  ///     address token,
  ///     address owner,
  ///     address spender,
  ///     uint8 successSlot,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param token The ERC-20 token address.
  /// @param owner The balance owner.
  /// @param spender The spender address.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return resultSlot The transient storage slot which will host 'result'.
  ///
  ///
  /// @param READ_ALLOWANCE_PERMIT2 Reads the ERC-20 allowance granted by
  /// 'owner' to 'spender' via 'permit2' by invoking the following low-level
  /// call:
  ///
  /// 'IPermit2(permit2).allowance(owner, token, spender)'
  ///
  /// and storing 'result' in the transient storage slot 'resultSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.READ_ALLOWANCE_PERMIT2,
  ///     address token,
  ///     address owner,
  ///     address spender,
  ///     uint8 resultSlot
  ///  )'
  ///
  /// @param token The ERC-20 token address.
  /// @param owner The balance owner.
  /// @param spender The spender address.
  /// @return resultSlot The transient storage slot which will host 'result'.
  ///
  ///
  /// @param READ_ALLOWANCE_ERC6909 Reads the ERC-6909 allowance granted by
  /// 'owner' to 'spender' with identifier 'id' by invoking the following
  /// low-level call:
  ///
  /// 'IERC6909(token).allowance(owner, spender, id)'
  ///
  /// and storing 'result' and 'success' in the transient storage slots 
  /// 'resultSlot' and 'successSlot', respectively. This action and its inputs
  /// should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.READ_ALLOWANCE_ERC6909,
  ///    address token,
  ///    uint256 id,
  ///    address owner,
  ///    address spender,
  ///    uint8 successSlot,
  ///    uint8 resultSlot
  ///  )'
  ///
  /// @param token The ERC-6909 token address.
  /// @param id The multi-token identifier.
  /// @param owner The balance owner.
  /// @param spender The spender address.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return resultSlot The transient storage slot which will host 'result'.
  /// 
  ///
  /// @param READ_IS_OPERATOR_ERC6909 Reads the ERC-6909 operator status of
  /// 'spender' granted by 'owner' by invoking the following low-level call:
  ///
  /// 'IERC6909(token).isOperatorERC6909Selector(owner, spender)'
  ///
  /// and storing 'result' and 'success' in the transient storage slots 
  /// 'resultSlot' and 'successSlot', respectively. This action and its inputs
  /// should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.READ_IS_OPERATOR_ERC6909,
  ///    address token,
  ///    address owner,
  ///    address spender,
  ///    uint8 successSlot,
  ///    uint8 resultSlot
  ///  )'
  ///
  /// @param token The ERC-6909 token address.
  /// @param owner The balance owner.
  /// @param spender The spender address.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return resultSlot The transient storage slot which will host 'result'.
  ///
  ///
  /// @param READ_IS_APPROVED_FOR_ALL_ERC1155 Reads the ERC-1155 approvedForAll
  /// status of 'spender' granted by 'owner' by invoking the following
  /// low-level call:
  ///
  /// 'IERC1155(token).isApprovedForAllERC1155Selector(owner, spender)'
  ///
  /// and storing 'result' and 'success' in the transient storage slots 
  /// 'resultSlot' and 'successSlot', respectively. This action and its inputs
  /// should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.READ_IS_APPROVED_FOR_ALL_ERC1155,
  ///    address token,
  ///    address owner,
  ///    address spender,
  ///    uint8 successSlot,
  ///    uint8 resultSlot
  ///  )'
  ///
  /// @param token The ERC-6909 token address.
  /// @param owner The balance owner.
  /// @param spender The spender address.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return resultSlot The transient storage slot which will host 'result'.
  ///
  ///
  /// @param READ_DOUBLE_BALANCE Reads the singleton '(tag0, tag1)' double
  /// balance of 'owner' by invoking the following low-level call:
  ///
  /// 'INofeeswap(nofeeswap).storageAccess(
  ///    keccak256(
  ///      abi.encodePacked(
  ///        tag0,
  ///        tag1,
  ///        owner,
  ///        uint96(uint256(keccak256("doubleBalance"))) - 1
  ///      )
  ///    )
  ///  )'
  ///
  /// and storing the resulting two values in the transient storage slots 
  /// 'value0Slot' and 'value1Slot', for 'tag0' and 'tag1', respectively. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.READ_DOUBLE_BALANCE,
  ///    Tag tag0,
  ///    Tag tag1,
  ///    address owner,
  ///    uint8 value0Slot,
  ///    uint8 value1Slot
  ///  )'
  ///
  /// @param tag0 The arithmetically smaller tag.
  /// @param tag0 The arithmetically larger tag.
  /// @param owner The double balance owner.
  /// @return value0Slot The transient slot to host the balance of 'tag0'.
  /// @return value1Slot The transient slot to host the balance of 'tag1'.
  ///
  ///
  /// @param WRAP_NATIVE Wraps a 'value' of native token by invoking the
  /// low-level call:
  ///
  /// 'IWETH9(weth9){value: value}.deposit()'
  ///
  /// where 'value := tload(valueSlot)', and storing 'success' in the transient
  /// storage slot 'successSlot'. This action and its inputs should be encoded
  /// as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.WRAP_NATIVE,
  ///     uint8 valueSlot,
  ///     uint8 successSlot
  ///  )'
  ///
  /// @param valueSlot The amount to be wrapped.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param UNWRAP_NATIVE Unwraps an 'amount' of WETH9 by invoking the
  /// low-level call:
  ///
  /// 'IWETH9(weth9).withdraw(amount)'
  ///
  /// where 'amount := tload(amountSlot)', and storing 'success' in the
  /// transient storage slot 'successSlot'. This action and its inputs should
  /// be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.UNWRAP_NATIVE,
  ///     uint8 amountSlot,
  ///     uint8 successSlot
  ///  )'
  ///
  /// @param amountSlot The amount to be unwrapped.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param PERMIT_PERMIT2 Grants permit2 allowance to 'spender' for a given
  /// 'amount' of the owner's token via the owner's EIP-712 signature by
  /// invoking the low-level call:
  ///
  /// 'IPermit2(permit2).permit(
  ///    owner,
  ///    IPermit2.PermitSingle({
  ///      details: IPermit2.PermitDetails({
  ///        token: token,
  ///        amount: amount,
  ///        expiration: expiration,
  ///        nonce: nonce
  ///      }),
  ///      spender: spender,
  ///      sigDeadline: uint256(signatureDeadline)
  ///    }),
  ///    signature
  ///  )'
  ///
  /// and storing 'success' in the transient storage slot 'successSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.PERMIT_PERMIT2,
  ///     address owner,
  ///     uint48 nonce,
  ///     uint8 amountSlot,
  ///     address token,
  ///     uint48 expiration,
  ///     uint48 signatureDeadline,
  ///     address spender,
  ///     uint8 successSlot,
  ///     uint8 signatureByteCount,
  ///     bytes signature
  ///  )'
  ///
  /// @param owner The owner of the tokens being approved.
  /// @param nonce An incrementing value indexed per owner, token, and spender
  /// for each signature.
  /// @param amountSlot The transient slot hosting the permission amount.
  /// @param token ERC-20 token address.
  /// @param expiration Timestamp at which a spender's token allowances become
  /// invalid.
  /// @param signatureDeadline Deadline on the permit signature.
  /// @param spender Address permissioned on the allowed tokens.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @param signatureByteCount Should be equal to 'uint8(signature.length)'.
  /// @param signature The owner's signature over the permit data.
  ///
  ///
  /// @param PERMIT_BATCH_PERMIT2 Grants permit2 allowance for a batch of
  /// tokens owned by 'owner' to 'spender' via the owner's EIP-712 signature by
  /// invoking the low-level call:
  ///
  /// 'IPermit2(permit2).permit(
  ///    owner,
  ///    IPermit2.PermitBatch({
  ///      details: [
  ///        IPermit2.PermitDetails({
  ///          token: token[0],
  ///          amount: amount[0],
  ///          expiration: uint48(expiration[0]),
  ///          nonce: nonce[0]
  ///        }),
  ///        IPermit2.PermitDetails({
  ///          token: token[1],
  ///          amount: amount[1],
  ///          expiration: uint48(expiration[1]),
  ///          nonce: nonce[1]
  ///        }),
  ///
  ///         .
  ///         .
  ///         .
  ///
  ///        IPermit2.PermitDetails({
  ///          token: token[numberOfPermissions - 1],
  ///          amount: amount[numberOfPermissions - 1],
  ///          expiration: uint48(expiration[numberOfPermissions - 1]),
  ///          nonce: nonce[numberOfPermissions - 1]
  ///        })
  ///      ],
  ///      spender: spender,
  ///      sigDeadline: uint256(signatureDeadline)
  ///    }),
  ///    signature
  ///  )'
  ///
  /// and storing 'success' in the transient storage slot 'successSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.PERMIT_BATCH_PERMIT2,
  ///    address owner,
  ///    uint48 signatureDeadline,
  ///    uint8 signatureByteCount,
  ///    address spender,
  ///    uint8 successSlot,
  ///    uint8 numberOfPermissions,
  ///    abi.encodePacked(
  ///      abi.encodePacked(
  ///        address token[0],
  ///        uint8 amountSlot[0],
  ///        uint40 expiration[0],
  ///        uint48 nonce[0]
  ///      ),
  ///      abi.encodePacked(
  ///        address token[0],
  ///        uint8 amountSlot[0],
  ///        uint40 expiration[0],
  ///        uint48 nonce[0]
  ///      ),
  ///
  ///      .
  ///      .
  ///      .
  ///
  ///      abi.encodePacked(
  ///        address token[numberOfPermissions - 1],
  ///        uint8 amountSlot[numberOfPermissions - 1],
  ///        uint40 expiration[numberOfPermissions - 1],
  ///        uint48 nonce[numberOfPermissions - 1]
  ///      ),
  ///    ),
  ///    bytes signature
  ///  )'
  ///
  /// @param owner The owner of the tokens being approved.
  /// @param signatureDeadline Deadline on the permit signature.
  /// @param signatureByteCount Should be equal to 'uint8(signature.length)'.
  /// @param spender Address permissioned on the allowed tokens.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @param numberOfPermissions The number of permissions to be granted.
  /// @param token ERC-20 token addresses.
  /// @param amountSlot The transient slots hosting the permission amounts.
  /// @param expiration Timestamps at which the spender's token allowances
  /// become invalid.
  /// @param nonce A nonce corresponding to each permission.
  /// @param signature The owner's signature over the permit data.
  ///
  ///
  /// @param TRANSFER_NATIVE Sends a 'value' of native token to 'to', where
  /// 'value := tload(valueSlot)', and stores 'success' in the transient
  /// storage slot 'successSlot'. This action and its inputs should be encoded
  /// as follows:
  ///
  /// 'abi.encodePacked(
  ///     Action Action.TRANSFER_NATIVE,
  ///     address to,
  ///     uint8 amountSlot,
  ///     uint8 successSlot
  ///  )'
  ///
  /// @param valueSlot The amount to be wrapped.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param TRANSFER_FROM_PAYER_ERC20 Sends an 'amount' of ERC-20 tokens from
  /// 'payer' to 'to' where 'amount := tload(amountSlot)', by invoking the
  /// following low-level call:
  ///
  /// 'IERC20(token).transferFrom(payer, to, amount)'
  ///
  /// and storing 'success' and 'result' in the transient storage slots
  /// 'successSlot' and 'resultSlot', respectively. This action and its inputs
  /// should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.TRANSFER_FROM_PAYER_ERC20,
  ///    address token,
  ///    uint8 amountSlot,
  ///    address to,
  ///    uint8 successSlot,
  ///    uint8 resultSlot,
  ///  )'
  ///
  /// @param token The ERC-20 address.
  /// @param amountSlot The transient storage slot containing the amount to be
  /// transferred.
  /// @param to The token recipient.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return resultSlot The transient storage slot which will host 'result'.
  ///
  ///
  /// @param TRANSFER_FROM_PAYER_PERMIT2 Sends an 'amount' of ERC-20 tokens
  /// from 'payer' to 'to' via permit2, where 'amount := tload(amountSlot)', by
  /// invoking the following low-level call:
  ///
  /// 'IPermit2(permit2).transferFrom(payer, to, amount, token)'
  ///
  /// and storing 'success' in the transient storage slot 'successSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.TRANSFER_FROM_PAYER_PERMIT2,
  ///    address to,
  ///    uint8 amountSlot,
  ///    address token,
  ///    uint8 successSlot,
  ///  )'
  ///
  /// @param to The token recipient.
  /// @param amountSlot The transient storage slot containing the amount to be
  /// transferred.
  /// @param token The ERC-20 address.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param TRANSFER_FROM_PAYER_ERC6909 Sends an 'amount' of ERC-6909 tokens
  /// with the identifier 'id' from 'payer' to 'to' where
  /// 'amount := tload(amountSlot)', by invoking the following low-level call:
  ///
  /// 'IERC6909(token).transferFrom(payer, to, id, amount)'
  ///
  /// and storing 'success' and 'result' in the transient storage slots
  /// 'successSlot' and 'resultSlot', respectively. This action and its inputs
  /// should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.TRANSFER_FROM_PAYER_ERC6909,
  ///    address token,
  ///    uint256 id,
  ///    address to,
  ///    uint8 amountSlot,
  ///    uint8 successSlot,
  ///    uint8 resultSlot
  ///  )'
  ///
  /// @param token The ERC-6909 address.
  /// @param id The multi-token identifier.
  /// @param to The token recipient.
  /// @param amountSlot The transient storage slot containing the amount to be
  /// transferred.
  /// @return successSlot The transient storage slot which will host success.
  /// @return resultSlot The transient storage slot which will host the result.
  ///
  ///
  /// @param SAFE_TRANSFER_FROM_PAYER_ERC1155 Sends an 'amount' of ERC-1155
  /// tokens of identifier 'id' from 'payer' to 'to' where
  /// 'amount := tload(amountSlot)', by invoking the following low-level call:
  ///
  /// 'IERC1155(token).safeTransferFrom(payer, to, id, amount, data)'
  ///
  /// and stores 'success' in the transient storage slot 'successSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.SAFE_TRANSFER_FROM_PAYER_ERC1155,
  ///    address token,
  ///    uint256 id,
  ///    address to,
  ///    uint8 amountSlot,
  ///    uint8 successSlot,
  ///    uint24 dataByteCount,
  ///    bytes data
  ///  )'
  ///
  /// @param token The ERC-1155 address.
  /// @param id The multi-token identifier to be transferred.
  /// @param to The token recipient.
  /// @param amountSlot The transient storage slot containing the amount to be
  /// transferred.
  /// @param dataByteCount Should be equal to 'uint24(data.length)'.
  /// @param data ERC-1155 transfer data.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param CLEAR Clears an 'amount' of operator's positive transient balance
  /// in 'tag', by invoking the following low-level call:
  ///
  /// 'INofeeswap(nofeeswap).clear(tag, amount)'
  ///
  /// where 'amount := tload(amountSlot)' and stores 'success' in the transient
  /// storage slot 'successSlot'. This action and its inputs should be encoded
  /// as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.CLEAR,
  ///    Tag tag,
  ///    uint8 amountSlot,
  ///    uint8 successSlot
  ///  )'
  ///
  /// @param tag The 'tag' to be cleared.
  /// @param amountSlot The transient storage slot containing the exact amount
  /// to be cleared.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param TAKE_TOKEN Takes an 'amount' of native or ERC-20 assets from
  /// Nofeeswap to 'to' by invoking the following low-level call:
  ///
  /// 'INofeeswap(nofeeswap).take(token, to, amount)'
  ///
  /// where 'amount := tload(amountSlot)' and storing 'success' in the
  /// transient storage slot 'successSlot'. This action and its inputs should
  /// be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.TAKE_TOKEN,
  ///    address token,
  ///    address to,
  ///    uint8 amountSlot,
  ///    uint8 successSlot
  ///  )'
  ///
  /// @param token The ERC-20 address to be taken or 'address(0)' which
  /// indicates native.
  /// @param to The recipient.
  /// @param amountSlot The transient storage slot containing the amount to be
  /// taken.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param TAKE_ERC6909 Takes an 'amount' of ERC-6909 assets with the
  /// identifier 'id' from Nofeeswap to 'to' by invoking the following
  /// low-level call:
  ///
  /// 'INofeeswap(nofeeswap).take(token, id, to, amount)'
  ///
  /// where 'amount := tload(amountSlot)' and storing 'success' in the
  /// transient storage slot 'successSlot'. This action and its inputs should
  /// be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.TAKE_ERC6909,
  ///    address token,
  ///    uint256 id,
  ///    address to,
  ///    uint8 amountSlot,
  ///    uint8 successSlot
  ///  )'
  ///
  /// @param token The ERC-6909 address to be taken.
  /// @param id The multi-token identifier.
  /// @param to The recipient.
  /// @param amountSlot The transient storage slot containing the amount to be
  /// taken.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param TAKE_ERC1155 Takes an 'amount' of ERC-1155 assets with identifier
  /// 'id' from Nofeeswap to 'to' by invoking the following low-level call:
  ///
  /// 'INofeeswap(nofeeswap).take(token, id, to, amount, data)'
  ///
  /// where 'amount := tload(amountSlot)' and storing 'success' in the
  /// transient storage slot 'successSlot'. This action and its inputs should
  /// be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.TAKE_ERC1155,
  ///    address token,
  ///    uint256 id,
  ///    address to,
  ///    uint8 amountSlot,
  ///    uint8 successSlot,
  ///    uint24 dataByteCount,
  ///    bytes data
  ///  )'
  ///
  /// @param token The ERC-1155 address to be taken.
  /// @param id The multi-token identifier.
  /// @param to The recipient.
  /// @param amountSlot The transient storage slot containing the amount to be
  /// taken.
  /// @param dataByteCount Should be equal to 'uint24(data.length)'.
  /// @param data The data to be used for ERC-1155 transfer.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param SYNC_TOKEN Synchronizes the protocol's ERC-20 'token' balance by
  /// invoking:
  ///
  /// 'INofeeswap(nofeeswap).sync(token)'
  ///
  /// This action should be encoded as follows:
  ///
  /// 'abi.encodePacked(Action Action.SYNC_TOKEN, address token)'
  ///
  /// @param token The ERC-20 address to be synced.
  ///
  ///
  /// @param SYNC_MULTITOKEN Synchronizes the protocol's ERC-6909 or ERC-1155
  /// 'token' balance of identifier 'id' by invoking:
  ///
  /// 'INofeeswap(nofeeswap).sync(token, id)'
  ///
  /// This action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.SYNC_MULTITOKEN,
  ///    address token,
  ///    uint256 id
  ///  )'
  ///
  /// @param token The ERC-6909 or ERC-1155 address to be synced.
  /// @param id The multi-token identifier to be synced.
  ///
  ///
  /// @param SETTLE Should be used after ERC-20, ERC6909, or ERC1155 transfers
  /// to nofeeswap in order to update operator's transient balances. Can be
  /// used to send a 'value' of native tokens to the protocol to settle the
  /// native transient balance of the operator, where
  /// 'value := tload(valueSlot)'. Invokes the following low-level call:
  ///
  /// 'INofeeswap(nofeeswap){value: value}.settle()'
  ///
  /// and stores 'success' in the transient storage slot 'successSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.SETTLE,
  ///    uint8 valueSlot,
  ///    uint8 successSlot,
  ///    uint8 resultSlot
  ///  )'
  ///
  /// @param valueSlot The native value to be sent.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return resultSlot The transient storage slot to host the amount paid.
  ///
  ///
  /// @param TRANSFER_TRANSIENT_BALANCE Transfers transient balance of 'tag'
  /// from the operator to 'receiver'. Can be used to settle on behalf of other
  /// accounts. Invokes the following low-level call:
  ///
  /// 'INofeeswap(nofeeswap).transferTransientBalanceFrom(
  ///    address(this),
  ///    receiver,
  ///    tag,
  ///    amount
  ///  )'.
  /// 
  /// and stores 'success' in the transient storage slot 'successSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.TRANSFER_TRANSIENT_BALANCE,
  ///    Tag tag,
  ///    address receiver,
  ///    uint8 amountSlot,
  ///    uint8 successSlot
  ///  )'
  ///
  /// @param tag The 'tag' whose balance to be transferred.
  /// @param receiver The balance recipient.
  /// @param amountSlot The transient storage slot containing the amount to be
  /// transferred.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param TRANSFER_TRANSIENT_BALANCE_FROM_PAYER Transfers transient balance
  /// of 'tag' from the 'payer' to 'receiver'. Can be used to settle on behalf
  /// of other accounts. Invokes the following low-level call:
  ///
  /// 'INofeeswap(nofeeswap).transferTransientBalanceFrom(
  ///    payer,
  ///    receiver,
  ///    tag,
  ///    amount
  ///  )'.
  /// 
  /// and stores 'success' in the transient storage slot 'successSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.TRANSFER_TRANSIENT_BALANCE_FROM_PAYER,
  ///    Tag tag,
  ///    address receiver,
  ///    uint8 amountSlot,
  ///    uint8 successSlot
  ///  )'
  ///
  /// @param tag The 'tag' whose balance to be transferred.
  /// @param receiver The balance recipient.
  /// @param amountSlot The transient storage slot containing the amount to be
  /// transferred.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param MODIFY_SINGLE_BALANCE Mints/burns an 'amount' of nofeeswap's
  /// singleton balance by invoking the following low-level call:
  ///
  /// 'INofeeswap(nofeeswap).modifyBalance(payer, tag, amount)'.
  /// 
  /// where 'amount := tload(amountSlot)' and stores 'success' in the transient
  /// storage slot 'successSlot'. This action and its inputs should be encoded
  /// as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.MODIFY_SINGLE_BALANCE,
  ///    Tag tag,
  ///    uint8 amountSlot,
  ///    uint8 successSlot
  ///  )'
  ///
  /// @param tag The 'tag' whose balance to be modified.
  /// @param amountSlot The transient storage slot containing the amount to be
  /// added (positive) or removed (negative) to/from the owner's singleton
  /// balance.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param MODIFY_DOUBLE_BALANCE Mints/burns an 'amount0' of 'tag0' and an
  /// 'amount1' of 'tag1' in nofeeswap's singleton double balance by invoking
  /// the following low-level call:
  ///
  /// 'INofeeswap(nofeeswap).modifyBalance(
  ///    payer,
  ///    tag0,
  ///    tag1,
  ///    amount0,
  ///    amount1
  ///  )'.
  /// 
  /// where 'amount0 := tload(amount0Slot)' and 'amount1 := tload(amount1Slot)'
  /// and stores 'success' in the transient storage slot 'successSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.MODIFY_DOUBLE_BALANCE,
  ///    Tag tag0,
  ///    Tag tag1,
  ///    uint8 amount0Slot,
  ///    uint8 amount1Slot,
  ///    uint8 successSlot
  ///  )'
  ///
  /// @param tag0 The arithmetically smaller tag.
  /// @param tag1 The arithmetically larger tag.
  /// @param amount0Slot The transient storage slot containing the amount of
  /// 'tag0' to be added (positive) or removed (negative) to/from the owner's
  /// singleton double balance.
  /// @param amount1Slot The transient storage slot containing the amount of
  /// 'tag1' to be added (positive) or removed (negative) to/from the owner's
  /// singleton double balance.
  /// @return successSlot The transient storage slot which will host 'success'.
  ///
  ///
  /// @param SWAP Performs a swap by invoking:
  ///
  /// 'INofeeswap(nofeeswap).swap(
  ///    poolId,
  ///    amountSpecified,
  ///    limit,
  ///    (crossThreshold << 128) | zeroForOne,
  ///    hookData
  /// )'.
  ///
  /// where
  ///
  /// 'amountSpecified := tload(amountSpecifiedSlot)'
  /// 'limit := X59.wrap(int256(uint256(limitOffsetted))) + 
  ///           getLogOffsetFromPoolId(poolId) - 
  ///           sixteenX59'
  /// 'crossThreshold := tload(crossThresholdSlot)'
  ///
  /// and stores 'success', 'amount0', and 'amount1' in the transient storage
  /// slots 'successSlot', 'amount0Slot', and 'amount1Slot'. This action and
  /// its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.SWAP,
  ///    uint256 poolId,
  ///    uint8 amountSpecifiedSlot,
  ///    uint64 limitOffsetted,
  ///    uint8 zeroForOne,
  ///    uint8 crossThresholdSlot,
  ///    uint8 successSlot,
  ///    uint8 amount0Slot,
  ///    uint8 amount1Slot,
  ///    uint16 hookDataBytesCount,
  ///    bytes hookData
  ///  )'
  ///
  /// Throws if 'crossThreshold' is negative or exceeds 'type(uint128).max'.
  ///
  /// @param poolId The target pool identifier.
  /// @param amountSpecified The amount to be given to (positive) or taken 
  /// from (negative) the pool.
  /// @param limitOffsetted This value is equal to
  /// '(2 ** 59) * log(p) - getLogOffsetFromPoolId(poolId) + sixteenX59' where
  /// 'p' is the intended price limit and 'log' denotes the natural logarithm
  /// operator.
  /// @param zeroForOne If ‘zeroForOne == 0' then 'tag0' is taken from and
  /// 'tag1' is given to the pool. If ‘zeroForOne == 1' then 'tag1' is taken
  /// from and 'tag0' is given to the pool. If ‘zeroForOne >= 2’ then the
  /// direction of the swap is towards 'p' which is defined above.
  /// @param crossThresholdSlot The transient storage slot containing
  /// 'crossThreshold' which is the number of shares that should be available
  /// in any interval for the swap function to transact in that interval.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return amount0Slot The transient storage slot which will host the amount
  /// of 'tag0' swapped. Positive values are incoming to the pool and negative
  /// values are outgoing from the pool.
  /// @return amount1Slot The transient storage slot which will host the amount
  /// of 'tag1' swapped. Positive values are incoming to the pool and negative
  /// values are outgoing from the pool.
  /// @param hookDataBytesCount Should be equal to 'uint16(hookData.length)'.
  /// @param hookData The data to be passed to the hook.
  ///
  ///
  /// @param MODIFY_POSITION Mints or burns within a given liquidity range by
  /// invoking:
  ///
  /// 'INofeeswap(nofeeswap).dispatch(
  ///    abi.encodeWithSelector(
  ///      INofeeswapDelegatee.modifyPosition.selector,
  ///      poolId,
  ///      qMin,
  ///      qMax,
  ///      shares,
  ///      hookData
  ///    )
  ///  )'.
  ///
  /// where
  ///
  /// 'qMin := X59.wrap(int256(uint256(qMinOffsetted))) + 
  ///          getLogOffsetFromPoolId(poolId) - 
  ///          sixteenX59'
  /// 'qMax := X59.wrap(int256(uint256(qMaxOffsetted))) + 
  ///          getLogOffsetFromPoolId(poolId) - 
  ///          sixteenX59'
  /// 'shares := tload(sharesSlot)'
  ///
  /// and stores 'success', 'amount0', and 'amount1' in the transient storage
  /// slots 'successSlot', 'amount0Slot', and 'amount1Slot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.MODIFY_POSITION,
  ///    uint256 poolId,
  ///    uint64 qMinOffsetted,
  ///    uint64 qMaxOffsetted,
  ///    uint8 sharesSlot,
  ///    uint8 successSlot,
  ///    uint8 amount0Slot,
  ///    uint8 amount1Slot,
  ///    uint16 hookDataBytesCount,
  ///    bytes hookData
  ///  )'
  ///
  /// @param poolId The target pool identifier.
  /// @param qMinOffsetted This value is equal to
  /// '(2 ** 59) * log(pMin) - getLogOffsetFromPoolId(poolId) + sixteenX59'
  /// where 'pMin' is the left position boundary.
  /// @param qMaxOffsetted This value is equal to
  /// '(2 ** 59) * log(pMax) - getLogOffsetFromPoolId(poolId) + sixteenX59'
  /// where 'pMax' is the right position boundary.
  /// @param sharesSlot The transient storage slot containing the number of
  /// shares to be minted (positive)/burned (negative) per interval. Applies
  /// to all 'log(pMax / pMin) / qSpacing' intervals within the given range.
  /// @param hookDataBytesCount Should be equal to 'uint16(hookData.length)'.
  /// @param hookData Data to be passed to hook.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return amount0Slot The transient storage slot which will host the amount
  /// of 'tag0' added (positive)/removed (negative).
  /// @return amount1Slot The transient storage slot which will host the amount
  /// of 'tag1' added (positive)/removed (negative).
  ///
  ///
  /// @param DONATE Donates the token amounts equivalent to a number of shares
  /// to be distributed proportionally among the LPs in the current active
  /// interval by invoking:
  ///
  /// 'INofeeswap(nofeeswap).dispatch(
  ///    abi.encodeWithSelector(
  ///      INofeeswapDelegatee.donate.selector,
  ///      poolId,
  ///      shares,
  ///      hookData
  ///    )
  ///  )'.
  ///
  /// where 'shares := tload(sharesSlot)', and stores 'success', 'amount0',
  /// and 'amount1' in the transient storage slots 'successSlot',
  /// 'amount0Slot', and 'amount1Slot'. This action and its inputs should be
  /// encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.DONATE,
  ///    uint256 poolId,
  ///    uint8 sharesSlot,
  ///    uint8 successSlot,
  ///    uint8 amount0Slot,
  ///    uint8 amount1Slot,
  ///    uint16 hookDataBytesCount,
  ///    bytes hookData
  ///  )'
  ///
  /// @param poolId The target pool identifier.
  /// @param sharesSlot The transient storage slot containing the number of
  /// shares to be donated.
  /// @param hookDataBytesCount Should be equal to 'uint16(hookData.length)'.
  /// @param hookData Data to be passed to hook.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return amount0Slot The transient storage slot which will host the amount
  /// of 'tag0' donated.
  /// @return amount1Slot The transient storage slot which will host the amount
  /// of 'tag1' donated.
  ///
  ///
  /// @param QUOTE_SWAP Determines the incoming and outgoing values of a swap
  /// without executing it and making any changes to storage by invoking:
  ///
  /// 'IQuoter(quoter).swap(
  ///    poolId,
  ///    amountSpecified,
  ///    limit,
  ///    (crossThreshold << 128) | zeroForOne,
  ///    hookData
  /// )'.
  ///
  /// where
  ///
  /// 'amountSpecified := tload(amountSpecifiedSlot)'
  /// 'limit := X59.wrap(int256(uint256(limitOffsetted))) + 
  ///           getLogOffsetFromPoolId(poolId) - 
  ///           sixteenX59'
  /// 'crossThreshold := tload(crossThresholdSlot)'
  ///
  /// and stores 'success', 'amount0', and 'amount1' in the transient storage
  /// slots 'successSlot', 'amount0Slot', and 'amount1Slot'. This action and
  /// its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.QUOTE_SWAP,
  ///    uint256 poolId,
  ///    uint8 amountSpecifiedSlot,
  ///    uint64 limitOffsetted,
  ///    uint8 zeroForOne,
  ///    uint8 crossThresholdSlot,
  ///    uint8 successSlot,
  ///    uint8 amount0Slot,
  ///    uint8 amount1Slot,
  ///    uint16 hookDataBytesCount,
  ///    bytes hookData
  ///  )'
  ///
  /// Throws if 'crossThreshold' is negative or exceeds 'type(uint128).max'.
  ///
  /// @param poolId The target pool identifier.
  /// @param amountSpecified The amount to be given to (positive) or taken 
  /// from (negative) the pool.
  /// @param limitOffsetted This value is equal to
  /// '(2 ** 59) * log(p) - getLogOffsetFromPoolId(poolId) + sixteenX59' where
  /// 'p' is the intended price limit and 'log' denotes the natural logarithm
  /// operator.
  /// @param zeroForOne If ‘zeroForOne == 0' then 'tag0' is taken from and
  /// 'tag1' is given to the pool. If ‘zeroForOne == 1' then 'tag1' is taken
  /// from and 'tag0' is given to the pool. If ‘zeroForOne >= 2’ then the
  /// direction of the swap is towards 'p' which is defined above.
  /// @param crossThresholdSlot The transient storage slot containing
  /// 'crossThreshold' which is the number of shares that should be available
  /// in any interval for the swap function to transact in that interval.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return amount0Slot The transient storage slot which will host the amount
  /// of 'tag0' swapped in X127 representation. Positive values are incoming to
  /// the pool and negative values are outgoing from the pool.
  /// @return amount1Slot The transient storage slot which will host the amount
  /// of 'tag1' swapped in X127 representation. Positive values are incoming to
  /// the pool and negative values are outgoing from the pool.
  /// @param hookDataBytesCount Should be equal to 'uint16(hookData.length)'.
  /// @param hookData The data to be passed to the hook.
  ///
  ///
  /// @param QUOTE_MODIFY_POSITION Mints or burns within a given liquidity
  /// range by invoking:
  ///
  /// 'IQuoter(quoter).modifyPosition(
  ///    poolId,
  ///    qMin,
  ///    qMax,
  ///    shares,
  ///    hookData
  ///  )'.
  ///
  /// where
  ///
  /// 'qMin := X59.wrap(int256(uint256(qMinOffsetted))) + 
  ///          getLogOffsetFromPoolId(poolId) - 
  ///          sixteenX59'
  /// 'qMax := X59.wrap(int256(uint256(qMaxOffsetted))) + 
  ///          getLogOffsetFromPoolId(poolId) - 
  ///          sixteenX59'
  /// 'shares := tload(sharesSlot)'
  ///
  /// and stores 'success', 'amount0', and 'amount1' in the transient storage
  /// slots 'successSlot', 'amount0Slot', and 'amount1Slot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.MODIFY_POSITION,
  ///    uint256 poolId,
  ///    uint64 qMinOffsetted,
  ///    uint64 qMaxOffsetted,
  ///    uint8 sharesSlot,
  ///    uint8 successSlot,
  ///    uint8 amount0Slot,
  ///    uint8 amount1Slot,
  ///    uint16 hookDataBytesCount,
  ///    bytes hookData
  ///  )'
  ///
  /// @param poolId The target pool identifier.
  /// @param qMinOffsetted This value is equal to
  /// '(2 ** 59) * log(pMin) - getLogOffsetFromPoolId(poolId) + sixteenX59'
  /// where 'pMin' is the left position boundary.
  /// @param qMaxOffsetted This value is equal to
  /// '(2 ** 59) * log(pMax) - getLogOffsetFromPoolId(poolId) + sixteenX59'
  /// where 'pMax' is the right position boundary.
  /// @param sharesSlot The transient storage slot containing the number of
  /// shares to be minted (positive)/burned (negative) per interval. Applies
  /// to all 'log(pMax / pMin) / qSpacing' intervals within the given range.
  /// @param hookDataBytesCount Should be equal to 'uint16(hookData.length)'.
  /// @param hookData Data to be passed to hook.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return amount0Slot The transient storage slot which will host the amount
  /// of 'tag0' added (positive)/removed (negative) in X127 representation.
  /// @return amount1Slot The transient storage slot which will host the amount
  /// of 'tag1' added (positive)/removed (negative) in X127 representation.
  ///
  ///
  /// @param QUOTE_DONATE Donates the token amounts equivalent to a number of
  /// shares to be distributed proportionally among the LPs in the current
  /// active interval by invoking:
  ///
  /// 'IQuoter(quoter).donate(
  ///    poolId,
  ///    shares,
  ///    hookData
  ///  )'.
  ///
  /// where 'shares := tload(sharesSlot)', and stores 'success', 'amount0',
  /// and 'amount1' in the transient storage slots 'successSlot',
  /// 'amount0Slot', and 'amount1Slot'. This action and its inputs should be
  /// encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.DONATE,
  ///    uint256 poolId,
  ///    uint8 sharesSlot,
  ///    uint8 successSlot,
  ///    uint8 amount0Slot,
  ///    uint8 amount1Slot,
  ///    uint16 hookDataBytesCount,
  ///    bytes hookData
  ///  )'
  ///
  /// @param poolId The target pool identifier.
  /// @param sharesSlot The transient storage slot containing the number of
  /// shares to be donated.
  /// @param hookDataBytesCount Should be equal to 'uint16(hookData.length)'.
  /// @param hookData Data to be passed to hook.
  /// @return successSlot The transient storage slot which will host 'success'.
  /// @return amount0Slot The transient storage slot which will host the amount
  /// of 'tag0' donated in X127 representation.
  /// @return amount1Slot The transient storage slot which will host the amount
  /// of 'tag1' donated in X127 representation.
  ///
  ///
  /// @param QUOTER_TRANSIENT_ACCESS Reads the transient storage of the quoter
  /// contract by invoking:
  ///
  /// 'TransientAccess(quoter).transientAccess(transientSlot)'
  ///
  /// and stores 'result' in the transient storage slot 'resultSlot'. This
  /// action and its inputs should be encoded as follows:
  ///
  /// 'abi.encodePacked(
  ///    Action Action.QUOTER_TRANSIENT_ACCESS,
  ///    bytes32 transientSlot,
  ///    uint8 resultSlot
  ///  )'
  ///
  /// @param transientSlot The transient storage slot to be read.
  /// @param resultSlot The transient storage slot that will host 'result'.
  ///
  ///
  /// @param REVERT Reverts with the current content of 'returndata' as reason.
  /// Encoded as:
  ///
  /// 'abi.encodePacked(Action Action.REVERT)'
  ///
  enum Action {
    PUSH0,
    PUSH10,
    PUSH16,
    PUSH32,
    NEG,
    ADD,
    SUB,
    MIN,
    MAX,
    MUL,
    DIV,
    DIV_ROUND_DOWN,
    DIV_ROUND_UP,
    LT,
    EQ,
    LTEQ,
    ISZERO,
    AND,
    OR,
    XOR,
    JUMPDEST,
    JUMP,
    READ_TRANSIENT_BALANCE,
    READ_BALANCE_OF_NATIVE,
    READ_BALANCE_OF_ERC20,
    READ_BALANCE_OF_MULTITOKEN,
    READ_ALLOWANCE_ERC20,
    READ_ALLOWANCE_PERMIT2,
    READ_ALLOWANCE_ERC6909,
    READ_IS_OPERATOR_ERC6909,
    READ_IS_APPROVED_FOR_ALL_ERC1155,
    READ_DOUBLE_BALANCE,
    WRAP_NATIVE,
    UNWRAP_NATIVE,
    PERMIT_PERMIT2,
    PERMIT_BATCH_PERMIT2,
    TRANSFER_NATIVE,
    TRANSFER_FROM_PAYER_ERC20,
    TRANSFER_FROM_PAYER_PERMIT2,
    TRANSFER_FROM_PAYER_ERC6909,
    SAFE_TRANSFER_FROM_PAYER_ERC1155,
    CLEAR,
    TAKE_TOKEN,
    TAKE_ERC6909,
    TAKE_ERC1155,
    SYNC_TOKEN,
    SYNC_MULTITOKEN,
    SETTLE,
    TRANSFER_TRANSIENT_BALANCE,
    TRANSFER_TRANSIENT_BALANCE_FROM_PAYER,
    MODIFY_SINGLE_BALANCE,
    MODIFY_DOUBLE_BALANCE,
    SWAP,
    MODIFY_POSITION,
    DONATE,
    QUOTE_SWAP,
    QUOTE_MODIFY_POSITION,
    QUOTE_DONATE,
    QUOTER_TRANSIENT_ACCESS,
    REVERT
  }

  /// @notice Nofeeswap contract address.
  function nofeeswap() external returns (address);

  /// @notice Permit2 contract address.
  function permit2() external returns (address);

  /// @notice weth9 contract address.
  function weth9() external returns (address);

  /// @notice Universal quoter contract address.
  function quoter() external returns (address);
}