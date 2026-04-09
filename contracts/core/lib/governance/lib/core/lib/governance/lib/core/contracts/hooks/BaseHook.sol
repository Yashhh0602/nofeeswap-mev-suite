// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {INofeeswap} from "../interfaces/INofeeswap.sol";
import {IHook} from "../interfaces/IHook.sol";

contract BaseHook is IHook {
  /// @notice Thrown when attempting to access an invalid hook.
  error InvalidHook();

  /// @inheritdoc IHook
  function preInitialize(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function postInitialize(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function preMint(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function midMint(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function postMint(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function preBurn(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function midBurn(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function postBurn(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function preSwap(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function midSwap(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }
  
  /// @inheritdoc IHook
  function postSwap(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function midDonate(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function preDonate(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function postDonate(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function preModifyKernel(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function midModifyKernel(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }

  /// @inheritdoc IHook
  function postModifyKernel(
    bytes calldata hookInput
  ) external virtual returns (bytes4) {
    revert InvalidHook();
  }
}