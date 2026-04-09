// Credit to: https://github.com/Uniswap/v4-core/blob/
// 80311e34080fee64b6fc6c916e9a51a437d0e482/src/interfaces/IExtsload.sol
pragma solidity ^0.8.28;

/// @notice Interface to access any storage slot of Nofeeswap.
interface IStorageAccess {
  /// @notice Provides access to a single Nofeeswap storage slot.
  /// @param slot Key of slot to sload.
  /// @return value The value of the slot as bytes32
  function storageAccess(bytes32 slot) external view returns (bytes32 value);

  /// @notice Provides access to consecutive Nofeeswap storage slots.
  /// @param startSlot Starting slot to be read.
  /// @param nSlots Number of slots to be read.
  /// @return values List of loaded values.
  function storageAccess(
    bytes32 startSlot,
    uint256 nSlots
  ) external view returns (bytes32[] memory values);

  /// @notice Provides access to a given list of Nofeeswap storage slots.
  /// @param slots List of slots to sload from.
  /// @return values List of loaded values.
  function storageAccess(
    bytes32[] calldata slots
  ) external view returns (bytes32[] memory values);
}