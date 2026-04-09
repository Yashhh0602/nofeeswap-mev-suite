// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {ISentinel} from "./ISentinel.sol";
import {Tag} from "../utilities/Tag.sol";
import {X59} from "../utilities/X59.sol";
import {IStorageAccess} from "./IStorageAccess.sol";
import {ITransientAccess} from "./ITransientAccess.sol";

/// @notice Interface for the Nofeeswap contract.
interface INofeeswap is IStorageAccess, ITransientAccess {
  /// @notice See ERC6909 specifications.
  function supportsInterface(
    bytes4 interfaceId
  ) external pure returns (bool);

  /// @notice See ERC6909 specifications.
  function balanceOf(
    address owner,
    Tag tag
  ) external view returns (
    uint256 amount
  );

  /// @notice See ERC6909 specifications.
  function allowance(
    address owner,
    address spender,
    Tag tag
  ) external view returns (
    uint256 amount
  );

  /// @notice See ERC6909 specifications.
  function isOperator(
    address owner,
    address spender
  ) external view returns (
    bool status
  );

  /// @notice See ERC6909 specifications.
  function transfer(
    address receiver,
    Tag tag,
    uint256 amount
  ) external returns (
    bool success
  );

  /// @notice See ERC6909 specifications.
  function transferFrom(
    address sender,
    address receiver,
    Tag tag,
    uint256 amount
  ) external returns (
    bool success
  );

  /// @notice See ERC6909 specifications.
  function approve(
    address spender,
    Tag tag,
    uint256 amount
  ) external returns (
    bool success
  );

  /// @notice See ERC6909 specifications.
  function setOperator(
    address spender,
    bool approved
  ) external returns (
    bool success
  );

  /// @notice Mints/burns singleton balance. This results in a transient
  /// storage balance which must be settled.
  ///
  /// transient balance <-> singleton balance
  ///
  /// @param owner Balance owner.
  /// @param tag The tag whose balance to be modified.
  /// @param amount The amount to be added (positive) or removed (negative)
  /// to/from the owner's singleton balance.
  function modifyBalance(
    address owner,
    Tag tag,
    int256 amount
  ) external;

  /// @notice Mints/burns singleton double balance of tags 0 and 1. Can be used
  /// for gas efficient transactions by eliminating the need to update two 
  /// storage slots. This results in transient storage balances which must be 
  /// settled.
  ///
  /// transient balance of tags 0 and 1 <-> singleton double balance
  ///
  /// @param owner Balance owner.
  /// @param tag0 The arithmetically smaller tag.
  /// @param tag1 The arithmetically larger tag.
  /// @param amount0 The amount of tag0 to be added (positive) or removed 
  /// (negative) to/from the owner's singleton balance.
  /// @param amount1 The amount of tag1 to be added (positive) or removed 
  /// (negative) to/from the owner's singleton balance.
  function modifyBalance(
    address owner,
    Tag tag0,
    Tag tag1,
    int256 amount0,
    int256 amount1
  ) external;

  /// @notice This function gives access to the following protocol methods that
  /// are safeguarded against reentrancy:
  ///
  ///   'INofeeswap.clear(Tag,uint256)'
  ///   'INofeeswap.take(address,address,uint256)'
  ///   'INofeeswap.take(address,uint256,address,uint256)'
  ///   'INofeeswap.take(address,uint256,address,uint256,bytes)'
  ///   'INofeeswap.settle(address)'
  ///   'INofeeswap.transferTransientBalanceFrom(address,address,Tag,uint256)'
  ///   'INofeeswap.modifyBalance(address,Tag,int256)'
  ///   'INofeeswap.modifyBalance(address,Tag,Tag,int256,int256)'
  ///   'INofeeswap.swap(uint256,int256,X59,uint256,bytes)'
  ///   'INofeeswapDelegatee.modifyPosition(uint256,X59,X59,int256,bytes)'
  ///   'INofeeswapDelegatee.donate(uint256,uint256,bytes)'
  ///
  /// @param unlockTarget The target contract address which must implement 
  /// 'IUnlockCallback.sol'.
  /// @param data The data/instructions to be passed to the target contract.
  /// @return result The output from the target contract.
  function unlock(
    address unlockTarget,
    bytes calldata data
  ) external payable returns (
    bytes memory result
  );

