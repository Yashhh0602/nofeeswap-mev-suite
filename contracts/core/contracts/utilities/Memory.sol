// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

/// @dev Nofeeswap's memory layout.
/// @notice Each 'uint16' value is a memory pointer referring to the
/// corresponding value in memory. This file is generated using 'Memory.py'.

import {Tag} from "./Tag.sol";
import {Index} from "./Index.sol";
import {X15} from "./X15.sol";
import {X23} from "./X23.sol";
import {X47} from "./X47.sol";
import {X59} from "./X59.sol";
import {X111} from "./X111.sol";
import {X127} from "./X127.sol";
import {X208} from "./X208.sol";
import {X216} from "./X216.sol";
import {Curve} from "./Curve.sol";
import {Kernel} from "./Kernel.sol";

// Refers to the third slot of the memory which contains the free memory
// pointer.
uint16 constant _freeMemoryPointer_ = 64;

// Refers to the fourth slot of the memory which remains blank.
uint16 constant _blank_ = 96;

// When the protocol calls a hook or the sentinel contract, a snapshot of the
// memory (with '_hookSelector_' as the starting point) is sent to the target
// contract as calldata. Before calling the target contract, this 4 byte space
// is populated with the intended function selector of the target contract.
uint16 constant _hookSelector_ = 128;

// This space is populated with the abi offset '0x20' so that the hook or the
// sentinel contract can decode the given calldata. This offset value points to
// the slot that contains the byte count of the snapshot given to the hook or
// the sentinel contract
uint16 constant _hookInputHeader_ = 132;

// This space is populated with the byte count of 'bytes calldata hookInput'
// which is passed as input to the hook or the sentinel contract.
uint16 constant _hookInputByteCount_ = 164;

// 'msg.sender' in the current execution context is placed in this space to be
// passed to the hook or the sentinel contract. This way, the hook or the
// sentinel contract have access to 'msg.sender' in the prior execution
// context (i.e., in the context where the protocol is called).
uint16 constant _msgSender_ = 196;

// This space is dedicated to the identifier of the intended pool. The least
// significant 160 bits of this memory space refer to the hook address. The
// next 20 bits are referred to as flags that are used by the protocol to know
// which methods from 'IHook.sol' should be invoked and what permissions are
// activated. Flags are further explained in 'IHook.sol'. The next 8 bits
// represent the natural logarithm of 'pOffset' which must be greater than or
// equal to '-89' and less than or equal to '89' in 'int8' representation
// (two's complement). Hence, 'pOffset' is greater than or equal to 'exp(-89)'
// and less than or equal to 'exp(+89)'. As will be discussed later, the price
// of the pool is always greater than or equal to
//
//  'pOffset * exp(- 16 + 1 / (2 ** 59))'
//
// and less than or equal to
//
//  'pOffset * exp(+ 16 - 1 / (2 ** 59))'.
uint16 constant _poolId_ = 216;

