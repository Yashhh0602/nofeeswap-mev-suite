// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X47} from "../utilities/X47.sol";

/// @notice Interface for the Sentinel contract.
interface ISentinel {
  /// @notice Gives the values of 'maxPoolGrowthPortion' and
  /// 'protocolGrowthPortion' when called by the protocol.
  /// @param sentinelInput Data passed to sentinel contract.
  /// @return maxPoolGrowthPortion The value for 'maxPoolGrowthPortion'. If 
  /// returns any value greater than 'oneX47' then protocol slot's default
  /// values are used.
  /// @return protocolGrowthPortion The value for 'protocolGrowthPortion'. If
  /// returns any value greater than 'oneX47' then protocol slot's default
  /// values are used.
  function getGrowthPortions(
    bytes calldata sentinelInput
  ) external returns (
    X47 maxPoolGrowthPortion,
    X47 protocolGrowthPortion
  );

  /// @notice Called by nofeeswap to get authorization for a pool 
  /// initialization.
  /// @param sentinelInput Data passed to sentinel contract which is a snapshot
  /// of nofeeswap's memory post initialization.
  function authorizeInitialization(
    bytes calldata sentinelInput
  ) external returns (bytes4 selector);

  /// @notice Called by nofeeswap to get authorization for modification of a 
  /// pool growth portion.
  /// @param sentinelInput Data passed to sentinel contract which is a snapshot
  /// of nofeeswap's memory.
  function authorizeModificationOfPoolGrowthPortion(
    bytes calldata sentinelInput
  ) external returns (bytes4 selector);
}