// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {Index} from "./Index.sol";
import {X15} from "./X15.sol";
import {X47} from "./X47.sol";
import {X59} from "./X59.sol";
import {X111} from "./X111.sol";
import {X127} from "./X127.sol";
import {X208} from "./X208.sol";
import {X216} from "./X216.sol";
import {Tag} from "./Tag.sol";

/// @notice Thrown in case of overflow when attempting to calculate
/// '(a * b) / denominator'.
error MulDivOverflow(uint256 a, uint256 b, uint256 denominator);

/// @notice Thrown in case of overflow or underflow when attempting to
/// calculate 'a + b'.
error SafeAddFailed(X127 a, X127 b);

/// @notice Thrown when balance exceeds 'type(uint128).max'.
error BalanceOverflow(uint256 balance);

/// @notice Thrown when safe cast into an int256 overflows.
error SafeCastOverflow(uint256 value);

/// @notice Thrown when the given 'qSpacing' is less than 'minLogSpacing'.
error LogSpacingIsTooSmall(X59 qSpacing);

/// @notice Thrown when attempting to initialize a curve sequence on blank
/// intervals.
error BlankIntervalsShouldBeAvoided(X59 qLower, X59 qUpper);

/// @notice Thrown when 'curveLength' is zero upon initialization.
error CurveLengthIsZero();

/// @notice Each member of the curve sequence should be in-between the
/// preceding two members. Thrown when a given initial curve sequence violates
/// this rule.
error InvalidCurveArrangement(X59 q0, X59 q1, X59 q2);

/// @notice Thrown when 'curveLength' is out of range.
error CurveIndexOutOfRange(Index length);

/// @notice Thrown in case of overflow when attempting to calculate 
///
/// 'amount := ceiling(
///
///     shares *
///
///     (getZeroForOne() ? sqrtOffset : sqrtInverseOffset) * 
///
///      multiplier
///     ------------
///       2 ** 208
///  )'.
error SafeOutOfRangeAmountOverflow(
  X127 sqrtOffsetOrSqrtInverseOffset,
  X208 growthMultiplier,
  int256 shares
);

/// @notice Thrown in case of overflow when attempting to calculate 
///
/// 'amount := ceiling(
///
///     (zeroOrOne ? sqrtOffset : sqrtInverseOffset) * 
///
///      liquidity      integral
///     ----------- * -------------
///       2 ** 111     outgoingMax
///  )'.
error SafeInRangeAmountOverflow(
  X127 sqrtOffsetOrSqrtInverseOffset,
  X216 integral,
  X111 liquidity,
  X216 outgoingMax,
  uint256 outgoingMaxModularInverse
);

/// @notice Thrown when the second horizontal coordinate of a given kernel is
/// '0'. In this case, we have a vertical jump at the origin which limits
/// liquidity growth.
error SecondHorizontalCoordinateIsZero();

/// @notice The horizontal coordinates should be monotonically non-decreasing.
error NonMonotonicHorizontalCoordinates(X59 q_i, X59 q_j);

/// @notice The vertical coordinates should be monotonically non-decreasing.
error NonMonotonicVerticalCoordinates(X15 c_i, X15 c_j);

/// @notice There should not be repetitive points.
error RepetitiveKernelPoints(X15 c_i, X59 q_i);

/// @notice Thrown when the horizontal coordinates of a non-vertical and 
/// non-horizontal segment are closer than '2 ** 32'.
error SlopeTooHigh(X59 q_i, X59 q_j);

/// @notice Thrown when the horizontal coordinates of a given 'kernelCompact'
/// exceeds 'qSpacing'.
error HorizontalCoordinatesMayNotExceedLogSpacing(X59 q_j, X59 qSpacing);

/// @notice There should not be three repetitive horizontal coordinates. A 
/// vertical jump (i.e., discontinuity) is permitted and can be constructed
/// via two repetitive horizontal coordinates. However, three repetitive
/// horizontal coordinates are always redundant and should be avoided.
error RepetitiveHorizontalCoordinates(X59 q_i);

