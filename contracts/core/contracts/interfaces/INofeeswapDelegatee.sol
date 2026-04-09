// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {ISentinel} from "../interfaces/ISentinel.sol";
import {X47} from "../utilities/X47.sol";
import {X59} from "../utilities/X59.sol";
import {Tag} from "../utilities/Tag.sol";

/// @notice Interface for the NofeeswapDelegatee contract.
interface INofeeswapDelegatee {
  /// @notice Initializes a new Nofeeswap pool.
  ///
  /// @param unsaltedPoolId The least significant 160 bits refer to the hook
  /// address. The next 20 bits are referred to as flags. The least significant
  /// 17 flags are described in 'IHook.sol'. The most significant 3 flags are
  /// not for hooks and are referred to as 'isMutableKernel',
  /// 'isMutablePoolGrowthPortion', and 'isDonateAllowed', from the least to
  /// the most significant. The next 8 bits represent the natural logarithm of
  /// 'pOffset' which must be greater than or equal to '-89' and less than or
  /// equal to '89' in 'int8' representation (two's complement). Hence,
  /// 'pOffset' is greater than or equal to 'exp(-89)' and less than or equal
  /// to 'exp(+89)'. As will be discussed later, the price of the pool is
  /// always greater than or equal to
  ///
  ///  'pOffset * exp(- 16 + 1 / (2 ** 59))'
  ///
  /// and less than or equal to
  ///
  ///  'pOffset * exp(+ 16 - 1 / (2 ** 59))'.
  ///
  /// One candidate for 'pOffset' is the current market price at the time of
  /// initialization. Alternatively, one may input 0 as the logarithm of
  /// 'pOffset' in which case, the price range of the pool would be limited to
  /// '(exp(-16), exp(+16))'.
  /// The remaining 68 bits are derived according to the following rule:
  ///
  /// 'unchecked {
  ///     poolId = unsaltedPoolId + (
  ///        keccak256(abi.encodePacked(msg.sender, unsaltedPoolId)) << 188
  ///     )
  ///  }'
  ///
  /// @param tag0 The arithmetically smaller tag. A tag may refer to native,
  /// ERC-20, ERC-6909, or ERC-1155 tokens as described in 'Tag.sol'
  ///
  /// @param tag1 The arithmetically larger tag.
  ///
  /// @param poolGrowthPortion The initial value for the pool growth portion. 
  /// With 'zeroX47' and 'oneX47' referring to 0% and 100%, respectively. This
  /// value dictates the portion of the growth that goes to the pool owner
  /// followed by the protocol.
  ///
  /// @param kernelCompactArray For every pool, the kernel function
  /// 'k : [0, qSpacing] -> [0, 1]' represents a monotonically non-decreasing
  /// piece-wise linear function. Let 'm + 1' denote the number of these
  /// breakpoints. For every integer '0 <= i <= m' the i-th breakpoint of the
  /// kernel represents the pair '(b[i], c[i])' where
  ///
  ///  '0 == b[0] <  b[1] <= b[2] <= ... <= b[m - 1] <  b[m] == qSpacing',
  ///  '0 == c[0] <= c[1] <= c[2] <= ... <= c[m - 1] <= c[m] == 1'.
  /// 
  /// In its compact form, each breakpoint occupies 10 bytes, in which:
  ///
  ///  - the 'X15' representation of '(2 ** 15) * c[i]' occupies 2 bytes,
  ///
  ///  - the 'X59' representation of '(2 ** 59) * b[i]' occupies 8 bytes,
  ///
  /// The above-mentioned layout is illustrated as follows:
  ///
  ///          A 80 bit kernel breakpoint
  ///  +--------+--------------------------------+
  ///  | 2 byte |             8 byte             |
  ///  +--------+--------------------------------+
  ///  |        |
  ///  |         \
  ///  |          (2 ** 59) * b[i]
  ///   \
  ///    (2 ** 15) * c[i]
  ///
  /// These 80 bit breakpoints are compactly encoded in a 'uint256[]' array and
  /// given as input to 'initialize' or 'modifyKernel' methods.
  ///
  /// Consider the following examples:
  ///
  ///   - The sequence of breakpoints
  ///
  ///       '(0, 0), (qSpacing, 1)'
  ///
  ///     implies that the diagram of 'k' is a single segment connecting the
  ///     point '(0, 0)' to the point '(qSpacing, 1)'. This leads to the kernel
  ///     function:
  ///
  ///       'k(h) := h / qSpacing'.
  ///
  ///   - The sequence of breakpoints
  ///
  ///       '(0, 0), (qSpacing / 2, 1), (qSpacing, 1)'
  ///
  ///     implies that the diagram of 'k' is composed of two segments:
  ///
  ///       - The first segment connects the point '(0, 0)' to the point
  ///         '(qSpacing / 2, 1)'.
  ///
  ///       - The second segment connects the point '(qSpacing / 2, 1)' to the
  ///         point '(qSpacing, 1)'.
  ///
  ///     The combination of the two segments leads to the kernel function:
  ///
  ///                 /
  ///                |  2 * h / qSpacing    if 0 < q < qSpacing / 2
  ///       'k(h) := |                                                      '.
  ///                |  1                   if qSpacing / 2 < q < qSpacing
  ///                 \
  ///
  ///   - The sequence of breakpoints
  ///
  ///       '(0, 0), (qSpacing / 2, 0), (qSpacing / 2, 1 / 2), (qSpacing, 1)'
  ///
  ///     implies that the diagram of 'k' is composed of three segments:
  ///
  ///       - The first segment belongs to the horizontal axis connecting the
  ///         point '(0, 0)' to the point '(qSpacing / 2, 0)'.
  ///
  ///       - The second segment is vertical, connecting the point
  ///         '(qSpacing / 2, 0)' to the point '(qSpacing / 2, 1 / 2)'. A
  ///         vertical segment (i.e., two consecutive breakpoints with equal
  ///         horizontal coordinates) indicates that the kernel function is
  ///         discontinuous which is permitted by the protocol. In this case,
  ///         we have a discontinuity at point 'qSpacing / 2' because:
  ///            
  ///           '0 == k(qSpacing / 2 - epsilon) != 
  ///                 k(qSpacing / 2 + epsilon) == 1 / 2 + epsilon / qSpacing'
  ///            
  ///         where 'epsilon > 0' is an arbitrarily small value approaching 0.
  ///
  ///       - The third segment connects the point '(qSpacing / 2, 1 / 2)' to
  ///         the point '(qSpacing, 1)'.
  ///
  ///     The combination of the three segments leads to the kernel function:
  ///
  ///                 /
  ///                |  0               if 0 < q < qSpacing / 2
  ///       'k(h) := |                                                  '.
  ///                |  h / qSpacing    if qSpacing / 2 < q < qSpacing
  ///                 \
  ///
  /// A wide variety of other functions can be constructed and provided as
  /// input. The break-points are provided to protocol as 'kernelCompactArray'
  /// upon initialization of a pool or when changing a pool's kernel. A pool 
  /// owner can provide a new kernel in the compact form through the function 
  /// 'modifyKernel'. For each break-point a 64-bit horizontal coordinate 
  /// is given in 'X59' representation, and a 16-bit vertical coordinate
  /// corresponding to kernel's intensity is provided in 'X15' representation.
  /// Hence, each break-point takes 80 bits in the compact form. The
  /// break-points should be tightly packed within a 'uint256[]' array with
  /// their height appears first.
  ///
  /// @param curveArray The curve sequence contains historical prices in 'X59'
  /// representation. It should have at least two members. In other words,
  /// every member of the curve sequence represents a historical price
  /// 'pHistorical' which is stored in the form:
  ///
  ///   '(2 ** 59) * (16 + qHistorical)'
  ///
  /// where
  ///
  ///   'qHistorical := log(pHistorical / pOffset)'.
  ///
  /// Hence, each member of the curve occupies exactly '64' bits as explained
  /// in 'Curve.sol'. And each slot of 'curveArray' comprises four members of
  /// the curve sequence.
  ///
  /// The first and the second members of the curve sequence correspond to the
  /// boundaries of the current active liquidity interval (i.e., 'qLower' and
  /// 'qUpper') with the order depending on the desired history. The last
  /// member of the curve represents the current price of the pool, i.e.,
  /// 'qCurrent'.
  ///    
  /// For every integer '0 <= i < l', denote the (i + 1)-th historical price
  /// recorded by the curve sequence as 'p[i]'. Additionally, to simplify the
  /// notations, the out-of-range price 'p[l]' is assigned the same value as
  /// 'p[l - 1]'. Now, for every integer '0 <= i <= l', define also 
  ///    
  ///   'q[i] := log(p[i] / pOffset)'.
  ///
  /// The curve sequence is constructed in such a way that for every
  /// '2 <= i < l', we have:
  ///
  ///   'min(q[i - 1], q[i - 2]) < q[i] < max(q[i - 1], q[i - 2])'.
  ///
  /// This ordering rule is verified upon initialization of any pool and it is
  /// preserved by every amendment to the curve sequence.
  ///
  /// One candidate for the initial curve sequence is
  ///
  ///   'q[0] := log(p[0] / pOffset)',
  ///   'q[1] := log(p[1] / pOffset)',
  ///   'q[2] := log(p[2] / pOffset)'.
  ///
  /// where
  ///
  ///   - 'p[2]' is the market log price at the time of initialization.
  ///
  ///   - '|q[1] - q[0]| = qSpacing' which is selected based on tokens'
  ///     economic characteristics such as price volatility.
  ///
  ///   - 'q[0] < q[2] < q[1]' if the historical price has reached 'q[2]' from
  ///     above.
  ///
  ///   - 'q[1] < q[2] < q[0]' if the historical price has reached 'q[2]' from
  ///     below.
  ///
  /// More intuitively, members of the curve can be viewed as historical peaks
  /// of the price with later members representing more recent peaks. The
  /// initial curve is supplied by the pool creator and it determines
  /// 'qSpacing' which should not be less than 'minLogSpacing'.
  ///
  /// @param hookData Data to be passed to the hook.
  function initialize(
    uint256 unsaltedPoolId,
    Tag tag0,
    Tag tag1,
    X47 poolGrowthPortion,
    uint256[] calldata kernelCompactArray,
    uint256[] calldata curveArray,
    bytes calldata hookData
  ) external;