  /// @notice WARNING - Once a balance is cleared, the corresponding funds
  /// become permanently inaccessible and remain locked within the contract.
  /// Executing a clear call will erase the entire balance owed to the caller
  /// without initiating any outbound transfer.
  /// @notice Clears transient balance owed to 'msg.sender'.
  /// @param tag The tag whose transient balance to be cleared.
  /// @param amount The amount to be cleared which must be equal to the current
  /// transient balance of the caller.
  function clear(
    Tag tag,
    uint256 amount
  ) external;

  /// @notice Pays native or ERC-20 assets from the protocol to 'to'. This
  /// results in a transient storage balance which must be settled.
  ///
  /// transient balance -> 'to' wallet
  ///
  /// @param token ERC-20 or native tokens to be taken from the protocol's
  /// wallet.
  /// @param to The target address.
  /// @param amount The amount of tokens to be taken from the protocol.
  function take(
    address token,
    address to,
    uint256 amount
  ) external;

  /// @notice Pays ERC-6909 assets from the protocol to 'to'. This results in a
  /// transient storage balance which must be settled.
  ///
  /// transient balance -> 'to' wallet
  ///
  /// @param token ERC-6909 address.
  /// @param tokenId Multi-token id to be taken from the protocol's wallet.
  /// @param to The target address.
  /// @param amount The amount of tokens to be taken from the protocol.
  function take(
    address token,
    uint256 tokenId,
    address to,
    uint256 amount
  ) external;

  /// @notice Pays ERC-1155 assets from the protocol to 'to'. This results in a
  /// transient storage balance which must be settled.
  ///
  /// transient balance -> 'to' wallet
  ///
  /// @param token ERC-1155 address.
  /// @param tokenId Multi-token id to be taken from the protocol's wallet.
  /// @param to The target address.
  /// @param amount The amount of tokens to be taken from the protocol.
  /// @param transferData Data to be used from 'IERC1155.safeTransferFrom'.
  function take(
    address token,
    uint256 tokenId,
    address to,
    uint256 amount,
    bytes calldata transferData
  ) external;

  /// @notice Synchronizes the protocol ERC-20 balance. Should be called prior
  /// to ERC-20 transfers to the protocol.
  /// @param token ERC-20 address to be synced.
  function sync(
    address token
  ) external;

  /// @notice Synchronizes the protocol ERC-1155 or ERC-6909 balance. Should be 
  /// called prior to ERC-1155 or ERC-6909 transfers to the protocol.
  /// @param token ERC-1155 or ERC-6909 address to be synced.
  /// @param tokenId Multi-token id to be synced.
  function sync(
    address token,
    uint256 tokenId
  ) external;

  /// @notice Should be called after ERC-20, ERC6909, or ERC1155 transfers to
  /// the protocol to update transient balances. Can be used to send native
  /// tokens to the protocol to settle native transient balance of 
  /// 'msg.sender'.
  /// @return paid The amount paid.
  function settle() external payable returns (
    uint256 paid
  );

  /// @notice Transfers transient balance from 'sender' to 'receiver'. Can be
  /// used to settle on behalf of other accounts.
  /// @param sender The sender's address.
  /// @param receiver The recipient's address.
  /// @param tag The tag whose balance to be transferred.
  /// @param amount The amount to be transferred.
  function transferTransientBalanceFrom(
    address sender,
    address receiver,
    Tag tag,
    uint256 amount
  ) external;

  /// @notice Gives access to 'NofeeswapDelegatee.sol' functionalities.
  /// @param input Encoded input via 'abi.encodeWithSelector' to be passed as 
  /// delegate call to 'NofeeswapDelegatee.sol'.
  /// @return output0 The first output slot.
  /// @return output1 The second output slot.
  function dispatch(
    bytes calldata input
  ) external returns (
    int256 output0,
    int256 output1
  );