// How does a swap work?
// ----------------------------------------------------------------------------
// A swap in a pool can be interpreted as a change in that pool's price. There
// are two types of swaps:
//
//  - If 'tag0' is outgoing from the pool and 'tag1' is incoming to the pool as
//    a result of a swap, then the swap is price increasing, i.e., the price
//    prior to the execution of the swap is lower than the price after the
//    execution of the swap.
//
//  - If 'tag0' is incoming to the pool and 'tag1' is outgoing from the pool as
//    a result of a swap, then the swap is price decreasing, i.e., the price
//    prior to the execution of the swap is higher than the price after the
//    execution of the swap.
//
// Let 'pOffset' represent the offset price whose natural logarithm is encoded
// in 'poolId' as described above (in the definition of 'poolId'). The protocol
// offers liquidity providers (LPs) the flexibility to deposit their liquidity
// in a range of their choosing. To this end, the price horizon is partitioned
// into a number of liquidity intervals with equal length in the natural
// logarithmic scale. An LP may choose any consecutive range of liquidity
// intervals to deposit their liquidity. By doing so, the LP acquires a number
// of shares in every liquidity interval that belongs to the given range. The
// shares can be used later to withdraw liquidity along with any accumulated
// growth which is accrued as a result of swap and donate actions.
//
// At each moment, a single one of the above-mentioned intervals is active to
// which the current price of the pool belongs. Let 'pLower' and 'pUpper',
// respectively, denote the minimum and maximum price in the current active
// liquidity interval and define
//
//  'qLower := log(pLower / pOffset)'
//  'qUpper := log(pUpper / pOffset)'
//  'qSpacing := log(pUpper / pLower)'.
//
// Then, for every integer 'j', the interval
//
//  '[qLower + j * qSpacing, qUpper + j * qSpacing]'
//
// is a valid liquidity interval if and only if:
//
//  '- 16 + 1 / (2 ** 59) + qSpacing < qLower + j * qSpacing'
//
// and
//
//  'qUpper + j * qSpacing <= + 16 - 1 / (2 ** 59) - qSpacing'.
//
// This includes the current active liquidity interval '[qLower, qUpper]'
// which corresponds to 'j == 0'.
//
// Every swap has the following input parameters:
//
//  - 'logPriceLimit': This value is the natural logarithm of a price limit in
//    'X59' representation. It imposes a constraint on the price of the pool
//    post execution of the swap. For price increasing swaps, 'logPriceLimit'
//    serves as an upper bound, in which case the price of the pool must not
//    exceed 'exp(logPriceLimit / (2 ** 59))'. For price decreasing swaps,
//    'logPriceLimit' serves as a lower bound, in which case the price of the
//    pool must not subceed 'exp(logPriceLimit / (2 ** 59))'. In both cases,
//    once the price of the pool reaches 'exp(logPriceLimit / (2 ** 59))', the
//    execution of the swap is halted. Put simply, no amount of tags are traded
//    with any price worst than 'exp(logPriceLimit / (2 ** 59))' for the
//    swapper.
//
//  - 'zeroForOne': If 'zeroForOne == 0', then the swap is price increasing in
//    which case 'tag0' is outgoing from the pool and 'tag1' is incoming to the
//    pool. If 'zeroForOne == 1', then the swap is price decreasing in which
//    case 'tag0' is incoming to the pool and 'tag1' is outgoing from the pool.
//    Given any other value, the movement of the price is towards
//    'logPriceLimit', i.e., the swap is price increasing if
//
//      'pCurrent < exp(logPriceLimit / (2 ** 59))'
//
//    and the swap is price decreasing if
//
//      'exp(logPriceLimit / (2 ** 59)) < pCurrent'
//
//    where 'pCurrent' represents the current price of the pool.
//
//  - 'amountSpecified': If 'amountSpecified > 0' then 'amountSpecified'
//    represents the amount of 'tag0' (if the swap is price decreasing) or the
//    amount of 'tag1' (if the swap is price increasing) to be given to the
//    pool subject to the constraint imposed by 'logPriceLimit'. If
//    'amountSpecified < 0' then '0 - amountSpecified' represents the amount of
//    'tag0' (if the swap is price increasing) or the amount of 'tag1' (if the
//    swap is price decreasing) to be taken from the pool. Define
//
//      'exactInput := amountSpecified > 0'
//
//    which determines whether 'amountSpecified' is incoming to the pool or
//    outgoing from the pool. Additionally, if 'zeroForOne == exactInput', then
//    'amountSpecified' is with respect to 'tag0' and if
//    'zeroForOne != exactInput' then 'amountSpecified' is with respect to
//    'tag1'.
//
//  - 'crossThreshold': If large enough, a swap may involve transitioning from
//    the active liquidity interval to other intervals. 'crossThreshold'
//    imposes a lower bound on the total number of shares that should be
//    available in any interval for the swapper to transact in that interval.
//    For example, if 'crossThreshold == 0', which is the default, no minimum
//    number of shares is imposed. If 'crossThreshold == 100', there has to be
//    at least 100 shares in the interval for the swap function to either swap
//    within or enter that interval.
//
// Consider a hypothetical pool that satisfies
//
//  'qLower < qCurrent < qUpper',
//
// where
//
//  'qCurrent := log(pCurrent / pOffset)'
//
// and 'pCurrent' is the current price of the pool.
//
// Consider a swap in this pool with the following parameters:
//
//  'logPriceLimit := (2 ** 59) * log(pLimit)'
//  'zeroForOne := 1'
//  'amountSpecified := +oo'
//  'crossThreshold := 0'
//
// where
//
//  'pLimit := exp(- 3 * qSpacing) * pCurrent'
//
// and
//
//  'qLimit := log(pLimit / pOffset)'.
//
// As explained later in this script, each of the above input parameters are
// loaded from calldata, transformed to appropriate formats and then stored in
// dedicated spaces in memory that are pointed to by the constant values
// '_logPriceLimit_', '_zeroForOne_', '_amountSpecified_', and
// '_crossThreshold_', respectively. Additionally, prior to the execution
// of the swap, 'qLimit' is calculated and stored in the memory space which
// is pointed to by '_logPriceLimitOffsetted_'.
//
// In this example, we have:
//
//  'qLower - 3 * qSpacing < qLimit < qUpper - 3 * qSpacing',
//
// which is illustrated as follows:
//
//             qLimit                                  qCurrent
//               |                                         |
//  ... <--+-------------+-------------+-------------+-------------+--> ...
//
// In the presence of liquidity, the further away 'qLimit' is from 'qCurrent'
// the larger the outgoing amount from the pool and the incoming amount to the
// pool are.
//
// In the above example, the swap is price decreasing which means that 'tag0'
// is incoming to the pool and 'tag1' is outgoing from the pool as a result of
// the swap.
//
// Observe that 'qLimit' is three intervals away from 'qCurrent'. Hence, in
// order to go from 'qCurrent' to 'qLimit' we need to transact in the following
// four intervals:
//
//  '[qLower - 0 * qSpacing, qUpper - 0 * qSpacing]',
//  '[qLower - 1 * qSpacing, qUpper - 1 * qSpacing]',
//  '[qLower - 2 * qSpacing, qUpper - 2 * qSpacing]',
//  '[qLower - 3 * qSpacing, qUpper - 3 * qSpacing]'.
//
// At each point throughout the execution of the swap, as we transition from
// each interval to the next one, the memory pointers '_back_' and '_next_' are
// used in order to keep track of the boundaries for the current active
// interval. Each of these pointers refer to a memory space in which the
// following two values are enclosed:
//
//  'qBack := log(pBack / pOffset)'
//  'qNext := log(pNext / pOffset)'
//
// (among other values) where 'pBack' is the boundary of the current active
// liquidity interval in the opposite direction of the swap and 'pNext' is the
// other boundary in the direction of the swap.
//
// For price increasing swaps, the initial values for 'qBack' and 'qNext' are
// as follows
//
//  'qBack := qLower'
//  'qNext := qUpper'.
//
// However, in the present example, since the swap is price decreasing, these
// initial values are:
//
//  'qBack := qUpper'
//  'qNext := qLower'.
//
// as illustrated here:
//
//             qLimit                                   qCurrent
//               |                                         |
//  ... <--+-------------+-------------+-------------+-------------+--> ...
//                                                   |             |
//                                                 qNext         qBack
//
// As the price transitions to a new liquidity interval, the content of the
// memory spaces that are pointed to by '_back_' and '_next_' are updated
// accordingly.
//
// Now, in order to perform this swap, we need to proceed as follows:
//
//  - The dynamic parameters of the pool are read from the protocol's storage
//    which include the followings:
//
//    - 'sharesTotal': This is the total number of shares that are deposited in
//      the current active liquidity interval '[qLower, qUpper]' across all
//      LPs. Consider an example where we have only two LP positions such that
//      
//      - The first position has 2 shares in every interval from 'qLower' to
//        'qUpper + 2 * qSpacing', i.e., 2 shares in each of the intervals
//        '[qLower, qUpper]', '[qLower + qSpacing, qUpper + qSpacing]', and
//        '[qSpacing + 2 * qSpacing, qUpper + 2 * qSpacing]'.
//      
//      - The second position has 5 shares in every interval from
//        'qLower - qSpacing' to 'qUpper + qSpacing', i.e., 5 shares in each of
//        the intervals '[qLower - qSpacing, qUpper - qSpacing]',
//        '[qLower, qUpper]', and '[qLower + qSpacing, qUpper + qSpacing]'.
//
//      In this case, both LP positions include the active liquidity interval
//      '[qLower, qUpper]' which means that 'sharesTotal == 2 + 5 == 7'.
//
//    - 'growth': The amount of liquidity which is allocated to a single LP
//      share in the active interval increases as a result of a swap or a
//      donation. We use this parameter to keep track of the amount of
//      liquidity for each share. 'growth' is stored in 'X111' format and we
//      always have 'growth >= oneX111'.
//
//    - 'qCurrent': This is equal to 'log(pCurrent / pOffset)' where 'pCurrent'
//      is the current price of the pool prior to the execution of the swap.
//
//    - 'staticParamsStoragePointer': Certain information about the pool that
//      never change (e.g., 'tag0' and 'tag1') or do not change frequently are
//      encoded in an external smart contract's bytecode. We refer to this
//      external smart contract as the storage smart contract of the pool. This
//      way, the encoded parameters can be accessed by reading the storage
//      smart contract's bytecode which is more gas efficient than accessing
//      protocol's storage via 'sload'. However, if we ever need to make any
//      modification, a new storage smart contract should be deployed with an
//      updated bytecode. Hence, the protocol needs to keep track of the
//      address for the storage smart contract associated with each pool.
//      Instead of storing a 20-byte address for each pool, we calculate it
//      from 'staticParamsStoragePointer' as further explained in
//      'Storage.sol'. Hence, 'staticParamsStoragePointer' is a 16-bit pointer
//      which is used to derive the address of the storage smart contract from
//      which additional information about the pool is read.
//
//  - The curve sequence is read from the protocol's storage. The 'curve' is a
//    sequence containing historical prices in 'X59' representation. It should
//    have at least two members. In other words, every  member of the curve
//    sequence represents a historical price 'pHistorical' which is stored in
//    the form:
//
//      '(2 ** 59) * (16 + qHistorical)'
//
//    where
//
//      'qHistorical := log(pHistorical / pOffset)'.
//
//    Hence, each member of the curve occupies exactly '64' bits as explained
//    in 'Curve.sol'. This is because 'pHistorical' satisfies
//
//      'pOffset * exp(- 16 + 1 / (2 ** 59)) <= pHistorical'
//
//    and
//
//      'pHistorical <= pOffset * exp(+ 16 - 1 / (2 ** 59))'.
//
//    which conclude that
//
//      '1 <= (2 ** 59) * (16 + qHistorical) <= 2 ** 64 - 1'.
//
//    The first and the second members of the curve sequence correspond to the
//    boundaries of the current active liquidity interval (i.e., 'qLower' and
//    'qUpper') with the order depending on the pool's history. The last member
//    of the curve represents the current price of the pool, i.e., 'qCurrent'.
//    
//    Let 'l' denote the number of members in the curve sequence. Since, we
//    already know 'qCurrent' from dynamic parameters, we can determine 'l'
//    without having to load an entire length slot! In other words, we keep
//    reading members of the curve sequence from protocol's storage (four
//    members per slot) until we encounter 'qCurrent' which is already known
//    from dynamic parameters. Then, 'l' can be determined based on the
//    position of 'qCurrent' in the curve sequence.
//
//    For every integer '0 <= i < l', denote the (i + 1)-th historical price
//    recorded by the curve sequence as 'p[i]'. Additionally, to simplify the
//    notations, the out-of-range price 'p[l]' is assigned the same value as
//    'p[l - 1]'. Now, for every integer '0 <= i <= l', define also 
//    
//      'q[i] := log(p[i] / pOffset)'.
//
//    The curve sequence is constructed in such a way that for every
//    '2 <= i < l', we have:
//
//      'min(q[i - 1], q[i - 2]) < q[i] < max(q[i - 1], q[i - 2])'.
//
//    This ordering rule is verified upon initialization of any pool and it is
//    preserved by every amendment to the curve sequence.
//    
//    In order to use the curve sequence, we need to define a number of
//    functions. For every '0 <= i <= l - 2', if 'q[i + 2] < q[i]' define
//
//      'w_i : [qLower, qUpper] -> [0, qSpacing]'
//
//    as
//
//                  /
//                 |  q - q[i + 1]  if q[i + 2] < q < q[i]
//      'w_i(q) := |                                       '
//                 |  0             otherwise
//                  \
//
//    and if 'q[i] < q[i + 2]' define
//
//      'w_i : [qLower, qUpper] -> [0, qSpacing]'
//
//    as
//
//                  /
//                 |  q[i + 1] - q  if q[i] < q < q[i + 2]
//      'w_i(q) := |                                        '
//                 |  0             otherwise
//                  \
//
//    Each of the above functions is regarded as a phase. Observe that the
//    diagram for each of the phase is a compactly supported (i.e., equal to
//    zero outside of a bounded interval) segment with either '45' or '135'
//    degrees angle. Define
//
//      'w : [qLower, qUpper] -> [0, qSpacing]'
//
//    as
//
//               l - 2
//               -----
//               \
//      'w(q) := /     w_i(q).
//               -----
//               i = 0
//
//    This function will be used to determine the distribution of liquidity
//    within the active interval '[qLower, qUpper]'. As we will discuss later
//    in this script, the distribution of liquidity is modified with every swap
//    via amendments to the curve sequence and this process ensures liquidity
//    growth for the LPs without the need to charge fees.
//
//    For example, let
//
//      'q[0] := qUpper'
//      'q[1] := qLower'
//      'q[2]'
//      'q[3] := qCurrent'
//
//    represent the curve sequence. Then,
//
//      'w(q) := w_0(q) + w_1(q) + w_2(q)'
//
//    can be plotted as follows:
//
//            w(q)
//              ^
//      spacing |                /
//              |               /
//              |              /
//              |             /
//              |            /
//              |           /
//              |          /
//              |\
//              | \
//              |  \
//              |   \
//              |        /
//              |       /
//              |      /
//              |     /
//            0 +----+----+-------+-> q
//           qLower  |    |       |
//                   |   q[2]   qUpper
//                   |
//               qCurrent
//    
//    To summarize, reading the curve sequence from the protocol's storage
//    gives us access to 'qLower', 'qUpper' and the function 'w'.
//
//    The curve sequence is defined for every inactive liquidity interval as
//    well, although we do not need to keep track of them. For every integer
//    'j > 0', the curve sequence associated with the interval:
//
//      '[qLower + j * qSpacing, qUpper + j * qSpacing]'
//
//    is composed of only two members:
//
//      'q[0] := qUpper + j * qSpacing' 
//      'q[1] := qLower + j * qSpacing'. 
//
//    Hence, the function
//
//      'w : [qLower + j * qSpacing, qUpper + j * qSpacing] -> [0, qSpacing]'
//
//    corresponding to that interval is defined as:
//
//      'w(q) := q - qLower - j * qSpacing'
//
//    which is consistent with the prior definition of 'w' for the active
//    interval. Additionally, for every integer 'j < 0', the curve sequence
//    associated with the interval:
//
//      '[qLower + j * qSpacing, qUpper + j * qSpacing]'
//
//    is composed of only two members:
//
//      'q[0] := qLower + j * qSpacing' 
//      'q[1] := qUpper + j * qSpacing'. 
//
//    Hence, the function
//
//      'w : [qLower + j * qSpacing, qUpper + j * qSpacing] -> [0, qSpacing]'
//
//    corresponding to that interval is defined as:
//
//      'w(q) := qUpper + j * qSpacing - q'
//    
//    which is also consistent with our prior definition.
//
//    After reading the curve sequence for the active interval, we store
//    'qBack' and 'qNext' in their dedicated memory spaces in order to keep
//    track of the boundaries of the active liquidity interval. In the present
//    example, since the swap is price decreasing, the initial values for
//    'qBack' and 'qNext' are as follows:
//
//      'qBack := qUpper',
//      'qNext := qLower'.
//
//    For price increasing swaps, these initial values are
//
//      'qBack := qLower',
//      'qNext := qUpper'.
//
//    As discussed before, 'qBack' and 'qNext' are continuously updated
//    throughout the execution of a swap as we transition to new liquidity
//    intervals.
//
//  - Next, the kernel function is read from the storage smart contract's
//    bytecode. To this end, the dynamic parameter 'staticParamsStoragePointer'
//    is used to calculate the address to the storage smart contract associated
//    with the pool whose bytecode contains the kernel function. The kernel,
//    denoted by
//
//      'k : [0, qSpacing] -> [0, 1]',
//
//    is a monotonically non-decreasing piecewise linear function which is
//    characterized via a list of breakpoints. Each breakpoint has a horizontal
//    coordinate as well as a vertical coordinate. Consider the following
//    examples:
//
//      - The sequence of breakpoints
//
//          '(0, 0), (qSpacing, 1)'
//
//        implies that the diagram of 'k' is a single segment connecting the
//        point '(0, 0)' to the point '(qSpacing, 1)'. This leads to the kernel
//        function:
//
//          'k(h) := h / qSpacing'.
//
//      - The sequence of breakpoints
//
//          '(0, 0), (qSpacing / 2, 1), (qSpacing, 1)'
//
//        implies that the diagram of 'k' is composed of two segments:
//
//          - The first segment connects the point '(0, 0)' to the point
//            '(qSpacing / 2, 1)'.
//
//          - The second segment connects the point '(qSpacing / 2, 1)' to the
//            point '(qSpacing, 1)'.
//
//        The combination of the two segments leads to the kernel function:
//
//                    /
//                   |  2 * h / qSpacing    if 0 < q < qSpacing / 2
//          'k(h) := |                                                      '.
//                   |  1                   if qSpacing / 2 < q < qSpacing
//                    \
//
//      - The sequence of breakpoints
//
//          '(0, 0), (qSpacing / 2, 0), (qSpacing / 2, 1 / 2), (qSpacing, 1)'
//
//        implies that the diagram of 'k' is composed of three segments:
//
//          - The first segment belongs to the horizontal axis connecting the
//            point '(0, 0)' to the point '(qSpacing / 2, 0)'.
//
//          - The second segment is vertical, connecting the point
//            '(qSpacing / 2, 0)' to the point '(qSpacing / 2, 1 / 2)'. A
//            vertical segment (i.e., two consecutive breakpoints with equal
//            horizontal coordinates) indicates that the kernel function is
//            discontinuous which is permitted by the protocol. In this case,
//            we have a discontinuity at point 'qSpacing / 2' because:
//            
//              '0 == k(qSpacing / 2 - epsilon) != 
//                    k(qSpacing / 2 + epsilon) == 1 / 2 + epsilon / qSpacing'
//            
//            where 'epsilon > 0' is an arbitrarily small value approaching 0.
//
//          - The third segment connects the point '(qSpacing / 2, 1 / 2)' to
//            the point '(qSpacing, 1)'.
//
//        The combination of the three segments leads to the kernel function:
//
//                    /
//                   |  0               if 0 < q < qSpacing / 2
//          'k(h) := |                                                  '.
//                   |  h / qSpacing    if qSpacing / 2 < q < qSpacing
//                    \
//    
//    Hence, reading the kernel breakpoints from the storage smart contract
//    gives us access to the function 'k'.
//    
//    Define
//
//      'k(w(.)) : [qLower, qUpper] -> [0, 1]'
//
//    as the liquidity distribution function. As we will demonstrate next, one
//    can determine the outgoing amount from the pool and the incoming amount
//    to the pool by integrating the liquidity distribution function. More
//    precisely, consider a swap that involves a movement of price from
//    'qCurrent' to
//
//      'qTarget := log(pTarget / pOffset)'
//
//    within the same active liquidity interval, i.e.,
//
//      'qLower <= qTarget <= qUpper'.
//
//    If 'qCurrent < qTarget, then the outgoing amount of 'tag0' as a result of
//    this movement is proportional to the following integration of the
//    liquidity distribution function:
//
//                               - 8     / qTarget
//        currentToTarget      e        |    - h / 2
//      '----------------- := ------- * |  e         k(w(h)) dh'.
//           2 ** 216            2      |
//                                     / qCurrent
//
//    In this case, the incoming amount of 'tag1' as a result of this movement
//    is proportional to the following integration of the liquidity
//    distribution function:
//
//                                       - 8     / qTarget
//        incomingCurrentToTarget      e        |    + h / 2
//      '------------------------- := ------- * |  e         k(w(h)) dh'.
//               2 ** 216                2      |
//                                             / qCurrent
//
//    On the other hand, if 'qTarget < qCurrent', then the outgoing amount of
//    'tag1' and the incoming amount of 'tag0', respectively, are proportional
//    to the following integrations of the liquidity distribution function:
//
//                               - 8     / qCurrent
//        currentToTarget      e        |    + h / 2
//      '----------------- := ------- * |  e         k(w(h)) dh',
//           2 ** 216            2      |
//                                     / qTarget
//
//                                       - 8     / qCurrent
//        incomingCurrentToTarget      e        |    - h / 2
//      '------------------------- := ------- * |  e         k(w(h)) dh'.
//                2 ** 216               2      |
//                                             / qTarget
//
//    Now, imagine a scenario where we want to move all the way from 'qCurrent'
//    to 'qUpper' which is a price increasing swap. Hence, in this case, the
//    outgoing amount of 'tag0' is proportional to:
//
//                         - 8     / qUpper
//        integral0      e        |    - h / 2
//      '----------- := ------- * |  e         k(w(h)) dh'.
//        2 ** 216         2      |
//                               / qCurrent
//
//    Observe that moving from 'qCurrent' to 'qUpper' depletes the entire
//    reserve of 'tag0', within the interval '[qLower, qUpper]' (because we
//    cannot go further than that without transitioning to a new interval).
//    Hence, the total reserve of 'tag0' within the interval '[qLower, qUpper]'
//    is proportional to 'integral0' which is given by the above formula.
//
//    Similarly, imagine a scenario where we want to move all the way from
//    'qCurrent' to 'qLower' which is a price decreasing swap. Hence, in this
//    case, the outgoing amount of 'tag1' is proportional to:
//
//                         - 8     / qCurrent
//        integral1      e        |    + h / 2
//      '----------- := ------- * |  e         k(w(h)) dh',
//        2 ** 216         2      |
//                               / qLower
//
//    Observe that moving from 'qCurrent' to 'qLower' depletes the entire
//    reserve of 'tag1', within the interval '[qLower, qUpper]' (because we
//    cannot go further than that without transitioning to a new interval).
//    Hence, the total reserve of 'tag1' within the interval '[qLower, qUpper]'
//    is proportional to 'integral1' which is given by the above formula.
//
//    The values 'integral0' and 'integral1' are stored among the dynamic
//    parameters. This is because storing and updating them with every swap is
//    more gas efficient than recalculating them.
//
//    To summarize, in order to execute a swap,
//
//      - the function 'w' is formed by reading the members of the curve
//        sequence from the protocol's storage,
//   
//      - the kernel function 'k' is formed by reading its breakpoints from the
//        pool's storage smart contract, and
//
//      - the outgoing amount from the pool and the incoming amount to the pool
//        are determined by integrating the liquidity distribution function
//        'k(w(.))'.
//
//    An alternative way to look at the notion of liquidity distribution is to
//    imagine a traditional automated market making (AMM) diagram as
//    illustrated below:
//
//                tag1   pUpper
//                  ^   /
//                  |  /
//                  | /
//                  *
//                  |.
//                  | .
//                  |  .    
//                  |   .           pCurrent
//                  |     .        /
//                  |       .     /
//                  |         .  /           pTarget
//        integral1 + - - - - - *           /
//                  |           |  .       /         pLower
//                  |           |     .   /         /
//                  |           |        *         /
//                  |           |            .    /
//                  +-----------+----------------*----> tag0
//                              |
//                          integral0 
//
//    where the horizontal and vertical coordinates, respectively, correspond
//    to the reserves of 'tag0' and 'tag1', in the active liquidity interval.
//
//    Remember that the current reserve of 'tag0' in '[qLower, qUpper]' is
//    proportional to 'integral0' and the current reserve of 'tag1' in the same
//    interval is proportional to 'integral1'. Because of this, the point
//    '(integral0, integral1)' in the above diagram is indicated as 'pCurrent'
//    which is the current price of the pool. As a result, '0 - pCurrent' is
//    equal to the slope of the diagram at the point '(integral0, integral1)'.
//    
//    A swapper is permitted to move to any point that belongs to the above
//    diagram by giving or taking appropriate amounts of 'tag0' and 'tag1'.
//    When a swapper moves on the above diagram we calculate the outgoing and
//    incoming amounts of 'tag0' and 'tag1' by computing the two integrals
//    'currentToTarget' and 'incomingCurrentToTarget'. In short, the shape of
//    the above diagram is determined by the liquidity distribution function
//    'k(w(.))'.
//
//    As we will discuss later in this script, after a movement to 'pTarget',
//    the curve sequence is amended in preparation for the next swap which
//    renders a different liquidity distribution function. Such amendment also
//    leads to a new AMM diagram with the following properties:
//
//    - The new diagram intersects with the old one at the point 'pTarget'.
//      This is due to the conservation of interval reserves.
//
//    - The new diagram is tangent to the old one at point 'pTarget'. This is
//      because our transition to a new AMM diagram should not change the price
//      of the pool, i.e., the slopes of the new diagrams should be the same as
//      the old diagrams at the intersection point which means that the two are
//      tangent.
//
//    The proposed structure for the kernel function enables the pool creators
//    to build custom AMM diagrams. Additionally, the proposed structure for
//    the curve sequence allows the protocol to keep track of AMM diagrams,
//    efficiently. In other words, the curve sequence and the kernel function
//    provide us with an efficient method to store the geometry of AMM diagrams
//    and to transform them into new ones.
//
//    Now, in order to derive the outgoing and incoming amounts from the
//    integral values 'currentToTarget' and 'incomingCurrentToTarget' we need
//    to access the static parameters that are explained next.
//
//  - The static parameters of the pool are read from the same storage smart 
//    contract whose address is calculated using the dynamic parameter
//    'staticParamsStoragePointer'. This includes the following parameters:
//
//    - 'sqrtOffset': This is the square root of 'pOffset' in 'X127'
//      representation, i.e.,
//
//        'sqrtOffset := (2 ** 127) * sqrt(pOffset)'.
//
//      This value is used frequently for calculating any amount of 'tag1'.
//      Because of this, we calculate it at the time of initialization and
//      store it among the static parameters.
//
//    - 'sqrtInverseOffset': This is the square root of '1 / pOffset' in 'X127'
//      representation, i.e.,
//
//        'sqrtInverseOffset := (2 ** 127) / sqrt(pOffset)'
//
//      This value is used frequently for calculating any amount of 'tag0'.
//      Because of this, we calculate it at the time of initialization and
//      store it among the static parameters.
//
//    - 'outgoingMax': This value is a kernel parameter in 'X216'
//      representation which is defined as follows:
//
//                             - 8     / qSpacing
//          outgoingMax      e        |    - h / 2
//        '------------- := ------- * |  e         k(h) dh'.
//           2 ** 216          2      |
//                                   / 0
//
//      'outgoingMax' is used frequently for calculating any amount of 'tag0'
//      and 'tag1'. Because of this, we calculate 'outgoingMax' and its modular
//      inverse at the time of initialization or anytime that the kernel
//      function is modified and then we store the resulting values among the
//      static parameters.
//
//      Now, we have all of the parameters that are needed to calculate the
//      outgoing amount from the pool and the incoming amount to the pool as
//      long as we remain within the current active liquidity interval.
//
//      For a price increasing swap we have:
//                                                               growth
//        'amount0Partial := sqrtInverseOffset * sharesTotal * ---------- * 
//                                                              2 ** 111
//                            currentToTarget
//                           -----------------',
//                              outgoingMax
//                                                        growth
//        'amount1Partial := sqrtOffset * sharesTotal * ---------- * 
//                                                       2 ** 111
//                            incomingCurrentToTarget
//                           -------------------------',
//                                  outgoingMax
//
//      where 'amount0Partial' denotes the amount of outgoing 'tag0' from the
//      pool and 'amount1Partial' denotes the amount of incoming 'tag1' to the
//      pool, as a result of swapping within the active liquidity interval,
//      where both of the amounts are in 'X127' representation.
//
//      Similarly, for a price decreasing swap we have:
//                                                               growth
//        'amount0Partial := sqrtInverseOffset * sharesTotal * ---------- * 
//                                                              2 ** 111
//                            incomingCurrentToTarget
//                           -------------------------',
//                                  outgoingMax
//                                                        growth
//        'amount1Partial := sqrtOffset * sharesTotal * ---------- * 
//                                                       2 ** 111
//                            currentToTarget
//                           -----------------',
//                              outgoingMax
//
//      where 'amount0Partial' denotes the amount of incoming 'tag0' to the
//      pool and 'amount1Partial' denotes the amount of outgoing 'tag1' from
//      the pool, as a result of swapping within the active liquidity interval,
//      where both of the amounts are in 'X127' representation.
//
//    - 'incomingMax': This value is a kernel parameter in 'X216'
//      representation which is defined as follows:
//
//                             - 8 - qSpacing / 2     / qSpacing
//          incomingMax      e                       |    + h / 2
//        '------------- := ---------------------- * |  e         k(h) dh'.
//           2 ** 216                  2             |
//                                                  / 0
//
//      Consider a scenario where the price of the pool is moved all the way
//      from the left interval boundary 'qLower', to the right interval
//      boundary 'qUpper', as part of a swap. In this case, let 
//      'amount0Partial' denote the amount of outgoing 'tag0' from the pool and
//      let 'amount1Partial' denote the amount of incoming 'tag1' to the pool,
//      as a result of swapping within the entire interval, '[qLower, qUpper]'
//      where both of the amounts are in 'X127' representation. Then, we have:
//
//        'amount0Partial ==
//                                             growth
//         sqrtInverseOffset * sharesTotal * ---------- *
//                                            2 ** 111
//
//                            - 8     / qUpper
//           2 ** 216       e        |                     - h / 2
//         ------------- * ------- * |   k(h - qLower) * e         dh ==
//          outgoingMax       2      |
//                                  / qLower
//
//                                             growth
//         sqrtInverseOffset * sharesTotal * ---------- *
//                                            2 ** 111
//
//                            - 8 - qLower / 2     / qSpacing
//           2 ** 216       e                     |            - h / 2
//         ------------- * -------------------- * |   k(h) * e         dh ==
//          outgoingMax              2            |
//                                               / 0
//
//                                             growth       - qLower / 2
//         sqrtInverseOffset * sharesTotal * ---------- * e              '
//                                            2 ** 111
//
//      and
//
//        'amount1Partial ==
//                                      growth
//         sqrtOffset * sharesTotal * ---------- *
//                                     2 ** 111
//
//                            - 8     / qUpper
//           2 ** 216       e        |                     + h / 2
//         ------------- * ------- * |   k(h - qLower) * e         dh ==
//          outgoingMax       2      |
//                                  / qLower
//
//                                      growth       2 ** 216
//         sqrtOffset * sharesTotal * ---------- * ------------- * 
//                                     2 ** 111     outgoingMax
//
//            - 8 + (qUpper - qSpacing) / 2     / qSpacing
//          e                                  |            + h / 2
//         --------------------------------- * |   k(h) * e         dh ==
//                         2                   |
//                                            / 0
//
//                                      growth
//         sqrtOffset * sharesTotal * ---------- * 
//                                     2 ** 111
//
//          incomingMax      + qUpper / 2
//         ------------- * e              '.
//          outgoingMax
//
//      Consider another scenario where the price of the pool is moved all the
//      way from the right interval boundary 'qUpper', to the left interval
//      boundary 'qLower', as part of a swap. In this case, let
//      'amount1Partial' denote the amount of outgoing 'tag1' from the pool and
//      let 'amount0Partial' denote the amount of incoming 'tag0' to the
//      pool, as a result of swapping within the the entire interval,
//      '[qLower, qUpper]' where both of the amounts are in 'X127'
//      representation. Then, we have:
//
//        'amount1Partial ==
//                                      growth
//         sqrtOffset * sharesTotal * ---------- *
//                                     2 ** 111
//
//                            - 8     / qUpper
//           2 ** 216       e        |                     + h / 2
//         ------------- * ------- * |   k(qUpper - h) * e         dh ==
//          outgoingMax       2      |
//                                  / qLower
//
//                                      growth
//         sqrtOffset * sharesTotal * ---------- *
//                                     2 ** 111
//
//                            - 8 + qUpper / 2     / qSpacing
//           2 ** 216       e                     |            - h / 2
//         ------------- * -------------------- * |   k(h) * e         dh ==
//          outgoingMax              2            |
//                                               / 0
//
//                                      growth       + qUpper / 2
//         sqrtOffset * sharesTotal * ---------- * e              '.
//                                     2 ** 111
//
//      and
//
//        'amount0Partial ==
//                                             growth
//         sqrtInverseOffset * sharesTotal * ---------- *
//                                            2 ** 111
//
//                            - 8     / qUpper
//           2 ** 216       e        |                     - h / 2
//         ------------- * ------- * |   k(qUpper - h) * e         dh ==
//          outgoingMax       2      |
//                                  / qLower
//
//                                             growth       2 ** 216
//         sqrtInverseOffset * sharesTotal * ---------- * ------------- * 
//                                            2 ** 111     outgoingMax
//
//            - 8 - (qLower + qSpacing) / 2     / qSpacing
//          e                                  |            + h / 2
//         --------------------------------- * |   k(h) * e         dh ==
//                          2                  |
//                                            / 0
//
//                                             growth
//         sqrtInverseOffset * sharesTotal * ---------- * 
//                                            2 ** 111
//
//          incomingMax      - qLower / 2
//         ------------- * e              '.
//          outgoingMax
//
//      Hence, in order to facilitate the calculation of 'amount0Partial' and
//      'amount1Partial' in such scenarios, we calculate 'incomingMax' at the
//      time of initialization or anytime that the kernel function is modified
//      and then we store the resulting value among the static parameters.
//
//      Lastly, we are going to prove the inequality
//
//        'incomingMax >= outgoingMax'
//
//      which will be used later in this script. According to the definitions
//      for 'outgoingMax' and 'incomingMax', we have:
//
//                             - 8 - qSpacing / 2     / qSpacing
//          incomingMax      e                       |    + h / 2
//        '------------- := ---------------------- * |  e         k(h) dh
//           2 ** 216                  2             |
//                                                  / 0
//
//                             - 8     / qSpacing
//                           e        |             - (qSpacing - h) / 2
//                       == ------- * |    k(h) * e                      dh
//                             2      |
//                                   / 0
//
//                             - 8     / qSpacing
//                           e        |           - h / 2        outgoingMax
//                       >= ------- * |  k(h) * e         dh == -------------'.
//                             2      |                           2 ** 216
//                                   / 0
//
//      which is concluded from Hardy–Littlewood inequality and the fact that
//      'exp(- (qSpacing - h) / 2)' is an increasing rearrangement of
//      'exp(- h / 2)'.
//  
//  - In the previous steps we read the dynamic parameters, the curve sequence,
//    the kernel function, and the static parameters. The next step is to move
//    the price towards 'qNext' until any of the following conditions are met:
//
//    (a) 'amountSpecified' is fulfilled, after which the swap is halted.
//
//    (b) 'qLimit' is reached, after which the swap is halted.
//
//    (c) 'qNext' is reached, after which we transition to a new interval.
//
//    Before doing so, we need to verify the condition,
//
//      'sharesTotal >= crossThreshold'.
//
//    If true, we move the price within the current interval, if not we halt
//    the swap.
//
//    As we move the price from 'qCurrent' towards 'qNext', the integrals
//    'currentToTarget' and 'incomingCurrentToTarget' are continuously
//    incremented as they are cumulatively calculated piece by piece. This
//    process involves exploring the liquidity distribution function 'k(w(h))'
//    within the active liquidity interval. Since 'k(w(.))' is a piecewise
//    linear function, we proceed piece by piece and we increment both
//    'currentToTarget' and 'incomingCurrentToTarget' as we move forward. The
//    process of exploring 'k(w(.))' is explained later in this script and in
//    'Interval.sol'.
//
//    In the present example, since 'zeroForOne == True' and
//    'amountSpecified == +oo > 0', we have:
//
//      'zeroForOne == exactInput'
//
//    which indicates that 'amountSpecified' is with respect to 'tag0'.
//
//    Remember that for price decreasing swaps (as is the case in this
//    example), as long as we remain within the current active liquidity
//    interval, the amount of incoming 'tag0' is calculated as:
//
//                                                             growth
//      'amount0Partial == sqrtInverseOffset * sharesTotal * ---------- * 
//                                                            2 ** 111
//                          incomingCurrentToTarget
//                         -------------------------',
//                                outgoingMax
//
//    which means that in order for us to meet the stopping criteria (a), we
//    should have:
//                                                                growth
//      '|amountSpecified| == sqrtInverseOffset * sharesTotal * ---------- * 
//                                                               2 ** 111
//                             incomingCurrentToTarget
//                            -------------------------',
//                                   outgoingMax
//    or equivalently,
//
//      'incomingCurrentToTarget == 
//
//                      |amountSpecified|          1          2 ** 111
//       outgoingMax * ------------------- * ------------- * ----------'.
//                      sqrtInverseOffset     sharesTotal      growth
//
//    As we increment 'currentToTarget' and 'incomingCurrentToTarget' by
//    moving towards 'qNext', at every step (i.e., with each piece of the
//    liquidity distribution function 'k(w(.))') we need to determine whether
//    'amountSpecified' is fulfilled or not. To that end, before starting the
//    exploration, the protocol calculates the right hand side of the above
//    equation, i.e.,
//
//                      |amountSpecified|          1          2 ** 111
//       outgoingMax * ------------------- * ------------- * ----------'.
//                      sqrtInverseOffset     sharesTotal      growth
//
//    which is regarded as 'integralLimit', and stores its 'X216'
//    representation in the memory space which is pointed to by
//    '_integralLimit_'.
//
//    Consider a hypothetical swap for which 'exactInput == false'. Then, every
//    time that we increment 'currentToTarget', we check whether it has
//    exceeded 'integralLimit'. Once it has, we use the method
//    'searchOutgoingTarget' in 'Interval.sol' to find the precise value
//
//      'qTarget := log(pTarget / pOffset)'
//
//    in order to have
//
//      'currentToTarget == integralLimit'
//
//    which guarantees that 'amountSpecified' is fulfilled.
//
//    If 'exactInput == true', as is the case in our current example, every
//    time that we increment 'incomingCurrentToTarget', we check whether it has
//    exceeded 'integralLimit'. Once it has, we use the method
//    'searchIncomingTarget' in 'Interval.sol' to find the precise value
//
//      'qTarget := log(pTarget / pOffset)'
//
//    in order to have
//
//      'incomingCurrentToTarget == integralLimit'
//
//    which guarantees that 'amountSpecified' is fulfilled.
//
//    After either of the above searches, the price of the pool is moved to
//    'qTarget' and the corresponding outgoing and incoming amounts are
//    calculated.
//
//    Throughout the execution of the swap, whenever we enter a new liquidity
//    interval, both 'amountSpecified' and 'integralLimit' are updated. This is
//    further explained in the next step.
//
//    However, remember that in the present example, we have
//    'amountSpecified == +oo' which means that:
//
//      'integralLimit := outgoingMax * 
//
//        |amountSpecified|          1          2 ** 111
//       ------------------- * ------------- * ---------- == +oo'.
//        sqrtInverseOffset     sharesTotal      growth
//
//    Hence, 'incomingCurrentToTarget' may never exceed 'integralLimit' and the
//    stopping criteria (a) is not reachable. Put simply, since
//    'amountSpecified' is equal to infinity, we may never reach it and we only
//    need to worry about 'qLimit' and 'qNext'.
//
//    In order to keep track of (b) and (c) concurrently, the protocol
//    calculates
//
//      'qLimitWithinInterval := min(max(qLower, qLimit), qUpper)'
//
//    and stores it in the memory space which is referred to by
//    '_logPriceLimitOffsettedWithinInterval_'. As we move forward with pieces
//    of the liquidity distribution function, we continuously check whether
//    'qLimitWithinInterval' is reached. If so, we either need to halt the swap
//    (stopping criteria (b)) or transition to a new interval (stopping
//    criteria (c)).
//
//    In our example, it can be easily observed that
//
//      'qLimitWithinInterval == qNext'
//
//    as illustrated below:
//
//                                             qLimitWithinInterval
//                                                      |
//                  qLimit                              |  qCurrent
//                     |                                |     |
//     ... <--+-------------+-------------+-------------+-------------+--> ...
//                                                      |             |
//                                                    qNext         qBack
//
//    Hence, in the present active liquidity interval, we do not need to worry
//    about 'qLimit' either and we can move forward until we reach 'qNext'.
//    After that, we need to update a number of parameters, including:
//
//    - 'amount0': This is the total amount of 'tag0' which is traded as a
//      result of this swap. In this example, since our swap is price
//      decreasing, we should have 'amount0 > 0' which indicates that 'amount0'
//      is incoming to the pool. Hence, according to the above formulas, with
//      each interval that we transact in, 'amount0' should be incremented by:
//
//                                                               growth
//        'amount0Partial := sqrtInverseOffset * sharesTotal * ---------- *
//                                                              2 ** 111
//                            incomingCurrentToTarget
//                           -------------------------'
//                                  outgoingMax
//
//    - 'amount1': This is the total amount of 'tag1' which is traded as a
//      result of this swap. In this example, since our swap is price
//      decreasing, we should have 'amount1 < 0' which indicates that 'amount1'
//      is outgoing from the pool. Hence, according to the above formulas, with
//      each interval that we transact in, 'amount1' should be decremented by:
//
//                                                        growth
//        'amount1Partial := sqrtOffset * sharesTotal * ---------- *
//                                                       2 ** 111
//                            currentToTarget
//                           -----------------'
//                              outgoingMax
//
//    - 'amountSpecified': Since the swap is partially fulfilled, we should
//      decrement 'amountSpecified' by 'amount0Partial' to reflect this:
//
//        'amountSpecified -= amount0Partial'.
//
//    - 'curve': As explained before, when we transact in a liquidity interval,
//      as part of a swap, we then need to amend the curve sequence for that
//      interval in preparation for the next swap. In this example, the
//      amendment is straightforward. Since we are about to transition out of
//      the interval '[qLower, qUpper]', it should turn into an inactive
//      interval. Hence, the corresponding curve sequence for this interval
//      should transform into a sequence of length two as is the case for every
//      inactive liquidity interval. Following the pattern that was introduced
//      earlier for inactive liquidity intervals, the amended curve sequence
//      for '[qLower, qUpper]' should be:
//
//        'q[0] := qUpper',
//        'q[1] := qLower'.
//
//      This amendment, transforms the function 'w' associated with
//      '[qLower, qUpper]' from the following:
//
//            w(q)
//              ^
//      spacing |                /
//              |               /
//              |              /
//              |             /
//              |            /
//              |           /
//              |          /
//              |\
//              | \
//              |  \
//              |   \
//              |        /
//              |       /
//              |      /
//              |     /
//            0 +----+----+-------+-> q
//           qLower  |    |       |
//                   |   q[2]  qUpper
//                   |
//               qCurrent
//
//      to a new function:
//
//        'wAmended(q) := q - qLower'
//
//      which can be plotted as follows:
//
//          wAmended(q)
//              ^
//      spacing |                /
//              |               /
//              |              /
//              |             /
//              |            /
//              |           /
//              |          /
//              |         /
//              |        /
//              |       /
//              |      /
//              |     /
//              |    /
//              |   /
//              |  /
//              | /
//              |/
//            0 +-----------------+-> q
//           qLower               |
//                             qUpper
//
//      As we will demonstrate next, this procedure results in positive growth
//      for liquidity providers.
//
//    - 'growth': As discussed earlier, before transitioning out of the
//      interval '[qLower, qUpper]', the curve sequence for this interval is
//      amended. This action, changes the function 'w' to 'wAmended' which in
//      turn changes the liquidity distribution function from 'k(w(.))' to
//      'k(wAmended(.))'. However, the amount of reserve for 'tag0' within
//      '[qLower, qUpper]' should stay the same before and after the amendment
//      of the curve sequence. This is because modifying the curve sequence is
//      a change in our trading policy and it does not introduce or remove any
//      amount of liquidity. Hence, in order to conserve the amount of 'tag0'
//      within '[qLower, qUpper]' despite the transformation of 'w' to
//      'wAmended', we need to make an adjustment to the 'growth' value and
//      turn it into 'growthAmended'. In order to determine 'growthAmended',
//      the following equation is solved:
//
//        'totalReserveOfTag0Before == totalReserveOfTag0After'
//
//      where 'totalReserveOfTag0Before' is the total amount of 'tag0' within
//      '[qLower, qUpper]' which is calculated based on 'k(w(.))', whereas
//      'totalReserveOfTag0After' is the same value calculated based on
//      'k(wAmended(.))'. The two sides of the equation can be derived as:
//
//        'totalReserveOfTag0Before = sqrtInverseOffset * sharesTotal * 
//
//                                         - 8     / qUpper
//           growth       2 ** 216       e        |    - h / 2
//         ---------- * ------------- * ------- * |  e         k(w(h)) dh',
//          2 ** 111     outgoingMax       2      |
//                                               / qLower
//
//        'totalReserveOfTag0After = sqrtInverseOffset * sharesTotal * 
//
//          growthAmended       2 ** 216
//         --------------- * ------------- *
//             2 ** 111       outgoingMax
//
//            - 8     / qUpper
//          e        |    - h / 2
//         ------- * |  e         k(wAmended(h)) dh',
//            2      |
//                  / qLower
//
//      Hence, 'growthAmended' can be derived as:
//
//                                           / qUpper
//                                          |    - h / 2
//                                          |  e         k(w(h)) dh
//                                          |
//                                         / qLower
//        'growthAmended == growth * ---------------------------------'.
//                                       / qUpper
//                                      |    - h / 2
//                                      |  e         k(wAmended(h)) dh
//                                      |
//                                     / qLower
//
//      Observe that 'wAmended' is a monotonically non-decreasing rearrangement
//      of 'w'. This is because pieces of 'wAmended' can be flipped and
//      rearranged in order to transform its diagram to the diagram of 'w'. On
//      the other hand, since 'k' is a monotonically non-decreasing function,
//      we can conclude that 'k(wAmended(.))' is a monotonically non-decreasing
//      rearrangement of 'k(w(.))'. Hence, according to the Hardy–Littlewood
//      inequality, we have:
//
//            / qUpper                             / qUpper
//           |    - h / 2                         |    - h / 2
//        '  |  e         k(wAmended(h)) dh  <=   |  e         k(w(h)) dh '
//           |                                    |
//          / qLower                             / qLower
//      
//      which concludes that:
//
//        'growthAmended >= growth'.
//
//      This is exactly what we want!
//
//      To summarize, when we transact in a liquidity interval as part of a
//      swap, we then need to amend the curve sequence for that interval. After
//      that, in order to make up for the transformation of 'w' to 'wAmended',
//      the 'growth' value should be incremented according to the above formula
//      for 'growthAmended'.
//
//    - 'qCurrent': Lastly, as we move the price of the pool to 'qNext', the
//      value for 'qCurrent' should be updated to reflect this change. which is
//      illustrated as follows:
//
//                qLimit                              qCurrent
//                   |                                   |
//      ... <--+-------------+-------------+-------------+-------------+--> ...
//                                                       |             |
//                                                     qNext         qBack
//    
//    Now, we are ready to transition out of the interval '[qLower, qUpper]'
//    which is explained next.
//
//  - In the previous step we moved the price of the pool to 'qNext' to
//    partially fulfill the requested swap. In this step, we transition from
//    the original liquidity interval '[qLower, qUpper]' to its adjacent
//    interval '[qLower - qSpacing, qUpper - qSpacing]'. This transition
//    involves updating the following parameters:
//
//    - 'sharesTotal': The current value of 'sharesTotal' reflects the total
//      number of shares within '[qLower, qUpper]'. As we are transitioning to
//      '[qLower - qSpacing, qUpper - qSpacing]', this value should be modified
//      in order to reflect the total number of shares in the new active
//      interval.
//
//      We keep track of the total share values in all of the liquidity
//      intervals via the mapping 'sharesDelta' within protocol's storage. Let
//      'qBoundary' denote an arbitrary boundary for a liquidity interval,
//      i.e.,
//
//        'qBoundary == qLower + j * qSpacing'
//
//      for some integer 'j'. Let 'sharesTotalLeft' and 'sharesTotalRight'
//      denote the total number of shares within the intervals
//
//        '[qBoundary - qSpacing, qBoundary]' and
//        '[qBoundary, qBoundary + qSpacing]',
//
//      respectively. Define:
//
//        'sharesDelta[qBoundary] := sharesTotalRight - sharesTotalLeft'.
//
//      In other words, 'sharesDelta[qBoundary]' is defined as the difference
//      between the total number of shares within the two liquidity intervals
//      that contain 'qBoundary'.
//
//      Hence, for price increasing swaps, as we transition to a new interval,
//      'sharesTotal' should be modified as follows:
//
//        'sharesTotal += sharesDelta[qNext]',
//
//      and for price decreasing swaps, as we transition to a new interval,
//      'sharesTotal' should be modified as follows:
//
//        'sharesTotal -= sharesDelta[qNext]'.
//
//      This way of accounting for the total shares makes liquidity deposit or
//      withdrawal by LPs more efficient. Imagine an example where an LP
//      intends to deposit '100' shares in every interval within the range
//      'qLower - i * qSpacing' to 'qUpper + j * qSpacing', where 'i' and 'j'
//      are arbitrary non-negative integers. In this case, we need to add '100'
//      shares to every one of the following intervals:
//
//        '[qLower - i * qSpacing, qUpper - i * qSpacing]',
//          .
//          .
//          .
//        '[qLower - 1 * qSpacing, qUpper - 1 * qSpacing]',
//        '[qLower               , qUpper               ]',
//        '[qLower + 1 * qSpacing, qUpper + 1 * qSpacing]',
//          .
//          .
//          .
//        '[qLower + j * qSpacing, qUpper + j * qSpacing]'.
//
//      However, it may not be efficient or even possible to enumerated every
//      single one of the 'i + j + 1' intervals and thanks to 'sharesDelta', we
//      do not need to do that! Alternatively, in order to account for the
//      additional '100' shares, the protocol:
//
//      - increments 'sharesDelta[qLower - i * qSpacing]' by '100',
//
//      - increments 'sharesTotal' by '100',
//
//      - decrements 'sharesDelta[qUpper + j * qSpacing]' by '100',
//
//      which is sufficient to updated the total number of shares in every
//      liquidity interval within the intended range.
//
//    - 'growth': In the prior step, we updated the content of the memory space
//      which is pointed to by '_growth_', according to the following formula:
//
//                                          / qUpper
//                                         |    - h / 2
//                                         |  e         k(w(h)) dh
//                                         |
//                                        / qLower
//        'growthAmended == growth * ----------------------------------'.
//                                       / qUpper
//                                      |    - h / 2
//                                      |  e         k(wAmended(h)) dh
//                                      |
//                                     / qLower
//
//      Hence, the current value stored in this memory space reflects the
//      updated liquidity growth within '[qLower, qUpper]' (as a result of the
//      partial swap that moved the price to 'qNext').
//
//      Now, as we are transitioning out of '[qLower, qUpper]', 'growthAmended'
//      which currently resides in the memory has to be written somewhere in
//      the protocol's storage, and then the amount of liquidity growth within
//
//        '[qLower - qSpacing, qUpper - qSpacing]'
//
//      should be loaded in the memory so that we can transact within this new
//      interval.
//
//      We keep track of these 'growth' values for all of the liquidity
//      intervals, via the mapping 'growthMultiplier'. For every integer 'm',
//      let 'growth(m)' denote the 'growth' value for the interval
//
//        '[qLower + m * qSpacing, qUpper + m * qSpacing]'.
//
//      Hence, 'growth(0)' corresponds to '[qLower, qUpper]' which is the
//      current value stored in memory. 
//
//      Now, for every integer 'm >= 1' define:
//
//          growthMultiplier[qLower + m * qSpacing]
//        '----------------------------------------- := 
//                         2 ** 208
//         ---- +oo
//         \            growth(+j)      (- qLower - j * qSpacing) / 2
//         /           ------------ * e                               '.
//         ---- j = m    2 ** 111
//
//      According to the above definition, for every integer 'm >= 1',
//
//          sqrtInverseOffset     growthMultiplier[qLower + m * qSpacing]
//        '------------------- * -----------------------------------------'
//              2 ** 127                         2 ** 208
//
//      is equal to the total amount of 'tag0' corresponding to a single
//      liquidity provider's share in every interval spanning from
//      'qLower + m * qSpacing' to '+oo'.
//
//      Similarly, for every integer 'm >= 1' define:
//
//          growthMultiplier[qUpper - m * qSpacing]
//        '----------------------------------------- := 
//                         2 ** 208
//         ---- +oo
//         \            growth(-j)      (+ qUpper - j * qSpacing) / 2
//         /           ------------ * e                               '.
//         ---- j = m    2 ** 111
//
//      According to the above definition, for every integer 'm >= 1',
//
//          sqrtOffset     growthMultiplier[qUpper - m * qSpacing]
//        '------------ * -----------------------------------------'
//           2 ** 127                     2 ** 208
//
//      is equal to the total amount of 'tag1' corresponding to a single
//      liquidity provider's share in every interval spanning from '-oo' to
//      'qUpper - m * qSpacing'.
//
//      The following illustration further elaborates the notion of 
//      'growthMultiplier':
//
//                                         growthMultiplier[qUpper + qSpacing]
//                                                                    |-->
//       growthMultiplier[qLower - qSpacing]                          |
//           <--|                                                     |
//              |                        growthMultiplier[qUpper]     |
//              |                                   |-->              |
//              |      growthMultiplier[qLower]     |                 |
//              |              <--|                 |                 |
//              |                 |     growth      |                 |
//              |                 |       ==        |                 |
//              |    growth(-1)   |    growth(0)    |    growth(+1)   |
//       ... <--+-----------------+-----------------+-----------------+--> ...
//                                |                 |
//                              qLower           qUpper
//
//      In the above figure, 'growthMultiplier[qUpper]' and
//      'growthMultiplier[qUpper + qSpacing]' point towards '+oo'. This is
//      because these two values are proportional to the the amount of 'tag0'
//      for a single share in every interval within '[qUpper, +oo]' and
//      '[qUpper + qSpacing, +oo]', respectively. This is also the case for
//      every 'growthMultiplier[qBoundary]' where 'qBoundary' is on the right
//      side of the active liquidity interval as it is proportional to the
//      amount of 'tag0' for a single share in every interval within
//      '[qBoundary, +oo]'.
//
//      On the contrary, 'growthMultiplier[qLower]' and
//      'growthMultiplier[qLower - qSpacing]' point towards '-oo'. This is
//      because these two values are proportional to the the amount of 'tag1'
//      for a single share in every interval within '[-oo, qLower]' and
//      '[-oo, qLower - qSpacing]', respectively. This is also the case for
//      every 'growthMultiplier[qBoundary]' where 'qBoundary' is on the left
//      side of the active liquidity interval as it is proportional to the
//      amount of 'tag1' for a single share in every interval whithin
//      '[-oo, qBoundary]'.
//
//      Instead of storing the growth value for each inactive interval, the
//      protocol stores the mapping 'growthMultiplier'.
//
//      This way of accounting for the growth values makes liquidity deposit or
//      withdrawal by LPs more efficient. Imagine an example where an LP
//      intends to deposit '100' shares in every interval within the range
//      'qLower + i * qSpacing' to 'qUpper + j * qSpacing', where 'i' and 'j'
//      are arbitrary positive integers. In this case, we need to calculate the
//      amount of 'tag0' corresponding to '100' shares in every one of the
//      following intervals:
//
//        '[qLower + i       * qSpacing, qUpper + i       * qSpacing]',
//        '[qLower + (i + 1) * qSpacing, qUpper + (i + 1) * qSpacing]',
//          .
//          .
//          .
//        '[qLower + (j - 1) * qSpacing, qUpper + (j - 1) * qSpacing]',
//        '[qLower + j       * qSpacing, qUpper + j       * qSpacing]'.
//
//      However, it may not be efficient or even possible to enumerated every
//      single one of the 'j - i + 1' intervals and thanks to
//      'growthMultiplier', we do not need to do that! Alternatively, the
//      protocol calculates the amount of 'tag0' that needs to be deposited
//      using the following formula:
//
//                sqrtInverseOffset
//        '100 * ------------------- * (
//                    2 ** 127
//
//                          growthMultiplier[qLower + i * qSpacing]
//                         ----------------------------------------- - 
//                                          2 ** 208
//
//                          growthMultiplier[qUpper + j * qSpacing]
//                         -----------------------------------------
//                                          2 ** 208
//         )'.
//
//      The following figure visualizes the direction of the growth multipliers
//      prior to the transition from '[qLower, qUpper]' to the new interval
//      '[qLower - qSpacing, qUpper - qSpacing]':
//
//                           growthMultiplier[qCurrent - qSpacing]
//                                      <--|
//                                         |            growthMultiplier[qBack]
//                                         |                           |-->
//                                         | growthMultiplier[qCurrent]|
//                                         |          <--|             |
//                qLimit                   |             |             |
//                   |                     |  growth(-1) |  growth(0)  |
//      ... <--+-------------+-------------+-------------+-------------+--> ...
//                                                       |             |
//                                                     qNext         qBack
//                                                       |
//                                                    qCurrent
//
//      where 'growth(0) := growthAmended'. As shown in the above figure,
//      'growthMultiplier[qBack]' points towards '+oo' because it is on the
//      right side of the active liquidity interval whereas
//      'growthMultiplier[qCurrent]' and 'growthMultiplier[qCurrent - qSpacing]'
//      point towards '-oo' because they are on the left side of the active
//      liquidity interval.
//
//      As part of this interval transition, we need to take the following
//      steps:
//      
//      - 'growth(-1)' is the value which is supposed to replace
//        'growthAmended' in the memory space which is pointed to by
//        '_growth_'. However, since the protocol does not store growth values
//        for inactive intervals, we do not have direct access to 'growth(-1)'.
//        Because of this, we calculate it via the following formula:
//
//            growth(-1)       - qCurrent / 2
//          '------------ == e                * ( 
//             2 ** 111
//
//             growthMultiplier[qCurrent]
//            ---------------------------- - 
//                      2 ** 208
//
//             growthMultiplier[qCurrent - qSpacing]
//            ---------------------------------------
//                           2 ** 208
//           )'
//
//      - Next, we need to recalculate 'growthMultiplier[qCurrent]' because it
//        is currently pointing to '-oo' since 'qCurrent' is on the left side
//        of '[qLower, qUpper]'. However, once we transition, 'qCurrent' would
//        be on the right side of the active liquidity interval
//
//          '[qLower - qSpacing, qUpper - qSpacing]'
//
//        which means that it should point to '+oo'. Hence,
//        'growthMultiplier[qCurrent]' is recalculated via the following
//        formula:
//
//            growthMultiplier[qCurrent]      growthMultiplier[qBack]
//          '---------------------------- := ------------------------- +
//                    2 ** 208                       2 ** 208
//
//            growthAmended      - qCurrent / 2
//           --------------- * e                '.
//              2 ** 111
//
//        Observe that according to the above formula, 'growthAmended' is
//        incorporated into 'growthMultiplier[qCurrent]' which is where it is
//        kept track of.
//
//      The following figure illustrates the above modification of the
//      'growthMultiplier' mapping:
//
//                           growthMultiplier[qCurrent - qSpacing]
//                                      <--|
//                                         |            growthMultiplier[qBack]
//                                         |                           |-->
//                                         | growthMultiplier[qCurrent]|
//                                         |             |-->          |
//                qLimit                   |             |             |
//                   |                     |             |             |
//      ... <--+-------------+-------------+-------------+-------------+--> ...
//                                                       |             |
//                                                     qNext         qBack
//                                                       |
//                                                    qCurrent
//
//    - 'qBack' and 'qNext': Since we are dealing with a price decreasing swap,
//      the values 'qBack' and 'qNext' should be modified as follows in order
//      to represent the new liquidity interval that we are transitioning to:
//
//        'qBack -= qSpacing',
//        'qNext -= qSpacing'.
//
//      which is illustrated below:
//
//                qLimit                              qCurrent
//                   |                                   |
//      ... <--+-------------+-------------+-------------+-------------+--> ...
//                                         |             |
//                                       qNext         qBack
//    
//    - 'curve': As we discussed before, since
//
//          '[qLower - qSpacing, qUpper - qSpacing]'
//
//      is currently inactive, its corresponding curve sequence is composed of
//      only two members:
//
//      'q[0] := qUpper - qSpacing',
//      'q[1] := qLower - qSpacing'.
//
//      As part of the transition, we discard the previous curve sequence and
//      initiate this above curve sequence in memory.
//
//    Now, the transition to '[qLower - qSpacing, qUpper - qSpacing]' is
//    complete and throughout the remainder of this example, we refer to this
//    interval as the active liquidity interval. Additionally, we redefine:
//
//      'qUpper := qUpper - qSpacing', 
//      'qLower := qLower - qSpacing'
//
//    which allows us to continue using the notation '[qLower, qUpper]' in
//    order to refer to the active liquidity interval.
//
//  - In this step, we need to determine whether we should explore the active
//    interval '[qLower, qUpper]' or to cross it entirely, i.e., all the way
//    from 'qBack' to 'qNext'. In the former case, we need to integrate the
//    liquidity distribution function 'k(w(.))' piece by piece through which
//    the 'incomingCurrentToTarget' and 'currentToTarget' are calculated. As we
//    discussed before, the calculation of these integrals leads to
//    'amount0Partial' and 'amount1Partial', respectively. However, the latter
//    case is more efficient because if the active interval is crossed 
//    entirely, then the precalculated integrals 'incomingMax' and
//    'outgoingMax' can be used to determine 'amount0Partial' and
//    'amount1Partial'. In order for the protocol to be able to cross the
//    active interval entirely the following two criteria should be met:
//
//    (a) The cross must not violate 'qLimit'. In other words, for price
//        increasing swaps we should have
//
//          'qNext <= qLimit'
//
//        and for price decreasing swaps, we should have
//
//          'qLimit <= qNext'.
//
//        which is the case in the present example.
//
//    (b) The cross must not violate 'amountSpecified'. In order words, if
//        'exactInput == false', then the outgoing amount from the pool as a
//        result of crossing all the way from 'qBack' to 'qNext' must not
//        exceed the remaining absolute value '0 - amountSpecified'. Similarly,
//        if 'exactInput == true', then the incoming amount to the pool as a
//        result of crossing all the way from 'qBack' to 'qNext' must not
//        exceed the remaining value 'amountSpecified'.
//
//        In order to verify this, we first need to recalculate 'integralLimit'
//        based on the decremented value for '|amountSpecified|':
//        
//          'integralLimit :=
//
//                          |amountSpecified|          1          2 ** 111
//           outgoingMax * ------------------- * ------------- * ----------
//                          sqrtInverseOffset     sharesTotal      growth
//
//           == +oo'.
//
//        which remains equal to '+oo' for this example.
//
//        Next, we need to define the notion of 'integralLimitInterval' which
//        is compared with 'integralLimit' in order to determine if
//        'amountSpecified' is violated or not. Consider the following four
//        scenarios:
//
//        - If the swap is price increasing and 'exactInput == false', define:
//
//                                         - 8     / qUpper
//            integralLimitInterval      e        |    - h / 2
//          '----------------------- := ------- * |  e         k(h - qLower) dh
//                   2 ** 216              2      |
//                                               / qLower
//
//                - qLower / 2    outgoingMax
//           == e              * -------------'
//                                 2 ** 216
//
//        - If the swap is price increasing and 'exactInput == true', define:
//
//                                         - 8     / qUpper
//            integralLimitInterval      e        |    + h / 2
//          '----------------------- := ------- * |  e         k(h - qLower) dh
//                   2 ** 216              2      |
//                                               / qLower
//
//                + qUpper / 2    incomingMax
//           == e              * -------------'
//                                 2 ** 216
//
//        - If the swap is price decreasing and 'exactInput == false', define:
//
//                                         - 8     / qUpper
//            integralLimitInterval      e        |    + h / 2
//          '----------------------- := ------- * |  e         k(qUpper - h) dh
//                   2 ** 216              2      |
//                                               / qLower
//
//                + qUpper / 2    outgoingMax
//           == e              * -------------'
//                                 2 ** 216
//
//        - If the swap is price decreasing and 'exactInput == true', define:
//
//                                         - 8     / qUpper
//            integralLimitInterval      e        |    - h / 2
//          '----------------------- := ------- * |  e         k(qUpper - h) dh
//                   2 ** 216              2      |
//                                               / qLower
//
//                - qLower / 2    incomingMax
//           == e              * -------------'
//                                 2 ** 216
// 
//        In the first and the fourth cases above, 'amountSpecified' is in
//        'tag0'. By crossing the active interval entirely, the absolute value
//        '|amountSpecified|' is decremented by:
//
//                                               growth
//          'sqrtInverseOffset * sharesTotal * ---------- * 
//                                              2 ** 111
//            integralLimitInterval
//           -----------------------',
//                 outgoingMax
// 
//        In the second and the third cases above, 'amountSpecified' is in
//        'tag1'. By crossing the active interval entirely, the absolute value
//        '|amountSpecified|' is decremented by:
//
//                                        growth      integralLimitInterval
//          'sqrtOffset * sharesTotal * ---------- * -----------------------',
//                                       2 ** 111          outgoingMax
//
//        Hence, in both cases, by crossing the active interval, the limit
//        imposed by 'amountSpecified' is not violated if and only if:
//        
//          'integralLimitInterval <= integralLimit'.
//
//    In the present example, since 'integralLimit == +oo' and
//    'qLimit <= qNext' both (a) and (b) are satisfied which means that we can
//    cross the active interval and move the price to 'qNext' directly, while
//    determining the outgoing and incoming amounts based on the precalculated
//    parameters of the pool.
//
//    Once again, before the execution of this cross, we need to verify the
//    condition, 'sharesTotal >= crossThreshold'. If not met, the swap call is
//    halted and the current values accumulated as 'amount0' and 'amount1' are
//    exchanged.
//
//  - In order to move the price from 'qBack' to 'qNext', we need to update a
//    number of parameters, including:
//
//    - 'amount0': According to the above formulas, as we move the price all
//      the way from 'qBack' to 'qNext', 'amount0' should be incremented by:
//
//                                                               growth
//        'amount0Partial == sqrtInverseOffset * sharesTotal * ---------- *
//                                                              2 ** 111
//          incomingMax      - qLower / 2
//         ------------- * e              '.
//          outgoingMax
//
//    - 'amount1': According to the above formulas, as we move the price all
//      the way from 'qBack' to 'qNext', 'amount1' should be decremented by:
//
//                                                        growth
//        'amount1Partial == sqrtOffset * sharesTotal * ---------- * 
//                                                       2 ** 111
//                             + qUpper / 2
//                           e              '.
//
//    - 'amountSpecified': Since the swap is partially fulfilled, we should
//      decrement 'amountSpecified' by 'amount0Partial' to reflect this:
//
//        'amountSpecified -= amount0Partial'.
//
//    - 'curve': Following the pattern that was introduced earlier, for
//      inactive liquidity intervals, the amended curve sequence for
//      '[qLower, qUpper]' should be:
//
//        'q[0] := qUpper',
//        'q[1] := qLower'.
//
//      This amendment, transforms the function 'w' associated with
//      '[qLower, qUpper]' from the following:
//
//            w(q)
//              ^
//      spacing |\
//              | \
//              |  \
//              |   \
//              |    \
//              |     \
//              |      \
//              |       \
//              |        \
//              |         \
//              |          \
//              |           \
//              |            \
//              |             \
//              |              \
//              |               \
//              |                \
//            0 +-----------------+-> q
//           qLower               |
//                              qUpper
//                                |
//                            qCurrent
//
//      to a new function:
//
//        'wAmended(q) := q - qLower'
//
//      which can be plotted as follows:
//
//          wAmended(q)
//              ^
//      spacing |                /
//              |               /
//              |              /
//              |             /
//              |            /
//              |           /
//              |          /
//              |         /
//              |        /
//              |       /
//              |      /
//              |     /
//              |    /
//              |   /
//              |  /
//              | /
//              |/
//            0 +-----------------+-> q
//           qLower               |
//                              qUpper
//
//      As we will demonstrate next, this procedure results in growth for
//      liquidity providers.
//
//    - 'growth': As discussed earlier, since the liquidity distribution
//      function 'k(w(.))' is modified to 'k(wAmended(.))', we need to make an
//      adjustment to the 'growth' value and turn it into 'growthAmended'.
//      In order to determine 'growthAmended', the following equation is
//      solved:
//
//        'totalReserveOfTag0Before == totalReserveOfTag0After'
//
//      where 'totalReserveOfTag0Before' is the total amount of 'tag0' within
//      '[qLower, qUpper]' which is calculated based on 'k(w(.))', whereas
//      'totalReserveOfTag0After' is the same value calculated based on
//      'k(wAmended(.))'. The two sides of the equation can be derived as:
//
//        'totalReserveOfTag0Before == sqrtInverseOffset * sharesTotal * 
//
//                                         - 8     / qUpper
//           growth       2 ** 216       e        |    - h / 2
//         ---------- * ------------- * ------- * |  e         k(w(h)) dh ==
//          2 ** 111     outgoingMax       2      |
//                                               / qLower
//
//                                             growth       2 ** 216
//         sqrtInverseOffset * sharesTotal * ---------- * ------------- *
//                                            2 ** 111     outgoingMax
//
//            - 8     / qUpper
//          e        |    - h / 2
//         ------- * |  e         k(qUpper - h) dh ==
//            2      |
//                  / qLower
//
//                                             growth
//         sqrtInverseOffset * sharesTotal * ---------- * 
//                                            2 ** 111
//
//          incomingMax      - qLower / 2
//         ------------- * e              '.
//          outgoingMax
//
//      and
//
//        'totalReserveOfTag0After ==
//
//                                            growthAmended
//         sqrtInverseOffset * sharesTotal * --------------- * 
//                                              2 ** 111
//
//                            - 8     / qUpper
//            2 ** 216      e        |    - h / 2
//         ------------- * ------- * |  e         k(h - qLower) dh' == 
//          outgoingMax       2      |
//                                  / qLower
//
//                                            growthAmended
//         sqrtInverseOffset * sharesTotal * --------------- *
//                                              2 ** 111
//
//           - qLower / 2
//         e              '.
//
//
//      Hence, 'growthAmended' is given by the following formula:
//
//                                    incomingMax
//        'growthAmended == growth * -------------'.
//                                    outgoingMax
//
//      As proven earlier, 'incomingMax' is always greater than or equal to
//      'outgoingMax'. Hence, crossing the active interval results in growth.
//
//    - 'qCurrent': Lastly, as we move the price of the pool to 'qNext', the
//      value for 'qCurrent' should be updated to reflect this change., which
//      is illustrated as follows:
//
//                qLimit                qCurrent
//                   |                     |
//      ... <--+-------------+-------------+-------------+-------------+--> ...
//                                         |             |
//                                       qNext         qBack
//
//  - Similar to the prior steps, as we reach 'qNext', we transition from the
//    original liquidity interval '[qLower, qUpper]' to its adjacent interval
//    '[qLower - qSpacing, qUpper - qSpacing]'. This transition involves the
//    adjustment of growth multipliers. In addition we need to update 'growth'
//    'sharesTotal', 'qBack', 'qNext', as well as the curve sequence. The new
//    status of the pool following this transition is illustrated as follows:
//
//                qLimit                qCurrent
//                   |                     |
//      ... <--+-------------+-------------+-------------+-------------+--> ...
//                           |             |
//                         qNext         qBack
//
//  - Similar to the prior steps, as we transition to a new liquidity interval,
//    we determine whether we should cross this new active interval entirely or
//    not. In the present example, since 'qLimit <= qNext' and 
//    'amountSpecified == +oo', we need to cross one more time. This action
//    will modify 'amount0', 'amount1', 'growth', as well as the curve
//    sequence. Additionally, crossing the active interval moves 'qCurrent' to
//    'qNext' which is illustrated below:
//
//                        qCurrent
//                qLimit     |
//                   |       |
//      ... <--+-------------+-------------+-------------+-------------+--> ...
//                           |             |
//                         qNext         qBack
//
//  - Next, we need to perform another transition in order to enter the
//    liquidity interval that contains 'qLimit'. The new status of the pool
//    following this transition is illustrated as follows:
//
//                        qCurrent
//                qLimit     |
//                   |       |
//      ... <--+-------------+-------------+-------------+-------------+--> ...
//             |             |
//           qNext         qBack
//  
//  - Once again, as we transition to a new liquidity interval, we determine
//    whether we should cross this new active interval entirely or not. This,
//    time, since 'qNext < qLimit', we should transact within the active
//    interval as opposed to crossing it. To this end, we move the price
//    towards 'qNext' until either of the following conditions are met:
//
//    (a) 'amountSpecified' is fulfilled.
//
//    (b) 'qLimit' is reached.
//
//    We move the price from 'qCurrent' towards 'qNext' by enumerating pieces
//    of the present liquidity distribution function 'k(w(.))'. To this end,
//    the memory pointers '_begin_' and '_target_' are used in order to keep
//    track of the two endpoints for the current piece under exploration. Here,
//    we refer to these endpoints as 'qBegin' and 'qTarget'.
//
//    We start with 'qBegin == qCurrent' and move forward by continuously
//    updating 'qBegin' and 'qTarget'. In each step, the integrals
//    'currentToTarget' and 'incomingCurrentToTarget' are incremented to
//    account for the outgoing amount from the pool and the incoming amount to
//    the pool.
//
//    While incrementing the two integrals, we need to continuously monitor
//    condition (a). To that end, we once again calculate 'integralLimit'
//
//      'integralLimit := outgoingMax * 
//
//        |amountSpecified|          1          2 ** 111
//       ------------------- * ------------- * ---------- == +oo'.
//        sqrtInverseOffset     sharesTotal      growth
//
//    With each increment of 'incomingCurrentToTarget' we check whether it has
//    exceeded 'integralLimit' in which case the swap is halted (alternatively,
//    in the case where 'exactInput == false', we need to continuously check
//    whether 'currentToTarget' has exceeded 'integralLimit' or not). However,
//    this stopping criteria does not apply to this example because
//    'integralLimit == +oo'.
//
//    Hence, we can move forward until the stopping criteria (b) is met, i.e.,
//    until
//
//      'qTarget == qLimit'.
//
//    Once the above condition is met, we need to update a number of
//    parameters, including:
//
//    - 'amount0': As discussed in the prior steps, the following increment
//      should be applied to 'amount0':
//                                                               growth
//        'amount0Partial := sqrtInverseOffset * sharesTotal * ---------- *
//                                                              2 ** 111
//                            incomingCurrentToTarget
//                           -------------------------'
//                                  outgoingMax
//
//    - 'amount1': As discussed in the prior steps, the following decrement
//      should be applied to 'amount1':
//                                                        growth
//        'amount1Partial := sqrtOffset * sharesTotal * ---------- *
//                                                       2 ** 111
//                            currentToTarget
//                           -----------------'
//                              outgoingMax
//
//    - 'amountSpecified': Since the swap is partially fulfilled, we should
//      decrement 'amountSpecified' by 'amount0Partial' to reflect this:
//
//        'amountSpecified -= amount0Partial'.
//
//    - 'qCurrent': Since we moved the price of the pool to 'qLimit', the value
//      for 'qCurrent' in memory (i.e., the content of the memory space which
//      is pointed to by '_logPriceCurrent_') should be updated to
//
//        'qCurrent := qTarget'.
//
//      This is illustrated as follows:
//
//                qTarget
//                   |
//                qLimit
//                   |
//      ... <--+-------------+-------------+-------------+-------------+--> ...
//             |     |       |
//           qNext   |     qBack
//                   |
//               qCurrent
//
//    - 'curve' and 'growth': Now that the target price is determined as well
//      as the outgoing and incoming amounts, we need to update the AMM curve 
//      in preparation for the next swap. To this end, the curve sequence
//      should be amended. In doing so, we need to respect certain
//      requirements:
//
//      Firstly, remember that the last member of the curve sequence should
//      always correspond to the current price of the pool, i.e., 'qCurrent'.
//      Now that we have set 'qCurrent' to 'qTarget' the curve sequence should
//      be amended with this new value in preparation for the next swap.
//
//      Secondly, we should be mindful of the fact that amending the curve
//      sequence changes the liquidity distribution function from 'k(w(.))' to
//      'k(wAmended(.))' and we need to make sure that this change does not
//      affect our accounting of the total interval reserves with respect to
//      both tags. More precisely, the curve sequence must be amended subject
//      to the following constraints:
//
//        'totalReserveOfTag0Before == totalReserveOfTag0After'
//
//        'totalReserveOfTag1Before == totalReserveOfTag1After'
//
//      where 'totalReserveOfTag0Before' and 'totalReserveOfTag1Before',
//      respectively, are the total reserves of 'tag0' and 'tag1' within
//      '[qLower, qUpper]' that are calculated based on 'k(w(.))', whereas
//      'totalReserveOfTag0After' and 'totalReserveOfTag1After' are the same
//      amounts that are calculated based on 'k(wAmended(.))'.
//
//      The two sides of the first equation can be derived as:
//
//        'totalReserveOfTag0Before := sqrtInverseOffset * sharesTotal * 
//
//                                         - 8     / qUpper
//           growth       2 ** 216       e        |    - h / 2
//         ---------- * ------------- * ------- * |  e         k(w(h)) dh',
//          2 ** 111     outgoingMax       2      |
//                                               / qTarget
//      and
//
//        'totalReserveOfTag0After := 
//
//                                            growthAmended
//         sqrtInverseOffset * sharesTotal * --------------- *
//                                               2 ** 111
//
//                            - 8     / qUpper
//           2 ** 216       e        |    - h / 2
//         ------------- * ------- * |  e         k(wAmended(h)) dh',
//          outgoingMax       2      |
//                                  / qTarget
//
//      which simplify the first equation to:
//
//                               / qUpper
//                              |    - h / 2
//                              |  e         k(wAmended(h)) dh
//                              |
//              growth         / qTarget
//        '--------------- == ---------------------------------'.
//          growthAmended           / qUpper
//                                 |    - h / 2
//                                 |  e         k(w(h)) dh
//                                 |
//                                / qTarget
//
//      The two sides of the second equation can be derived as:
//
//        'totalReserveOfTag1Before := sqrtOffset * sharesTotal * 
//
//                                         - 8     / qTarget
//           growth       2 ** 216       e        |    + h / 2
//         ---------- * ------------- * ------- * |  e         k(w(h)) dh',
//          2 ** 111     outgoingMax       2      |
//                                               / qLower
//      and
//
//        'totalReserveOfTag1After := 
//
//                                     growthAmended      2 ** 216
//         sqrtOffset * sharesTotal * --------------- * ------------- *
//                                        2 ** 111       outgoingMax
//
//            - 8     / qTarget
//          e        |    + h / 2
//         ------- * |  e         k(wAmended(h)) dh',
//            2      |
//                  / qLower
//
//      which simplifies the second equation to:
//
//                               / qTarget
//                              |    + h / 2
//                              |  e         k(wAmended(h)) dh
//                              |
//            growth           / qLower
//        '--------------- == ---------------------------------'.
//          growthAmended           / qTarget
//                                 |    + h / 2
//                                 |  e         k(w(h)) dh
//                                 |
//                                / qLower
//
//      Based on the above equations, finding 'growthAmended' with respect to
//      'k(w(.))' and 'k(wAmended(.))' is straightforward.
//
//      However, in order to satisfy both of the equations, we should have:
//
//            / qTarget                         / qUpper
//           |   + h/2                         |   - h/2
//           |  e      k(wAmended(h)) dh       |  e      k(wAmended(h)) dh
//           |                                 |
//          / qLower                          / qTarget
//        '------------------------------ == ------------------------------'.
//               / qTarget                         / qUpper
//              |    + h/2                        |    - h/2
//              |  e       k(w(h)) dh             |  e       k(w(h)) dh
//              |                                 |
//             / qLower                          / qTarget
//
//      Because of the above constraint, we need to take an additional step
//      prior to amending the curve sequence with 'qTarget'.
//
//      Observe that the current curve sequence is last updated when we
//      transitioned into '[qLower, qUpper]' and it is composed of the
//      following two points:
//
//        'q[0] := qLower',
//        'q[1] := qUpper'.
//
//      The corresponding diagram for the current curve sequence is illustrated
//      as follows:
//
//            w(q)
//              ^
//      spacing |                /
//              |               /
//              |              /
//              |             /
//              |            /
//              |           /
//              |          /
//              |\
//              | \
//              |  \
//              |   \
//              |        /
//              |       /
//              |      /
//              |     /
//            0 +----+----+-------+-> q
//           qLower  |    |       |
//                   |   q[2]  qUpper
//                   |
//               qCurrent
//
//            w(q)
//              ^
//      spacing |\
//              | \
//              |  \
//              |   \
//              |    \
//              |     \
//              |      \
//              |       \
//              |        \
//              |         \
//              |          \
//              |           \
//              |            \
//              |             \
//              |              \
//            0 +-------+------+-> q
//           qLower     |      |
//                      |    qUpper
//                      |
//                   qTarget
//
//      Before amending the curve sequence with 'qTarget', we first determine a
//      point between 'qTarget' and 'qNext == qLower' which is regarded as
//      'qOvershoot':
//
//            w(q)
//              ^
//      spacing |\
//              | \
//              |  \
//              |   \
//              |    \
//              |     \
//              |      \
//              |       \
//              |        \
//              |         \
//              |          \
//              |           \
//              |            \
//              |             \
//              |              \
//              |               \
//              |                \
//            0 +----+----+-------+-> q
//           qLower  |    |       |
//                   |    |     qUpper
//                   |    |
//                   | qTarget
//                   |
//               qOvershoot
//
//      Then, the curve sequence is amended with 'qOvershoot' which leads to
//      the following sequence:
//
//        'q[0] := qUpper',
//        'q[1] := qLower',
//        'q[2] := qOvershoot'.
//
//      and the following diagram:
//
//              ^
//      spacing |\
//              | \
//              |  \
//              |                /
//              |               /
//              |              /
//              |             /
//              |            /
//              |           /
//              |          /
//              |         /
//              |        /
//              |       /
//              |      /
//              |     /
//            0 +----+----+-------+-> q
//           qLower  |    |       |
//                   |    |     qUpper
//                   |    |
//                   |  qTarget
//                   |
//               qOvershoot
//
//      In this case, amending the curve sequence has increased its length.
//      However, this is not always the case. As explained in 'Curve.sol', this
//      process may involve clearing a number of members from the end of the
//      curve sequence and then inserting the new member.
//
//      After the amendment with 'qOvershoot', the resulting curve sequence is
//      then amended with 'qTarget' which leads to the following sequence:
//
//        'q[0] := qUpper',
//        'q[1] := qLower',
//        'q[2] := qOvershoot',
//        'q[3] := qTarget'.
//
//      and the following diagram:
//
//          wAmended(q)
//              ^
//      spacing |\
//              | \
//              |  \
//              |   \
//              |                /
//              |               /
//              |              /
//              |             /
//              |            /
//              |           /
//              |          /
//              |     \
//              |      \
//              |       \
//              |        \
//            0 +----+----+-------+-> q
//           qLower  |    |       |
//                   |    |     qUpper
//                   |    |
//                   | qTarget
//                   |
//               qOvershoot
//
//      The purpose of first amending with 'qOvershoot' is to have an
//      additional degree of freedom in order to satisfy the equation:
//
//        'f(qOvershoot) == 0'
//
//      where
//
//        'f(qOvershoot) :=
//
//            / qUpper                         / qTarget
//           |   - h/2                        |   + h/2
//           |  e      k(wAmended(h)) dh      |  e      k(wAmended(h)) dh
//           |                                |
//          / qTarget                        / qLower
//         ------------------------------ - ------------------------------'.
//               / qUpper                         / qTarget
//              |    - h/2                       |    + h/2
//              |  e       k(w(h)) dh            |  e       k(w(h)) dh
//              |                                |
//             / qTarget                        / qLower
//
//      By investigating the above equation, we can observe that:
//
//        - Both of the denominators are fixed. This is because at this stage,
//          'qTarget' is fully determined either through 'qLimit' or
//          'amountSpecified'. Additionally, the current curve sequence is
//          fixed which dictates the shape of 'w(.)'.
//
//        - Both of the numerators are functions of 'qOvershoot'. This is
//          because 'wAmended(.)' can be fully characterized by
//
//            - the current curve sequence which is fixed,
//
//            - 'qTarget' which is also fixed,
//
//            - and 'qOvershoot' which is the only unknown value that we are
//              trying to determine.
//
//      Hence, in order to update the liquidity distribution function from
//      'k(w(.))' to 'k(wAmended(.))', which updates the AMM diagram of the
//      active interval, we need to solve the above equation with respect to
//      'qOvershoot'. As proven in nofeeswap's yellowpaper, there always exist
//      a root between 'qTarget' and 'qNext' that satisfies:
//
//        'growthAmended >= growth'.
//
//      This root is found via numerical search by running the methods
//      'moveOvershoot' and 'searchOvershoot' from 'Interval.sol'.
//
//      Remember that 'k(w(.))' and 'k(wAmended(.))' are piecewise linear
//      functions whose domains cover the entire active interval. The method
//      'moveOvershoot' from 'Interval.sol' identifies a range within
//      '[qLower, qUpper]':
//
//        - in which 'k(w(.))' is linear,
//
//        - in which 'k(wAmended(.))' is linear, and
//
//        - to which 'qOvershoot' belongs.
//
//      Since 'f(.)' is a continuous function, the membership of a root (i.e.,
//      'qOvershoot') to a particular range can be verified by evaluating the
//      sign of 'f(.)' at the two ends of the range. Hence, in light of the
//      intermediate value theorem, if the signs at the two ends of the range
//      are different, then there has to be a root somewhere within this
//      range.
//
//      Next, the method 'searchOvershoot' from 'Interval.sol' performs a
//      Newton search in order to pinpoint the precise value of 'qOvershoot'
//      within the range that is identified by 'moveOvershoot'.
//
//      Once 'qOvershoot' is calculated, we proceed with the two amendments to
//      the curve sequence via 'qOvershoot' and 'qTarget'.
//
//      After that, we derive 'growthAmended' based on the following formula:
//
//                                          / qTarget
//                                         |    + h / 2
//                                         |  e         k(w(h)) dh
//                                         |
//                                        / qLower
//        'growthAmended == growth * ---------------------------------'.
//                                      / qTarget
//                                     |    + h / 2
//                                     |  e         k(wAmended(h)) dh
//                                     |
//                                    / qLower
//
//      This concludes the update of our liquidity distribution function (or
//      equivalently, the update of our AMM diagram) for the next swap.
//
//  - The last step involves writing the dynamic parameters of the pool as well
//    as the amended curve sequence in the protocol's storage which concludes
//    this example.