  /// @notice Mints or burns within a given liquidity range. Let 'pLower' and
  /// 'pUpper' represent the boundaries of the currently active liquidity
  /// interval. Let 'pMin' and 'pMax' correspond to the left and the right
  /// boundaries of the LP position to be modified, i.e.,
  ///
  ///   'logPriceMin == (2 ** 59) * log(pMin)',
  ///   'logPriceMax == (2 ** 59) * log(pMax)'.
  ///
  /// Additionally, define:
  ///
  ///   'logPriceMinOffsetted := (2 ** 59) * (16 + log(pMin / pOffset))',
  ///   'logPriceMaxOffsetted := (2 ** 59) * (16 + log(pMax / pOffset))'.
  ///
  /// Assume that
  ///
  ///   'pUpper < pMin'.
  ///
  /// Then, if an LP wants to withdraw a single share from every interval from
  /// 'pMin' to 'pMax', the number of tags owed are equal to:
  ///
  ///   'amount0 = (
  ///       growthMultiplier[logPriceMinOffsetted] - 
  ///       growthMultiplier[logPriceMaxOffsetted]
  ///    ) * sqrtInverseOffset'.
  ///
  /// Now, assume that 'pMax < pLower'. The amount of tag1 corresponding to a
  /// single share from 'logPriceMin' to 'pMax' is equal to:
  ///
  ///   'amount1 = (
  ///       growthMultiplier[logPriceMaxOffsetted] - 
  ///       growthMultiplier[logPriceMinOffsetted]
  ///    ) * sqrtOffset'
  ///
  /// Lastly, the amounts locked in the active interval for a single share are
  /// equal to:
  ///
  ///   'amount0 = growth * (integral0 / outgoingMax) * sqrtInverseOffset'
  ///   'amount1 = growth * (integral1 / outgoingMax) * sqrtOffset'
  ///
  /// Based on the above formulas, we can efficiently calculate the outgoing
  /// and incoming amounts for any arbitrary LP position.
  ///
  /// @param poolId The target pool identifier.
  /// @param logPriceMin The left position boundary '(2 ** 59) * log(pMin)'
  /// which must be equal to the active interval boundaries modulo 'qSpacing'.
  /// @param logPriceMax The right position boundary '(2 ** 59) * log(pMax)'
  /// which must be equal to the active interval boundaries modulo 'qSpacing'.
  /// @param shares Number of shares to be minted (positive)/burned (negative)
  /// per interval. Applies to all 'log(pMax / pMin) / qSpacing' intervals
  /// within the given range.
  /// @param hookData Data to be passed to hook.
  /// @return amount0 The amount of tag0 added (positive)/removed (negative).
  /// @return amount1 The amount of tag1 added (positive)/removed (negative).
  function modifyPosition(
    uint256 poolId,
    X59 logPriceMin,
    X59 logPriceMax,
    int256 shares,
    bytes calldata hookData
  ) external returns (
    int256 amount0,
    int256 amount1
  );

