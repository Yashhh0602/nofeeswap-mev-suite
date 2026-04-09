// Credit to: https://github.com/Uniswap/v4-core/blob/
// efb0dec66562c494ea54d67adfe0939d759c275e/src/Extsload.sol
pragma solidity ^0.8.28;

import {IStorageAccess} from "./interfaces/IStorageAccess.sol";

contract StorageAccess is IStorageAccess {
  /// @inheritdoc IStorageAccess
  function storageAccess(
    bytes32 slot
  ) external view override returns (bytes32) {
    assembly ("memory-safe") {
      // The input slot is read from storage and stored in memory scratch space
      // to be returned.
      mstore(0, sload(slot))
      return(0, 0x20)
    }
  }

  /// @inheritdoc IStorageAccess
  function storageAccess(
    bytes32 startSlot,
    uint256 nSlots
  ) external view override returns (bytes32[] memory) {
    assembly ("memory-safe") {
      let freeMemoryPointer := mload(0x40)
      let start := freeMemoryPointer
      // The number of slots is multiplied by 32 to calculate the total byte
      // size.
      let length := shl(5, nSlots)
      // The abi offset of the dynamic array in the returndata is 32.
      mstore(freeMemoryPointer, 0x20)
      // Store the length of the array to be returned.
      mstore(add(freeMemoryPointer, 0x20), nSlots)
      // Update 'freeMemoryPointer' to the first location to hold a result.
      freeMemoryPointer := add(freeMemoryPointer, 0x40)
      // The end of the array to be constructed is determined. Once
      // 'freeMemoryPointer' reaches 'end', the loop is broken.
      let end := add(freeMemoryPointer, length)
      // A loop over the number of slots to be read.
      for {} 1 {} {
        // The current slot is read from storage and placed in memory.
        mstore(freeMemoryPointer, sload(startSlot))
        // 'freeMemoryPointer' is moved forward by 32 bytes.
        freeMemoryPointer := add(freeMemoryPointer, 0x20)
        // The current slot is moved by 1.
        startSlot := add(startSlot, 1)
        // Once 'freeMemoryPointer' reaches 'end', there are no more slots to
        // be read and the loop is broken.
        if iszero(lt(freeMemoryPointer, end)) { break }
      }
      // The constructed array is returned with the length and the offset 
      // slots included.
      return(start, sub(end, start))
    }
  }

  /// @inheritdoc IStorageAccess
  function storageAccess(
    bytes32[] calldata slots
  ) external view override returns (bytes32[] memory) {
    assembly ("memory-safe") {
      // The free memory pointer is loaded.
      let freeMemoryPointer := mload(0x40)
      let start := freeMemoryPointer
      // For abi encoding the response - the array will be found at 0x20.
      mstore(freeMemoryPointer, 0x20)
      // Next we store the length of the return array.
      mstore(add(freeMemoryPointer, 0x20), slots.length)
      // Update 'freeMemoryPointer' to the first location to hold an array 
      // entry.
      freeMemoryPointer := add(freeMemoryPointer, 0x40)
      // The number of slots is multiplied by 32 to calculate the total byte
      // size. The end of the array to be constructed is determined. Once
      // 'freeMemoryPointer' reaches 'end', the loop is broken.
      let end := add(freeMemoryPointer, shl(5, slots.length))
      // The offset associated with 'slots' is loaded so that the input slots
      // can be read one by one.
      let calldataPointer := slots.offset
      // A loop over the number of slots to be read.
      for {} 1 {} {
        // The slot given by the 'calldataPointer' is read from storage and 
        // placed in memory.
        mstore(freeMemoryPointer, sload(calldataload(calldataPointer)))
        // 'freeMemoryPointer' is moved forward by 32 bytes.
        freeMemoryPointer := add(freeMemoryPointer, 0x20)
        // 'calldataPointer' is moved forward by 32 bytes.
        calldataPointer := add(calldataPointer, 0x20)
        // Once 'freeMemoryPointer' reaches 'end', there are no more slots to
        // be read and the loop is broken.
        if iszero(lt(freeMemoryPointer, end)) { break }
      }
      // The constructed array is returned with the length and the offset 
      // slots included.
      return(start, sub(end, start))
    }
  }
}