// Swap Inputs
// ----------------------------------------------------------------------------
// The following memory pointers correspond to the inputs of the method 'swap'
// from 'Nofeeswap.sol'. Each parameter is read from calldata via the method
// 'readSwapInput' from 'Calldata.sol'. Then, the parameters are transformed to
// appropriate formats and stored in their dedicated memory locations as listed
// below. Throughout the execution of the swap, the following memory pointers
// as well as the corresponding getter functions can be used to access each
// parameter. Moreover, when invoking an applicable hook these input parameters
// are passed to the hook as calldata and they can be accessed via the
// corresponding calldata pointers and getter functions that are listed in
// 'HookCalldata.sol'.
uint16 constant _swapInput_ = 248;

// 'crossThreshold' refers to a minimum limit on the total number of shares
// that should be available in any interval for the 'swap' method to transact
// in that interval.
//
// For example, if 'crossThreshold == 50', then there has to be a minimum of
// 50 shares present in an interval so that the algorithm either enters that
// interval or crosses it entirely. Once we encounter an interval with the
// total number of shares less than 50, the 'swap' call is halted and the price
// of the pool does not go beyond that point.
//
// However, if 'crossThreshold == 0', which is the default, no minimum number
// of shares is imposed.
//
// The calldata layout of the method 'swap' in 'Nofeeswap.sol' does not have a
// slot dedicated to 'crossThreshold'. Instead, the two inputs 'crossThreshold'
// and 'zeroForOne' share the same slot in calldata as illustrated below:
//
//     +---------------------------+---------------------------+
//     | crossThreshold (128 bits) |   zeroForOne (128 bits)   |
//     +---------------------------+---------------------------+
//
// 'crossThreshold' occupies the most significant 128 bits and 'zeroForOne'
// occupies the least significant 128 bits. Hence, 16 bytes are reserved for
// 'crossThreshold' in memory.
uint16 constant _crossThreshold_ = 248;

