// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {_hookInputByteCount_} from "../utilities/Memory.sol";
import {writeProtocol, writeSentinel} from "../utilities/Storage.sol";
import "../utilities/SentinelCalls.sol";

/// @title This contract exposes the internal functions of 'SentinelCalls.sol'
/// for testing purposes.
contract SentinelCallsWrapper {
  function _invokeSentinelGetGrowthPortions(
    ISentinel sentinel,
    bytes calldata content
  ) public returns (
    X47 maxPoolGrowthPortion,
    X47 protocolGrowthPortion
  ) {
    writeSentinel(sentinel);
    uint256 hookInputByteCount;
    assembly {
      let hookInputStart := add(4, calldataload(36))
      calldatacopy(
        _hookInputByteCount_,
        hookInputStart,
        add(32, calldataload(hookInputStart))
      )
    }
    return invokeSentinelGetGrowthPortions();
  }

  function _invokeAuthorizeInitialization(
    ISentinel sentinel,
    bytes calldata content
  ) public {
    writeSentinel(sentinel);
    uint256 hookInputByteCount;
    assembly {
      let hookInputStart := add(4, calldataload(36))
      calldatacopy(
        _hookInputByteCount_,
        hookInputStart,
        add(32, calldataload(hookInputStart))
      )
    }
    invokeAuthorizeInitialization();
  }

  function _invokeAuthorizeModificationOfPoolGrowthPortion(
    ISentinel sentinel,
    bytes calldata content
  ) public {
    writeSentinel(sentinel);
    uint256 hookInputByteCount;
    assembly {
      let hookInputStart := add(4, calldataload(36))
      calldatacopy(
        _hookInputByteCount_,
        hookInputStart,
        add(32, calldataload(hookInputStart))
      )
    }
    invokeAuthorizeModificationOfPoolGrowthPortion();
  }
}

contract MockSentinel2 is ISentinel {
  X47 public maxPoolGrowthPortion;
  X47 public protocolGrowthPortion;
  bytes4 public authorizeInitializationSelector;
  bytes4 public authorizeModificationOfPoolGrowthPortionSelector;
  bool public reverting;
  bytes public revertMessage;

  function setValues(
    X47 _maxPoolGrowthPortion,
    X47 _protocolGrowthPortion,
    bytes4 selector0,
    bytes4 selector1,
    bool _reverting,
    bytes calldata _revertMessage
  ) external {
    maxPoolGrowthPortion = _maxPoolGrowthPortion;
    protocolGrowthPortion = _protocolGrowthPortion;
    authorizeInitializationSelector = selector0;
    authorizeModificationOfPoolGrowthPortionSelector = selector1;
    reverting = _reverting;
    revertMessage = _revertMessage;
  }

  function getGrowthPortions(
    bytes calldata sentinelInput
  ) external returns (
    X47 _maxPoolGrowthPortion,
    X47 _protocolGrowthPortion
  ) {
    if (reverting) {
      bytes memory _revertMessage = revertMessage;
      uint256 length = _revertMessage.length;
      assembly {
        revert(add(_revertMessage, 32), length)
      }
    } else {
      bytes memory input = sentinelInput;
      uint256 length = input.length;
      assembly {
        log1(add(input, 32), length, 0)
      }
      return (maxPoolGrowthPortion, protocolGrowthPortion);
    }
  }

  function authorizeInitialization(
    bytes calldata sentinelInput
  ) external returns (bytes4 selector) {
    if (reverting) {
      bytes memory _revertMessage = revertMessage;
      uint256 length = _revertMessage.length;
      assembly {
        revert(add(_revertMessage, 32), length)
      }
    } else {
      bytes memory input = sentinelInput;
      uint256 length = input.length;
      assembly {
        log1(add(input, 32), length, 0)
      }
      return authorizeInitializationSelector;
    }
  }

  function authorizeModificationOfPoolGrowthPortion(
    bytes calldata sentinelInput
  ) external returns (bytes4 selector) {
    if (reverting) {
      bytes memory _revertMessage = revertMessage;
      uint256 length = _revertMessage.length;
      assembly {
        revert(add(_revertMessage, 32), length)
      }
    } else {
      bytes memory input = sentinelInput;
      uint256 length = input.length;
      assembly {
        log1(add(input, 32), length, 0)
      }
      return authorizeModificationOfPoolGrowthPortionSelector;
    }
  }
}