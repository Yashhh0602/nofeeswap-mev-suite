// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {
  IERC1155Receiver
} from "@openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import {INofeeswap} from "@core/interfaces/INofeeswap.sol";
import {Operator} from "../Operator.sol";

// bytes4(keccak256('transientAccess(bytes32)'));
bytes4 constant transientAccessSelector = 0x834178fe;

/// @title This contract is a notional nofeeswap hook for test purposes.
contract MockPayer {
  function call(
    address target,
    uint256 value,
    address operator,
    uint256[] calldata transientSlots,
    bytes calldata data
  ) external {
    assembly {
      // 132 = 4 'selector' + 32 'target' + 32 'value' + 32 'operator'
      //     + 32 'startOfTransientSlots'
      let start := add(4, calldataload(132))
      let size := calldataload(start)

      calldatacopy(128, add(32, start), size)

      if iszero(
        call(
          gas(),
          calldataload(4), // target
          calldataload(36), // value
          128,
          size,
          0,
          0
        )
      ) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }

      start := add(4, calldataload(100))
      size := shl(5, calldataload(start))
      let pointer := add(32, start)
      let end := add(pointer, size)

      for {} lt(pointer, end) { pointer := add(pointer, 32) } {
        let storageSlot := calldataload(pointer)
        mstore(0, transientAccessSelector)
        mstore(4, storageSlot)
        pop(call(gas(), calldataload(68), 0, 0, 36, 0, 32))
        sstore(storageSlot, mload(0))
      }
    }
  }

  function storageAccess(
    uint256 slot
  ) external view returns (uint256) {
    assembly {
      mstore(0, sload(slot))
      return(0, 0x20)
    }
  }

  receive() external payable {}

  function onERC1155Received(
    address ,
    address ,
    uint256 ,
    uint256 ,
    bytes calldata
  ) external pure returns (bytes4) {
    return IERC1155Receiver.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address ,
    address ,
    uint256[] calldata ,
    uint256[] calldata ,
    bytes calldata
  ) external pure returns (bytes4) {
    return IERC1155Receiver.onERC1155BatchReceived.selector;
  }
}