// The input 'amountSpecified' of the 'swap' method in 'Nofeeswap.sol' is a
// signed integer. If positive ('exactInput == true'), this value represents
// the requested incoming amount to be given to the pool as a result of the
// swap call. If negative ('exactInput == false'), this value represents the
// requested outgoing amount to be taken from the pool as a result of the swap
// call. As an initial step of the swap algorithm, the method 'readSwapInput'
// from 'Calldata.sol' performs the following actions:
//
//  - Reads the integer representation of 'amountSpecified' from the dedicated
//    calldata slot.
//
//  - Caps it by '2 ** 127 - 1' from above and by '1 - 2 ** 127' from below.
//
//  - Transforms it to the 'X127' format.
//
//  - Stores the resulting value in the 32 byte memory space which is referred
//    to by '_amountSpecified_'.
//
// Throughout the execution of the swap, 'amountSpecified' is partially
// fulfilled with each interval that we visit and because of this, the content
// of this memory space is continuously updated.
//
// Due to limited granularity of logarithmic price in 'X59' representation, a
// requested amount may not be fulfilled. However,
//
//  - if 'amountSpecified > 0', the incoming amount to be given to the pool as
//    a result of the swap call must not exceed 'amountSpecified'.
//
//  - if 'amountSpecified < 0', the outgoing amount to be taken from the pool
//    as a result of the swap call must be greater than or equal to
//    '0 - amountSpecified'.
//
// 32 bytes are reserved for the 'X127' representation of 'amountSpecified' in
// memory.
uint16 constant _amountSpecified_ = 264;

// The input 'logPriceLimit' of the 'swap' method in 'Nofeeswap.sol' is a
// signed value in 'X59' format. Define
//
//  'pLimit := exp(logPriceLimit / (2 ** 59))'.
//
// The input 'logPriceLimit' imposes a limit on the price of the pool post
// execution of the swap call.
//
//  - For price increasing swaps, 'logPriceLimit' serves as an upper bound, in
//    which case the price of the pool must not exceed 'pLimit'.
//
//  - For price decreasing swaps, 'logPriceLimit' serves as a lower bound, in
//    which case the price of the pool must not subceed 'pLimit'.
//
// In both cases, once the price of the pool reaches 'pLimit', the execution of
// the swap is halted. Put simply, no amount of tags are traded with any price
// worst than 'pLimit' for the swapper.
//
// 32 bytes are reserved for 'logPriceLimit' in memory.
uint16 constant _logPriceLimit_ = 296;

// Let 'pLower' and 'pUpper', respectively, denote the minimum and maximum
// price in the current active liquidity interval and define
//
//  'qLower := log(pLower / pOffset)'
//  'qUpper := log(pUpper / pOffset)'
//  'qSpacing := log(pUpper / pLower)',
//  'qMost  := + 16 - 1 / (2 ** 59) - qSpacing'.
//  'qLeast := - 16 + 1 / (2 ** 59) + qSpacing'.
//
// As previously argued, for every integer 'j', the interval
//
//  '[qLower + j * qSpacing, qUpper + j * qSpacing]'
//
// is a valid liquidity interval if and only if:
//
//  '- qMost <= qLower + j * qSpacing'
//
// and
//
//  'qUpper + j * qSpacing <= + qMost.
//
// This includes the current active liquidity interval '[qLower, qUpper]'
// which corresponds to 'j == 0'.
//
// Because of this,
//
//  'qCurrent := log(pCurrent / pOffset)'
//
// always satisfies
//
//  'qCurrent >= qLeast + ((qLower - qLeast) % qSpacing)'
//
// and
//
//  'qCurrent <= qMost - ((qMost - qLower) % qSpacing)'
//
// where 'pCurrent' is the current price of the pool.
//
// In order to enforce the above inequalities, the following value is
// calculated in the method 'setSwapParams' of 'swap.sol':
//
//  'qLimit := min(
//     max(
//       qLeast + ((qLower - qLeast) % qSpacing),
//       log(pLimit / pOffset)
//     ),
//     qMost - ((qMost - qLower) % qSpacing)
//   )'
//
// based on 'qLower', 'qUpper', and 'logPriceLimit'. Then, the offset binary
// 'X59' representation of 'qLimit', i.e.,
//
//  'logPriceLimitOffsetted := (2 ** 59) * (16 + qLimit)'
//
// is stored in the memory space which is pointed to by
// '_logPriceLimitOffsetted_'.
//
// Because
// 
//  '- 16 + 1 / (2 ** 59) <= qLimit <= + 16 - 1 / (2 ** 59)',
//
// we have
//
//  '1 <= logPriceLimitOffsetted <= (2 ** 64) - 1',
//
// which is why 8 bytes are reserved for 'logPriceLimitOffsetted' in memory.
uint16 constant _logPriceLimitOffsetted_ = 328;

// Swap Parameters
// ----------------------------------------------------------------------------
// The following memory pointers correspond to a number of secondary parameters
// that are derived and stored in memory in order to facilitate the execution
// of each 'swap' call. The following memory pointers as well as the
// corresponding getter functions can be used to access each parameter.
// Moreover, when invoking either of the 'midSwap' and 'postSwap' hooks, if
// applicable, these parameters are included in memory snapshot that is passed
// to the hook as calldata. Hence they can be accessed via the corresponding
// calldata pointers and getter functions that are listed in
// 'HookCalldata.sol'.
uint16 constant _swapParams_ = 336;

// As discussed before, the calldata layout of the method 'swap' in
// 'Nofeeswap.sol' does not have a slot dedicated to 'crossThreshold' or
// 'zeroForOne'. Instead, the two inputs 'crossThreshold' and 'zeroForOne'
// share the same slot in calldata as illustrated below:
//
//     +---------------------------+---------------------------+
//     | crossThreshold (128 bits) |   zeroForOne (128 bits)   |
//     +---------------------------+---------------------------+
//
// 'crossThreshold' occupies the most significant 128 bits and 'zeroForOne'
// occupies the least significant 128 bits.
//
//  - If the given 'zeroForOne' input is equal to '0', then the swap is price
//    increasing in which case 'tag0' is outgoing from the pool and 'tag1' is
//    incoming to the pool.
//
//  - If the given 'zeroForOne' input is equal to '1', then the swap is price
//    decreasing in which case 'tag0' is incoming to the pool and 'tag1' is
//    outgoing from the pool.
//
//  - If the given 'zeroForOne' input is equal to any other value, then the
//    movement of the price is towards 'logPriceLimit', i.e., the swap is price
//    increasing if
//
//      'pCurrent < pLimit'
//
//    and the swap is price decreasing if
//
//      'pLimit < pCurrent'
//
//    where
//
//      'pLimit := exp(logPriceLimit / (2 ** 59))'.
//
//    and 'pCurrent' represents the current price of the pool.
//
// A single byte is reserved for this memory space. After the investigation of
// calldata and comparing 'pCurrent' with 'pLimit',
//
//   - If the swap is deemed to be price increasing, then the byte which is
//     pointed to by '_zeroForOne_' is left as '0x00'.
//
//   - If the swap is price decreasing, then this byte is populated with
//     '0xFF'.
//
// The getter function 'getZeroForOne' in this script and the getter function
// 'getZeroForOneFromCalldata' in 'HookCalldata.sol' give access to the content
// of this memory space (or calldata in the context of the hook contract) as a
// boolean with 'false' and 'true' representing price increasing and price
// decreasing swaps, respectively.
uint16 constant _zeroForOne_ = 336;

// The input 'amountSpecified' of the 'swap' method in 'Nofeeswap.sol' is a
// signed integer. The following memory spaces contains the sign of
// 'amountSpecified' which can be accessed as a boolean. To this end, a single
// byte is reserved in memory which is pointed to by '_exactInput_'.
//
//   - If 'amountSpecified > 0', then 'amountSpecified' represents the
//     requested incoming amount to be given to the pool as a result of the
//     swap call. In this case the byte which is pointed to by '_exactInput_'
//     is left as '0x00'.
//
//   - If 'amountSpecified < 0', then '0 - amountSpecified' represents the
//     requested outgoing amount to be taken from the pool as a result of the
//     swap call. In this case the byte which is pointed to by '_exactInput_'
//     is populated with '0xFF'.
//
// The getter function 'getExactInput' in this script and the getter function
// 'getExactInputFromCalldata' in 'HookCalldata.sol' give access to the content
// of this memory space (or calldata in the context of the hook contract) as a
// boolean with 'false' and 'true' representing exact output and exact input 
// swaps, respectively.
uint16 constant _exactInput_ = 337;

// The execution of a swap call may involve transacting in a single liquidity
// interval, or it may require visits to multiple intervals.
//
// If 'crossThreshold' and 'logPriceLimitOffsetted' are not binding, and in the
// presence of sufficient liquidity, the protocol should be able to fulfill
// 'amountSpecified' in the current active interval. This process involves a
// movement of price from
//
//  'qCurrent := log(pCurrent / pOffset)'
//
// to
//
//  'qTarget := log(pTarget / pOffset)'
//
// within the same active liquidity interval, i.e.,
//
//   'qLower <= qTarget <= qUpper'.
//
// In order to accomplish this, we need to solve the equation:
//
//  '|amountSpecified| == 
//
//      (getZeroForOne() != getExactInput() ? sqrtOffset : sqrtInverseOffset) * 
//
//                      growth
//      sharesTotal * ---------- * 
//                     2 ** 111
//
//       getExactInput() ? incomingCurrentToTarget : currentToTarget
//      -------------------------------------------------------------',
//                                outgoingMax
//
// where '|amountSpecified|', 'sqrtOffset', 'sqrtInverseOffset', 'outgoingMax',
// 'sharesTotal', and 'growth' remain fixed as long as we are in the same
// interval.
//
// Hence, as an initial step of a swap call's execution and with each visit to
// a new interval, the following value is calculated in 'X216' format:
//
//  'integralLimit := min(
//
//      oneX216 - epsilonX216,
//
//                           1          2 ** 111
//      outgoingMax *  ------------- * ---------- *
//                      sharesTotal      growth
//
//                                |amountSpecified|
//      -----------------------------------------------------------------------
//       (getZeroForOne() != getExactInput()) ? sqrtOffset : sqrtInverseOffset
//
//   )'.
//
// Based on the above equations, it is straightforward to verify that
// 'amountSpecified' is fulfilled if and only if:
//
//   'getExactInput() ? incomingCurrentToTarget : currentToTarget
//     == 
//    integralLimit'.
//
// Since the left-hand side is a function of 'qTarget', the above equation is
// solved by methods 'searchOutgoingTarget' and 'searchIncomingTarget' in
// 'Interval.sol' in order to calculate the precise value of 'qTarget' that
// fulfills 'amountSpecified'. These two methods work with 'integralLimit'.
//
// 'integralLimit' is less than 'oneX216' and does not exceed 216 bits. Hence,
// 27 bytes are reserved for the memory space that stores 'integralLimit'.
uint16 constant _integralLimit_ = 338;

// Let 'pLower' and 'pUpper', respectively, denote the minimum and maximum
// price in the current active liquidity interval and define
//
//  'qLower := log(pLower / pOffset)',
//  'qUpper := log(pUpper / pOffset)'.
//
// By crossing the active interval entirely from one end to the other end, the
// absolute value '|amountSpecified|' is decremented by
//
//  '(getZeroForOne() != getExactInput() ? sqrtOffset : sqrtInverseOffset) * 
//
//                   growth      integralLimitInterval
//   sharesTotal * ---------- * -----------------------',
//                  2 ** 111          outgoingMax
//
// where 'integralLimitInterval' for the present interval is defined as
//
//  'integralLimitInterval := (getExactInput() ? incomingMax : outgoingMax)
//
//           (getZeroForOne() != getExactInput() ? - qLower : + qUpper) / 2
//       * e                                                               '.
//
// By crossing the active interval, the limit imposed by 'amountSpecified' is
// not violated if and only if:
//        
//  'integralLimitInterval <= integralLimit'.
//
// Hence, 'integralLimitInterval' can be used to determined whether we should
// cross a new active interval entirely or not.
//
// 'integralLimitInterval' is calculated with each visit to a new interval and
// stored in the 27 bytes memory space which is pointed to by
// '_integralLimitInterval_'.
uint16 constant _integralLimitInterval_ = 365;

// Throughout the execution of a swap, this 32 bytes memory space hosts the
// 'X127' representation of 'amount0' which is the total amount of 'tag0' that
// is traded so far. Concluding the visit to each interval involves
// incrementing the absolute value '|amount0|' with
//                                                         growth
//  'amount0Partial := sqrtInverseOffset * sharesTotal * ---------- *
//                                                        2 ** 111
//
//   (getZeroForOne() ? incomingCurrentToTarget : currentToTarget)'.
//
// If positive, 'amount0' is incoming to the pool and if negative it is
// outgoing from the pool.
uint16 constant _amount0_ = 392;

// Throughout the execution of a swap, this 32 bytes memory space hosts the
// 'X127' representation of 'amount1' which is the total amount of 'tag1' that
// is traded so far. Concluding the visit to each interval involves
// incrementing the absolute value '|amount1|' with
//                                                  growth
//  'amount1Partial := sqrtOffset * sharesTotal * ---------- *
//                                                 2 ** 111
//
//   (getZeroForOne() ? currentToTarget : incomingCurrentToTarget)'.
//
// If positive, 'amount1' is incoming to the pool and if negative it is
// outgoing from the pool.
uint16 constant _amount1_ = 424;

// At each point throughout the execution of a swap, as we transition from
// each interval to the next one, the memory pointer '_back_' is used in order
// to keep track of the active interval boundary in the opposite direction of
// the swap.
//
// Let 'pLower' and 'pUpper', respectively, denote the minimum and maximum
// price in the current active liquidity interval and define
//
//  'qBack := log((getZeroForOne() ? pUpper : pLower) / pOffset)'.
//
// The 62 bytes memory space which is pointed to by '_back_' hosts the
// following values:
//
//  '_back_.log() := (2 ** 59) * (16 + qBack)',
//  '_back_.sqrt(false) := (2 ** 216) * exp(- 8 - qBack / 2)',
//  '_back_.sqrt(true) := (2 ** 216) * exp(- 8 + qBack / 2)'.
//
// which can be accessed via 'PriceLibrary'. The logarithmic price
// '_back_.log()' occupies 64 bits, whereas '_back_.sqrt(false)' and
// '_back_.sqrt(true)' occupy 216 bits each.
uint16 constant _back_ = 456;

// At each point throughout the execution of a swap, as we transition from
// each interval to the next one, the memory pointer '_next_' is used in order
// to keep track of the active interval boundary in the direction of the swap.
//
// Let 'pLower' and 'pUpper', respectively, denote the minimum and maximum
// price in the current active liquidity interval and define
//
//  'qNext := log((getZeroForOne() ? pLower : pUpper) / pOffset)'.
//
// The 62 bytes memory space which is pointed to by '_next_' hosts the
// following values:
//
//  '_next_.log() := (2 ** 59) * (16 + qNext)',
//  '_next_.sqrt(false) := (2 ** 216) * exp(- 8 - qNext / 2)',
//  '_next_.sqrt(true) := (2 ** 216) * exp(- 8 + qNext / 2)'.
//
// which can be accessed via 'PriceLibrary'. The logarithmic price
// '_next_.log()' occupies 64 bits, whereas '_next_.sqrt(false)' and
// '_next_.sqrt(true)' occupy 216 bits each.
uint16 constant _next_ = 518;

// An LP may choose any consecutive range of liquidity intervals to deposit
// their liquidity. By doing so, the LP acquires a number of shares in every
// liquidity interval that belongs to the given range.
//
// Let 'pLower' and 'pUpper', respectively, denote the minimum and maximum
// price in the current active liquidity interval and define
//
//  'qLower := log(pLower / pOffset)',
//  'qUpper := log(pUpper / pOffset)'.
//
// Additionally, let
// 
//    sqrtInverseOffset     growthMultiplier[qUpper]
//  '------------------- * --------------------------'
//         2 ** 127                 2 ** 208
//
// represent the total amount of 'tag0' corresponding to a single liquidity
// provider's share from 'qUpper' to '+oo' and
//
//    sqrtOffset     growthMultiplier[qLower]
//  '------------ * --------------------------'
//     2 ** 127             2 ** 208
//
// represent the total amount of 'tag1' corresponding to a single liquidity
// provider's share from '-oo' to 'qLower'.
//
// The 32 bytes memory space which is pointed to by '_backGrowthMultiplier_'
// hosts the 'X208' representation of
// 'growthMultiplier[getZeroForOne() ? qUpper : qLower]'.
//
// The 32 bytes memory space which is pointed to by '_nextGrowthMultiplier_'
// hosts the 'X208' representation of
// 'growthMultiplier[getZeroForOne() ? qLower : qUpper]'.
uint16 constant _backGrowthMultiplier_ = 580;
uint16 constant _nextGrowthMultiplier_ = 612;

