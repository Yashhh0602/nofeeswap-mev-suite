// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {GrowthOverflow} from "./Errors.sol";
import {X47} from "./X47.sol";
import {X111, maxGrowth} from "./X111.sol";
import {X216} from "./X216.sol";
import {FullMathLibrary} from "./FullMath.sol";
import {getProtocolGrowthPortion, getPoolGrowthPortion} from "./Memory.sol";

/// @notice Updates the current growth value to
///
///                     oneX47 - protocolGrowthPortion
/// 'growth + growth * -------------------------------- * 
///                                 oneX47
///
///                     oneX47 - poolGrowthPortion      numerator
///                    ---------------------------- * -------------'
///                               oneX47               denominator
///
/// 'growth' should be non-negative and not greater than 'maxGrowth'.
/// 'numerator' should be non-negative.
/// 'denominator' should be positive.
function updateGrowth(
  X111 growth,
  X216 numerator,
  X216 denominator
) pure returns (
  X111 updatedGrowth
) {
  // The input requirements of 'updateGrowth(X111,int256,uint256)' are
  // identical to the input requirements of this method.
  return updateGrowth(
    growth,
    X216.unwrap(numerator),
    // Casting is safe because of the input requirement 'denominator > 0'.
    uint256(X216.unwrap(denominator))
  );
}

/// @notice Updates the current growth value to
///
///                     oneX47 - protocolGrowthPortion
/// 'growth + growth * -------------------------------- * 
///                                 oneX47
///
///                     oneX47 - poolGrowthPortion      numerator
///                    ---------------------------- * -------------'
///                               oneX47               denominator
///
/// 'growth' should be non-negative and not greater than 'maxGrowth'.
/// 'numerator' should be non-negative.
/// 'denominator' should be positive.
function updateGrowth(
  X111 growth,
  int256 numerator,
  uint256 denominator
) pure returns (
  X111 updatedGrowth
) {
  // Casting is safe because of the input requirement 'numerator >= 0'.
  uint256 _numerator = uint256(numerator);
  X47 protocolGrowthPortion = getProtocolGrowthPortion();
  X47 poolGrowthPortion = getPoolGrowthPortion();
  uint256 valueX205;
  assembly {
    // 'growth * (oneX47 - protocolGrowthPortion)'
    //
    // The multiplication is safe because 'growth <= maxGrowth' and 
    // 'protocolGrowthPortion <= oneX47'.
    //
    // The shift to the left is safe because 'growth <= maxGrowth'.
    //
    // The subtraction is safe because 'protocolGrowthPortion <= oneX47'.
    let valueX158 := sub(shl(47, growth), mul(protocolGrowthPortion, growth))

    // 'growth * (oneX47 - protocolGrowthPortion)
    //         * (oneX47 - poolGrowthPortion)'
    //
    // The multiplication is safe because 'valueX158 <= (maxGrowth << 47)' and 
    // 'protocolGrowthPortion <= oneX47'.
    //
    // The shift to the left is safe because 'growth <= (maxGrowth << 47)'.
    //
    // The subtraction is safe because 'poolGrowthPortion <= oneX47'.
    valueX205 := sub(shl(47, valueX158), mul(poolGrowthPortion, valueX158))
  }
  {
    // We have 'valueX205 * _numerator / denominator < 2 ** 256' if and only if
    // 'msb := valueX205 * _numerator / (2 ** 256) < denominator'. Hence, the
    // following check ensures that the next 'mulDiv' will not overflow.
    (, uint256 msb) = FullMathLibrary.mul512(valueX205, _numerator);
    require(msb < denominator, GrowthOverflow());
  }
  // 'mulDiv' is safe due to the prior check.
  // The addition is also safe because 'growth <= maxGrowth' and
  // second term is less than '2 ** (256 - 94)'.
  updatedGrowth = growth + X111.wrap(
    int256(FullMathLibrary.mulDiv(valueX205, _numerator, denominator) >> 94)
  );

  // Signed comparison is valid because 'maxGrowth' is positive and less than
  // '2 ** 255 - 1' and also:
  // 'updatedGrowth >= growth >= 0',
  // 'updatedGrowth < maxGrowth + 2 ** (256 - 94) < 2 ** 255 - 1'.
  require(updatedGrowth <= maxGrowth, GrowthOverflow());
}