/// @notice There should not be three repetitive vertical coordinates. A 
/// horizontal segment (i.e., constant range) is permitted and can be 
/// constructed via two repetitive vertical coordinates. However, three
/// repetitive vertical coordinates are always redundant and should be
/// avoided.
error RepetitiveVerticalCoordinates(X15 c_i);

/// @notice Thrown when 'kernelLength' is out of range.
error KernelIndexOutOfRange(Index length);

/// @notice The last vertical coordinate should be equal to 'oneX15'.
error LastVerticalCoordinateMismatch(X15 c_j);

/// @notice Thrown when growth exceeds maximum permitted value of 'maxGrowth'.
error GrowthOverflow();

/// @notice Thrown when accrued growth portion values exceed '2 ** 104 - 1'.
error AccruedGrowthPortionOverflow(X127 accruedValue);

/// @notice Thrown when given flags are invalid or not consistent with hook.
error InvalidFlags(uint256);

/// @notice Thrown when the numerical search for outgoing target fails which 
/// should never heappen.
error SearchingForOutgoingTargetFailed();

/// @notice Thrown when the numerical search for incoming target fails which
/// should never heappen.
error SearchingForIncomingTargetFailed();

/// @notice Thrown when the numerical search for overshoot fails which should
/// never heappen.
error SearchingForOvershootFailed();

/// @notice Thrown if attempting to unlock the protocol while already unlocked.
error AlreadyUnlocked(address currentCaller);

/// @notice Thrown when any of the following methods are invoked prior to the
/// protocol being unlocked:
///
///   'INofeeswap.clear'
///   'INofeeswap.take'
///   'INofeeswap.settle'
///   'INofeeswap.transferTransientBalanceFrom'
///   'INofeeswap.modifyBalance'
///   'INofeeswap.swap'
///   'INofeeswapDelegatee.modifyPosition'
///   'INofeeswapDelegatee.donate'
///
error ProtocolIsLocked();

/// @notice Thrown when attempting to perform the following operations on a 
/// pool which is locked:
///
///   'INofeeswap.swap'
///   'INofeeswapDelegatee.modifyPosition'
///   'INofeeswapDelegatee.donate'
///   'INofeeswapDelegatee.modifyKernel'
///   'INofeeswapDelegatee.modifyPoolGrowthPortion'
///   'INofeeswapDelegatee.updateGrowthPortions'
///   'INofeeswapDelegatee.collectPool'
///   'INofeeswapDelegatee.collectProtocol'
///
error PoolIsLocked(uint256 poolId);

/// @notice Thrown when the deployment of static parameters fail.
error DeploymentFailed();

/// @notice Thrown when the method 'redeployStaticParamsAndKernel' is run
/// externally.
error CannotRedeployStaticParamsAndKernelExternally();

/// @notice Thrown when attempting to sync protocol's reserve of native token.
error NativeTokenCannotBeSynced();

/// @notice Thrown when the spender allowance for a tag is insufficient.
error InsufficientPermission(address spender, Tag tag);

/// @notice Thrown when the total number of shares accross all liquidity
/// intervals exceed '2 ** 127 - 1'.
error SharesGrossOverflow(int256 sharesGross);

/// @notice Thrown when attempting to access a pool which does not exist.
error PoolDoesNotExist(uint256 poolId);

/// @notice Thrown when the owner balance for a tag is insufficient.
error InsufficientBalance(address owner, Tag tag);

/// @notice Throws when Sentinel response is invalid.
error InvalidSentinelResponse(bytes4 response);

/// @notice Thrown when the given 'zeroForOne' is not in agreement with 
/// 'logPriceLimitOffsetted'.
error InvalidDirection(X59 current, X59 limit);

/// @notice Thrown when attempting to initialize a pool that already exists.
error PoolExists(uint256 poolId);

