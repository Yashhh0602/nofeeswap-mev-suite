// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X23} from "./X23.sol";
import {X47, zeroX47} from "./X47.sol";
import {X127, zeroX127, accruedMax} from "./X127.sol";
import {getProtocolGrowthPortion, getPoolGrowthPortion} from "./Memory.sol";
import {AccruedGrowthPortionOverflow} from "./Errors.sol";

/// @notice Calculates protocol and pool growth portions as follows:
///
///                                            protocolGrowthPortion
///  'protocolPortionIncrement := increment * -----------------------'
///                                                   oneX47
///
///  'poolPortionIncrement := 
///
///                oneX47 - protocolGrowthPortion     poolGrowthPortion
///   increment * -------------------------------- * -------------------'
///                            oneX47                       oneX47
///
///  'updatedAccrued := currentAccrued + 
///                     poolPortionIncrement + protocolPortionIncrement'
///
///  'updatedPoolRatio = 
///
///    currentPoolRatio * currentAccrued + oneX23 * poolPortionIncrement
///   -------------------------------------------------------------------'
///                            updatedAccrued
///
/// 'increment' should be non-negative.
/// 'currentAccrued' should be non-negative.
/// 'currentPoolRatio' should not be greater than 'oneX23'.
function calculateGrowthPortion(
  X127 increment,
  X127 currentAccrued,
  X23 currentPoolRatio
) pure returns (
  X127 updatedAccrued,
  X23 updatedPoolRatio
) {
  // Protocol and pool growth portions are loaded from memory.
  X47 protocolGrowthPortion = getProtocolGrowthPortion();
  X47 poolGrowthPortion = getPoolGrowthPortion();

  // First, we calculate 'poolPortionIncrement' and then 'updatedAccrued'.
  // Both should be rounded down.
  X127 poolPortionIncrement;
  {
    assembly {
      // Pool owner receives the following amount:
      //
      //                oneX47 - protocolGrowthPortion     poolGrowthPortion
      //  'increment * -------------------------------- * -------------------'
      //                           oneX47                       oneX47
      //
      // We first calculate
      //
      //  'coefficientX94 := (oneX47 - protocolGrowthPortion) * 
      //                     poolGrowthPortion'
      //
      // The multiplication is safe because both values fit within '48' bits.
      let coefficientX94 := mul(
        // The subtraction is safe because 'protocolGrowthPortion <= oneX47'
        sub(shl(47, 1), protocolGrowthPortion),
        poolGrowthPortion
      )

      // Next, we calculate:
      //
      //                                       coefficientX94
      // 'poolPortionIncrement := increment * ----------------'.
      //                                          2 ** 94
      //
      // which does not overflow because 'coefficientX94 <= 2 ** 94'.
      //
      // Let 's := increment * coefficientX94 - (2 ** 256 - 1) * p'
      // Let 'r := increment * coefficientX94 - (2 ** 94) * q'
      // Then 's - r == (2 ** 94) * q' [modulo '2 ** 256 - 1']
      // And 'q == (2 ** 162) * (s - r)' [modulo '2 ** 256 - 1']
      poolPortionIncrement := mulmod(
        // '(s - r) % (2 ** 256 - 1)'
        addmod(
          // 's'
          mulmod(increment, coefficientX94, not(0)),
          // '(0 - r) % (2 ** 256 - 1)'
          // The subtraction is safe because the output of 'mulmod' is less
          // than '1 << 94'.
          sub(not(0), mulmod(increment, coefficientX94, shl(94, 1))),
          not(0)
        ),
        // modular inverse of '1 << 94' modulo '2 ** 256 - 1'
        shl(162, 1),
        not(0)
      )

      // The pool and the protocol receive a total of:
      //
      //                oneX47 - protocolGrowthPortion     poolGrowthPortion
      //  'increment * -------------------------------- * ------------------- +
      //                           oneX47                       oneX47
      //
      //                protocolGrowthPortion
      //   increment * -----------------------'
      //                       oneX47
      //
      // We first calculate:
      //
      // 'coefficientX94 := 
      //  poolGrowthPortion * (oneX47 - protocolGrowthPortion) +
      //  oneX47 * protocolGrowthPortion'
      //
      // The addition is safe because both values fit within '94' bits.
      //
      // The shift is safe because 'protocolGrowthPortion <= oneX47'
      coefficientX94 := add(coefficientX94, shl(47, protocolGrowthPortion))

      // Next, we calculate:
      //
      //                                                  coefficientX94
      // 'updatedAccrued := currentAccrued + increment * ----------------'.
      //                                                     2 ** 94
      //
      // The calculation of
      //
      //               coefficientX94
      // 'increment * ----------------'
      //                  2 ** 94
      //
      // does not overflow because 'coefficientX94 <= 2 ** 94'.
      //
      // The possibility of overflow for the addition will be checked later.
      updatedAccrued := add(
        currentAccrued,
        // Let 's := increment * coefficientX94 - (2 ** 256 - 1) * p'
        // Let 'r := increment * coefficientX94 - (2 ** 94) * q'
        // Then 's - r == (2 ** 94) * q' [modulo '2 ** 256 - 1']
        // And 'q == (2 ** 162) * (s - r)' [modulo '2 ** 256 - 1']
        mulmod(
          // '(s - r) % (2 ** 256 - 1)'
          addmod(
            // 's'
            mulmod(increment, coefficientX94, not(0)),
            // '(0 - r) % (2 ** 256 - 1)'
            // The subtraction is safe because the output of 'mulmod' is less
            // than '1 << 94'.
            sub(not(0), mulmod(increment, coefficientX94, shl(94, 1))),
            not(0)
          ),
          // modular inverse of '1 << 94' modulo '2 ** 256 - 1'
          shl(162, 1),
          not(0)
        )
      )
    }
  }

  // 'updatedAccrued < currentAccrued' is a necessary and sufficient indication
  // of overflow for the above addition.
  require(
    updatedAccrued >= currentAccrued,
    AccruedGrowthPortionOverflow(updatedAccrued)
  );
  
  // We should also ensure that 'updatedAccrued' does not exceed 'accruedMax'
  // because only '104' bits are allocated to this value in storage.
  require(
    updatedAccrued <= accruedMax,
    AccruedGrowthPortionOverflow(updatedAccrued)
  );

  if (updatedAccrued > zeroX127) {
    // The multiplication and addition are safe because the numerator never
    // exceeds '2 ** 255 - 1' due to prior checks.
    assembly {
      // The division is safe due to the prior check
      // 'updatedAccrued > zeroX127'.
      updatedPoolRatio := div(
        // The addition is safe because both sides do not exceed
        // 'accruedMax << 23'.
        add(
          // The multiplication is safe because
          // 'currentAccrued <= updatedAccrued <= accruedMax' and
          // 'currentPoolRatio <= oneX23'.
          mul(currentPoolRatio, currentAccrued),
          // The shift is safe because
          // 'poolPortionIncrement <= currentAccrued + 
          //                          poolPortionIncrement + 
          //                          protocolPortionIncrement
          //                       == updatedAccrued <= accruedMax'.
          shl(23, poolPortionIncrement)
        ),
        updatedAccrued
      )
    }
  }
}

/// @notice Determines whether a pool should charge any growth portions.
function isGrowthPortion() pure returns (bool result) {
  return (
    getPoolGrowthPortion() > zeroX47 || getProtocolGrowthPortion() > zeroX47
  );
}