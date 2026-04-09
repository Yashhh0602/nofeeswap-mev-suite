// Credit to: https://github.com/Uniswap/v4-core/blob/
// 80311e34080fee64b6fc6c916e9a51a437d0e482/src/interfaces/IExttload.sol
pragma solidity ^0.8.28;

/// @notice Interface to access any transient storage slot of Nofeeswap.
interface ITransientAccess {
  /// @notice Provides access to a single Nofeeswap transient storage slot.
  /// @param slot Key of slot to tload.
  /// @return value The value of the slot as bytes32
  function transientAccess(bytes32 slot) external view returns (bytes32 value);

  /// @notice Provides access to consecutive Nofeeswap transient storage slots.
  /// @param startSlot Starting slot to be read.
  /// @param nSlots Number of slots to be read.
  /// @return values List of loaded values.
  function transientAccess(
    bytes32 startSlot,
    uint256 nSlots
  ) external view returns (bytes32[] memory values);

  /// @notice Provides access to a given list of Nofeeswap transient storage
  /// slots.
  /// @param slots List of slots to tload from.
  /// @return values List of loaded values.
  function transientAccess(
    bytes32[] calldata slots
  ) external view returns (bytes32[] memory values);
}