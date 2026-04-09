// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X15} from "./X15.sol";
import {X59} from "./X59.sol";
import {X216} from "./X216.sol";

library PriceLibrary {
  using PriceLibrary for uint256;

  /// @notice Stores a given price in a given memory location with the 
  /// following layout:
  ///
  ///  pointer
  ///     |
  ///     +--------+---------------------------+---------------------------+
  ///     | 8 byte |          27 byte          |          27 byte          |
  ///     +--------+---------------------------+---------------------------+
  ///     |        |                           |
  ///     |        |                            \
  ///     |        |                             sqrtInversePrice
  ///     |         \
  ///     |          sqrtPrice
  ///      \
  ///       logPrice
  ///
  /// 'pointer' should not be less than '32'.
  /// 'logPrice' should be non-negative and less than '2 ** 64'.
  /// 'sqrtPrice' should be non-negative and less than 'oneX216'.
  /// 'sqrtInversePrice' should be non-negative and less than 'oneX216'.
  function storePrice(
    uint256 pointer,
    X59 logPrice,
    X216 sqrtPrice,
    X216 sqrtInversePrice
  ) internal pure {
    assembly {
      // The preceding slot is cached so that it can be restored after we place
      // all values in their appropriate memory locations.
      // The subtraction is safe because of the input requirement on 'pointer'.
      let precedingPointer := sub(pointer, 32)
      let precedingSlot := mload(precedingPointer)

      // We move '64 + 216 + 216' bits forward to reach the following location:
      //
      //                                                          pointer + 62
      //                                                                  \
      //                                                                   |
      //  +--------+---------------------------+---------------------------+
      //  | 8 byte |          27 byte          |          27 byte          |
      //  +--------+---------------------------+---------------------------+
      //  |        |                           |
      //  |        |                            \
      //  |        |                             sqrtInversePrice
      //  |         \
      //  |          sqrtPrice
      //   \
      //    logPrice
      //
      // Then we move '256' bits backward to point to the beginning of the slot
      // whose least significant '216' bits are supposed to host
      // 'sqrtInversePrice'.
      //
      // '64 + 216 + 216 - 256' bits == '30' bytes.
      mstore(add(pointer, 30), sqrtInversePrice)

      // We move '64 + 216' bits forward to reach the following location:
      //
      //                                  pointer + 35
      //                                       |
      //  +--------+---------------------------+---------------------------+
      //  | 8 byte |          27 byte          |          27 byte          |
      //  +--------+---------------------------+---------------------------+
      //  |        |                           |
      //  |        |                            \
      //  |        |                             sqrtInversePrice
      //  |         \
      //  |          sqrtPrice
      //   \
      //    logPrice
      //
      // Then we move '256' bits backward to point to the beginning of the slot
      // whose least significant '216' bits are supposed to host 'sqrtPrice'.
      //
      // '64 + 216 - 256' bits == '3' bytes.
      mstore(add(pointer, 3), sqrtPrice)

      // We move '64' bits forward to reach the following location:
      //
      //      pointer + 8
      //           |
      //  +--------+---------------------------+---------------------------+
      //  | 8 byte |          27 byte          |          27 byte          |
      //  +--------+---------------------------+---------------------------+
      //  |        |                           |
      //  |        |                            \
      //  |        |                             sqrtInversePrice
      //  |         \
      //  |          sqrtPrice
      //   \
      //    logPrice
      //
      // Then we move '256' bits backward to point to the beginning of the slot
      // whose least significant '64' bits are supposed to host 'logPrice'.
      //
      // '64 - 256' bits == '-24' bytes.
      //
      // The subtraction is safe because of the input requirement on 'pointer'.
      mstore(sub(pointer, 24), logPrice)

      // The preceding slot is restored.
      mstore(precedingPointer, precedingSlot)
    }
  }

  /// @notice Calculates the sqrt and sqrtInverse of a given logPrice and
  /// stores everything in the given memory location with the following
  /// layout:
  ///
  ///  pointer
  ///     |
  ///     +--------+---------------------------+---------------------------+
  ///     | 8 byte |          27 byte          |          27 byte          |
  ///     +--------+---------------------------+---------------------------+
  ///     |        |                           |
  ///     |        |                            \
  ///     |        |                             sqrtInversePrice
  ///     |         \
  ///     |          sqrtPrice
  ///      \
  ///       logPrice
  ///
  /// 'pointer' should not be less than '32' and 'pointer + 30' should not
  /// overflow.
  ///
  /// 'logPrice' should be greater than 0 and less than (2 ** 64).
  function storePrice(
    uint256 pointer,
    X59 logPrice
  ) internal pure {
    // The requirements of 'exp' are satisfied here because 
    // '0 < logPrice < 2 ** 64'.
    (X216 sqrtPrice, X216 sqrtInversePrice) = logPrice.exp();

    // The requirements of 'storePrice' are satisfied here, because of the
    // input requirement on 'pointer' and because both outputs of 'exp' are
    // less than 'oneX216':
    //
    // '0 < logPrice' -> '(2 ** 216) * exp(- logPrice / (2 ** 60)) < 2 ** 216'
    //
    // 'logPrice < 2 ** 64' -> 
    // '(2 ** 216) * exp(- 16 + logPrice / (2 ** 60)) < 2 ** 216'
    //
    pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
  }

  /// @notice Stores a given price in a given memory location with the
  /// following layout:
  ///
  ///   pointer
  ///      |
  ///   +--+--------+---------------------------+---------------------------+
  ///   |  | 8 byte |          27 byte          |          27 byte          |
  ///   +--+--------+---------------------------+---------------------------+
  ///   |  |        |                           |
  ///   |  |        |                            \
  ///   |  |        |                             sqrtInversePrice
  ///   |  |         \
  ///   |  |          sqrtPrice
  ///   |   \
  ///   |    logPrice
  ///    \
  ///     heightPrice
  ///
  /// 'pointer' should not be less than '34'.
  /// 'heightPrice' should be less than or equal to 'oneX15'.
  /// 'logPrice' should be non-negative and less than (2 ** 64).
  /// 'sqrtPrice' should be non-negative and less than 'oneX216'.
  /// 'sqrtInversePrice' should be non-negative and less than 'oneX216'.
  function storePrice(
    uint256 pointer,
    X15 heightPrice,
    X59 logPrice,
    X216 sqrtPrice,
    X216 sqrtInversePrice
  ) internal pure {
    assembly {
      // The preceding slot is cached so that it can be restored after we place
      // all values in their appropriate memory location.
      // The subtraction is safe because of the input requirement on 'pointer'.
      let precedingPointer := sub(pointer, 34)
      let precedingSlot := mload(precedingPointer)

      // We move '64 + 216 + 216' bits forward to reach the following location:
      //
      //                                                          pointer + 62
      //                                                                     \
      //                                                                      |
      //  +--+--------+---------------------------+---------------------------+
      //  |  | 8 byte |          27 byte          |          27 byte          |
      //  +--+--------+---------------------------+---------------------------+
      //  |  |        |                           |
      //  |  |        |                            \
      //  |  |        |                             sqrtInversePrice
      //  |  |         \
      //  |  |          sqrtPrice
      //  |   \
      //  |    logPrice
      //   \
      //    heightPrice
      //
      // Then we move '256' bits backward to point to the beginning of the slot
      // whose least significant '216' bits are supposed to host
      // 'sqrtInversePrice'.
      //
      // '64 + 216 + 216 - 256' bits == '30' bytes.
      mstore(add(pointer, 30), sqrtInversePrice)

      // We move '64 + 216' bits forward to reach the following location:
      //
      //                                  pointer + 35
      //                                         \
      //                                          |
      //  +--+--------+---------------------------+---------------------------+
      //  |  | 8 byte |          27 byte          |          27 byte          |
      //  +--+--------+---------------------------+---------------------------+
      //  |  |        |                           |
      //  |  |        |                            \
      //  |  |        |                             sqrtInversePrice
      //  |  |         \
      //  |  |          sqrtPrice
      //  |   \
      //  |    logPrice
      //   \
      //    heightPrice
      //
      // Then we move '256' bits backward to point to the beginning of the slot
      // whose least significant '216' bits are supposed to host 'sqrtPrice'.
      //
      // '64 + 216 - 256' bits == '3' bytes.
      mstore(add(pointer, 3), sqrtPrice)

      // We move '64' bits forward to reach the following location:
      //
      //      pointer + 8
      //             \
      //              |
      //  +--+--------+---------------------------+---------------------------+
      //  |  | 8 byte |          27 byte          |          27 byte          |
      //  +--+--------+---------------------------+---------------------------+
      //  |  |        |                           |
      //  |  |        |                            \
      //  |  |        |                             sqrtInversePrice
      //  |  |         \
      //  |  |          sqrtPrice
      //  |   \
      //  |    logPrice
      //   \
      //    heightPrice
      //
      // Then we move '256' bits backward to point to the beginning of the slot
      // whose least significant '64' bits are supposed to host 'logPrice'.
      //
      // '64 - 256' bits == '-24' bytes.
      // The subtraction is safe because of the input requirement on 'pointer'.
      mstore(sub(pointer, 24), logPrice)

      // We move '256' bits backward to point to the beginning of the slot
      // whose least significant '16' bits are supposed to host 'heightPrice'.
      //
      // '0 - 256' bits == '-32' bytes.
      // The subtraction is safe because of the input requirement on 'pointer'.
      mstore(sub(pointer, 32), heightPrice)

      // The preceding slot is restored.
      mstore(precedingPointer, precedingSlot)
    }
  }

  /// @notice Returns the height of a price given its memory pointer with the 
  /// following layout:
  ///
  ///       pointer
  ///      /
  ///     |
  ///  +--+--------+---------------------------+---------------------------+
  ///  |  | 8 byte |          27 byte          |          27 byte          |
  ///  +--+--------+---------------------------+---------------------------+
  ///  |  |        |                           |
  ///  |  |        |                            \
  ///  |  |        |                             sqrtInversePrice
  ///  |  |         \
  ///  |  |          sqrtPrice
  ///  |   \
  ///  |    logPrice
  ///   \
  ///    heightPrice
  ///
  function height(
    uint256 pointer
  ) internal pure returns (
    X15 value
  ) {
    assembly {
      // We move '2' bytes backward to read the slot whose most significant
      // '16' bits host 'height'.
      //
      //    pointer - 2
      //   /
      //  |
      //  +--+--------+---------------------------+---------------------------+
      //  |  | 8 byte |          27 byte          |          27 byte          |
      //  +--+--------+---------------------------+---------------------------+
      //  |  |        |                           |
      //  |  |        |                            \
      //  |  |        |                             sqrtInversePrice
      //  |  |         \
      //  |  |          sqrtPrice
      //  |   \
      //  |    logPrice
      //   \
      //    heightPrice
      //
      // Then we shift the content by '240' bits to the right in order to get
      // 'height'.
      //
      // The subtraction is safe, because the pointer refer to a price with
      // height and therefore its value is not less than '2'.
      value := shr(240, mload(sub(pointer, 2)))
    }
  }

  /// @notice Returns the logarithm of a price given its memory pointer with
  /// the following layout:
  ///
  ///       pointer
  ///      /
  ///     |
  ///  +--+--------+---------------------------+---------------------------+
  ///  |  | 8 byte |          27 byte          |          27 byte          |
  ///  +--+--------+---------------------------+---------------------------+
  ///  |  |        |                           |
  ///  |  |        |                            \
  ///  |  |        |                             sqrtInversePrice
  ///  |  |         \
  ///  |  |          sqrtPrice
  ///  |   \
  ///  |    logPrice
  ///   \
  ///    heightPrice
  ///
  function log(
    uint256 pointer
  ) internal pure returns (
    X59 logPrice
  ) {
    assembly {
      // The given pointer refers to the slot whose most significant '64' bits
      // host 'logPrice'. We read this slot and then we shift the content by
      // '192' bits to the right in order to get 'logPrice'.
      logPrice := shr(192, mload(pointer))
    }
  }

  /// @notice Returns the 'sqrtPrice' or 'sqrtInversePrice' given a memory 
  /// pointer with the following layout:
  ///
  ///       pointer
  ///      /
  ///     |
  ///  +--+--------+---------------------------+---------------------------+
  ///  |  | 8 byte |          27 byte          |          27 byte          |
  ///  +--+--------+---------------------------+---------------------------+
  ///  |  |        |                           |
  ///  |  |        |                            \
  ///  |  |        |                             sqrtInversePrice
  ///  |  |         \
  ///  |  |          sqrtPrice
  ///  |   \
  ///  |    logPrice
  ///   \
  ///    heightPrice
  ///
  function sqrt(
    uint256 pointer,
    bool inverse
  ) internal pure returns (
    X216 value
  ) {
    assembly {
      // If 'inverse == true' then we move '35' bytes forward to read the slot
      // whose most significant '216' bits host 'sqrtPriceInverse'.
      //
      //                                  pointer + 35
      //                                         \
      //                                          |
      //  +--+--------+---------------------------+---------------------------+
      //  |  | 8 byte |          27 byte          |          27 byte          |
      //  +--+--------+---------------------------+---------------------------+
      //  |  |        |                           |
      //  |  |        |                            \
      //  |  |        |                             sqrtInversePrice
      //  |  |         \
      //  |  |          sqrtPrice
      //  |   \
      //  |    logPrice
      //   \
      //    heightPrice
      //
      // Then we shift the content by '40' bits to the right in order to get
      // 'sqrtPriceInverse'.
      //
      // If 'inverse == false' then we move '8' bytes forward to read the slot
      // whose most significant '216' bits host 'sqrtPrice'.
      //
      //      pointer + 8
      //             \
      //              |
      //  +--+--------+---------------------------+---------------------------+
      //  |  | 8 byte |          27 byte          |          27 byte          |
      //  +--+--------+---------------------------+---------------------------+
      //  |  |        |                           |
      //  |  |        |                            \
      //  |  |        |                             sqrtInversePrice
      //  |  |         \
      //  |  |          sqrtPrice
      //  |   \
      //  |    logPrice
      //   \
      //    heightPrice
      //
      // Then we shift the content by '40' bits to the right in order to get
      // 'sqrtPrice'.
      //
      // The additions and the multiplication are safe because 
      // 'iszero(inverse)' is a boolean.
      value := shr(
        40,
        mload(
          add(
            sub(35, mul(27, iszero(inverse))), // inverse ? 35 : 8
            pointer
          )
        )
      )
    }
  }

  /// @notice Copies a price from one memory pointer to another each with the 
  /// following layout:
  ///
  ///  pointer
  ///     |
  ///     +--------+---------------------------+---------------------------+
  ///     | 8 byte |          27 byte          |          27 byte          |
  ///     +--------+---------------------------+---------------------------+
  ///     |        |                           |
  ///     |        |                            \
  ///     |        |                             sqrtInversePrice
  ///     |         \
  ///     |          sqrtPrice
  ///      \
  ///       logPrice
  ///
  function copyPrice(
    uint256 pointer0,
    uint256 pointer1
  ) internal pure {
    assembly {
      // Each price contains '62' bytes which is copied from one place to the
      // next.
      mcopy(pointer0, pointer1, 62)
    }
  }

  /// @notice Copies a price with height from one memory pointer to another
  /// each with the following layout:
  ///
  ///       pointer
  ///      /
  ///     |
  ///  +--+--------+---------------------------+---------------------------+
  ///  |  | 8 byte |          27 byte          |          27 byte          |
  ///  +--+--------+---------------------------+---------------------------+
  ///  |  |        |                           |
  ///  |  |        |                            \
  ///  |  |        |                             sqrtInversePrice
  ///  |  |         \
  ///  |  |          sqrtPrice
  ///  |   \
  ///  |    logPrice
  ///   \
  ///    heightPrice
  ///
  function copyPriceWithHeight(
    uint256 pointer0,
    uint256 pointer1
  ) internal pure {
    assembly {
      // Each price contains '64' bytes which is copied from one place to the
      // next. We move two bytes backward to point to the beginning of 'height'
      // as opposed to the end of 'height':
      //
      //    pointer
      //   /
      //  |
      //  +--+--------+---------------------------+---------------------------+
      //  |  | 8 byte |          27 byte          |          27 byte          |
      //  +--+--------+---------------------------+---------------------------+
      //  |  |        |                           |
      //  |  |        |                            \
      //  |  |        |                             sqrtInversePrice
      //  |  |         \
      //  |  |          sqrtPrice
      //  |   \
      //  |    logPrice
      //   \
      //    heightPrice
      //
      // The subtractions are safe, because both pointers refer to prices with
      // height and therefore their values are not less than '2'.
      mcopy(sub(pointer0, 2), sub(pointer1, 2), 64)
    }
  }

  /// @notice Given the memory pointer for a pair of prices with height, this
  /// function reads the corresponding horizontal and vertical coordinates.
  /// 'pointer' refers to the first price and 'pointer + 64' refers to the
  /// second one.
  function segment(
    uint256 pointer
  ) internal pure returns (
    X59 b0,
    X59 b1,
    X15 c0,
    X15 c1
  ) {
    c0 = pointer.height();
    b0 = pointer.log();

    // We move '64' bytes forward to point to the second price.
    unchecked {
      pointer += 64;
    }

    c1 = pointer.height();
    b1 = pointer.log();
  }
}