/// @notice Thrown when 'log(pOffset)' is not within the range '[-89, +89]'.
error LogOffsetOutOfRange(X59 qOffset);

/// @notice Thrown when the given tags are not in the correct order, i.e.,
/// 'tag0 < tag1'.
error TagsOutOfOrder(Tag tag0, Tag tag1);

/// @notice Thrown when a given growth portion is greater than one.
error InvalidGrowthPortion(X47 poolGrowthPortion);

/// @notice Thrown when a given logarithmic price does not belong to the range
/// '[log(pOffset) - 16 + 1 / (2 ** 59), log(pOffset) + 16 - 1 / (2 ** 59)]'.
error LogPriceOutOfRange(X59 logPrice);

/// @notice Thrown when attempting to mint/burn a position with zero shares or
/// when the number of shares does not belong to 
/// '[- type(int128).max, type(int128).max]'.
error InvalidNumberOfShares(int256 shares);

/// @notice Thrown when attempting to initialize a pool with 'poolId == 0'.
error PoolIdCannotBeZero();

/// @notice Thrown when attempting to access protocol operations via an
/// unauthorized address.
error OnlyByProtocol(address attemptingAddress, address protocolAddress);

/// @notice Thrown when attempting to access pool operations via an
/// unauthorized address.
error OnlyByPoolOwner(address attemptingAddress, address poolOwnerAddress);

/// @notice Thrown when attempting to mint/burn a position with invalid
/// lower bound which is not equal to interval boundaries modulo 'qSpacing'.
error LogPriceMinIsNotSpaced(X59 logPriceMin);

/// @notice Thrown when attempting to mint/burn a position with invalid
/// upper bound which is not equal to interval boundaries modulo 'qSpacing'.
error LogPriceMaxIsNotSpaced(X59 logPriceMax);

/// @notice Thrown when attempting to mint/burn a position with invalid
/// lower bound which is not greater than 'qSpacing'
error LogPriceMinIsInBlankArea(X59 logPriceMin);

/// @notice Thrown when attempting to mint/burn a position with invalid
/// lower bound which is not less than 'thirtyTwoX59 - qSpacing'.
error LogPriceMaxIsInBlankArea(X59 logPriceMax);

/// @notice Thrown when the given logPrices for a position are not in the
/// correct order.
error LogPricesOutOfOrder(X59 logPriceMin, X59 logPriceMax);

/// @notice Thrown when attempting donate to a pool whose donate flag is not 
/// active.
error DonateIsNotAllowed(uint256 poolId);

/// @notice Thrown when attempting to perform a donate to an empty interval.
error CannotDonateToEmptyInterval();

/// @notice Thrown when attempting to change an immutable kernel.
error ImmutableKernel(uint256 poolId);

/// @notice Thrown when attempting to change an immutable poolGrowthPortion.
error ImmutablePoolGrowthPortion(uint256 poolId);

/// @notice Thrown when attempting to make a delegate call to the protocol.
error NoDelegateCall(address context);

/// @notice Thrown when transient balances are not cleared.
error OutstandingAmount();

/// @notice Thrown when attempting to transfer NofeeAssets to address 0.
error CannotTransferToAddressZero();

/// @notice Thrown when the amount to be cleared is not equal to the transient
/// balance of 'msg.sender'.
error NotEqualToTransientBalance(int256 currentBalance);

/// @notice Thrown when the size of 'hookData' exceeds 'type(uint16).max'.
error HookDataTooLong(uint256 hookDataByteCount);

/// @notice Thrown when attempting to transfer ownership to address 0.
error AdminCannotBeAddressZero();

/// @notice Thrown when attempting to settle a tag with nonzero 'msg.value'.
error MsgValueIsNonZero(uint256 msgValue);

/// @notice Thrown when attempting to mint a position after burning it in the
/// same transaction.
error CannotMintAfterBurning(uint256 poolId, X59 qMin, X59 qMax);