// Interval Parameters
// ----------------------------------------------------------------------------
// The following memory pointers correspond to the main variables that are used
// to calculate swaps within the active liquidity interval.
//
// Let 'pCurrent' denote the current price of the pool and let 'pLower' and
// 'pUpper', respectively, denote the minimum and maximum price in the current
// active liquidity interval. Define:
//
//  'qLower := log(pLower / pOffset)',
//  'qUpper := log(pUpper / pOffset)',
//  'qSpacing := log(pUpper / pLower)',
//  'qCurrent := log(pCurrent / pOffset)'.
//
// Then we have:
//
//  'qLower <= qCurrent <= qUpper',
//
// Consider a swap that involves a movement of price from 'qCurrent' to
//
//  'qTarget := log(pTarget / pOffset)'
//
// within the same active liquidity interval, i.e.,
//
//  'qLower <= qTarget <= qUpper'.
//
// Notice that 'qTarget' is an unknown value which will be determined based on
// one of the followings:
//
//  - 'qLimitWithinInterval', which is calculated based on the input
//    'logPriceLimit' as well as 'qLower' and 'qUpper'. It is stored in the
//    memory space which is pointed to by
//    '_logPriceLimitOffsettedWithinInterval_'.
//
//  - 'integralLimit', which is calculated based on the input 'amountSpecified'
//    and is stored in the memory space which is pointed to by
//    '_integralLimit_'.
//
// After determination of 'qTarget', the amounts of 'tag0' and 'tag1' to be
// exchanged as a result of the movement within '[qLower, qUpper]' are equal
// to:
//
//                                                         growth
//  'amount0Partial := sqrtInverseOffset * sharesTotal * ---------- *
//                                                        2 ** 111
//
//    getZeroForOne() ? incomingCurrentToTarget : currentToTarget
//   -------------------------------------------------------------',
//                            outgoingMax
// and
//                                                  growth
//  'amount1Partial := sqrtOffset * sharesTotal * ---------- *
//                                                 2 ** 111
//
//    getZeroForOne() ? currentToTarget : incomingCurrentToTarget
//   -------------------------------------------------------------',
//                            outgoingMax
//
// where the parameters 'sqrtInverseOffset', 'sqrtOffset', 'sharesTotal',
// 'growth', and 'outgoingMax' remain fixed throughout the movement from
// 'qCurrent' to 'qTarget'.
//
// While searching for 'qTarget', the two integrals 'currentToTarget' and
// 'incomingCurrentToTarget' are calculated. These two integrals are defined as
// follows:
//
//                           - 8
//    currentToTarget      e
//  '----------------- := ------- * (
//       2 ** 216            2
//
//                         / qCurrent                 / qTarget
//                        |    + h / 2               |    - h / 2
//     getZeroForOne() ?  |  e         k(w(h)) dh :  |  e         k(w(h)) dh
//                        |                          |
//                       / qTarget                  / qCurrent
//
//   )'
//
// and
//                                   - 8
//    incomingCurrentToTarget      e
//  '------------------------- := ------- * (
//           2 ** 216                2
//
//                         / qCurrent                 / qTarget
//                        |    - h / 2               |    + h / 2
//     getZeroForOne() ?  |  e         k(w(h)) dh :  |  e         k(w(h)) dh
//                        |                          |
//                       / qTarget                  / qCurrent
//
//   )'.
//
// To further clarify the above definitions, we first need to define the
// function 'w(.)' which is constructed based on the curve sequence.
//
// The curve sequence comprises 64 bit logarithmic prices in the form of
//
//  '(2 ** 59) * (16 + qHistorical)'
//
// where every 'qHistorical' satisfies:
//
//  'qLower <= qHistorical <= qUpper'.
//
// Hence, each slot of the curve sequence consists of up to four members. The
// curve sequence should have at least two members. The first and the second
// members are 'qLower' and 'qUpper' with the order depending on the pool's
// history. The last member is always 'qCurrent'. Consider the following curve
// sequence:
// 
//  'q[0], q[1], q[2], ..., q[l - 1]'
//
// where 'l' is the number of members. Additionally, to simplify the notations,
// the out-of-range member 'q[l]' is assigned the same value as 'q[l - 1]'. In
// order for the above sequence to be considered valid, we should have:
//
//  'min(q[i - 1], q[i - 2]) < q[i] < max(q[i - 1], q[i - 2])'.
//
// for every '2 <= i < l'. Define
// 
//  'w : [qLower, qUpper] -> [0, qSpacing]'
//
// as
//           l - 2
//           -----
//           \
//  'w(q) := /     w_i(q)'.
//           -----
//           i = 0
//
// where for every '0 <= i <= l - 2', the function
//
//  'w_i : [qLower, qUpper] -> [0, qSpacing]'
//
// is regarded as a phase which is defined as
//
//  'w_i(q) :=
//
//    /
//   |  |q - q[i + 1]|  if  min(q[i], q[i + 2]) < q < max(q[i], q[i + 2])
//   |                                                                    '.
//   |  0               otherwise
//    \
//
// Observe that for each '0 <= i <= l - 2', the phase 'w_i' can be
// characterized via the following three consecutive members of the curve
// sequence:
//
//  'q[i], q[i + 1], q[i + 2]'
//
// Next, we need to define the function 'k(.)' which is constructed from the
// kernel. The kernel is composed of breakpoints. Let 'm + 1' denote the number
// of these breakpoints. For every integer '0 <= i <= m' the i-th breakpoint of
// the kernel represents the pair '(b[i], c[i])' where
//
//  '0 == b[0] <  b[1] <= b[2] <= ... <= b[m - 1] <  b[m] == qSpacing',
//  '0 == c[0] <= c[1] <= c[2] <= ... <= c[m - 1] <= c[m] == 1'.
// 
// Each breakpoint occupies 64 bytes, in which:
//
//  - the 'X15' representation of '(2 ** 15) * c[i]' occupies 2 bytes,
//
//  - the 'X59' representation of '(2 ** 59) * b[i]' occupies 8 bytes,
//
//  - the 'X216' representation of '(2 ** 216) * exp(- b[i] / 2)' occupies 27
//    bytes,
//
//  - the 'X216' representation of '(2 ** 216) * exp(- 16 + b[i] / 2)' occupies
//    27 bytes.
//
// The above-mentioned layout is illustrated as follows:
//
//                      A 512 bit kernel breakpoint
//  +--+--------+---------------------------+---------------------------+
//  |  | 8 byte |          27 byte          |          27 byte          |
//  +--+--------+---------------------------+---------------------------+
//  |  |        |                           |
//  |  |        |                            \
//  |  |        |                             (2 ** 216) * exp(- 16 + b[i] / 2)
//  |  |         \
//  |  |          (2 ** 216) * exp(- b[i] / 2)
//  |   \
//  |    (2 ** 59) * b[i]
//   \
//    (2 ** 15) * c[i]
//
// Consider the following list of kernel breakpoints:
//
//  '(b[0], c[0]), (b[1], c[1]), (b[2], c[2]), ..., (b[m], c[m])'
//
// and for every integer '0 < i <= m', define
//
//  'k_i : [0, qSpacing] -> [0, 1]'
//
// as
//
//  'k_i(q) :=
//
//    /            c[i] - c[i - 1]
//   | c[i - 1] + ----------------- * (q - b[i - 1])  if  b[i - 1] < q < b[i]
//   |             b[i] - b[i - 1]                                           ',
//   | 0                                              otherwise
//    \
//
// which means that if 'b[i - 1] == b[i]', then 'k_i(q) := 0'. Now, the kernel
// function
// 
//  'k : [0, qSpacing] -> [0, 1]'
//
// is defined as
//
//             m
//           -----
//           \
//  'k(q) := /     k_i(q)'.
//           -----
//           i = 1
//
// Define the liquidity distribution function
//
//  'k(w(.)) : [qLower, qUpper] -> [0, 1]'
//
// for the active interval as the composition of 'k(.)' with 'w(.)'.
//
// As argued above, while searching for 'qTarget', the integrals
// 'currentToTarget' and 'incomingCurrentToTarget' are calculated based on
// 'k(w(.))' which enables the protocol to determine 'amount0Partial' and
// 'amount1Partial' when moving the price from 'qCurrent' to 'qTarget'. In
// addition, we need to calculate two other integrals that are referred to as
// 'currentToOrigin' and 'originToOvershoot' which will be defined later in
// this script. Next, we explain how this search is conducted.
//
// Remember that both 'w(.)' and 'k(.)' are piecewise linear functions. As a
// result, 'k(w(.))' is also piecewise linear. In search for 'qTarget', we
// enumerate the pieces of 'k(w(.))', one by one, until we discover the piece
// to which 'qTarget' belongs. To this end, the two indices 'indexCurve' and
// 'indexKernelTotal' are employed:
//
//  - 'indexCurve' keeps track of the current phase under exploration (i.e.,
//    the piece of 'w(.)'). Remember, that 'w_indexCurve' can be characterized
//    via the following three consecutive members of the curve sequence:
//
//      'q[indexCurve], q[indexCurve + 1], q[indexCurve + 2]'.
//
//    Here, we refer to 'q[indexCurve + 1]' and 'q[indexCurve]' as 'qOrigin'
//    and 'qEnd', respectively. Throughout the search, 'qOrigin' and 'qEnd'
//    are stored, respectively, in the memory spaces which are pointed to by
//    '_origin_' and '_end_', and they are updated with each transition to a
//    new phase.
//
//    Additionally, the memory space which is pointed to by '_direction_' keeps
//    track of the boolean:
//
//      'qEnd < q[indexCurve + 2]'.
//
//    Hence, 'getDirection() == false' means that we are currently searching
//    within the range
//    
//      'q[indexCurve + 2] < q < qEnd'
//
//    in which
//
//      'w(q) == w_indexCurve(q) == q - qOrigin'.
//
//    Whereas, 'getDirection() == true' means that we are currently searching
//    within the range
//    
//      'qEnd < q < q[indexCurve + 2]'
//
//    in which
//
//      'w(q) == w_indexCurve(q) == qOrigin - q'.
//
//    In order to determine whether 'qTarget' belongs to the current range
//    under exploration, i.e., the range between
//
//      'min(qEnd, q[indexCurve + 2])'
//
//    and
//
//      'max(qEnd, q[indexCurve + 2])'
//
//    we start from the price 'q[indexCurve + 2]' and proceed towards the price
//    'qEnd' by enumerating the pieces of
//
//      'k(w(q)) == getDirection() ? k(qOrigin - q) : k(q - qOrigin)'
//
//    one by one. The fact that 'w(.)' is a linear function throughout the
//    above range, means that we only need to worry about the pieces of either
//    'k(qOrigin - q)' or 'k(q - qOrigin)', depending on the direction.
//
//    The process of enumerating phases starts with the following initial
//    state:
//
//      - 'indexCurve := l - 2',
//
//      - 'qOrigin := q[indexCurve + 1] == q[l - 1] == qCurrent',
//
//      - 'qEnd := q[indexCurve] == q[l - 2]'.
//
//    Once we reach 'qEnd', we transition to a new phase by
//
//      - decrementing 'indexCurve' by one,
//
//      - updating 'qOrigin' and 'qEnd',
//
//      - updating the direction flag,
//
//    and the cycle continues until we reach the phase to which 'qTarget'
//    belongs.
//
//  - 'indexKernelTotal' keeps track of the pieces of the kernel function that
//    we enumerate as we explore the current phase. As defined earlier, let:
//
//      - 'qOrigin := q[indexCurve + 1]'
//
//      - 'qEnd := q[indexCurve]'
//
//      - 'getDirection() := qEnd < q[indexCurve + 2]'
//
//    correspond to the current phase under exploration which leads to the
//    following simplification of the liquidity distribution function:
//
//      'k(w(q)) == getDirection() ? k(qOrigin - q) : k(q - qOrigin)'
//
//    within the range
//
//      'min(q[indexCurve + 2], qEnd) < q < max(q[indexCurve + 2], qEnd)'.
//
//    Hence, as we move from 'q[indexCurve + 2]' to 'qEnd', each piece of
//    'k(w(.))' can be characterized via the following four vertical and
//    horizontal coordinates:
//
//      'cTotal0 := c[indexKernelTotal - 1]',
//
//      'qTotal0 := getDirection() ? 
//                  qOrigin - b[indexKernelTotal - 1] : 
//                  qOrigin + b[indexKernelTotal - 1]',
//
//      'cTotal1 := c[indexKernelTotal]',
//
//      'qTotal1 := getDirection() ? 
//                  qOrigin - b[indexKernelTotal] : 
//                  qOrigin + b[indexKernelTotal]'.
//
//    The pair '(cTotal0, qTotal0)' is stored in the memory space which is
//    pointed to by '_total0_' and similarly, the pair '(cTotal1, qTotal1)' is
//    stored in the memory space which is pointed to by '_total1_'.
//
//    Hence, the function 'k(w(.))' is linear within the intersection of the
//    two ranges:
//
//      'min(q[indexCurve + 2], qEnd) < q < max(q[indexCurve + 2], qEnd)',
//
//    and
//
//      'min(qTotal0, qTotal1) < q < max(qTotal0, qTotal1)'.
//
//    As long as 'k(w(.))' is linear, we have closed-forms for all of the
//    integrals that we intend to calculate. Hence, it is important to keep
//    track of the domain in which 'k(w(.))' is linear and to update it as we
//    move forward in our search. Moreover, we need to make sure that 'qTarget'
//    does not go beyond 'qLimitWithinInterval'. Hence, with each transition to
//    a new phase or a new piece of the kernel function, we make the following
//    two updates:
//
//      'qBegin := getDirection() ? 
//                 min(q[indexCurve + 2], qTotal0) : 
//                 max(q[indexCurve + 2], qTotal0)',
//
//      'qTarget := (
//                    getDirection() == getZeroForOne()
//                  ) ? (
//                    getDirection() ? 
//                    max(max(qEnd, qTotal1), qLimitWithinInterval) : 
//                    min(min(qEnd, qTotal1), qLimitWithinInterval)
//                  ) : (
//                    getDirection() ? 
//                    max(qEnd, qTotal1) : 
//                    min(qEnd, qTotal1)
//                  )',
//
//    where 'qBegin' and 'qTarget' are stored, respectively, in the memory
//    spaces that are pointed to by '_begin_' and '_target_'. Both values are
//    updated with each transition to a new phase or a new piece of 'k(w(.))'.
//
//    The process of enumerating the pieces of the kernel function starts with
//    the initial state 'indexKernelTotal := 1'.
//
// While searching for 'qTarget', we need to calculate the following two
// integrals, in addition to 'currentToTarget' and 'incomingCurrentToTarget':
//
//                           - 8
//    currentToOrigin      e
//  '----------------- := ------- * (
//       2 ** 216            2
//
//                         / qOrigin                  / qCurrent
//                        |    - h / 2               |    + h / 2
//     getZeroForOne() ?  |  e         k(w(h)) dh :  |  e         k(w(h)) dh
//                        |                          |
//                       / qCurrent                 / qOrigin
//
//   )'
//
// and
//                             - 8
//    originToOvershoot      e
//  '------------------- := ------- * (
//        2 ** 216             2
//
//     getZeroForOne() ? 
//
//       / qOrigin
//      |    + h / 2
//      |  e         k(qOrigin - h) dh :
//      |
//     / qTarget
//
//       / qTarget
//      |    - h / 2
//      |  e         k(h - qOrigin) dh
//      |
//     / qOrigin
//
//   )'.
//
// To summarize, the four integrals:
//
//  - 'currentToTarget',
//
//  - 'incomingCurrentToTarget',
//
//  - 'currentToOrigin', and
//
//  - 'originToOvershoot',
//
// are incremented with each decrement of 'indexCurve' or increment of
// 'indexKernelTotal'.
//
// The following figure illustrates the ranges covered by the above integrals
// in the case of 'getZeroForOne() == false', i.e., 'qCurrent < qTarget':
//
//                                                currentToTarget
//                                                exp(- h / 2) * k(w(h))
//           currentToOrigin                    / 
//    exp(+ h / 2) * k(w(h))                   /\ 
//                          \                 /   incomingCurrentToTarget
//                           \               /    exp(+ h / 2) * k(w(h))
//                            \             /
//                     |<------------>|<-------->|
//                     |              |          |
//      +--------------+--------------+----------+------------------+
//      |              |              |          |                  |
//    qLower           |          qCurrent       |                qUpper
//                     |                         |
//                     |<----------------------->|
//                     |            \            |
//                  qOrigin          \        qTarget == qOvershoot
//                                    \
//                             originToOvershoot
//                             exp(- h / 2) * k(h - qOrigin)
//
// The search for 'qTarget' is conducted by calling the method 'moveTarget()'
// from 'Interval.sol' in a loop until either of the following condition are
// met:
//
//  - 'qLimitWithinInterval == qTarget', or
//
//  - 'integralLimit == (
//       getExactInput() ? incomingCurrentToTarget : currentToTarget
//     )'.
//
// Define:
//
//                                - 8     / qUpper
//    integral0Incremented      e        |    - h / 2
//  '---------------------- := ------- * |  e         k(w(h)) dh',
//          2 ** 216              2      |
//                                      / qTarget
//
//                                - 8     / qTarget
//    integral1Incremented      e        |    + h / 2
//  '---------------------- := ------- * |  e         k(w(h)) dh'.
//          2 ** 216              2      |
//                                      / qLower
//
// Now, the total reserves of 'tag0' and 'tag1' within '[qLower, qUpper]' after
// the movement of price from 'qCurrent' to 'qTarget' (i.e., after the exchange
// of 'amount0Partial' and 'amount1Partial') are equal to 
//
//                                       growth      integral0Incremented
//  'sqrtInverseOffset * sharesTotal * ---------- * ----------------------'
//                                      2 ** 111         outgoingMax
//
// and
//
//                                growth      integral1Incremented
//  'sqrtOffset * sharesTotal * ---------- * ----------------------',
//                               2 ** 111         outgoingMax
//
// respectively. The ranges covered by 'integral0Incremented' and
// 'integral1Incremented' are illustrated as follows:
//
//                                                    integral0Incremented
//                                                    exp(- h / 2) * k(w(h))
//                integral1Incremented               /
//                exp(+ h / 2) * k(w(h))            /
//      |<-------------------------------------->|<---------------->|
//      |                                        |                  |
//      +----------------------------------------+------------------+
//      |                                        |                  |
//    qLower                                  qTarget             qUpper
//
// After the search for 'qTarget' is concluded, and 'amount0Partial' and
// 'amount1Partial' are calculated, we need to determine 'qOvershoot'. If
// 'getZeroForOne() == false', we have
//
//  'qTarget <= qOvershoot <= qUpper'
//
// and if 'getZeroForOne() == true', we have
//
//  'qLower <= qOvershoot <= qTarget'.
//
// The curve sequence is first amended with 'qOvershoot' and then 'qTarget', in
// preparation for the next swap.
//
// To this end, define:
//                              - 8
//    currentToOvershoot      e
//  '-------------------- := ------- * (
//         2 ** 216             2
//
//                         / qCurrent                 / qOvershoot
//                        |    + h / 2               |    - h / 2
//     getZeroForOne() ?  |  e         k(w(h)) dh :  |  e         k(w(h)) dh
//                        |                          |
//                       / qOvershoot               / qCurrent
//
//   )'
//
// and
//                             - 8
//    targetToOvershoot      e
//  '------------------- := ------- * (
//         2 ** 216            2
//
//     getZeroForOne()
//
//         / qTarget
//        |    + h / 2
//     ?  |  e         k(qTarget - h) dh
//        |
//       / qOvershoot
//
//         / qOvershoot
//        |    - h / 2
//     :  |  e         k(h - qTarget) dh
//        |
//       / qTarget
//
//   )'
//
// While searching for 'qOvershoot', the four integrals:
//
//  - 'currentToOvershoot',
//
//  - 'targetToOvershoot',
//
//  - 'originToOvershoot', and
//
//  - 'currentToOrigin',
//
// are kept track of. The following figure illustrates the ranges covered by
// the above integrals in the case of 'getZeroForOne() == false', i.e.,
// 'qCurrent < qTarget':
//
//           currentToOrigin                      currentToOvershoot
//    exp(+ h / 2) * k(w(h))                      exp(- h / 2) * k(w(h))
//                          \                    /
//                           \                  /
//                            \                /
//              |<------------------->|<--------------->|
//              |                     |                 |
//              |                     |    qTarget      |
//              |                     |       |         |
//      +-------+---------------------+-------+---------+-----------+
//      |       |                     |       |         |           |
//    qLower    |                 qCurrent    |<------->|         qUpper
//              |                                  /    |
//              |                                 /     |
//              |                targetToOvershoot      |
//              |    exp(- h / 2) * k(h - qTarget)      |
//              |                                       |
//              |                                       |
//              |<------------------------------------->|
//              |                     /                 |
//           qOrigin                 /              qOvershoot
//                                  /
//                                 /
//                originToOvershoot
//    exp(- h / 2) * k(h - qOrigin)
//
// Now, in order to find 'qOvershoot', we need to solve the equation:
//
//   'f(qOvershoot) == 0'
//
// where
//
//   'f(qOvershoot) := getZeroForOne() ? 
//                     s0(qOvershoot) - s1(qOvershoot) : 
//                     s1(qOvershoot) - s0(qOvershoot)',
//
// and the two functions 's0' and 's1' are defined as:
//
//                          - 8      / qTarget
//                        e         |   + h / 2
//                       ------- *  |  e        k(wAmended(h)) dh
//                          2       |
//                                 / qLower
//   's1(qOvershoot) := ------------------------------------------',
//                                integral1Incremented
//
//                          - 8      / qUpper
//                        e         |   - h / 2
//                       ------- *  |  e        k(wAmended(h)) dh
//                          2       |
//                                 / qTarget
//   's0(qOvershoot) := ------------------------------------------'.
//                                integral0Incremented
//
// Now, according to the amendement procedure which is described in
// 'Curve.sol', if 'getZeroForOne() == false', we have:
//
//                       / k(w(h))            if  qOvershoot < h < qUpper
//   'k(wAmended(h)) == |  k(h - qTarget)     if  qTarget < h < qOvershoot '
//                      |  k(qOvershoot - h)  if  qOrigin < h < qTarget
//                       \ k(w(h))            if  qLower < h < qOrigin
//
// and if 'getZeroForOne() == true', we have:
//
//                       / k(w(h))            if  qLower < h < qOvershoot
//   'k(wAmended(h)) == |  k(qTarget - h)     if  qOvershoot < h < qTarget '.
//                      |  k(h - qOvershoot)  if  qTarget < h < qOrigin
//                       \ k(w(h))            if  qOrigin < h < qUpper
//
// For the case 'getZeroForOne() == false', the above formulas conclude that:
//
//  - the numerator of 's1' is equal to:
//
//        - 8     / qTarget
//      e        |    + h / 2
//    '------- * |  e         k(wAmended(h)) dh == 
//        2      |
//              / qLower
//
//        - 8     / qOrigin
//      e        |    + h / 2
//     ------- * |  e         k(wAmended(h)) dh +
//        2      |
//              / qLower
//
//                                - 8     / qTarget
//                              e        |    + h / 2
//                             ------- * |  e         k(wAmended(h)) dh ==
//                                2      |
//                                      / qOrigin
//
//        - 8     / qOrigin
//      e        |    + h / 2
//     ------- * |  e         k(w(h)) dh +
//        2      |
//              / qLower
//
//                                - 8     / qTarget
//                              e        |    + h / 2
//                             ------- * |  e         k(qOvershoot - h) dh ==
//                                2      |
//                                      / qOrigin
//
//        - 8     / qOrigin
//      e        |    + h / 2
//     ------- * |  e         k(w(h)) dh +
//        2      |
//              / qLower
//
//                                - 8     / qOvershoot
//                              e        |    + h / 2
//                             ------- * |  e         k(qOvershoot - h) dh -
//                                2      |
//                                      / qOrigin
//
//                                - 8     / qOvershoot
//                              e        |    + h / 2
//                             ------- * |  e         k(qOvershoot - h) dh ==
//                                2      |
//                                      / qTarget
//
//        - 8     / qTarget
//      e        |    + h / 2
//     ------- * |  e         k(w(h)) dh - 
//        2      |
//              / qLower
//
//        - 8     / qTarget                   - 8     / qCurrent
//      e        |    + h / 2               e        |    + h / 2
//     ------- * |  e         k(w(h)) dh - ------- * |  e         k(w(h)) dh +
//        2      |                            2      |
//              / qCurrent                          / qOrigin
//
//        - 8 + (qOrigin + qOvershoot) / 2     / qOvershoot
//      e                                     |    - h / 2
//     ------------------------------------ * |  e         k(h - qOrigin) dh -
//                        2                   |
//                                           / qOrigin
//
//        - 8 + (qTarget + qOvershoot) / 2     / qOvershoot
//      e                                     |    - h / 2
//     ------------------------------------ * |  e         k(h - qTarget) dh ==
//                        2                   |
//                                           / qTarget
//
//      integral1Incremented - incomingCurrentToTarget - currentToOrigin
//     ------------------------------------------------------------------ + 
//                                  2 ** 216
//
//      exp((qOrigin + qOvershoot) / 2) * originToOvershoot
//     ----------------------------------------------------- - 
//                            2 ** 216
//
//      exp((qTarget + qOvershoot) / 2) * targetToOvershoot
//     -----------------------------------------------------'.
//                            2 ** 216
//
//  - the numerator of 's0' is equal to:
//
//        - 8     / qUpper
//      e        |    - h / 2
//    '------- * |  e         k(wAmended(h)) dh == 
//        2      |
//              / qTarget
//
//        - 8     / qOvershoot
//      e        |    - h / 2
//     ------- * |  e         k(wAmended(h)) dh +
//        2      |
//              / qTarget
//
//                                - 8     / qUpper
//                              e        |    - h / 2
//                             ------- * |  e         k(wAmended(h)) dh == 
//                                2      |
//                                      / qOvershoot
//
//        - 8     / qOvershoot
//      e        |    - h / 2
//     ------- * |  e         k(h - qTarget) dh +
//        2      |
//              / qTarget
//
//                                - 8     / qUpper
//                              e        |    - h / 2
//                             ------- * |  e         k(w(h)) dh == 
//                                2      |
//                                      / qOvershoot
//
//        - 8     / qOvershoot
//      e        |    - h / 2
//     ------- * |  e         k(h - qTarget) dh +
//        2      |
//              / qTarget
//
//        - 8     / qTarget                   - 8     / qUpper
//      e        |    - h / 2               e        |    - h / 2
//     ------- * |  e         k(w(h)) dh + ------- * |  e         k(w(h)) dh -
//        2      |                            2      |
//              / qCurrent                          / qTarget
//
//        - 8     / qOvershoot
//      e        |
//     ------- * |  e         k(w(h)) dh == 
//        2      |
//              / qCurrent
//
//      targetToOvershoot + currentToTarget
//     ------------------------------------- + 
//                    2 ** 216
//
//      integral0Incremented - currentToOvershoot
//     -------------------------------------------'.
//                       2 ** 216
//
// Similar arguments can be made for the case 'getZeroForOne() == true' and for
// both cases, we have:
//
//   'f(qOvershoot) := getZeroForOne() ? (
//
//      (
//
//        exp(- (qOrigin + qOvershoot) / 2) * originToOvershoot -
//
//        exp(- (qTarget + qOvershoot) / 2) * targetToOvershoot - 
//
//        incomingCurrentToTarget - currentToOrigin
//
//      ) / integral0Incremented - (
//
//        targetToOvershoot + currentToTarget - currentToOvershoot
//      
//      ) / integral1Incremented
//
//    ) : (
//
//      (
//
//        exp(+ (qOrigin + qOvershoot) / 2) * originToOvershoot -
//
//        exp(+ (qTarget + qOvershoot) / 2) * targetToOvershoot - 
//
//        incomingCurrentToTarget - currentToOrigin
//
//      ) / integral1Incremented - (
//
//        targetToOvershoot + currentToTarget - currentToOvershoot
//      
//      ) / integral0Incremented
//
//    )'.
//
// We use Newton's method in order to pinpoint the precise value for
// 'qOvershoot' which satisfies:
//
//   'f(qOvershoot) == 0'.
//
// To this end, we need access to a simple and closed-form expression for all
// of the above integrals. Hence, we first need to restrict our search to a
// domain in which both 'k(w(.))' and 'k(|h - qTarget|)' are linear.
//
// Hence, prior to the above-mentioned numerical search, we first need to move
// 'qOvershoot' from 'qTarget' towards 'qNext' until we determine the
// followings:
//
//   - The piece of 'k(w(.))' to which 'qOvershoot' belongs.
//
//   - The piece of 'k(|h - qTarget|)' to which 'qOvershoot' belongs.
//
// The former is accomplished via a similar procedure as we delineated before
// in search for 'qTarget'. Put simply, we start with
//
//   'qOvershoot := qTarget'
//
// because
//
//   'f(qTarget) < 0',
//
// and we keep moving 'qOvershoot' forward until we encounter a point that
// satisfies:
//
//   'f(qOvershoot) > 0'.
//
// Throughout the movement from 'qTarget' towards 'qNext', we keep track of the
// current phase under exploration using the variables:
//
//   - 'indexCurve', 'qOrigin', 'qEnd', 'direction',
//
// and we keep track of the current piece of the kernel function using the
// variables:
//
//   - 'indexKernelTotal', 'cTotal0', 'cTotal1', 'qTotal0', 'qTotal1'
//
// Throughout the search for 'qOvershoot', the piece of 'k(|h - qTarget|)' to
// which 'qOvershoot' belongs is determined using an additional index:
//
//  - 'indexKernelForward' keeps track of the pieces of the function
//    'k(|h - qTarget|)' that we enumerate as we move from 'qTarget' to
//    'qOvershoot'. Each piece of 'k(|h - qTarget|)' can be characterized via
//    the following four vertical and horizontal coordinates:
//
//      'cForward0 := c[indexKernelForward - 1]',
//
//      'qForward0 := getZeroForOne() ? 
//                    qTarget - b[indexKernelForward - 1] : 
//                    qTarget + b[indexKernelForward - 1]',
//
//      'cForward1 := c[indexKernelForward]',
//
//      'qForward1 := getZeroForOne() ? 
//                    qTarget - b[indexKernelForward] : 
//                    qTarget + b[indexKernelForward]'.
//
//    The pair '(cForward0, qForward0)' is stored in the memory space which is
//    pointed to by '_forward0_' and similarly, the pair
//    '(cForward1, qForward1)' is stored in the memory space which is pointed
//    to by '_forward1_'.
//
//    Hence, the function 'k(|. - qTarget|)' is linear within the range:
//
//      'min(qForward0, qForward1) < q < max(qForward0, qForward1)'.
//
//    and the function 'k(w(.))' is linear within the intersection of the two
//    ranges:
//
//      'min(q[indexCurve + 2], qEnd) < q < max(q[indexCurve + 2], qEnd)',
//
//    and
//
//      'min(qTotal0, qTotal1) < q < max(qTotal0, qTotal1)'.
//
//    Now, in order to have closed-forms for all of the integrals that the
//    formula for 'f(qOvershoot)' comprises, at each step, we keep track of the
//    domain in which both 'k(w(.))' and 'k(|. - qTarget|)' are linear and we
//    update this domain as we move forward in our search. Hence, with every
//    update of 'indexCurve', 'indexKernelTotal', and 'indexKernelForward', we
//    make the following two updates:
//
//      'qBegin := (
//                   direction == getZeroForOne()
//                 ) ? (
//                   direction ? 
//                   max(max(q[indexCurve + 2], qTotal0), qForward0) : 
//                   min(min(q[indexCurve + 2], qTotal0), qForward0)
//                 ) : (
//                   direction ? 
//                   max(q[indexCurve + 2], qTotal0) : 
//                   min(q[indexCurve + 2], qTotal0)
//                 )',
//
//      'qOvershoot := (
//                       direction == getZeroForOne()
//                     ) ? (
//                       direction ? 
//                       max(max(qEnd, qTotal1), qForward1) : 
//                       min(min(qEnd, qTotal1), qForward1)
//                     ) : (
//                       direction ? 
//                       max(qEnd, qTotal1) : 
//                       min(qEnd, qTotal1)
//                     )',
//
//    where 'qBegin' and 'qOvershoot' are stored, respectively, in the memory
//    spaces that are pointed to by '_begin_' and '_overshoot_'. Both values
//    are updated with each transition to a new phase, a new piece of
//    'k(w(.))', or a new piece of 'k(|. - qTarget|)'.
//
//    The process of enumerating the pieces of 'k(|. - qTarget|)' starts with
//    the initial state 'indexKernelForward := 1'.
//
// Determining the search domain to which 'qOvershoot' belongs and in which
// both 'k(w(.))' and 'k(|. - qTarget|)' are linear, is conducted by calling
// the method 'moveOvershoot' from 'Interval.sol' in a loop until the following
// condition is met:
//
//   'f(qBegin) <= 0' and 'f(qOvershoot) >  0'.
//
// Then, according to the intermediate value theorem, there exists a solution
// in this search domain which satisfies:
//
//   'f(qOvershoot) == 0'.
//
// Then, this solution is found by calling the method 'searchOvershoot' from
// 'Interval.sol'.
//
// In order to calculate the Newton step at each stage, we need to find the
// derivative of 'f(.)'. If 'getZeroForOne() == false', then we have:
//
//          d f
//   '-------------- ==
//     d qOvershoot
//
//    (
//
//        + (qOrigin + qOvershoot) / 2    originToOvershoot
//      e                              * ------------------- -
//                                              2
//
//        + (qTarget + qOvershoot) / 2    targetToOvershoot
//      e                              * ------------------- +
//                                              2
//         - 8 + qOrigin / 2
//       e
//      --------------------- * k(qOvershoot - qOrigin) -
//                2
//
//         - 8 + qTarget / 2
//       e
//      --------------------- * k(qOvershoot - qTarget)
//                2
//
//    ) / integral1Incremented - (
//
//         - 8 - qOvershoot / 2
//       e
//      ------------------------ * k(qOvershoot - qTarget) - 
//                  2
//
//         - 8 - qOvershoot / 2
//       e
//      ------------------------ * k(qOvershoot - qOrigin) 
//                  2
//
//    ) / integral0Incremented'.
//
// If 'getZeroForOne() == true', then we have:
//
//          d f
//   '-------------- ==
//     d qOvershoot
//
//    (
//
//         - 8 + qOvershoot / 2
//       e
//      ------------------------ * k(qTarget - qOvershoot) - 
//                  2
//
//         - 8 + qOvershoot / 2
//       e
//      ------------------------ * k(qOrigin - qOvershoot) 
//                  2
//
//    ) / integral1Incremented - (
//
//        - (qOrigin + qOvershoot) / 2    originToOvershoot
//      e                              * ------------------- -
//                                              2
//
//        - (qTarget + qOvershoot) / 2    targetToOvershoot
//      e                              * ------------------- +
//                                              2
//         - 8 - qOrigin / 2
//       e
//      --------------------- * k(qOrigin - qOvershoot) - 
//                2
//
//         - 8 - qTarget / 2
//       e
//      --------------------- * k(qTarget - qOvershoot)
//                2
//
//    ) / integral0Incremented'.
//
// After the calulation of 'qOvershoot', the amended values 'growthAmended', 
// 'integral0Amended' and 'integral1Amended' are determined as follows:
//
//                         growth              growth
//  'growthAmended == ---------------- == ----------------',
//                     s0(qOvershoot)      s1(qOvershoot)
//
//                            - 8     / qUpper
//    integral0Amended      e        |    - h / 2
//  '------------------ := ------- * |  e         k(wAmended(h)) dh == 
//        2 ** 216            2      |
//                                  / qTarget
//
//                              growth        integral0Incremented
//                         --------------- * ----------------------',
//                          growthAmended           2 ** 216
//
//                            - 8     / qTarget
//    integral1Amended      e        |    + h / 2
//  '------------------ := ------- * |  e         k(wAmended(h)) dh == 
//        2 ** 216            2      |
//                                  / qLower
//
//                              growth        integral0Incremented
//                         --------------- * ----------------------',
//                          growthAmended           2 ** 216
//
// where the ranges covered by 'integral0Amended' and 'integral1Amended' are
// illustrated as follows:
//
//                         integral0Amended
//                         exp(- h / 2) * k(wAmended(h))
//                                                      \
//             integral1Amended                          \
//             exp(+ h / 2) * k(wAmended(h))              \
//      |<-------------------------------------->|<---------------->|
//      |                                        |                  |
//      +----------------------------------------+------------------+
//      |                                        |                  |
//    qLower                                  qTarget             qUpper
//
// In the following section, the memory pointers that are used for the purpose
// of the above calculations are introduced.
uint16 constant _interval_ = 644;