  /// @notice Performs a swap.
  /// @param poolId The target pool identifier.
  /// @param amountSpecified The amount to be given to (positive) or taken 
  /// from (negative) the pool.
  /// @param logPriceLimit The limit logPrice constraint. This value is equal
  /// to '(2 ** 59) * log(p)' where 'p' is the intended price limit and 'log'
  /// denotes the natural logarithm operator.
  /// @param zeroForOne If ‘zeroForOne & ((1 << 128) - 1) == 0' then tag0 is
  /// taken from and tag1 is given to the pool. If 
  /// ‘zeroForOne & ((1 << 128) - 1) == 1' then tag1 is taken from and tag0 is
  /// given to the pool. If ‘zeroForOne & ((1 << 128) - 1)’ is greater than 1,
  /// then the direction of the swap is towards 'logPriceLimit'.
  /// ‘(zeroForOne >> 128)’ is a threshold on the number of shares that should
  /// be available in any interval for the swap function to transact in that 
  /// interval. For example, if (zeroForOne >> 128 == 0), which is the default,
  /// no minimum number of shares is imposed.
  /// @param hookData The data to be passed to the hook.
  /// @return amount0 The amount of tag0 swapped. Positive values are incoming
  /// to the pool and negative values are outgoing from the pool.
  /// @return amount1 The amount of tag1 swapped. Positive values are incoming
  /// to the pool and negative values are outgoing from the pool.
  function swap(
    uint256 poolId,
    int256 amountSpecified,
    X59 logPriceLimit,
    uint256 zeroForOne,
    bytes calldata hookData
  ) external returns (
    int256 amount0,
    int256 amount1
  );

  /// @notice Emitted when a tag is transferred.
  /// @notice See ERC6909 specifications.
  event Transfer(
    address caller,
    address indexed from,
    address indexed to,
    Tag indexed tag,
    uint256 amount
  );