  /// @notice Donates the token amounts equivalent to a number of shares to be
  /// distributed proportionally among the LPs in the current active interval.
  /// @param poolId The target pool identifier.
  /// @param shares The number of shares to be donated.
  /// @param hookData Data to be passed to the hook.
  /// @return amount0 The amount of tag0 donated.
  /// @return amount1 The amount of tag1 donated.
  function donate(
    uint256 poolId,
    uint256 shares,
    bytes calldata hookData
  ) external returns (
    int256 amount0,
    int256 amount1
  );

  /// @notice Sets 'maxPoolGrowthPortion', 'protocolGrowthPortion', and 
  /// protocol's owner in one slot. Must be called by the current protocol 
  /// owner only.
  /// @param protocol New value for protocol slot.
  function modifyProtocol(
    uint256 protocol
  ) external;

  /// @notice Sets the 'sentinel' contract. Must be called by the current
  /// protocol owner only.
  /// @param sentinel New sentinel contract.
  function modifySentinel(
    ISentinel sentinel
  ) external;

  /// @notice This function updates the pool owner. Must be called by the 
  /// current owner of the target pool only.
  /// @param poolId The target pool identifier.
  /// @param newOwner The new owner's address.
  function modifyPoolOwner(
    uint256 poolId,
    address newOwner
  ) external;