// The direction of the current 'phase' under exploration. Everytime that we
// move from one 'phase' to the next, by decrementing 'indexCurve' this binary
// value is flipped. 'direction' should not be confused with 'zeroForOne' which
// does not change throughout a swap. Define:
//
//  'qEnd := q[indexCurve]'.
//
// 'direction = 0x00' if 'q[indexCurve + 2] < qEnd', i.e., when we are moving
// towards '+oo', in search for 'qTarget' or 'qOvershoot'. In this case, for
// every 'q[indexCurve + 2] < h < qEnd', we have:
//
//  'w(h) := h - qOrigin'.
//
// 'direction = 0xFF' if 'qEnd < q[indexCurve + 2]', i.e., when we are moving
// towards '-oo', in search for 'qTarget' or 'qOvershoot'. In this case, for
// every 'qEnd < h < q[indexCurve + 2]', we have:
//
//  'w(h) := qOrigin - h'.
//
uint16 constant _direction_ = 644;

// The index of 'qEnd' among the members of the 'curve', i.e.,
//
//  'qEnd == q[indexCurve]'.
//
// While searching for 'qTarget' and 'qOvershoot', the value of 'indexCurve'
// starts from 'curveLength - twoIndex' and is decremented by 'oneIndex' with
// each run of the function 'movePhase()' in 'Interval.sol'.
uint16 constant _indexCurve_ = 645;

// The index of 'qTotal1' and 'cTotal1' among the breakpoints of the 'kernel',
// i.e.,
//
//  'cTotal0 := c[indexKernelTotal - 1]',
//
//  'qTotal0 := direction ? 
//              qOrigin - b[indexKernelTotal - 1] : 
//              qOrigin + b[indexKernelTotal - 1]',
//
//  'cTotal1 == c[indexKernelTotal]',
//
//  'qTotal1 == direction ? 
//              qOrigin - b[indexKernelTotal] : 
//              qOrigin + b[indexKernelTotal]'.
//
// While searching for 'qTarget' and 'qOvershoot', the value of
// 'indexKernelTotal' starts from 'oneIndex' and is incremented by 'oneIndex'
// with each transition to a new piece of kernel as we explore 'k(w(h))'.
//
// If 'getDirection() == false', then we have:
//
//  'k(w(h)) == k(h - qOrigin) == k_indexKernelTotal(h - qOrigin) :=
//
//                         cTotal1 - cTotal0
//              cTotal0 + ------------------- * (h - qTotal0)'.
//                         qTotal1 - qTotal0
//
// for every 'qBegin < h < qTarget'.
//
// If 'getDirection() == true', then we have:
//
//  'k(w(h)) == k(qOrigin - h) == k_indexKernelTotal(qOrigin - h) :=
//
//                         cTotal1 - cTotal0
//              cTotal0 + ------------------- * (qTotal0 - h)'.
//                         qTotal0 - qTotal1
//
// for every 'qTarget < h < qBegin'.
uint16 constant _indexKernelTotal_ = 647;

// The index of 'qForward1' and 'cForward1' among the breakpoints of the
// 'kernel', i.e.,
//
//  'cForward0 := c[indexKernelForward - 1]',
//
//  'qForward0 := getZeroForOne() ? 
//                qTarget - b[indexKernelForward - 1] : 
//                qTarget + b[indexKernelForward - 1]',
//
//  'cForward1 := c[indexKernelForward]',
//
//  'qForward1 := getZeroForOne() ? 
//                qTarget - b[indexKernelForward] : 
//                qTarget + b[indexKernelForward]'.
//
// While searching for 'qOvershoot', the value of 'indexKernelForward' starts
// from 'oneIndex' and is incremented by 'oneIndex' with each transition to a
// new piece of kernel.
//
// If 'getZeroForOne() == false', then we have:
//
//  'k(h - qTarget) == k_indexKernelForward(h - qTarget) :=
//
//                                  cForward1 - cForward0
//                     cForward0 + ----------------------- * (h - qForward0)'.
//                                  qForward1 - qForward0
//
// for every 'qBegin < h < qOvershoot'.
//
// If 'getZeroForOne() == true', then we have:
//
//  'k(qTarget - h) == k_indexKernelForward(qTarget - h) :=
//
//                                  cForward1 - cForward0
//                     cForward0 + ----------------------- * (qForward0 - h)'.
//                                  qForward0 - qForward1
//
// for every 'qOvershoot < h < qBegin'.
uint16 constant _indexKernelForward_ = 649;

// Let 'pLower' and 'pUpper' be the minimum and maximum price in the active
// liquidity interval and define
//
//  'qLower := log(pLower / pOffset)',
//  'qUpper := log(pUpper / pOffset)'.
//  'qLimitWithinInterval := min(max(qLower, qLimit), qUpper)'
//
// The value set as 'logPriceLimitOffsetted' may be outside of the current
// active liquidity interval. In such cases, we first need to perform a swap
// towards the current interval boundary and then we transition to a new
// interval. In order to perform the former step, 'qLimitWithinInterval' is
// calculated and its offset binary 'X59' representation, i.e.,
//
//  '_origin_.log() := (2 ** 59) * (16 + qOrigin)'
//
// is stored in the memory space which pointed to by
// '_logPriceLimitOffsettedWithinInterval_'.
uint16 constant _logPriceLimitOffsettedWithinInterval_ = 651;

// Let 'pCurrent' represent the current price within the active liquidity
// interval (prior to the movement to 'qTarget' or 'qNext'). This value
// corresponds to the last member of the curve. Define:
//
//  'qCurrent := log(pCurrent / pOffset)',
//
// The 62 bytes memory space which is pointed to by '_current_' hosts the
// following values:
//
//  '_current_.log() := (2 ** 59) * (16 + qCurrent)',
//  '_current_.sqrt(false) := (2 ** 216) * exp(- 8 - qCurrent / 2)',
//  '_current_.sqrt(true) := (2 ** 216) * exp(- 8 + qCurrent / 2)'.
//
// which can be accessed via 'PriceLibrary'. The logarithmic price
// '_current_.log()' occupies 64 bits, whereas '_current_.sqrt(false)' and
// '_current_.sqrt(true)' occupy 216 bits each.
uint16 constant _current_ = 659;

// Let 'indexCurve' represent the index of the current phase under exploration.
// Define:
//
//  'qOrigin := q[indexCurve + 1]',
//
//  'qEnd := q[indexCurve]'.
//
// If 'getDirection() == false', for every 'q[indexCurve + 2] < h < qEnd', we
// have:
//
//  'w(h) := h - qOrigin'.
//
// If 'getDirection() == true', for every 'qEnd < h < q[indexCurve + 2]', we
// have:
//
//  'w(h) := qOrigin - h'.
//
// The 62 bytes memory space which is pointed to by '_origin_' hosts the
// following values:
//
//  '_origin_.log() := (2 ** 59) * (16 + qOrigin)',
//  '_origin_.sqrt(false) := (2 ** 216) * exp(- 8 - qOrigin / 2)',
//  '_origin_.sqrt(true) := (2 ** 216) * exp(- 8 + qOrigin / 2)'.
//
// which can be accessed via 'PriceLibrary'. The logarithmic price
// '_origin_.log()' occupies 64 bits, whereas '_origin_.sqrt(false)' and
// '_origin_.sqrt(true)' occupy 216 bits each.
uint16 constant _origin_ = 721;

// At every step of searching for 'qTarget', the range
//
//  'min(qBegin, qTarget) < h < max(qBegin, qTarget)'
//
// represents a piece of the liquidity distribution function 'k(w(.))' in which
// 'k(w(.))' is linear. More precisely, if 'getDirection() == false', we have:
//
//  'k(w(h)) == k(h - qOrigin) == k_indexKernelTotal(h - qOrigin) :=
//
//                         cTotal1 - cTotal0
//              cTotal0 + ------------------- * (h - qTotal0)'.
//                         qTotal1 - qTotal0
//
// for every 'qBegin < h < qTarget' and if 'getDirection() == true', we have:
//
//  'k(w(h)) == k(qOrigin - h) == k_indexKernelTotal(qOrigin - h) :=
//
//                         cTotal1 - cTotal0
//              cTotal0 + ------------------- * (qTotal0 - h)'.
//                         qTotal0 - qTotal1
//
// for every 'qTarget < h < qBegin'.
//
// At the stage where we search for 'qTarget', we have
//
//  'qBegin := direction ? 
//             min(q[indexCurve + 2], qTotal0) : 
//             max(q[indexCurve + 2], qTotal0)'.
//
// At every step of searching for 'qOvershoot', the following inequality
//
//  'min(qBegin, qOvershoot) < h < max(qBegin, qOvershoot)'
//
// represents a range in which both 'k(w(.))' and 'k(|. - qTarget|)' are
// linear. More precisely, if 'getZeroForOne() == false', we have:
//
//  'k(h - qTarget) == k_indexKernelForward(h - qTarget) :=
//
//                                  cForward1 - cForward0
//                     cForward0 + ----------------------- * (h - qForward0)'.
//                                  qForward1 - qForward0
//
// for every 'qBegin < h < qOvershoot' and if 'getZeroForOne() == true', we
// have:
//
//  'k(qTarget - h) == k_indexKernelForward(qTarget - h) :=
//
//                                  cForward1 - cForward0
//                     cForward0 + ----------------------- * (qForward0 - h)'.
//                                  qForward0 - qForward1
//
// for every 'qOvershoot < h < qBegin'.
//
// At the stage where we search for 'qOvershoot', we have
//
//  'qBegin := (
//               direction == getZeroForOne()
//             ) ? (
//               direction ? 
//               max(max(q[indexCurve + 2], qTotal0), qForward0) : 
//               min(min(q[indexCurve + 2], qTotal0), qForward0)
//             ) : (
//               direction ? 
//               max(q[indexCurve + 2], qTotal0) : 
//               min(q[indexCurve + 2], qTotal0)
//             )',
//
// The 62 bytes memory space which is pointed to by '_begin_' hosts the
// following values:
//
//  '_begin_.log() := (2 ** 59) * (16 + qBegin)',
//  '_begin_.sqrt(false) := (2 ** 216) * exp(- 8 - qBegin / 2)',
//  '_begin_.sqrt(true) := (2 ** 216) * exp(- 8 + qBegin / 2)'.
//
// which can be accessed via 'PriceLibrary'. The logarithmic price
// '_begin_.log()' occupies 64 bits, whereas '_begin_.sqrt(false)' and
// '_begin_.sqrt(true)' occupy 216 bits each.
uint16 constant _begin_ = 783;

// Let 'indexCurve' represent the index of the current phase under exploration.
// Define:
//
//  'qOrigin := q[indexCurve + 1]',
//
//  'qEnd := q[indexCurve]'.
//
// If 'getDirection() == false', for every 'q[indexCurve + 2] < h < qEnd', we
// have:
//
//  'w(h) := h - qOrigin'.
//
// If 'getDirection() == true', for every 'qEnd < h < q[indexCurve + 2]', we
// have:
//
//  'w(h) := qOrigin - h'.
//
// The 62 bytes memory space which is pointed to by '_end_' hosts the following
// values:
//
//  '_end_.log() := (2 ** 59) * (16 + qEnd)',
//  '_end_.sqrt(false) := (2 ** 216) * exp(- 8 - qEnd / 2)',
//  '_end_.sqrt(true) := (2 ** 216) * exp(- 8 + qEnd / 2)'.
//
// which can be accessed via 'PriceLibrary'. The logarithmic price
// '_end_.log()' occupies 64 bits, whereas '_end_.sqrt(false)' and
// '_end_.sqrt(true)' occupy 216 bits each.
uint16 constant _end_ = 845;

// Every visit to a liquidity interval as part of a swap involves the movement
// of price from 'pCurrent' to 'pTarget'. Define:
//
//  'qCurrent := log(pCurrent / pOffset)',
//  'qTarget := log(pTarget / pOffset)',
//
// and assume that
//
//  'qLower <= qCurrent <= qUpper',
//  'qLower <= qTarget <= qUpper',
//
// where '[qLower, qUpper]' represents the current active liquidity interval.
//
// At first 'qTarget' is an unknown value which will be determined based on one
// of the followings:
//
//  - 'qLimitWithinInterval', which is calculated based on the input
//    'logPriceLimit' as well as 'qLower' and 'qUpper'. It is stored in the
//    memory space which is pointed to by
//    '_logPriceLimitOffsettedWithinInterval_'.
//
//  - 'integralLimit', which is calculated based on the input 'amountSpecified'
//    and is stored in the memory space which is pointed to by
//    '_integralLimit_'.
//
// After determination of 'qTarget', the amounts of 'tag0' and 'tag1' to be
// exchanged as a result of the movement within '[qLower, qUpper]' are equal
// to:
//
//                                                         growth
//  'amount0Partial := sqrtInverseOffset * sharesTotal * ---------- *
//                                                        2 ** 111
//
//                      - 8     / max(qCurrent, qTarget)
//         1          e        |                         - h / 2
//   ------------- * ------- * |                       e         k(w(h)) dh',
//    outgoingMax       2      |
//                            / min(qCurrent, qTarget)
//
// and
//                                                  growth
//  'amount1Partial := sqrtOffset * sharesTotal * ---------- *
//                                                 2 ** 111
//
//                      - 8     / max(qCurrent, qTarget)
//         1          e        |                         + h / 2
//   ------------- * ------- * |                       e         k(w(h)) dh',
//    outgoingMax       2      |
//                            / min(qCurrent, qTarget)
//
// where the parameters 'sqrtInverseOffset', 'sqrtOffset', 'sharesTotal',
// 'growth', and 'outgoingMax' remain fixed throughout the movement from
// 'qCurrent' to 'qTarget'.
//
// In search for 'qTarget', we first need to enumerate the pieces of 'k(w(.))',
// one by one, until we discover the piece to which 'qTarget' belongs. While 
// enumerating the pieces of 'k(w(.))', one end of the current piece under
// exploration is 'qBegin' and the other end is temporarily referred to as:
//
//  'qTarget := (
//                direction == getZeroForOne()
//              ) ? (
//                direction ? 
//                max(max(qEnd, qTotal1), qLimitWithinInterval) : 
//                min(min(qEnd, qTotal1), qLimitWithinInterval)
//              ) : (
//                direction ? 
//                max(qEnd, qTotal1) : 
//                min(qEnd, qTotal1)
//              )'.
//
// After the correct piece is determined, we perform a numerical search via
// either of the methods 'searchOutgoingTarget' or 'searchIncomingTarget' in
// 'Interval.sol' in order to pinpoint the precise value of 'qTarget'.
//
// At every step of searching for the piece to which 'qTarget' belongs, if 
// 'getDirection() == false', we have:
//
//  'k(w(h)) == k(h - qOrigin) == k_indexKernelTotal(h - qOrigin) :=
//
//                         cTotal1 - cTotal0
//              cTotal0 + ------------------- * (h - qTotal0)'.
//                         qTotal1 - qTotal0
//
// for every 'qBegin < h < qTarget' and if 'getDirection() == true', we have:
//
//  'k(w(h)) == k(qOrigin - h) == k_indexKernelTotal(qOrigin - h) :=
//
//                         cTotal1 - cTotal0
//              cTotal0 + ------------------- * (qTotal0 - h)'.
//                         qTotal0 - qTotal1
//
// for every 'qTarget < h < qBegin'.
//
// The 62 bytes memory space which is pointed to by '_target_' hosts the
// following values:
//
//  '_target_.log() := (2 ** 59) * (16 + qTarget)',
//  '_target_.sqrt(false) := (2 ** 216) * exp(- 8 - qTarget / 2)',
//  '_target_.sqrt(true) := (2 ** 216) * exp(- 8 + qTarget / 2)'.
//
// which can be accessed via 'PriceLibrary'. The logarithmic price
// '_target_.log()' occupies 64 bits, whereas '_target_.sqrt(false)' and
// '_target_.sqrt(true)' occupy 216 bits each.
uint16 constant _target_ = 907;

// Assume that we are in the process of doing a swap within an interval for
// which 'qTarget' as well as both 'amount0Partial' and 'amount1Partial' are
// determined. Let '[qLower, pUpper]' represent the active liquidity interval
// and define:
//
// Now we need to update the curve in preparation for the next swap. Before
// doing so, define:
//
//                                - 8     / qUpper
//    integral0Incremented      e        |    - h / 2
//  '---------------------- := ------- * |  e         k(w(h)) dh',
//          2 ** 216              2      |
//                                      / qTarget
//
//                                - 8     / qTarget
//    integral1Incremented      e        |    + h / 2
//  '---------------------- := ------- * |  e         k(w(h)) dh'.
//          2 ** 216              2      |
//                                      / qLower
//
// Then we have:
//
//                                                                   growth
//  'totalReserveOfTag0Before := sqrtInverseOffset * sharesTotal * ---------- * 
//                                                                  2 ** 111
//    integral0Incremented
//   ----------------------'
//        outgoingMax
//
//                                                            growth
//  'totalReserveOfTag1Before := sqrtOffset * sharesTotal * ---------- * 
//                                                           2 ** 111
//    integral1Incremented
//   ----------------------'
//        outgoingMax
//
// Now, assume that the curve sequence is updated and the function 'w' is
// transformed into a new function 'wAmended' which is constructed based on the
// updated curve sequence. Then, we can similarly define:
//
//                            - 8     / qUpper
//    integral0Amended      e        |    - h / 2
//  '------------------ := ------- * |  e         k(wAmended(h)) dh',
//        2 ** 216            2      |
//                                  / qTarget
//
//                            - 8     / qTarget
//    integral1Amended      e        |    + h / 2
//  '------------------ := ------- * |  e         k(wAmended(h)) dh'.
//        2 ** 216            2      |
//                                  / qLower
//
// Then we have:
//
//  'totalReserveOfTag0After := sqrtInverseOffset * sharesTotal *
//
//    growthAmended     integral0Amended
//   --------------- * ------------------'
//      2 ** 111          outgoingMax
//
//  'totalReserveOfTag1After := sqrtOffset * sharesTotal * 
//
//    growthAmended     integral1Amended
//   --------------- * ------------------'
//      2 ** 111          outgoingMax
//
// Now, we need to make sure that the reserve amounts before and after the
// curve update are the same, which means that:
//
//  'totalReserveOfTag0Before == totalReserveOfTag0After'
//  'totalReserveOfTag1Before == totalReserveOfTag1After'
//
// This leads to the following two equations:
// 
//       growth            integral0Amended
//  '--------------- == ----------------------'
//    growthAmended      integral0Incremented
// 
//       growth            integral1Amended
//  '--------------- == ----------------------'
//    growthAmended      integral1Incremented
//
// Hence, we must have:
//
//      integral0Amended          integral1Amended
//  '---------------------- == ----------------------'
//    integral0Incremented      integral1Incremented
//
// which means that:
//
//      / qUpper                          / qTarget
//     |   - h/2                         |   + h/2
//     |  e      k(wAmended(h)) dh       |  e      k(wAmended(h)) dh
//     |                                 |
//    / qTarget                         / qLower
//  '------------------------------ == ------------------------------'.
//         / qUpper                          / qTarget
//        |    - h/2                        |    + h/2
//        |  e       k(w(h)) dh             |  e       k(w(h)) dh
//        |                                 |
//       / qTarget                         / qLower
//
// As a result, we should update the curve in such a way that the above
// equality is satisfied.
//
// To that end, once 'qOvershoot' and both 'amount0Partial' and
// 'amount1Partial' are determined, the curve sequence is amended with
// 'qOvershoot' and then 'qTarget'.
//
// If 'getZeroForOne() == false' then 'qTarget <= qOvershoot' and if
// 'getZeroForOne() == true' then 'qOvershoot <= qTarget'. Assume that
// 'wAmended' is constructed from the amended curve sequence. 'qOvershoot' is
// calculated in such a way that the above equality holds for the amended
// curve. The process of searching for 'qOvershoot' is further explained at
// the beginning of this section.
//
// The 62 bytes memory space which is pointed to by '_overshoot_' hosts the
// following values:
//
//  '_overshoot_.log() := (2 ** 59) * (16 + qOvershoot)',
//  '_overshoot_.sqrt(false) := (2 ** 216) * exp(- 8 - qOvershoot / 2)',
//  '_overshoot_.sqrt(true) := (2 ** 216) * exp(- 8 + qOvershoot / 2)'.
//
// which can be accessed via 'PriceLibrary'. The logarithmic price
// '_overshoot_.log()' occupies 64 bits, whereas '_overshoot_.sqrt(false)' and
// '_overshoot_.sqrt(true)' occupy 216 bits each.
uint16 constant _overshoot_ = 969;