  /// @notice Emitted when an operator is assigned/absolved by the owner.
  /// @notice See ERC6909 specifications.
  event OperatorSet(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  /// @notice Emitted when a spender's permission is updated by the owner.
  /// @notice See ERC6909 specifications.
  event Approval(
    address indexed owner,
    address indexed spender,
    Tag indexed tag,
    uint256 amount
  );

  /// @notice Emitted when owner's double balance is modified.
  /// @param caller The caller of 'INofeeswap.modifyBalance'.
  /// @param owner The double balance owner.
  /// @param tag The corresponding tag.
  /// @param increment The amount being incremented/decremented.
  /// @param balance The resulting balance.
  event ModifyDoubleBalanceEvent(
    address indexed caller,
    address indexed owner,
    Tag indexed tag,
    int256 increment,
    uint256 balance
  );

  /// @notice Emitted when the pool owner's accrued growth portions are
  /// collected.
  /// @param poolId The target pool identifier.
  /// @param owner Current owner of the target pool.
  /// @param amount0 The total amount of tag0 collected.
  /// @param amount1 The total amount of tag1 collected.
  event PoolCollection(
    uint256 indexed poolId,
    address indexed owner,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted when the protocol owner's accrued growth portions are
  /// collected.
  /// @param poolId The target pool identifier.
  /// @param amount0 The total amount of tag0 collected.
  /// @param amount1 The total amount of tag1 collected.
  event ProtocolCollection(
    uint256 indexed poolId,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted when protocol slot is updated.
  /// @param newOwner The new protocol owner.
  /// @param newProtocol The new protocol slot.
  event ModifyProtocol(
    address indexed newOwner,
    uint256 newProtocol
  );

  /// @notice Emitted when the sentinel contract is updated.
  /// @param oldSentinel The old sentinel contract.
  /// @param newSentinel The new sentinel contract.
  event ModifySentinel(
    ISentinel oldSentinel,
    ISentinel newSentinel
  );

  /// @notice Emitted when a pool owner is updated.
  /// @param poolId The target pool identifier.
  /// @param oldOwner The old owner of the target pool.
  /// @param newOwner The new owner of the target pool.
  event ModifyPoolOwner(
    uint256 indexed poolId,
    address indexed oldOwner,
    address indexed newOwner
  );

  /// @notice Emitted when a nofeeswap pool is initialized.
  /// @param poolId The target pool identifier.
  /// @param tag0 The arithmetically smaller tag.
  /// @param tag1 The arithmetically larger tag.
  /// @param data A snapshot of memory which includes 'staticParams', 'kernel',
  /// 'kernelCompact', and 'curve'.
  event Initialize(
    uint256 indexed poolId,
    Tag indexed tag0,
    Tag indexed tag1,
    bytes data
  );

  /// @notice Emitted when a nofeeswap position is created, burned or modified.
  /// @param poolId The target pool identifier.
  /// @param caller Caller of the external 'modifyPosition' function.
  /// @param data A snapshot of memory which includes the following parameters
  /// (as defined in 'Memory.sol') that are tightly packed together:
  ///  - 'logPriceMinOffsetted' in 'X59' representation (8 bytes)
  ///  - 'logPriceMaxOffsetted' in 'X59' representation (8 bytes)
  ///  - 'shares' in 'int256' representation (32 bytes)
  ///  - 'logPriceMin' in 'X59' representation (32 bytes)
  ///  - 'logPriceMax' in 'X59' representation (32 bytes)
  ///  - 'positionAmount0' in 'X127' representation (32 bytes)
  ///  - 'positionAmount1' in 'X127' representation (32 bytes)
  event ModifyPosition(
    uint256 indexed poolId,
    address indexed caller,
    bytes32[6] data
  );

  /// @notice Emitted with donates.
  /// @param poolId The target pool identifier.
  /// @param caller Caller of the external 'donate' function.
  /// @param data A snapshot of memory which contains the new value for
  /// 'growth'.
  /// This is sufficient to determine all of the donate parameters.
  event Donate(
    uint256 indexed poolId,
    address indexed caller,
    bytes32 data
  );

  /// @notice Emitted when a swap is performed. The last two members of the
  /// curve are logged which are sufficient to uniquely characterize the state.
  /// In other words, if we know both 'qTarget' and 'qOvershoot' that appear at
  /// the end of the amended curve, then we can deterministically track the
  /// state of each pool without having to perform any numerical search.
  /// @param poolId The target pool identifier.
  /// @param caller Caller of the external 'swap' function.
  /// @param data A snapshot of memory which includes the last two members of
  /// the amended curve (i.e., 'qOvershoot' and 'qTarget'). This is sufficient
  /// to reproduce the swap.
  event Swap(
    uint256 indexed poolId,
    address indexed caller,
    bytes32 data
  );

  /// @notice Emitted when a pending kernel is introduced for a nofeeswap pool.
  /// @param poolId The target pool identifier.
  /// @param caller Current owner of the target pool.
  /// @param data A snapshot of memory which includes 'staticParams', 'kernel',
  /// and 'kernelCompact'.
  event ModifyKernel(
    uint256 indexed poolId,
    address indexed caller,
    bytes data
  );

  /// @notice Emitted when a nofeeswap pool growth portion is modified.
  /// @param poolId The target pool identifier.
  /// @param caller Current owner of the target pool.
  /// @param data A snapshot of memory which contains the new value for 
  /// 'poolGrowthPortion'.
  event ModifyPoolGrowthPortion(
    uint256 indexed poolId,
    address indexed caller,
    bytes32 data
  );

  /// @notice Emitted when the growth portions for a nofeeswap pool are synced
  /// with the protocol or sentinel contract.
  /// @param poolId The target pool identifier.
  /// @param caller Current owner of the target pool.
  /// @param data A snapshot of memory which contains the new values for 
  /// 'maxPoolGrowthPortion' and 'protocolGrowthPortion'.
  event UpdateGrowthPortions(
    uint256 indexed poolId,
    address indexed caller,
    bytes32 data
  );
}