  /// @notice This function provides a new pending 'kernel'. The pending kernel 
  /// is activated after the first interval transition. Replaces any existing
  /// pending kernel. Must be called by the current owner of the target pool 
  /// only.
  /// @param poolId The target pool identifier.
  /// @param kernelCompactArray The new kernel array in its compact form.
  /// @param hookData Data to be passed to hook.
  function modifyKernel(
    uint256 poolId,
    uint256[] calldata kernelCompactArray,
    bytes calldata hookData
  ) external;

  /// @notice This function modifies 'poolGrowthPortion'. Must be called by the 
  /// current owner of the target pool only.
  /// @param poolId The target pool identifier.
  /// @param poolGrowthPortion The new pool growth portion.
  function modifyPoolGrowthPortion(
    uint256 poolId,
    X47 poolGrowthPortion
  ) external;

  /// @notice Allows any address to update 'maxPoolGrowthPortion' and/or 
  /// 'protocolGrowthPortion' of a pool to the most recent values set by the 
  /// sentinel contract or protocol owner.
  /// @param poolId The target pool identifier.
  function updateGrowthPortions(uint256 poolId) external;

  /// @notice Collects pool owner's accrued growth portions. Can be called by
  /// any address. The collected amounts are transferred to the pool owner's 
  /// singleton balance.
  /// @param poolId The target pool identifier.
  /// @return amount0 The total amount of tag0 collected.
  /// @return amount1 The total amount of tag1 collected.
  function collectPool(uint256 poolId) external returns (
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Collects protocol owner's accrued growth portions. Can be called
  /// by any address. The collected amounts are transferred to the protocol 
  /// owner's singleton balance.
  /// @param poolId The target pool identifier.
  /// @return amount0 The total amount of tag0 collected.
  /// @return amount1 The total amount of tag1 collected.
  function collectProtocol(uint256 poolId) external returns (
    uint256 amount0,
    uint256 amount1
  );
}