// At every step of searching for 'qTarget', the range
//
//  'min(qBegin, qTarget) < h < max(qBegin, qTarget)'
//
// represents a piece of the liquidity distribution function 'k(w(.))' in which
// 'k(w(.))' is linear. More precisely, if 'getDirection() == false', we have:
//
//  'k(w(h)) == k(h - qOrigin) == k_indexKernelTotal(h - qOrigin) :=
//
//                         cTotal1 - cTotal0
//              cTotal0 + ------------------- * (h - qTotal0)'.
//                         qTotal1 - qTotal0
//
// for every 'qBegin < h < qTarget' and if 'getDirection() == true', we have:
//
//  'k(w(h)) == k(qOrigin - h) == k_indexKernelTotal(qOrigin - h) :=
//
//                         cTotal1 - cTotal0
//              cTotal0 + ------------------- * (qTotal0 - h)'.
//                         qTotal0 - qTotal1
//
// for every 'qTarget < h < qBegin', where:
//
//  'cTotal0 := c[indexKernelTotal - 1]',
//
//  'qTotal0 := direction ? 
//              qOrigin - b[indexKernelTotal - 1] : 
//              qOrigin + b[indexKernelTotal - 1]',
//
//  'cTotal1 := c[indexKernelTotal]',
//
//  'qTotal1 := direction ? 
//              qOrigin - b[indexKernelTotal] : 
//              qOrigin + b[indexKernelTotal]'.
//
// The pair '(cTotal0, qTotal0)' is stored in the memory space which is pointed
// to by '_total0_' and similarly, the pair '(cTotal1, qTotal1)' is stored in
// the memory space which is pointed to by '_total1_'.
//
// The 64 bytes memory space which is pointed to by '_total0_' hosts the
// following values:
//
//  '_total0_.height() := (2 ** 15) * cTotal0',
//  '_total0_.log() := (2 ** 59) * (16 + qTotal0)',
//  '_total0_.sqrt(false) := (2 ** 216) * exp(- 8 - qTotal0 / 2)',
//  '_total0_.sqrt(true) := (2 ** 216) * exp(- 8 + qTotal0 / 2)'.
//
// which can be accessed via 'PriceLibrary'. The vertical coordinate
// '_total0_.height()' occupies 16 bits, the logarithmic price '_total0_.log()'
// occupies 64 bits, whereas '_total0_.sqrt(false)' and '_total0_.sqrt(true)'
// occupy 216 bits each.
//
// The 64 bytes memory space which is pointed to by '_total1_' hosts the
// following values:
//
//  '_total1_.height() := (2 ** 15) * cTotal1',
//  '_total1_.log() := (2 ** 59) * (16 + qTotal1)',
//  '_total1_.sqrt(false) := (2 ** 216) * exp(- 8 - qTotal1 / 2)',
//  '_total1_.sqrt(true) := (2 ** 216) * exp(- 8 + qTotal1 / 2)'.
//
// which can be accessed via 'PriceLibrary'. The vertical coordinate
// '_total1_.height()' occupies 16 bits, the logarithmic price '_total1_.log()'
// occupies 64 bits, whereas '_total1_.sqrt(false)' and '_total1_.sqrt(true)'
// occupy 216 bits each.
uint16 constant _total0_ = 1033;
uint16 constant _total1_ = 1097;

// At every step of searching for 'qOvershoot', the range
//
//  'min(qBegin, qOvershoot) < h < max(qBegin, qOvershoot)'
//
// represents a piece of 'k(|. - qTarget|)'. If 'getZeroForOne() == false',
// then we have:
//
//  'k(h - qTarget) == k_indexKernelForward(h - qTarget) :=
//
//                                  cForward1 - cForward0
//                     cForward0 + ----------------------- * (h - qForward0)',
//                                  qForward1 - qForward0
//
// for every 'qBegin < h < qOvershoot' and if 'getZeroForOne() == true', then
// we have:
//
//  'k(qTarget - h) == k_indexKernelForward(qTarget - h) :=
//
//                                  cForward1 - cForward0
//                     cForward0 + ----------------------- * (qForward0 - h)',
//                                  qForward0 - qForward1
//
// for every 'qOvershoot < h < qBegin' where
//
//  'cForward0 := c[indexKernelForward - 1]',
//
//  'qForward0 := getZeroForOne() ? 
//                qTarget - b[indexKernelForward - 1] : 
//                qTarget + b[indexKernelForward - 1]',
//
//  'cForward1 := c[indexKernelForward]',
//
//  'qForward1 := getZeroForOne() ? 
//                qTarget - b[indexKernelForward] : 
//                qTarget + b[indexKernelForward]'.
//
// The pair '(cForward0, qForward0)' is stored in the memory space which is
// pointed to by '_forward0_' and similarly, the pair '(cForward1, qForward1)'
// is stored in the memory space which is pointed to by '_forward1_'.
//
// The 64 bytes memory space which is pointed to by '_forward0_' hosts the
// following values:
//
//  '_forward0_.height() := (2 ** 15) * cForward0',
//  '_forward0_.log() := (2 ** 59) * (16 + qForward0)',
//  '_forward0_.sqrt(false) := (2 ** 216) * exp(- 8 - qForward0 / 2)',
//  '_forward0_.sqrt(true) := (2 ** 216) * exp(- 8 + qForward0 / 2)'.
//
// which can be accessed via 'PriceLibrary'. The vertical coordinate
// '_forward0_.height()' occupies 16 bits, the logarithmic price
// '_forward0_.log()' occupies 64 bits, whereas '_forward0_.sqrt(false)' and
// '_forward0_.sqrt(true)' occupy 216 bits each.
//
// The 64 bytes memory space which is pointed to by '_forward1_' hosts the
// following values:
//
//  '_forward1_.height() := (2 ** 15) * cForward1',
//  '_forward1_.log() := (2 ** 59) * (16 + qForward1)',
//  '_forward1_.sqrt(false) := (2 ** 216) * exp(- 8 - qForward1 / 2)',
//  '_forward1_.sqrt(true) := (2 ** 216) * exp(- 8 + qForward1 / 2)'.
//
// which can be accessed via 'PriceLibrary'. The vertical coordinate
// '_forward1_.height()' occupies 16 bits, the logarithmic price
// '_forward1_.log()' occupies 64 bits, whereas '_forward1_.sqrt(false)' and
// '_forward1_.sqrt(true)' occupy 216 bits each.
uint16 constant _forward0_ = 1161;
uint16 constant _forward1_ = 1225;

// While searching for 'qTarget', the integral 'incomingCurrentToTarget' is
// calculated. This integral is defined as follows:
//
//                                   - 8
//    incomingCurrentToTarget      e
//  '------------------------- := ------- * (
//           2 ** 216                2
//
//                         / qCurrent                 / qTarget
//                        |    - h / 2               |    + h / 2
//     getZeroForOne() ?  |  e         k(w(h)) dh :  |  e         k(w(h)) dh
//                        |                          |
//                       / qTarget                  / qCurrent
//
//   )'.
//
// The pointer below refers to the above integral in 'X216' representation
// which takes up to 27 bytes.
uint16 constant _incomingCurrentToTarget_ = 1287;

// While searching for 'qTarget', the integral 'currentToTarget' is calculated.
// This integral is defined as follows:
//
//                           - 8
//    currentToTarget      e
//  '----------------- := ------- * (
//       2 ** 216            2
//
//                         / qCurrent                 / qTarget
//                        |    + h / 2               |    - h / 2
//     getZeroForOne() ?  |  e         k(w(h)) dh :  |  e         k(w(h)) dh
//                        |                          |
//                       / qTarget                  / qCurrent
//
//   )'
//
// The pointer below refers to the above integral in 'X216' representation
// which takes up to 27 bytes.
uint16 constant _currentToTarget_ = 1314;

// While searching for 'qTarget' and 'qOvershoot', we need to calculate the
// following integral:
//
//                           - 8
//    currentToOrigin      e
//  '----------------- := ------- * (
//       2 ** 216            2
//
//                         / qOrigin                  / qCurrent
//                        |    - h / 2               |    + h / 2
//     getZeroForOne() ?  |  e         k(w(h)) dh :  |  e         k(w(h)) dh
//                        |                          |
//                       / qCurrent                 / qOrigin
//
//   )'.
//
// 'currentToOrigin' is used for the calculation of 'overshoot' as discussed in
// 'Interval.sol'.
//
// The pointer below refers to the above integral in 'X216' representation
// which takes up to 27 bytes.
uint16 constant _currentToOrigin_ = 1341;

// While searching for 'qTarget' and 'qOvershoot', we need to calculate the
// following integral:
//
//                              - 8
//    currentToOvershoot      e
//  '-------------------- := ------- * (
//         2 ** 216             2
//
//                         / qCurrent                 / qOvershoot
//                        |    + h / 2               |    - h / 2
//     getZeroForOne() ?  |  e         k(w(h)) dh :  |  e         k(w(h)) dh
//                        |                          |
//                       / qOvershoot               / qCurrent
//
//   )'
//
// 'currentToOvershoot' is used for the calculation of 'overshoot' as discussed
// in 'Interval.sol'.
//
// The pointer below refers to the above integral in 'X216' representation
// which takes up to 27 bytes.
uint16 constant _currentToOvershoot_ = 1368;

// While searching for 'qOvershoot', we need to calculate the following
// integral:
//
//                             - 8
//    targetToOvershoot      e
//  '------------------- := ------- * (
//         2 ** 216            2
//
//     getZeroForOne()
//
//         / qTarget
//        |    + h / 2
//     ?  |  e         k(qTarget - h) dh
//        |
//       / qOvershoot
//
//         / qOvershoot
//        |    - h / 2
//     :  |  e         k(h - qTarget) dh
//        |
//       / qTarget
//
//   )'
//
// 'targetToOvershoot' is used for the calculation of 'overshoot' as discussed
// in 'Interval.sol'.
//
// The pointer below refers to the above integral in 'X216' representation
// which takes up to 27 bytes.
uint16 constant _targetToOvershoot_ = 1395;

// While searching for 'qTarget' and 'qOvershoot', we need to calculate the
// following integral:
//
//                             - 8
//    originToOvershoot      e
//  '------------------- := ------- * (
//        2 ** 216             2
//
//     getZeroForOne() ? 
//
//       / qOrigin
//      |    + h / 2
//      |  e         k(qOrigin - h) dh :
//      |
//     / qTarget
//
//       / qTarget
//      |    - h / 2
//      |  e         k(h - qOrigin) dh
//      |
//     / qOrigin
//
//   )'
//
// 'originToOvershoot' is used for the calculation of 'overshoot' as discussed
// in 'Interval.sol'.
//
// The pointer below refers to the above integral in 'X216' representation
// which takes up to 27 bytes.
uint16 constant _originToOvershoot_ = 1422;

uint16 constant _endOfInterval_ = 1449;

// Accrued Parameters
// ----------------------------------------------------------------------------
// The spaces that are pointed to by the following memory pointers contain
// information about the accrued growth portions that are owed to the protocol
// and the pool. After each swap or donate, the interval liquidity grows. A
// portion of this growth goes to the protocol. A portion of the remaining
// growth goes to the pool owner. These values are compactly written on
// protocol's storage in which they occupy exactly one slot.
uint16 constant _accruedParams_ = 1449;

// This 32 bytes memory space hosts the 'X127' representation of 'accrued0'
// where
//
//    accrued0
//  '----------'
//    2 ** 127
//
// is the total unclaimed amount in 'tag0' owed to both the protocol and the
// pool owner.
uint16 constant _accrued0_ = 1449;

// This 32 bytes memory space hosts the 'X127' representation of 'accrued1'
// where
//
//    accrued1
//  '----------'
//    2 ** 127
//
// is the total unclaimed amount in 'tag1' owed to both the protocol and the
// pool owner.
uint16 constant _accrued1_ = 1481;

// This 3 bytes memory space hosts the 'X23' representation of 'poolRatio0'
// where
//
//    poolRatio0     accrued0
//  '------------ * ----------'
//     2 ** 23       2 ** 127
//
// is the accrued amount in 'tag0' owed to the pool and
//
//    oneX23 - poolRatio0     accrued0
//  '--------------------- * ----------'
//          2 ** 23           2 ** 127
//
// is the accrued amount in 'tag0' owed to the protocol.
uint16 constant _poolRatio0_ = 1513;

// This 3 bytes memory space hosts the 'X23' representation of 'poolRatio1'
// where
//
//    poolRatio1     accrued1
//  '------------ * ----------'
//     2 ** 23       2 ** 127
//
// is the accrued amount in 'tag1' owed to the pool and
//
//    oneX23 - poolRatio1     accrued1
//  '--------------------- * ----------'
//          2 ** 23           2 ** 127
//
// is the accrued amount in 'tag1' owed to the protocol.
uint16 constant _poolRatio1_ = 1516;

// Pointers
// ----------------------------------------------------------------------------
// The following memory pointers give access to data with dynamic size.
uint16 constant _pointers_ = 1519;

// The content of this 32 bytes memory space points to the beginning of the
// kernel.
// The memory space starting from 'getKernel()' to
// 'getKernel() + 64 * (getKernelLength() - 1)' hosts the kernel breakpoints
// that are loaded from the bytecode of the storage smart contract (64 bytes
// for each breakpoint of the kernel function except for '(b[0], c[0])' which
// is omitted).
uint16 constant _kernel_ = 1519;

// The content of this 32 bytes memory space points to the beginning of the
// curve sequence. The memory space starting from 'getCurve()' to
// 'getCurve() + 8 * getCurveLength()' hosts the curve sequence which is loaded
// from the protocol's storage (8 bytes for each member of the curve sequence).
uint16 constant _curve_ = 1551;

// The content of this 32 bytes memory space points to the beginning of
// 'hookData'. The memory space starting from 'getHookData()' to
// 'getHookData() + getHookDataByteCount()' hosts 'hookData' which is loaded
// from calldata.
uint16 constant _hookData_ = 1583;

// This 2 bytes memory space hosts the number of breakpoints of the kernel
// function which is calculated from the size of the storage smart contract.
uint16 constant _kernelLength_ = 1615;

// This 2 bytes memory space hosts the number of members of the curve sequence.
uint16 constant _curveLength_ = 1617;

// This 2 bytes memory space hosts the number of bytes that 'hookData'
// occupies.
uint16 constant _hookDataByteCount_ = 1619;

// Dynamic Parameters
// ----------------------------------------------------------------------------
// The following memory pointers are dedicated to dynamic parameters of the
// pool that may change with each swap. Dynamic parameters are stored in
// protocol's storage and take a total of three slots. In the event that
// 'staticParamsStoragePointer' overflows and
// 'staticParamsStoragePointerExtension' is needed, a fourth storage slot is
// populated, rendering interactions with the pool more expensive.
uint16 constant _dynamicParams_ = 1621;

// The content of this 32 bytes memory space is referred to as
// 'staticParamsStoragePointerExtension' which is closely related to
// 'staticParamsStoragePointer'.
//
// If 'staticParamsStoragePointer < type(uint16).max', then
// 'staticParamsStoragePointerExtension' is not written on protocol's storage
// and we have:
//
//  'staticParamsStoragePointerExtension == staticParamsStoragePointer'
//
// If 'staticParamsStoragePointer == type(uint16).max', then
// 'staticParamsStoragePointerExtension' populates a dedicated storage slot
// whose content can be used to derive the address of the storage smart
// contract that contains the static parameters and the kernel.
uint16 constant _staticParamsStoragePointerExtension_ = 1621;

// The content of this 2 bytes memory space is used to retrieve the address of
// the smart contract which holds the pool's static parameters and the kernel
// in its bytecode. This value is incremented every time that any of the static
// parameters are updated or when the kernel is modified. In the event of
// overflow, this value is set to 'type(uint16).max' and the 32 bytes space
// which is pointed to by '_staticParamsStoragePointerExtension_' is used to
// store the value from which the address to the storage smart contract is
// derived.
uint16 constant _staticParamsStoragePointer_ = 1653;

// This 8 bytes memory space hosts 'logPriceCurrent' which is the offsetted
// value of the current log price of the pool in 'X59' representation. More
// precisely,
//
//  'logPriceCurrent := (2 ** 59) * (16 + qCurrent)'
//
// where 
// 
//  'qCurrent := log(pCurrent / pOffset)',
//
// and 'pCurrent' represents the current price of the pool.
//
// This value is also used to determine the end of the curve sequence while
// reading the curve sequence from storage. Because the curve sequence does not
// have a length slot, but its last member is equal to 'logPriceCurrent'.
uint16 constant _logPriceCurrent_ = 1655;

// The total number of shares that are deposited in the current active
// liquidity interval across all LPs.
//
// We keep track of the total share values in all of the liquidity intervals
// via the mapping 'sharesDelta' within protocol's storage. Let 'qBoundary'
// denote an arbitrary boundary for a liquidity interval, i.e.,
//
//  'qBoundary == qLower + j * qSpacing'
//
// for some integer 'j'. Let 'sharesTotalLeft' and 'sharesTotalRight' denote
// the total number of shares within the intervals
//
//  '[qBoundary - qSpacing, qBoundary]' and
//  '[qBoundary, qBoundary + qSpacing]',
//
// respectively. Define:
//
//  'sharesDelta[qBoundary] := sharesTotalRight - sharesTotalLeft'.
//
// In other words, 'sharesDelta[qBoundary]' is defined as the difference
// between the total number of shares within the two liquidity intervals that
// contain 'qBoundary'.
uint16 constant _sharesTotal_ = 1663;

// With each visit to a liquidity interval or as a result of donations, the
// amount of liquidity which is allocated to a single LP share increases. We
// use the parameter 'growth' to keep track of liquidity per share for the
// active interval. 'growth' is stored in 'X111' format and we always have
// 'oneX111 <= growth <= maxGrowth == 1 << 127'.
//
// Let 'pLower' and 'pUpper', respectively, denote the minimum and maximum
// price in the current active liquidity interval and define
//
//  'qLower := log(pLower / pOffset)',
//  'qUpper := log(pUpper / pOffset)'.
//
// Growth values across inactive intervals are kept track of using the mapping
// 'growthMultiplier' as explained below.
//
// For every integer 'm >= 1', let 
// 
//    sqrtInverseOffset     growthMultiplier[qLower + m * qSpacing]
//  '------------------- * -----------------------------------------'
//        2 ** 127                         2 ** 208
//
// represent the total amount of 'tag0' corresponding to a single liquidity
// provider's share from 'qLower + m * qSpacing' to '+oo' and let
//
//    sqrtOffset     growthMultiplier[qUpper - m * qSpacing]
//  '------------ * -----------------------------------------'
//     2 ** 127                     2 ** 208
//
// represent the total amount of 'tag1' corresponding to a single liquidity
// provider's share from '-oo' to 'qLower'.
//
// For every integer 'm', let 'growth(m)' denote the 'growth' value for the
// interval
//
//  '[qLower + m * qSpacing, qUpper + m * qSpacing]'.
//
// Hence, 'growth(0)' corresponds to '[qLower, qUpper]' which is stored in
// the following memory space.
//
// According to the above definitions, for every integer 'm >= 1', we have
//
//    growthMultiplier[qLower + m * qSpacing]
//  '----------------------------------------- := 
//                    2 ** 208
//   ---- +oo
//   \            growth(+j)      (- qLower - j * qSpacing) / 2
//   /           ------------ * e                               '.
//   ---- j = m    2 ** 111
//
// and
//
//    growthMultiplier[qUpper - m * qSpacing]
//  '----------------------------------------- := 
//                    2 ** 208
//   ---- +oo
//   \            growth(-j)      (+ qUpper - j * qSpacing) / 2
//   /           ------------ * e                               '.
//   ---- j = m    2 ** 111
//
// The following illustration further elaborates the notion of 'growth' and
// 'growthMultiplier':
//
//                                         growthMultiplier[qUpper + qSpacing]
//                                                                    |-->
//       growthMultiplier[qLower - qSpacing]                          |
//           <--|                                                     |
//              |                        growthMultiplier[qUpper]     |
//              |                                   |-->              |
//              |      growthMultiplier[qLower]     |                 |
//              |              <--|                 |                 |
//              |                 |     growth      |                 |
//              |                 |       ==        |                 |
//              |    growth(-1)   |    growth(0)    |    growth(+1)   |
//       ... <--+-----------------+-----------------+-----------------+--> ...
//                                |                 |
//                              qLower           qUpper
//
// In the above figure, 'growthMultiplier[qUpper]' and
// 'growthMultiplier[qUpper + qSpacing]' point towards '+oo' as well as every
// growthMultiplier[qLower + m * qSpacing] for positive integers 'm'.
//
// On the contrary, 'growthMultiplier[qLower]' and
// 'growthMultiplier[qLower - qSpacing]' point towards '-oo' as well as every
// growthMultiplier[qUpper - m * qSpacing] for positive integers 'm'.
uint16 constant _growth_ = 1679;

// Let 'pCurrent' and 'pUpper' represent the current price and the maximum
// price of the active liquidity interval, respectively, and define:
//
// 'qCurrent := log(pCurrent / pOffset)',
// 'qUpper := log(pUpper / pOffset)'.
//
// The memory space which is pointed to by '_integral0_' hosts the following
// integral in 'X216' representation which takes up to 27 bytes:
//
//                     - 8     / qUpper
//    integral0      e        |    - h / 2
//  '----------- := ------- * |  e         k(w(h)) dh'.
//    2 ** 216         2      |
//                           / qCurrent
//
// The total reserve of 'tag0' in the active liquidity interval can be derived
// from the following formula:
//
//  'totalReserveOfTag0 == sqrtInverseOffset * sharesTotal *
//
//                           growth       integral0
//                         ---------- * -------------
//                          2 ** 111     outgoingMax
//
uint16 constant _integral0_ = 1695;

// Let 'pCurrent' and 'pLower' represent the current price and the minimum
// price of the active liquidity interval, respectively, and define:
//
// 'qCurrent := log(pCurrent / pOffset)',
// 'qLower := log(pLower / pOffset)'.
//
// The memory space which is pointed to by '_integral1_' hosts the following
// integral in 'X216' representation which takes up to 27 bytes:
//
//                     - 8     / qCurrent
//    integral1      e        |    + h / 2
//  '----------- := ------- * |  e         k(w(h)) dh'.
//    2 ** 216         2      |
//                           / qLower
//
// The total reserve of 'tag1' in the active liquidity interval can be derived
// from the following formula:
//
//  'totalReserveOfTag1 == sqrtOffset * sharesTotal *
//
//                           growth       integral1
//                         ---------- * -------------
//                          2 ** 111     outgoingMax
//
uint16 constant _integral1_ = 1722;

// For every pool, the static parameters and the kernel are encoded in the
// source code of a storage smart contract which is deployed using a disposable
// proxy contract. When deploying a new storage smart contract, its creation
// code is stored in this 11 bytes memory space with static parameters and
// kernel appearing immediately after. This way, a chunk of memory can be sent
// to the proxy in order to deploy the storage smart contract.
uint16 constant _deploymentCreationCode_ = 1749;

// Static Parameters
// ----------------------------------------------------------------------------
// The following memory pointers are dedicated to the static parameters of the
// pool that do not change as frequently as dynamic parameters. They are stored
// along with the kernel. Hence, everytime the kernel or any of the growth
// portions are updated, the entire storage smart contract is redeployed.
uint16 constant _staticParams_ = 1760;

// The arithmetically smaller tag to be traded by the pool. This value is
// immutable. A tag may refer to native, ERC-20, ERC-6909, or ERC-1155 tokens
// as described in 'Tag.sol'.
uint16 constant _tag0_ = 1760;

// The arithmetically larger tag to be traded by the pool. This value is
// immutable.
uint16 constant _tag1_ = 1792;

// This memory space hosts the value:
//
// 'sqrtOffset := (2 ** 127) * sqrt(pOffset)'
//
// where the natural logarithm of 'pOffset' is an 'int8' which is encoded from
// bit 181 to bit 188 of poolId.
uint16 constant _sqrtOffset_ = 1824;

// This memory space hosts the value:
//
// 'sqrtInverseOffset := (2 ** 127) / sqrt(pOffset)'
//
// where the natural logarithm of 'pOffset' is an 'int8' which is encoded from
// bit 181 to bit 188 of poolId.
uint16 constant _sqrtInverseOffset_ = 1856;

// Let 'pLower' and 'pUpper' denote the minimum and maximum price in the active
// liquidity interval, respectively, and define
//
//  'qSpacing := log(pUpper / pLower)',
//
// The 62 bytes memory space which is pointed to by '_spacing_' hosts the
// following values:
//
//  '_spacing_.log() := (2 ** 59) * (16 + qSpacing)',
//  '_spacing_.sqrt(false) := (2 ** 216) * exp(- qSpacing / 2)',
//  '_spacing_.sqrt(true) := (2 ** 216) * exp(- 16 + qSpacing / 2)'.
//
// which can be accessed via 'PriceLibrary'. The logarithmic price
// '_spacing_.log()' occupies 64 bits, whereas '_spacing_.sqrt(false)' and
// '_spacing_.sqrt(true)' occupy 216 bits each.
uint16 constant _spacing_ = 1888;

// Let 'pLower' and 'pUpper' denote the minimum and maximum price in the active
// liquidity interval, respectively, and define
//
//  'qUpper := log(pUpper / pOffset)',
//  'qLower := log(pLower / pOffset)',
//  'qSpacing := log(pUpper / pLower)'.
//
// This 27 bytes memory space hosts 'outgoingMax' which is a kernel parameter.
// The 'X216' representation of 'outgoingMax' is defined as follows:
//
//                       - 8     / qSpacing
//    outgoingMax      e        |    - h / 2
//  '------------- := ------- * |  e         k(h) dh'.
//     2 ** 216          2      |
//                             / 0
//
// 'outgoingMax' is used frequently for calculating any amount of 'tag0' and
// 'tag1'. Because of this, we calculate 'outgoingMax' and its modular inverse
// at the time of initialization or anytime that the kernel is modified and
// then we store the resulting values among the static parameters.
//
// 'outgoingMax' can be calculated with the following two equivalent formulas
// as well:
//
//                       - 8 + qLower / 2     / qUpper
//    outgoingMax      e                     |    - h / 2
//  '------------- := -------------------- * |  e         k(h - qLower) dh
//     2 ** 216                 2            |
//                                          / qLower
//
//                       - 8 - qUpper / 2     / qUpper
//                     e                     |    + h / 2
//                    -------------------- * |  e         k(qUpper - h) dh'.
//                              2            |
//                                          / qLower
//
// Notice that the above formulas are independent of the choice for 'qLower'
// and 'qUpper', and they result in the same value as long as 
// 'qUpper - qLower == qSpacing'.
uint16 constant _outgoingMax_ = 1950;

// This 32 bytes memory space hosts 'outgoingMaxModularInverse' which is the
// modular inverse of
//
//    outgoingMax 
//  '-------------'
//      2 ** n
//
// modulo '2 ** 256', where 'n' is the largest power of '2' that divides
// 'outgoingMax'. This value is calculated at the time of initialization or
// anytime that the kernel function is modified.
//
// Precalculation of 'outgoingMaxModularInverse' facilitates division by
// 'outgoingMax' which is done frequently.
uint16 constant _outgoingMaxModularInverse_ = 1977;

