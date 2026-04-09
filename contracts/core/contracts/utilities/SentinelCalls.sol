// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {ISentinel} from "../interfaces/ISentinel.sol";
import {
  _hookSelector_,
  getHookInputByteCount,
  setHookInputHeader,
  setHookSelector
} from "./Memory.sol";
import {InvalidSentinelResponse} from "./Errors.sol";
import {readSentinel} from "./Storage.sol";
import {X47, maxX47} from "./X47.sol";

ISentinel constant nullSentinel = ISentinel(address(0));

/// @notice Calls protocol's Sentinel to get 'maxPoolGrowthPortion' and 
/// 'protocolGrowthPortion'.
function invokeSentinelGetGrowthPortions() returns (
  X47 maxPoolGrowthPortion,
  X47 protocolGrowthPortion
) {
  // The outputs 'maxPoolGrowthPortion' and 'protocolGrowthPortion' are
  // initially set to the invalid value 'maxX47'. If the Sentinel contract
  // exists, these two values will be overwritten.
  maxPoolGrowthPortion = maxX47;
  protocolGrowthPortion = maxX47;

  // The Sentinel contract is read from the protocol's storage.
  ISentinel sentinel = readSentinel();

  // If the Sentinel contract exists, then 'ISentinel.getGrowthPortions' is
  // invoked and 'maxPoolGrowthPortion' and 'protocolGrowthPortion' are
  // overwritten.
  if (sentinel != nullSentinel) {
    // The appropriate selector corresponding to the method to be invoked is
    // placed in memory. 'selector' is cast as a 'uint32' because the setter
    // function 'setHookSelector' uses the least significant 32 bits as opposed
    // the most significant '32' bits.
    setHookSelector(uint32(ISentinel.getGrowthPortions.selector));

    // An abi offset of '0x20' is placed in memory in order to encode the
    // memory snapshot to be sent to the hook as type 'bytes'.
    setHookInputHeader(0x20);

    // The byte count of the memory snapshot to be sent to the Sentinel
    // contract is loaded from the memory.
    uint256 hookInputByteCount = getHookInputByteCount();

    assembly {
      // Invokes the 'ISentinel.getGrowthPortions' and relays the reason if
      // reverted.
      if iszero(
        // '_hookSelector_' points to the beginning of the calldata to be sent
        // to the Sentinel contract. The total calldata byte count is
        // 'hookInputByteCount + 4 + 32 + 32' where '4' accounts for the
        // selector, the first '32' accounts for the abi offset slot which is
        // populated with '0x20', and the second '32' accounts for the length
        // slot which is populated with 'hookInputByteCount'.
        call(
          gas(),
          sentinel,
          0,
          _hookSelector_,
          add(hookInputByteCount, 68),
          0,
          64
        )
      ) {
        // Return data is copied to memory and relayed as a revert message.
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }

      // The output of 'ISentinel.getGrowthPortions' overwrites 
      // 'maxPoolGrowthPortion' and 'protocolGrowthPortion'.
      maxPoolGrowthPortion := mload(0)
      protocolGrowthPortion := mload(32)
    }
  }
}

/// @notice Calls protocol's Sentinel to authorize initialization.
function invokeAuthorizeInitialization() {
  // The Sentinel contract is read from the protocol's storage.
  ISentinel sentinel = readSentinel();

  // If the Sentinel contract exists, then 'ISentinel.authorizeInitialization'
  // is invoked to authorize initialization.
  if (sentinel != nullSentinel) {
    // The appropriate selector corresponding to the method to be invoked is
    // placed in memory. 'selector' is cast as a 'uint32' because the setter
    // function 'setHookSelector' uses the least significant 32 bits as opposed
    // the most significant '32' bits.
    setHookSelector(uint32(ISentinel.authorizeInitialization.selector));

    // An abi offset of '0x20' is placed in memory in order to encode the
    // memory snapshot to be sent to the hook as type 'bytes'.
    setHookInputHeader(0x20);

    // The byte count of the memory snapshot to be sent to the Sentinel
    // contract is loaded from the memory.
    uint256 hookInputByteCount = getHookInputByteCount();

    bytes4 response;
    assembly {
      // Invokes the method 'ISentinel.authorizeInitialization' and relays the
      // reason if reverted.
      if iszero(
        // '_hookSelector_' points to the beginning of the calldata to be sent
        // to the Sentinel contract. The total calldata byte count is
        // 'hookInputByteCount + 4 + 32 + 32' where '4' accounts for the
        // selector, the first '32' accounts for the abi offset slot which is
        // populated with '0x20', and the second '32' accounts for length slot
        // which is populated with 'hookInputByteCount'.
        call(
          gas(),
          sentinel,
          0,
          _hookSelector_,
          add(hookInputByteCount, 68),
          0,
          32
        )
      ) {
        // Return data is copied to memory and relayed as a revert message.
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }

      response := mload(0)
    }

    // The output of 'ISentinel.authorizeInitialization' is examined.
    require(
      response == ISentinel.authorizeInitialization.selector,
      InvalidSentinelResponse(response)
    );
  }
}

/// @notice Calls protocol's Sentinel to authorize modification of pool growth
/// portion.
function invokeAuthorizeModificationOfPoolGrowthPortion() {
  // The Sentinel contract is read from the protocol's storage.
  ISentinel sentinel = readSentinel();

  // If the Sentinel contract exists, then 
  // 'ISentinel.authorizeModificationOfPoolGrowthPortion'
  // is invoked to authorize initialization.
  if (sentinel != nullSentinel) {
    // The appropriate selector corresponding to the method to be invoked is
    // placed in memory. 'selector' is cast as a 'uint32' because the setter
    // function 'setHookSelector' uses the least significant 32 bits as opposed
    // the most significant '32' bits.
    setHookSelector(
      uint32(ISentinel.authorizeModificationOfPoolGrowthPortion.selector)
    );

    // An abi offset of '0x20' is placed in memory in order to encode the
    // memory snapshot to be sent to the hook as type 'bytes'.
    setHookInputHeader(0x20);

    // The byte count of the memory snapshot to be sent to the Sentinel
    // contract is loaded from the memory.
    uint256 hookInputByteCount = getHookInputByteCount();

    bytes4 response;
    assembly {
      // Invokes the method 
      // 'ISentinel.authorizeModificationOfPoolGrowthPortion' and relays the
      // reason if reverted.
      if iszero(
        // '_hookSelector_' points to the beginning of the calldata to be sent
        // to the Sentinel contract. The total calldata byte count is
        // 'hookInputByteCount + 4 + 32 + 32' where '4' accounts for the
        // selector, the first '32' accounts for the abi offset slot which is
        // populated with '0x20', and the second '32' accounts for length slot
        // which is populated with 'hookInputByteCount'.
        call(
          gas(),
          sentinel,
          0,
          _hookSelector_,
          add(hookInputByteCount, 68),
          0,
          32
        )
      ) {
        // Return data is copied to memory and relayed as a revert message.
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }

      response := mload(0)
    }

    // The output of 'ISentinel.authorizeModificationOfPoolGrowthPortion' is
    // examined.
    require(
      response == ISentinel.authorizeModificationOfPoolGrowthPortion.selector,
      InvalidSentinelResponse(response)
    );
  }
}