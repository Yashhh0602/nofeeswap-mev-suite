// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {IHook} from "../interfaces/IHook.sol";
import {BaseHook} from "../hooks/BaseHook.sol";

/// @title This contract is a notional nofeeswap hook for test purposes.
contract MockHook is BaseHook {
  uint256 public _preInitialize;
  uint256 public _postInitialize;
  uint256 public _preMint;
  uint256 public _midMint;
  uint256 public _postMint;
  uint256 public _preBurn;
  uint256 public _midBurn;
  uint256 public _postBurn;
  uint256 public _preSwap;
  uint256 public _midSwap;
  uint256 public _postSwap;
  uint256 public _preDonate;
  uint256 public _midDonate;
  uint256 public _postDonate;
  uint256 public _preModifyKernel;
  uint256 public _midModifyKernel;
  uint256 public _postModifyKernel;

  bytes public preInitializeData;
  bytes public preMintData;
  bytes public preBurnData;
  bytes public preSwapData;
  bytes public preDonateData;
  bytes public preModifyKernelData;
  bytes public midMintData;
  bytes public midBurnData;
  bytes public midSwapData;
  bytes public midDonateData;
  bytes public midModifyKernelData;
  bytes public postInitializeData;
  bytes public postMintData;
  bytes public postBurnData;
  bytes public postSwapData;
  bytes public postDonateData;
  bytes public postModifyKernelData;

  function preInitialize(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_preInitialize;
    preInitializeData = hookInput;
    return IHook.preInitialize.selector;
  }

  function postInitialize(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_postInitialize;
    postInitializeData = hookInput;
    return IHook.postInitialize.selector;
  }

  function preMint(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_preMint;
    preMintData = hookInput;
    return IHook.preMint.selector;
  }

  function midMint(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_midMint;
    midMintData = hookInput;
    return IHook.midMint.selector;
  }

  function postMint(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_postMint;
    postMintData = hookInput;
    return IHook.postMint.selector;
  }

  function preBurn(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_preBurn;
    preBurnData = hookInput;
    return IHook.preBurn.selector;
  }

  function midBurn(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_midBurn;
    midBurnData = hookInput;
    return IHook.midBurn.selector;
  }

  function postBurn(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_postBurn;
    postBurnData = hookInput;
    return IHook.postBurn.selector;
  }

  function preSwap(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_preSwap;
    preSwapData = hookInput;
    return IHook.preSwap.selector;
  }

  function midSwap(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_midSwap;
    midSwapData = hookInput;
    return IHook.midSwap.selector;
  }

  function postSwap(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_postSwap;
    postSwapData = hookInput;
    return IHook.postSwap.selector;
  }

  function preDonate(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_preDonate;
    preDonateData = hookInput;
    return IHook.preDonate.selector;
  }

  function midDonate(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_midDonate;
    midDonateData = hookInput;
    return IHook.midDonate.selector;
  }

  function postDonate(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_postDonate;
    postDonateData = hookInput;
    return IHook.postDonate.selector;
  }

  function preModifyKernel(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_preModifyKernel;
    preModifyKernelData = hookInput;
    return IHook.preModifyKernel.selector;
  }

  function midModifyKernel(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_midModifyKernel;
    midModifyKernelData = hookInput;
    return IHook.midModifyKernel.selector;
  }

  function postModifyKernel(
    bytes calldata hookInput
  ) external override returns (bytes4) {
    ++_postModifyKernel;
    postModifyKernelData = hookInput;
    return IHook.postModifyKernel.selector;
  }
}