// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

/// @notice Each hook is invoked depending on whether its corresponding poolId
/// flag is nonzero.
/// @dev All of these functions should be callable by nofeeswap only.
/// @dev Each pre hook is invoked while the corresponding pool is unlocked. A
/// snapshot of all the input data is provided. Other parameters can be read
/// externally.
/// @dev Each mid hook is invoked while the corresponding pool is locked. A
/// snapshot of memory containing all of the pool parameters prior to the
/// action is provided to the hook contract.
/// @dev Each post hook is invoked while the corresponding pool is unlocked. A
/// snapshot of memory containing all of the pool parameters after the action
/// is provided to the hook contract.
interface IHook {
  /// @notice This hook is invoked if: poolId & (1 << 160) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.preInitialize.selector' is returned.
  function preInitialize(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 161) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.postInitialize.selector' is returned.
  function postInitialize(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 162) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.preMint.selector' is returned.
  function preMint(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 163) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.midMint.selector' is returned.
  function midMint(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 164) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.postMint.selector' is returned.
  function postMint(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 165) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.preBurn.selector' is returned.
  function preBurn(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 166) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.midBurn.selector' is returned.
  function midBurn(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 167) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.postBurn.selector' is returned.
  function postBurn(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 168) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.preSwap.selector' is returned.
  function preSwap(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 169) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.midSwap.selector' is returned.
  function midSwap(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 170) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.postSwap.selector' is returned.
  function postSwap(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 171) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.preDonate.selector' is returned.
  function preDonate(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 172) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.midDonate.selector' is returned.
  function midDonate(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 173) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.postDonate.selector' is returned.
  function postDonate(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 174) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.preModifyKernel.selector' is returned.
  function preModifyKernel(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 175) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.midModifyKernel.selector' is returned.
  function midModifyKernel(
    bytes calldata hookInput
  ) external returns (bytes4 selector);

  /// @notice This hook is invoked if: poolId & (1 << 176) != 0
  /// @param hookInput A memory snapshot passed to the hook via calldata. Each
  /// individual parameter is accessible via 'HookCalldata.sol'.
  /// @return selector The preceding call is reverted unless 
  /// 'IHook.postModifyKernel.selector' is returned.
  function postModifyKernel(
    bytes calldata hookInput
  ) external returns (bytes4 selector);
}