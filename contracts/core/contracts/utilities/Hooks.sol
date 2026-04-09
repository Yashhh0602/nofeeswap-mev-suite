// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {IHook} from "../interfaces/IHook.sol";
import {
  _hookSelector_,
  getPoolId,
  getHookInputByteCount,
  setHookInputHeader,
  setHookSelector
} from "./Memory.sol";
import {InvalidFlags} from "./Errors.sol";

/// @notice Extracts hook address from poolId.
function getHook() pure returns (IHook hookAddress) {
  // The least significant '160' bits of 'poolId' is cast as an address.
  return IHook(address(uint160(getPoolId() & type(uint160).max)));
}

/// @notice Makes a call to the hook.
function invokeHook(bytes4 selector) {
  // The appropriate selector corresponding to the method to be invoked is
  // placed in memory. 'selector' is cast as a 'uint32' because the setter
  // function 'setHookSelector' uses the least significant 32 bits as opposed
  // the most significant '32' bits.
  setHookSelector(uint32(selector));

  // An abi offset of '0x20' is placed in memory in order to encode the memory
  // snapshot to be sent to the hook as type 'bytes'.
  setHookInputHeader(32);

  // The hook contract to be used is extracted from 'poolId'.
  IHook hook = getHook();

  // The total byte count of the memory snapshot to be sent to the hook as
  // calldata is loaded.
  uint256 hookInputByteCount = getHookInputByteCount();

  assembly {
    // Invokes the given method in hook and relays the reason if reverted.
    if iszero(
      and(
        // Hook response must be exactly '32' bytes and equal to the
        // corresponding selector.
        and(eq(mload(0), selector), eq(returndatasize(), 32)),
        // '_hookSelector_' points to the beginning of the calldata to be sent
        // to the hook.
        // The total calldata byte count is 'hookInputByteCount + 4 + 32 + 32'
        // where '4' accounts for the selector, the first '32' accounts for the
        // abi offset slot which is populated with '0x20', and the second '32'
        // accounts for length slot which is populated with
        // 'hookInputByteCount'.
        call(
          gas(),
          hook,
          0,
          _hookSelector_,
          add(hookInputByteCount, 68),
          0,
          32
        )
      )
    ) {
      // Return data is copied to memory and relayed as a revert message.
      returndatacopy(0, 0, returndatasize())
      revert(0, returndatasize())
    }
  }
}

/// @notice Calls the pre initialize hook.
function invokePreInitialize() {
  invokeHook(IHook.preInitialize.selector);
}

/// @notice Calls the post initialize hook.
function invokePostInitialize() {
  invokeHook(IHook.postInitialize.selector);
}

/// @notice Calls the pre mint hook.
function invokePreMint() {
  invokeHook(IHook.preMint.selector);
}

/// @notice Calls the mid mint position hook.
function invokeMidMint() {
  invokeHook(IHook.midMint.selector);
}

/// @notice Calls the post mint position hook.
function invokePostMint() {
  invokeHook(IHook.postMint.selector);
}

/// @notice Calls the pre burn hook.
function invokePreBurn() {
  invokeHook(IHook.preBurn.selector);
}

/// @notice Calls the mid burn position hook.
function invokeMidBurn() {
  invokeHook(IHook.midBurn.selector);
}

/// @notice Calls the post burn position hook.
function invokePostBurn() {
  invokeHook(IHook.postBurn.selector);
}

/// @notice Calls the pre donate hook.
function invokePreDonate() {
  invokeHook(IHook.preDonate.selector);
}

/// @notice Calls the mid donate hook.
function invokeMidDonate() {
  invokeHook(IHook.midDonate.selector);
}

/// @notice Calls the post donate hook.
function invokePostDonate() {
  invokeHook(IHook.postDonate.selector);
}

/// @notice Calls the pre swap hook.
function invokePreSwap() {
  invokeHook(IHook.preSwap.selector);
}

/// @notice Calls the mid swap hook.
function invokeMidSwap() {
  invokeHook(IHook.midSwap.selector);
}

/// @notice Calls the post swap hook.
function invokePostSwap() {
  invokeHook(IHook.postSwap.selector);
}

/// @notice Calls the mid modify kernel hook.
function invokePreModifyKernel() {
  invokeHook(IHook.preModifyKernel.selector);
}

/// @notice Calls the mid modify kernel hook.
function invokeMidModifyKernel() {
  invokeHook(IHook.midModifyKernel.selector);
}

/// @notice Calls the post modify kernel hook.
function invokePostModifyKernel() {
  invokeHook(IHook.postModifyKernel.selector);
}

