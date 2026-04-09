// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

interface IUnlockCallback {
  /// @notice In order to interact with any of the following functions of 
  /// 'nofeeswap' and 'nofeeswapDelegatee', an account must first invoke
  /// 'INofeeswap.unlock(unlockTarget, data)' to unlock the protocol:
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
  /// The function 'INofeeswap.unlock' invokes
  /// 'IUnlockCallback(unlockTarget).unlockCallback(caller, data)' through
  /// which any account may interact with the above methods.
  ///
  /// The default target which implements 'unlockCallback' is 'Operator.sol'
  /// for which a sequence of instructions should be encoded as 'data'.
  ///
  /// All transient balances must be settled within 'unlockCallback' for the
  /// 'INofeeswap.unlock(unlockTarget, data)' call to not revert. In other
  /// words, all balances in transient storage for all accounts should net to
  /// zero so that 'INofeeswap.unlock(unlockTarget, data)' does not revert.
  ///
  /// @param caller The 'caller' of the protocol's
  /// 'INofeeswap.unlock(unlockTarget, data)' method.
  /// @param data The input data that was passed to the protocol's
  /// 'INofeeswap.unlock(unlockTarget, data)' method as input.
  /// @return returnData The output that should be returned to the 'caller'.
  function unlockCallback(
    address caller,
    bytes calldata data
  ) external payable returns (
    bytes memory returnData
  );
}
