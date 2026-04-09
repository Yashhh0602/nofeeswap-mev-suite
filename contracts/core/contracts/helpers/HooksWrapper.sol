// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {BaseHook} from "../hooks/BaseHook.sol";
import {_hookInputByteCount_, setPoolId} from "../utilities/Memory.sol";
import "../utilities/Hooks.sol";

/// @title This contract exposes internal functions of 'Hooks.sol' for testing.
contract HooksWrapper {
  function _getHook(
    uint256 poolId
  ) public returns (
    IHook hookAddress
  ) {
    setPoolId(poolId);
    return getHook();
  }

  function _invokeHook(
    uint256 poolId,
    bytes4 selector,
    bytes calldata content
  ) public {
    uint256 hookInputByteCount;
    assembly {
      let hookInputStart := add(4, calldataload(68))
      calldatacopy(
        _hookInputByteCount_,
        hookInputStart,
        add(32, calldataload(hookInputStart))
      )
    }
    setPoolId(poolId);
    invokeHook(selector);
  }

  function _validateFlags(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    validateFlags();
  }

  function _isPreInitialize(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPreInitialize();
  }

  function _isPostInitialize(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPostInitialize();
  }

  function _isPreMint(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPreMint();
  }

  function _isMidMint(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isMidMint();
  }

  function _isPostMint(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPostMint();
  }

  function _isPreBurn(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPreBurn();
  }

  function _isMidBurn(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isMidBurn();
  }

  function _isPostBurn(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPostBurn();
  }

  function _isPreSwap(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPreSwap();
  }

  function _isMidSwap(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isMidSwap();
  }

  function _isPostSwap(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPostSwap();
  }

  function _isPreDonate(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPreDonate();
  }

  function _isMidDonate(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isMidDonate();
  }

  function _isPostDonate(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPostDonate();
  }

  function _isPreModifyKernel(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPreModifyKernel();
  }

  function _isMidModifyKernel(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isMidModifyKernel();
  }

  function _isPostModifyKernel(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isPostModifyKernel();
  }

  function _isMutableKernel(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isMutableKernel();
  }

  function _isMutablePoolGrowthPortion(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isMutablePoolGrowthPortion();
  }

  function _isDonateAllowed(
    uint256 poolId
  ) public returns (
    bool flag
  ) {
    setPoolId(poolId);
    return isDonateAllowed();
  }

  function __isPreInitialize(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePreInitialize();
  }

  function __isPostInitialize(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePostInitialize();
  }

  function __isPreMint(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePreMint();
  }

  function __isMidMint(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokeMidMint();
  }

  function __isPostMint(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePostMint();
  }

  function __isPreBurn(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePreBurn();
  }

  function __isMidBurn(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokeMidBurn();
  }

  function __isPostBurn(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePostBurn();
  }

  function __isPreSwap(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePreSwap();
  }

  function __isMidSwap(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokeMidSwap();
  }

  function __isPostSwap(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePostSwap();
  }

  function __isPreDonate(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePreDonate();
  }

  function __isMidDonate(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokeMidDonate();
  }

  function __isPostDonate(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePostDonate();
  }

  function __isPreModifyKernel(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePreModifyKernel();
  }

  function __isMidModifyKernel(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokeMidModifyKernel();
  }

  function __isPostModifyKernel(
    uint256 poolId
  ) public {
    setPoolId(poolId);
    invokePostModifyKernel();
  }
}

contract MockHook2 is BaseHook {
  bytes4 public selector;
  bool public reverting;
  bool public returnSelector;
  bytes public message;

  function setValues(
    bytes4 _selector,
    bool _reverting,
    bool _returnSelector,
    bytes calldata _message
  ) external {
    selector = _selector;
    reverting = _reverting;
    returnSelector = _returnSelector;
    message = _message;
  }

  function arbitrary(
    bytes calldata hookInput
  ) external returns (bytes4) {
    if (reverting) {
      bytes memory _message = message;
      uint256 length = _message.length;
      assembly {
        revert(add(_message, 32), length)
      }
    } else {
      bytes memory input = hookInput;
      uint256 length = input.length;
      assembly {
        log1(add(input, 32), length, 0)
      }
      if (returnSelector) {
        return selector;
      } else {
        bytes memory output = message;
        length = output.length;
        assembly {
          return(add(output, 32), length)
        }
      }
    }
  }

  function preInitialize(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.preInitialize.selector;
  }

  function postInitialize(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.postInitialize.selector;
  }

  function preMint(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.preMint.selector;
  }

  function midMint(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.midMint.selector;
  }

  function postMint(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.postMint.selector;
  }

  function preBurn(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.preBurn.selector;
  }

  function midBurn(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.midBurn.selector;
  }

  function postBurn(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.postBurn.selector;
  }

  function preSwap(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.preSwap.selector;
  }

  function midSwap(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.midSwap.selector;
  }

  function postSwap(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.postSwap.selector;
  }

  function preDonate(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.preDonate.selector;
  }

  function midDonate(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.midDonate.selector;
  }

  function postDonate(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.postDonate.selector;
  }

  function preModifyKernel(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.preModifyKernel.selector;
  }

  function midModifyKernel(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.midModifyKernel.selector;
  }

  function postModifyKernel(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    return IHook.postModifyKernel.selector;
  }
}