// Let 'pLower' and 'pUpper' denote the minimum and maximum price in the active
// liquidity interval, respectively, and define
//
//  'qUpper := log(pUpper / pOffset)',
//  'qLower := log(pLower / pOffset)',
//  'qSpacing := log(pUpper / pLower)'.
//
// This 27 bytes memory space hosts 'outgoingMax' which is a kernel parameter.
// The 'X216' representation of 'outgoingMax' is defined as follows:
//
//                       - 8 - qSpacing / 2     / qSpacing
//    incomingMax      e                       |    + h / 2
//  '------------- := ---------------------- * |  e         k(h) dh'.
//     2 ** 216                 2              |
//                                            / 0
//
// 'incomingMax' is used for calculating the incoming amount as we cross an
// entire liquidity interval from 'qBack' to 'qNext'. Because of this, we
// calculate 'incomingMax' at the time of initialization or anytime that the
// kernel is modified and then we store the resulting value among the static
// parameters.
//
// 'incomingMax' can be calculated with the following two equivalent formulas
// as well:
//
//                       - 8 - qUpper / 2     / qUpper
//    incomingMax      e                     |    + h / 2
//  '------------- := -------------------- * |  e         k(h - qLower) dh
//     2 ** 216                 2            |
//                                          / qLower
//
//                       - 8 + qLower / 2     / qUpper
//                     e                     |    - h / 2
//                    -------------------- * |  e         k(qUpper - h) dh'.
//                              2            |
//                                          / qLower
//
// Notice that the above formulas are independent of the choice for 'qLower'
// and 'qUpper', and they result in the same value as long as 
// 'qUpper - qLower == qSpacing'.
uint16 constant _incomingMax_ = 2009;

// The content of the 6 bytes memory space which is pointed to by
// '_poolGrowthPortion_' dictates the portion of the growth that goes to the
// pool owner followed by the protocol.
//
// The content of the 6 bytes memory space which is pointed to by
// '_maxPoolGrowthPortion_' imposes a cap on the portion of the marginal growth
// that goes to the pool owner followed by the protocol.
//
// The content of the 6 bytes memory space which is pointed to by
// '_protocolGrowthPortion_' dictates the portion of the growth that goes to
// the protocol.
//
// 'maxPoolGrowthPortion' and 'protocolGrowthPortion' are set by the protocol
// slot or the sentinel contract. Any address can invoke a function to sync
// these two values with the global portions.
//
// This value is set by the protocol slot or the sentinel contract.
// Any address can invoke a function to sync this value with the global
// portion.
//
// Let '[qLower, qUpper]' represent the active liquidity interval. As part of a
// swap, assume that the price is moved from 'qCurrent' to 'qTarget' within
// '[qLower, qUpper]'. Define:
//
//                                - 8     / qUpper
//    integral0Incremented      e        |    - h / 2
//  '---------------------- := ------- * |  e         k(w(h)) dh',
//          2 ** 216              2      |
//                                      / qTarget
//
//                                - 8     / qTarget
//    integral1Incremented      e        |    + h / 2
//  '---------------------- := ------- * |  e         k(w(h)) dh'.
//          2 ** 216              2      |
//                                      / qLower
//
// Now, assume that the curve sequence is updated and the function 'w' is
// transformed into a new function 'wAmended' which is constructed based on the
// updated curve sequence. Define:
//
//                            - 8     / qUpper
//    integral0Amended      e        |    - h / 2
//  '------------------ := ------- * |  e         k(wAmended(h)) dh',
//        2 ** 216            2      |
//                                  / qTarget
//
//                            - 8     / qTarget
//    integral1Amended      e        |    + h / 2
//  '------------------ := ------- * |  e         k(wAmended(h)) dh'.
//        2 ** 216            2      |
//                                  / qLower
//
// Then we have:
//                              integral0Incremented
//  'growthAmended := growth * ----------------------
//                                integral0Amended
//
//                              integral1Incremented
//                 == growth * ----------------------'.
//                                integral1Amended
//
// Now, the marginal growth with respect to 'tag0' and 'tag1' can be defined
// as:
//
//  'marginalGrowthOfTag0 := sqrtInverseOffset * sharesTotal * 
//
//                            growthAmended - growth     integral0Amended
//                           ------------------------ * ------------------',
//                                    2 ** 111             outgoingMax
//
//  'marginalGrowthOfTag1 := sqrtOffset * sharesTotal * 
//
//                            growthAmended - growth     integral1Amended
//                           ------------------------ * ------------------'.
//                                    2 ** 111             outgoingMax
//
// Hence, as a result of this swap, the amount of 'tag0' that goes to the
// protocol is equal to:
//
//    protocolGrowthPortion
//  '----------------------- * marginalGrowthOfTag0'
//           2 ** 47
//
// and the amount of 'tag1' that goes to the protocol is equal to:
//
//    protocolGrowthPortion
//  '----------------------- * marginalGrowthOfTag1'
//           2 ** 47
//
// Additionally, the amount of 'tag0' that goes to the pool owner is equal to:
//
//    min(poolGrowthPortion, maxPoolGrowthPortion)
//  '---------------------------------------------- * 
//                      2 ** 47
//
//    oneX47 - protocolGrowthPortion
//   -------------------------------- * marginalGrowthOfTag0'
//               2 ** 47
//
// and the amount of 'tag1' that goes to the pool owner is equal to:
//
//    min(poolGrowthPortion, maxPoolGrowthPortion)
//  '---------------------------------------------- * 
//                      2 ** 47
//
//    oneX47 - protocolGrowthPortion
//   -------------------------------- * marginalGrowthOfTag1'
//               2 ** 47
//
uint16 constant _poolGrowthPortion_ = 2036;
uint16 constant _maxPoolGrowthPortion_ = 2042;
uint16 constant _protocolGrowthPortion_ = 2048;

// The number of members for the pending kernel. Once a new kernel is
// introduced, it remains pending until transition to a new liquidity interval.
// This value is an indicator for whether there exists a pending kernel.
// This value is used to ensure that a sufficient amount of space is reserved
// in memory for kernel, in case the pending kernel needs to be activated in
// the middle of a swap, i.e., read from the new storage smart contract.
uint16 constant _pendingKernelLength_ = 2054;

uint16 constant _endOfStaticParams_ = 2056;

// Modify Position Parameters
// ----------------------------------------------------------------------------
// The following memory pointers host the inputs and the resulting outputs of
// the method 'modifyPosition'. An LP may choose any consecutive range of
// liquidity intervals to deposit their liquidity. By doing so, the LP acquires
// a number of shares in every liquidity interval that belongs to the given
// range. The shares can be used later to withdraw liquidity along with any
// accumulated growth which is accrued as a result of swap and donate actions.
uint16 constant _modifyPositionInput_ = 248;

// Every LP position is characterized by two prices 'pMin' and 'pMax'. These
// two prices, respectively, correspond to the left and the right boundaries of
// the consecutive range in which the LP intends to deposit or withdraw
// liquidity. The following two 8 bytes memory spaces, respectively, host:
//
//  '(2 ** 59) * (16 + log(pMin / pOffset))',
//  '(2 ** 59) * (16 + log(pMax / pOffset))'.
uint16 constant _logPriceMinOffsetted_ = 248;
uint16 constant _logPriceMaxOffsetted_ = 256;

// This 32 bytes memory space hosts the number of shares to be added (positive)
// or removed (negative).
uint16 constant _shares_ = 264;

// The following two 32 bytes memory spaces, respectively, host:
//
//  'logPriceMin := (2 ** 59) * log(pMin)',
//  'logPriceMax := (2 ** 59) * log(pMax)'.
//
// Both 'logPriceMin' and 'logPriceMax' must be equal to the active interval
// boundaries modulo 'qSpacing'.
uint16 constant _logPriceMin_ = 296;
uint16 constant _logPriceMax_ = 328;

// The amount of 'tag0' to be added (positive) or removed (negative) in 'X127'
// representation, as a result of modifyPosition.
uint16 constant _positionAmount0_ = 360;
// The amount of 'tag1' to be added (positive) or removed (negative) in 'X127'
// representation, as a result of modifyPosition.
uint16 constant _positionAmount1_ = 392;

uint16 constant _endOfModifyPosition_ = 424;

////////////////////////////////////////////////////////////////////////////////
// The remainder of this script contains automatically generated getter and
// setter functions for the parameters introduced above.

function getFreeMemoryPointer() pure returns (
  uint256 freeMemoryPointer
) {
  assembly {
    freeMemoryPointer := mload(_freeMemoryPointer_)
  }
}

function setFreeMemoryPointer(
  uint256 freeMemoryPointer
) pure {
  assembly {
    mstore(_freeMemoryPointer_, freeMemoryPointer)
  }
}

function setHookSelector(
  uint32 hookSelector
) pure {
  assembly {
    mstore(
      _hookSelector_,
      or(
        shl(224, hookSelector),
        shr(32, mload(add(_hookSelector_, 4)))
      )
    )
  }
}

function setHookInputHeader(
  uint256 hookInputHeader
) pure {
  assembly {
    mstore(_hookInputHeader_, hookInputHeader)
  }
}

function getHookInputByteCount() pure returns (
  uint256 hookInputByteCount
) {
  assembly {
    hookInputByteCount := mload(_hookInputByteCount_)
  }
}

function setHookInputByteCount(
  uint256 hookInputByteCount
) pure {
  assembly {
    mstore(_hookInputByteCount_, hookInputByteCount)
  }
}

function setMsgSender(
  address msgSender
) pure {
  assembly {
    mstore(
      _msgSender_,
      or(
        shl(96, msgSender),
        shr(160, mload(add(_msgSender_, 20)))
      )
    )
  }
}

function getPoolId() pure returns (
  uint256 poolId
) {
  assembly {
    poolId := mload(_poolId_)
  }
}

function setPoolId(
  uint256 poolId
) pure {
  assembly {
    mstore(_poolId_, poolId)
  }
}

function getCrossThreshold() pure returns (
  uint256 crossThreshold
) {
  assembly {
    crossThreshold := shr(128, mload(_crossThreshold_))
  }
}

function setCrossThreshold(
  uint256 crossThreshold
) pure {
  assembly {
    mstore(
      _crossThreshold_,
      or(
        shl(128, crossThreshold),
        shr(128, mload(add(_crossThreshold_, 16)))
      )
    )
  }
}

function getAmountSpecified() pure returns (
  X127 amountSpecified
) {
  assembly {
    amountSpecified := mload(_amountSpecified_)
  }
}

function setAmountSpecified(
  X127 amountSpecified
) pure {
  assembly {
    mstore(_amountSpecified_, amountSpecified)
  }
}

function getLogPriceLimit() pure returns (
  X59 logPriceLimit
) {
  assembly {
    logPriceLimit := mload(_logPriceLimit_)
  }
}

function setLogPriceLimit(
  X59 logPriceLimit
) pure {
  assembly {
    mstore(_logPriceLimit_, logPriceLimit)
  }
}

function getLogPriceLimitOffsetted() pure returns (
  X59 logPriceLimitOffsetted
) {
  assembly {
    logPriceLimitOffsetted := shr(192, mload(_logPriceLimitOffsetted_))
  }
}

function setLogPriceLimitOffsetted(
  X59 logPriceLimitOffsetted
) pure {
  assembly {
    mstore(
      _logPriceLimitOffsetted_,
      or(
        shl(192, logPriceLimitOffsetted),
        shr(64, mload(add(_logPriceLimitOffsetted_, 8)))
      )
    )
  }
}

function getZeroForOne() pure returns (
  bool zeroForOne
) {
  assembly {
    zeroForOne := shr(255, mload(_zeroForOne_))
  }
}

function setZeroForOne(
  bool zeroForOne
) pure {
  assembly {
    mstore8(_zeroForOne_, mul(0xFF, zeroForOne))
  }
}

function getExactInput() pure returns (
  bool exactInput
) {
  assembly {
    exactInput := shr(255, mload(_exactInput_))
  }
}

function setExactInput(
  bool exactInput
) pure {
  assembly {
    mstore8(_exactInput_, mul(0xFF, exactInput))
  }
}

function getIntegralLimit() pure returns (
  X216 integralLimit
) {
  assembly {
    integralLimit := shr(40, mload(_integralLimit_))
  }
}

function setIntegralLimit(
  X216 integralLimit
) pure {
  assembly {
    mstore(
      _integralLimit_,
      or(
        shl(40, integralLimit),
        shr(216, mload(add(_integralLimit_, 27)))
      )
    )
  }
}

function getIntegralLimitInterval() pure returns (
  X216 integralLimitInterval
) {
  assembly {
    integralLimitInterval := shr(40, mload(_integralLimitInterval_))
  }
}

function setIntegralLimitInterval(
  X216 integralLimitInterval
) pure {
  assembly {
    mstore(
      _integralLimitInterval_,
      or(
        shl(40, integralLimitInterval),
        shr(216, mload(add(_integralLimitInterval_, 27)))
      )
    )
  }
}

function getAmount0() pure returns (
  X127 amount0
) {
  assembly {
    amount0 := mload(_amount0_)
  }
}

function setAmount0(
  X127 amount0
) pure {
  assembly {
    mstore(_amount0_, amount0)
  }
}

function getAmount1() pure returns (
  X127 amount1
) {
  assembly {
    amount1 := mload(_amount1_)
  }
}

function setAmount1(
  X127 amount1
) pure {
  assembly {
    mstore(_amount1_, amount1)
  }
}

function getBackGrowthMultiplier() pure returns (
  X208 backGrowthMultiplier
) {
  assembly {
    backGrowthMultiplier := mload(_backGrowthMultiplier_)
  }
}

function setBackGrowthMultiplier(
  X208 backGrowthMultiplier
) pure {
  assembly {
    mstore(_backGrowthMultiplier_, backGrowthMultiplier)
  }
}

function getNextGrowthMultiplier() pure returns (
  X208 nextGrowthMultiplier
) {
  assembly {
    nextGrowthMultiplier := mload(_nextGrowthMultiplier_)
  }
}

function setNextGrowthMultiplier(
  X208 nextGrowthMultiplier
) pure {
  assembly {
    mstore(_nextGrowthMultiplier_, nextGrowthMultiplier)
  }
}

function getDirection() pure returns (
  bool direction
) {
  assembly {
    direction := shr(255, mload(_direction_))
  }
}

function setDirection(
  bool direction
) pure {
  assembly {
    mstore8(_direction_, mul(0xFF, direction))
  }
}

function getIndexCurve() pure returns (
  Index indexCurve
) {
  assembly {
    indexCurve := shr(240, mload(_indexCurve_))
  }
}

function setIndexCurve(
  Index indexCurve
) pure {
  assembly {
    mstore(
      _indexCurve_,
      or(
        shl(240, indexCurve),
        shr(16, mload(add(_indexCurve_, 2)))
      )
    )
  }
}

function getLogPriceLimitOffsettedWithinInterval() pure returns (
  X59 logPriceLimitOffsettedWithinInterval
) {
  assembly {
    logPriceLimitOffsettedWithinInterval := 
      shr(192, mload(_logPriceLimitOffsettedWithinInterval_))
  }
}

function setLogPriceLimitOffsettedWithinInterval(
  X59 logPriceLimitOffsettedWithinInterval
) pure {
  assembly {
    mstore(
      _logPriceLimitOffsettedWithinInterval_,
      or(
        shl(192, logPriceLimitOffsettedWithinInterval),
        shr(64, mload(add(_logPriceLimitOffsettedWithinInterval_, 8)))
      )
    )
  }
}

function getAccrued0() pure returns (
  X127 accrued0
) {
  assembly {
    accrued0 := mload(_accrued0_)
  }
}

function setAccrued0(
  X127 accrued0
) pure {
  assembly {
    mstore(_accrued0_, accrued0)
  }
}

function getAccrued1() pure returns (
  X127 accrued1
) {
  assembly {
    accrued1 := mload(_accrued1_)
  }
}

function setAccrued1(
  X127 accrued1
) pure {
  assembly {
    mstore(_accrued1_, accrued1)
  }
}

function getPoolRatio0() pure returns (
  X23 poolRatio0
) {
  assembly {
    poolRatio0 := shr(232, mload(_poolRatio0_))
  }
}

function setPoolRatio0(
  X23 poolRatio0
) pure {
  assembly {
    mstore(
      _poolRatio0_,
      or(
        shl(232, poolRatio0),
        shr(24, mload(add(_poolRatio0_, 3)))
      )
    )
  }
}

function getPoolRatio1() pure returns (
  X23 poolRatio1
) {
  assembly {
    poolRatio1 := shr(232, mload(_poolRatio1_))
  }
}

function setPoolRatio1(
  X23 poolRatio1
) pure {
  assembly {
    mstore(
      _poolRatio1_,
      or(
        shl(232, poolRatio1),
        shr(24, mload(add(_poolRatio1_, 3)))
      )
    )
  }
}

function getKernel() pure returns (
  Kernel kernel
) {
  assembly {
    kernel := mload(_kernel_)
  }
}

function setKernel(
  Kernel kernel
) pure {
  assembly {
    mstore(_kernel_, kernel)
  }
}

function getCurve() pure returns (
  Curve curve
) {
  assembly {
    curve := mload(_curve_)
  }
}

function setCurve(
  Curve curve
) pure {
  assembly {
    mstore(_curve_, curve)
  }
}

function getHookData() pure returns (
  uint256 hookData
) {
  assembly {
    hookData := mload(_hookData_)
  }
}

function setHookData(
  uint256 hookData
) pure {
  assembly {
    mstore(_hookData_, hookData)
  }
}

function getKernelLength() pure returns (
  Index kernelLength
) {
  assembly {
    kernelLength := shr(240, mload(_kernelLength_))
  }
}

function setKernelLength(
  Index kernelLength
) pure {
  assembly {
    mstore(
      _kernelLength_,
      or(
        shl(240, kernelLength),
        shr(16, mload(add(_kernelLength_, 2)))
      )
    )
  }
}

function getCurveLength() pure returns (
  Index curveLength
) {
  assembly {
    curveLength := shr(240, mload(_curveLength_))
  }
}

function setCurveLength(
  Index curveLength
) pure {
  assembly {
    mstore(
      _curveLength_,
      or(
        shl(240, curveLength),
        shr(16, mload(add(_curveLength_, 2)))
      )
    )
  }
}

function getHookDataByteCount() pure returns (
  uint16 hookDataByteCount
) {
  assembly {
    hookDataByteCount := shr(240, mload(_hookDataByteCount_))
  }
}

function setHookDataByteCount(
  uint16 hookDataByteCount
) pure {
  assembly {
    mstore(
      _hookDataByteCount_,
      or(
        shl(240, hookDataByteCount),
        shr(16, mload(add(_hookDataByteCount_, 2)))
      )
    )
  }
}

function getStaticParamsStoragePointerExtension() pure returns (
  uint256 staticParamsStoragePointerExtension
) {
  assembly {
    staticParamsStoragePointerExtension := 
      mload(_staticParamsStoragePointerExtension_)
  }
}

function setStaticParamsStoragePointerExtension(
  uint256 staticParamsStoragePointerExtension
) pure {
  assembly {
    mstore(
      _staticParamsStoragePointerExtension_,
      staticParamsStoragePointerExtension
    )
  }
}

function getGrowth() pure returns (
  X111 growth
) {
  assembly {
    growth := shr(128, mload(_growth_))
  }
}

function setGrowth(
  X111 growth
) pure {
  assembly {
    mstore(
      _growth_,
      or(
        shl(128, growth),
        shr(128, mload(add(_growth_, 16)))
      )
    )
  }
}

function getIntegral0() pure returns (
  X216 integral0
) {
  assembly {
    integral0 := shr(40, mload(_integral0_))
  }
}

function setIntegral0(
  X216 integral0
) pure {
  assembly {
    mstore(
      _integral0_,
      or(
        shl(40, integral0),
        shr(216, mload(add(_integral0_, 27)))
      )
    )
  }
}

function getIntegral1() pure returns (
  X216 integral1
) {
  assembly {
    integral1 := shr(40, mload(_integral1_))
  }
}

function setIntegral1(
  X216 integral1
) pure {
  assembly {
    mstore(
      _integral1_,
      or(
        shl(40, integral1),
        shr(216, mload(add(_integral1_, 27)))
      )
    )
  }
}

function getSharesTotal() pure returns (
  uint256 sharesTotal
) {
  assembly {
    sharesTotal := shr(128, mload(_sharesTotal_))
  }
}

function setSharesTotal(
  uint256 sharesTotal
) pure {
  assembly {
    mstore(
      _sharesTotal_,
      or(
        shl(128, sharesTotal),
        shr(128, mload(add(_sharesTotal_, 16)))
      )
    )
  }
}

function getStaticParamsStoragePointer() pure returns (
  uint16 staticParamsStoragePointer
) {
  assembly {
    staticParamsStoragePointer := shr(240, mload(_staticParamsStoragePointer_))
  }
}

function setStaticParamsStoragePointer(
  uint16 staticParamsStoragePointer
) pure {
  assembly {
    mstore(
      _staticParamsStoragePointer_,
      or(
        shl(240, staticParamsStoragePointer),
        shr(16, mload(add(_staticParamsStoragePointer_, 2)))
      )
    )
  }
}

function getLogPriceCurrent() pure returns (
  X59 logPriceCurrent
) {
  assembly {
    logPriceCurrent := shr(192, mload(_logPriceCurrent_))
  }
}

function setLogPriceCurrent(
  X59 logPriceCurrent
) pure {
  assembly {
    mstore(
      _logPriceCurrent_,
      or(
        shl(192, logPriceCurrent),
        shr(64, mload(add(_logPriceCurrent_, 8)))
      )
    )
  }
}

function setDeploymentCreationCode(
  uint256 deploymentCreationCode
) pure {
  assembly {
    mstore(
      _deploymentCreationCode_,
      or(
        shl(168, deploymentCreationCode),
        shr(88, mload(add(_deploymentCreationCode_, 11)))
      )
    )
  }
}

function getTag0() pure returns (
  Tag tag0
) {
  assembly {
    tag0 := mload(_tag0_)
  }
}

function setTag0(
  Tag tag0
) pure {
  assembly {
    mstore(_tag0_, tag0)
  }
}

function getTag1() pure returns (
  Tag tag1
) {
  assembly {
    tag1 := mload(_tag1_)
  }
}

function setTag1(
  Tag tag1
) pure {
  assembly {
    mstore(_tag1_, tag1)
  }
}

function getSqrtOffset() pure returns (
  X127 sqrtOffset
) {
  assembly {
    sqrtOffset := mload(_sqrtOffset_)
  }
}

function setSqrtOffset(
  X127 sqrtOffset
) pure {
  assembly {
    mstore(_sqrtOffset_, sqrtOffset)
  }
}

function getSqrtInverseOffset() pure returns (
  X127 sqrtInverseOffset
) {
  assembly {
    sqrtInverseOffset := mload(_sqrtInverseOffset_)
  }
}

function setSqrtInverseOffset(
  X127 sqrtInverseOffset
) pure {
  assembly {
    mstore(_sqrtInverseOffset_, sqrtInverseOffset)
  }
}

function getOutgoingMax() pure returns (
  X216 outgoingMax
) {
  assembly {
    outgoingMax := shr(40, mload(_outgoingMax_))
  }
}

function setOutgoingMax(
  X216 outgoingMax
) pure {
  assembly {
    mstore(
      _outgoingMax_,
      or(
        shl(40, outgoingMax),
        shr(216, mload(add(_outgoingMax_, 27)))
      )
    )
  }
}

function getOutgoingMaxModularInverse() pure returns (
  uint256 outgoingMaxModularInverse
) {
  assembly {
    outgoingMaxModularInverse := mload(_outgoingMaxModularInverse_)
  }
}

function setOutgoingMaxModularInverse(
  uint256 outgoingMaxModularInverse
) pure {
  assembly {
    mstore(_outgoingMaxModularInverse_, outgoingMaxModularInverse)
  }
}

function getIncomingMax() pure returns (
  X216 incomingMax
) {
  assembly {
    incomingMax := shr(40, mload(_incomingMax_))
  }
}

function setIncomingMax(
  X216 incomingMax
) pure {
  assembly {
    mstore(
      _incomingMax_,
      or(
        shl(40, incomingMax),
        shr(216, mload(add(_incomingMax_, 27)))
      )
    )
  }
}

function getPoolGrowthPortion() pure returns (
  X47 poolGrowthPortion
) {
  assembly {
    poolGrowthPortion := shr(208, mload(_poolGrowthPortion_))
  }
}

function setPoolGrowthPortion(
  X47 poolGrowthPortion
) pure {
  assembly {
    mstore(
      _poolGrowthPortion_,
      or(
        shl(208, poolGrowthPortion),
        shr(48, mload(add(_poolGrowthPortion_, 6)))
      )
    )
  }
}

function getMaxPoolGrowthPortion() pure returns (
  X47 maxPoolGrowthPortion
) {
  assembly {
    maxPoolGrowthPortion := shr(208, mload(_maxPoolGrowthPortion_))
  }
}

function setMaxPoolGrowthPortion(
  X47 maxPoolGrowthPortion
) pure {
  assembly {
    mstore(
      _maxPoolGrowthPortion_,
      or(
        shl(208, maxPoolGrowthPortion),
        shr(48, mload(add(_maxPoolGrowthPortion_, 6)))
      )
    )
  }
}

function getProtocolGrowthPortion() pure returns (
  X47 protocolGrowthPortion
) {
  assembly {
    protocolGrowthPortion := shr(208, mload(_protocolGrowthPortion_))
  }
}

function setProtocolGrowthPortion(
  X47 protocolGrowthPortion
) pure {
  assembly {
    mstore(
      _protocolGrowthPortion_,
      or(
        shl(208, protocolGrowthPortion),
        shr(48, mload(add(_protocolGrowthPortion_, 6)))
      )
    )
  }
}

function getPendingKernelLength() pure returns (
  Index pendingKernelLength
) {
  assembly {
    pendingKernelLength := shr(240, mload(_pendingKernelLength_))
  }
}

function setPendingKernelLength(
  Index pendingKernelLength
) pure {
  assembly {
    mstore(
      _pendingKernelLength_,
      or(
        shl(240, pendingKernelLength),
        shr(16, mload(add(_pendingKernelLength_, 2)))
      )
    )
  }
}

function getLogPriceMinOffsetted() pure returns (
  X59 logPriceMinOffsetted
) {
  assembly {
    logPriceMinOffsetted := shr(192, mload(_logPriceMinOffsetted_))
  }
}

function setLogPriceMinOffsetted(
  X59 logPriceMinOffsetted
) pure {
  assembly {
    mstore(
      _logPriceMinOffsetted_,
      or(
        shl(192, logPriceMinOffsetted),
        shr(64, mload(add(_logPriceMinOffsetted_, 8)))
      )
    )
  }
}

function getLogPriceMaxOffsetted() pure returns (
  X59 logPriceMaxOffsetted
) {
  assembly {
    logPriceMaxOffsetted := shr(192, mload(_logPriceMaxOffsetted_))
  }
}

function setLogPriceMaxOffsetted(
  X59 logPriceMaxOffsetted
) pure {
  assembly {
    mstore(
      _logPriceMaxOffsetted_,
      or(
        shl(192, logPriceMaxOffsetted),
        shr(64, mload(add(_logPriceMaxOffsetted_, 8)))
      )
    )
  }
}

function getShares() pure returns (
  int256 shares
) {
  assembly {
    shares := mload(_shares_)
  }
}

function setShares(
  int256 shares
) pure {
  assembly {
    mstore(_shares_, shares)
  }
}

function getLogPriceMin() pure returns (
  X59 logPriceMin
) {
  assembly {
    logPriceMin := mload(_logPriceMin_)
  }
}

function setLogPriceMin(
  X59 logPriceMin
) pure {
  assembly {
    mstore(_logPriceMin_, logPriceMin)
  }
}

function getLogPriceMax() pure returns (
  X59 logPriceMax
) {
  assembly {
    logPriceMax := mload(_logPriceMax_)
  }
}

function setLogPriceMax(
  X59 logPriceMax
) pure {
  assembly {
    mstore(_logPriceMax_, logPriceMax)
  }
}

function getPositionAmount0() pure returns (
  int256 positionAmount0
) {
  assembly {
    positionAmount0 := mload(_positionAmount0_)
  }
}

function setPositionAmount0(
  int256 positionAmount0
) pure {
  assembly {
    mstore(_positionAmount0_, positionAmount0)
  }
}

function getPositionAmount1() pure returns (
  int256 positionAmount1
) {
  assembly {
    positionAmount1 := mload(_positionAmount1_)
  }
}

function setPositionAmount1(
  int256 positionAmount1
) pure {
  assembly {
    mstore(_positionAmount1_, positionAmount1)
  }
}