/// @notice Upon initialization of a new pool, this function verifies the
/// following constraints on the given flags that are embedded in poolId:
///
/// If the given kernel is immutable, then 'isPreModifyKernel() == 0', i.e.,
/// 'isPreModifyKernel() <= isMutableKernel()'.
///
/// If the given kernel is immutable, then 'isMidModifyKernel() == 0', i.e.,
/// 'isMidModifyKernel() <= isMutableKernel()'.
///
/// If the given kernel is immutable, then 'isPostModifyKernel() == 0', i.e.,
/// 'isPostModifyKernel() <= isMutableKernel()'.
///
/// If donate is not allowed, then 'isPreDonate() == 0', i.e.,
/// 'isPreDonate() <= isDonateAllowed()'.
///
/// If donate is not allowed, then 'isMidDonate() == 0', i.e.,
/// 'isMidDonate() <= isDonateAllowed()'.
///
/// If donate is not allowed, then 'isPostDonate() == 0', i.e.,
/// 'isPostDonate() <= isDonateAllowed()'.
///
/// Both 'isPreInitialize()' and 'isPostInitialize()' flags are zero if and
/// only if no hook address is provided, i.e., 'getHook() == address(0)'.
///
/// The least significant '17' flags are zero if and only if no hook address
/// is provided, i.e., '(flags && 0x1ffff == 0) == (hook == address(0))'.
function validateFlags() pure {
  bool valid = (
    (
      isMutableKernel() || !isPreModifyKernel()
    ) && (
      isMutableKernel() || !isMidModifyKernel()
    ) && (
      isMutableKernel() || !isPostModifyKernel()
    ) && (
      isDonateAllowed() || !isPreDonate()
    ) && (
      isDonateAllowed() || !isMidDonate()
    ) && (
      isDonateAllowed() || !isPostDonate()
    ) && (
      getHook() == IHook(address(0)) || isPreInitialize() || isPostInitialize()
    )
  );

  // 'poolId' and 'hook' are loaded from the memory.
  uint256 poolId = getPoolId();
  IHook hook = getHook();

  // In addition to the above checks, we need to ensure that the 'hook' is zero
  // if and only if all of the least significant '17' flags are zero.
  assembly {
    valid := and(
      valid,
      eq(
        // Whether the given hook address is non-zero.
        gt(hook, 0),
        // 'poolId' is shifted by '160' bits to the right so that the flags
        // appear as the least significant bits. Then, a '0x1ffff' mask is
        // applied to the resulting value in order to extract the least
        // significant '17' flags. The following line checks whether at least
        // one of these '17' flags is enabled.
        gt(and(shr(160, poolId), 0x1ffff), 0)
      )
    )
  }

  // Reverts if 'valid == false'.
  require(valid, InvalidFlags(poolId));
}

// In each of the following functions, 'poolId' is shifted by '160' bits to the
// right so that the flags appear as the least significant bits. Then, a mask
// is applied to the resulting value in order to extract the desired flag.

/// @notice Returns the 'pre initialize flag'.
function isPreInitialize() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x1), 0)
  }
}

/// @notice Returns the 'post initialize flag'.
function isPostInitialize() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x2), 0)
  }
}

/// @notice Returns the 'pre mint position flag'.
function isPreMint() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x4), 0)
  }
}

/// @notice Returns the 'mid mint position flag'.
function isMidMint() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x8), 0)
  }
}

/// @notice Returns the 'post mint position flag'.
function isPostMint() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x10), 0)
  }
}

/// @notice Returns the 'mid burn position flag'.
function isPreBurn() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x20), 0)
  }
}

/// @notice Returns the 'mid burn position flag'.
function isMidBurn() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x40), 0)
  }
}

/// @notice Returns the 'post burn position flag'.
function isPostBurn() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x80), 0)
  }
}

/// @notice Returns the 'pre swap flag'.
function isPreSwap() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x100), 0)
  }
}

/// @notice Returns the 'mid swap flag'.
function isMidSwap() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x200), 0)
  }
}

/// @notice Returns the 'post swap flag'.
function isPostSwap() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x400), 0)
  }
}

/// @notice Returns the 'pre donate flag'.
function isPreDonate() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x800), 0)
  }
}

/// @notice Returns the 'mid donate flag'.
function isMidDonate() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x1000), 0)
  }
}

/// @notice Returns the 'post donate flag'.
function isPostDonate() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x2000), 0)
  }
}

/// @notice Returns the 'pre modify kernel flag'.
function isPreModifyKernel() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x4000), 0)
  }
}

/// @notice Returns the 'mid modify kernel flag'.
function isMidModifyKernel() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x8000), 0)
  }
}

/// @notice Returns the 'post modify kernel flag'.
function isPostModifyKernel() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x10000), 0)
  }
}

/// @notice Returns the 'mutable kernel flag'.
/// This flag is not relevant to hook and it is a feature associated with the
/// corresponding pool.
function isMutableKernel() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x20000), 0)
  }
}

/// @notice Returns the 'mutable pool growth portion flag'.
/// This flag is not relevant to hook and it is a feature associated with the
/// corresponding pool.
function isMutablePoolGrowthPortion() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x40000), 0)
  }
}

/// @notice Returns the 'is donate allowed flag'.
/// This flag is not relevant to hook and it is a feature associated with the
/// corresponding pool.
function isDonateAllowed() pure returns (bool flag) {
  uint256 poolId = getPoolId();
  assembly {
    flag := gt(and(shr(160, poolId), 0x80000), 0)
  }
}