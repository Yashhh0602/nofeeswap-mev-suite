// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {Index, zeroIndex} from "./Index.sol";
import {X15} from "./X15.sol";
import {X59} from "./X59.sol";
import {X216, oneX216} from "./X216.sol";
import {PriceLibrary} from "./Price.sol";

using PriceLibrary for uint16;
using PriceLibrary for uint256;

// For every pool, the kernel function 'k : [0, qSpacing] -> [0, 1]' represents
// a monotonically non-decreasing piece-wise linear function whose breakpoints
// are listed in the storage smart contract. Let 'm + 1' denote the number
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
type Kernel is uint256;

using KernelLibrary for Kernel global;

library KernelLibrary {
  /// @notice Returns the components of the kernel breakpoint which corresponds
  /// to the given index.
  ///
  /// Index out of range should be avoided externally.
  function member(
    Kernel kernel,
    Index index
  ) internal pure returns (
    X15 height,
    X59 logShift,
    X216 sqrtShift,
    X216 sqrtInverseShift
  ) {
    // If 'index' is equal to 0, then this function should return 
    // '(zeroX15, zeroX59, oneX216, floor((2 ** 216) * exp(-16)))'. Because the
    // first member of kernelCompact is always '(zeroX15, zeroX59)'.
    if (index > zeroIndex) {
      uint256 pointer;
      assembly {
        // Each member of Kernel is '64 == 2 ** 6' bytes. Hence we shift
        // 'index' by '6' digits which is equivalent to multiplying by '64'.
        // The origin is omitted and handled separately. We subtract by
        // '62 = 8 + 27 + 27' so that the pointer corresponding to 
        // 'index == oneIndex' follows this layout:
        //
        //        pointer
        //      /
        //     |        A 512 bit kernel breakpoint
        //  +--+--------+-----------------+-----------------+
        //  |  | 8 byte |     27 byte     |     27 byte     |
        //  +--+--------+-----------------+-----------------+
        //  |  |        |                 |
        //  |  |        |                  \
        //  |  |        |                   (2 ** 216) * exp(- 16 + b[i] / 2)
        //  |  |         \
        //  |  |          (2 ** 216) * exp(- b[i] / 2)
        //  |   \
        //  |    (2 ** 59) * b[i]
        //   \
        //    (2 ** 15) * c[i]
        //
        pointer := add(kernel, sub(shl(6, index), 62))
      }
      // Now that 'pointer' points to a price with height according to the
      // above layout, all four values are loaded from memory using
      // 'PriceLibrary'.
      height = pointer.height();
      logShift = pointer.log();
      sqrtShift = pointer.sqrt(false);
      sqrtInverseShift = pointer.sqrt(true);
    } else {
      // 'height' and 'logShift' are zero by default.
      sqrtShift = oneX216;
      sqrtInverseShift = X216.wrap(
        0x0000000000000001E355BBAEE85CADA65F73F32E88FB3CC629B709109F57564D
      ); // floor((2 ** 216) * exp(-16))
    }
  }

  /// @notice This function calculates the resultant of the logarithmic price
  /// 'q' which is stored in 'basePrice' and the 'index' breakpoint of
  /// 'kernel'. The resultant is then stored in memory.
  ///
  /// If 'left == false', the resulting log price is equal to 
  ///
  ///  'qResultant := q + b[index]'.
  ///
  /// In this case we should have: '0 < q + b[index] < 2 ** 64'.
  ///
  /// If 'left == true', the resulting log price is equal to 
  ///
  ///  'qResultant := q - b[index]'.
  ///
  /// In this case we should have: '0 < q - b[index] < 2 ** 64'.
  ///
  /// Index out of range should be avoided externally.
  /// 'resultant' should not be less than '34'.
  function impose(
    Kernel kernel,
    uint256 resultant,
    uint256 basePrice,
    Index index,
    bool left
  ) internal pure {
    // These four values correspond to the kernel's member.
    (X15 height, X59 logShift, X216 sqrtShift, X216 sqrtInverseShift) = 
      kernel.member(index);
    
    // Addition or subtraction is safe due to the above requirements.
    // The multiplication does not overflow because both values are loaded from
    // 216 bits of memory. Hence, they are non-negative and are less than
    // oneX216.
    // The requirements of 'mulDivByExpInv16' are met because both values are 
    // loaded from 216 bits of memory. Hence, they are non-negative and are 
    // less than oneX216. Additionally, 'mulDivByExpInv16' does not overflow
    // and fits within 216 bits, because if 'left == false':
    //
    // '(basePrice.sqrt(true) ^ sqrtInverseShift) / (2 ** 216) == 
    //  exp(- 16 - 16 + (basePrice.log() + logShift) / (2 ** 60)) / exp(-16)
    //  == exp(- 16 + (basePrice.log() + logShift) / (2 ** 60)) <
    //  == exp(- 16 + (2 ** 64) / (2 ** 60)) <= 1'
    //
    // and if 'left == true':
    //
    // '(basePrice.sqrt(false) ^ sqrtInverseShift) / (2 ** 216) == 
    //  exp(-16 - (basePrice.log() - logShift) / (2 ** 60)) / exp(-16) == 
    //  exp(- (basePrice.log() - logShift) / (2 ** 60)) < exp(0) <= 1'
    //
    // Hence, the outcome of the multiplication and 'mulDivByExpInv16' do not
    // exceed 216 bits.
    (X59 logPrice, X216 sqrtPrice, X216 sqrtInversePrice) = left ? (
      basePrice.log() - logShift,
      basePrice.sqrt(false) ^ sqrtInverseShift,
      basePrice.sqrt(true) * sqrtShift
    ) : (
      basePrice.log() + logShift,
      basePrice.sqrt(false) * sqrtShift,
      basePrice.sqrt(true) ^ sqrtInverseShift
    );

    // The requirements of 'storePrice' are satisfied due to the above
    // arguments and the input requirements.
    resultant.storePrice(height, logPrice, sqrtPrice, sqrtInversePrice);
  }
}