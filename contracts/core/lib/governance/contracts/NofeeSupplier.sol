// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {INofee} from "./interfaces/INofee.sol";

/// @title At the time of deployment, a sequence of 
///
///   - recipients,
///   - amounts, and 
///   - block numbers 
///
/// are provided as input to constructor. This contract releases each payment
/// amount to its corresponding recipient after the given block number via the
/// 'ERC20' approval mechanism. This contract is used to release 'nofee'
/// payments to nofeeswap incentive contracts.

/// @notice Thrown when attempting to release a payment before the specified
/// block number.
error TooEarly(uint32 currentBlockNumber, uint32 paymentBlockNumber);

/// @notice Thrown when any account other than the admin attempts to access a
/// function that is reserved for the admin.
error OnlyByAdmin(address attemptingAddress, address adminAddress);

/// @notice Thrown when attempting to collect or forfeit a payment that has
/// already been made or forfeited.
error PaymentReleasedOrForfeitedAlready(uint256 payment);

/// @notice Thrown when attempting to set a payment to 'address(0)'.
error InvalidRecipient(uint256 payment);

/// @notice Emitted by the constructor for each payment.
/// @param payment The payment index which starts from zero.
/// @param recipient The recipient of the payment.
/// @param amount The amount of the payment.
/// @param blockNumber The block number after which the payment can be
/// released.
event PaymentAdded(
  uint256 indexed payment,
  address indexed recipient,
  uint256 amount,
  uint32 blockNumber
);

/// @notice Emitted when a payment is released.
/// @param payment The payment index.
/// @param recipient The recipient of the payment.
/// @param amount The amount of the payment.
/// @param blockNumber The block number at which the payment is released.
event Released(
  uint256 indexed payment,
  address indexed recipient,
  uint256 amount,
  uint32 blockNumber
);

/// @notice Emitted when a payment is forfeited.
/// @param payment The payment index.
/// @param recipient The recipient of the payment.
/// @param amount The amount of the payment.
/// @param blockNumber The block number at which the payment was forfeited.
event Forfeited(
  uint256 indexed payment,
  address indexed recipient,
  uint256 amount,
  uint32 blockNumber
);

/// @notice Emitted when a new admin is set.
/// @param oldAdmin The previous admin.
/// @param newAdmin The new admin.
event NewAdmin(
  address indexed oldAdmin,
  address indexed newAdmin
);

contract NofeeSupplier {
  /// @notice Token address to be supplied.
  INofee public immutable nofee;

  /// @notice The address that can forfeit payments.
  address public admin;

  /// @notice An array of recipients for each payment.
  address[] public recipients;

  /// @notice An array of the amounts to be supplied for each payment.
  uint256[] public amounts;

  /// @notice An array of block numbers after which the corresponding payments
  /// can be released.
  uint32[] public blockNumbers;

  /// @param _admin The admin of this contract.
  /// @param _nofee The token address to be supplied to recipients.
  /// @param data The sequence of payments that are tightly encoded. Each
  /// payment takes 36 bytes, with
  ///
  ///   - the first (most significant) 20 bytes for the recipient,
  ///   - the next 12 bytes for the payment amount, and
  ///   - the last 4 bytes containing the block number.
  ///
  /// In other words,
  ///
  ///   'data = abi.encodePacked(
  ///       recipients[0],
  ///       uint96(amounts[0]),
  ///       blockNumbers[0],
  ///       recipients[1],
  ///       uint96(amounts[1]),
  ///       blockNumbers[1],
  ///       recipients[2],
  ///       uint96(amounts[2]),
  ///       blockNumbers[2],
  ///       ...
  ///   )'.
  constructor(
    address _admin,
    INofee _nofee,
    bytes memory data
  ) {
    // The admin is set.
    admin = _admin;

    // The token to be supplied is set.
    nofee = _nofee;

    // Each payment is '36 = 20 + 12 + 4' bytes.
    // '20' bytes for the recipient's address.
    // '12' bytes for the payment amount. Notice that the total supply of nofee
    // does not exceed 'type(uint96).max'.
    // '4' bytes for the block number.
    uint256 length = data.length / 36;

    // The initial value for the memory pointer that will exhaust every value
    // encoded in 'data'. '32' is added to skip the length slot.
    uint256 pointer;
    assembly {
      pointer := add(data, 32)
    }

    // The total amount of nofee to be transferred to this contract.
    // Incremented with each payment.
    uint256 total;

    // A for loop over all of the payments.
    for (uint256 payment = 0; payment < length; ++payment) {
      // The recipient address is loaded from memory. Because the recipient is
      // a 160-bit address and 'mload' loads 256 bits, we need to shift by
      // 96 bits to remove the extra 96 bits. Then, the pointer is incremented
      // by '20 == 160 / 8' bytes to point at the payment amount to be loaded
      // next. The recipient may not be 'address(0)' because 'address(0)' is
      // later used an indication that the payment is either released or
      // forfeited.
      address _recipient;
      assembly {
        _recipient := shr(96, mload(pointer))
        pointer := add(pointer, 20)
      }
      require(_recipient != address(0), InvalidRecipient(payment));
      recipients.push(_recipient);

      // The payment amount is loaded from memory. Because the amount is a 
      // 96-bit value and 'mload' loads 256 bits, we need to shift by
      // 160 bits to remove the extra 160 bits. Then, the pointer is 
      // incremented by '12 == 96 / 8' bytes to point at the block number to be
      // loaded next.
      uint256 _amount;
      assembly {
        _amount := shr(160, mload(pointer))
        pointer := add(pointer, 12)
      }
      amounts.push(_amount);

      // The block number is loaded from memory. Because the block number is a 
      // 32-bit value and 'mload' loads 256 bits, we need to shift by
      // 224 bits to remove the extra 224 bits. Then, the pointer is 
      // incremented by '4 == 32 / 8' bytes to point at the recipient address
      // to be loaded next.
      uint32 _blockNumber;
      assembly {
        _blockNumber := shr(224, mload(pointer))
        pointer := add(pointer, 4)
      }
      blockNumbers.push(_blockNumber);

      // The total amount of nofee to be transferred to 'address(this)'
      // is incremented with each payment.
      total += _amount;

      // An event is emitted with each payment.
      emit PaymentAdded(payment, _recipient, _amount, _blockNumber);
    }

    // The total amount of nofee is transferred to 'address(this)'.
    _nofee.transferFrom(_admin, address(this), total);
  }

  /// @notice Sets a new admin for this contract.
  /// @param newAdmin The new admin.
  function setAdmin(
    address newAdmin
  ) public {
    // The current admin is read from storage.
    address _admin = admin;

    // Only the current admin is permitted to run this function.
    require(msg.sender == _admin, OnlyByAdmin(msg.sender, _admin));

    // The new admin is set in storage.
    admin = newAdmin;

    // An event is emitted for the new admin.
    emit NewAdmin(_admin, newAdmin);
  }

  /// @notice Any address can call this function to give the recipients access
  /// to the pre-specified amounts after the pre-specified block number.
  /// @param payments The list of payments to be released.
  function release(uint256[] calldata payments) public {
    // Token to be supplied is read.
    INofee _nofee = nofee;

    // A for loop over all of the payments to be released.
    uint256 length = payments.length;
    for (uint256 k = 0; k < length; ++k) {
      // The payment number is loaded from calldata.
      uint256 payment = payments[k];

      // The corresponding recipient is read from storage.
      // 'address(0)' indicates that the payment has either been forfeited or
      // already released.
      // The storage value is then set to 0.
      address _recipient = recipients[payment];
      require(
        _recipient != address(0),
        PaymentReleasedOrForfeitedAlready(payment)
      );
      recipients[payment] = address(0);

      // The amount to be released is read from storage.
      // The storage value is then set to 0.
      uint256 _amount = amounts[payment];
      amounts[payment] = 0;

      // The corresponding block number is read from storage.
      // The storage value is then set to 0.
      uint32 _blockNumber = blockNumbers[payment];
      blockNumbers[payment] = 0;

      // The current block number is cached.
      uint32 currentBlockNumber = uint32(block.number);

      // The current block should be ahead of the block number corresponding to
      // the payment.
      require(
        currentBlockNumber > _blockNumber,
        TooEarly(currentBlockNumber, _blockNumber)
      );

      // The recipient's allowance is incremented based on the payment amount.
      _nofee.approve(
        _recipient,
        _amount + _nofee.allowance(address(this), _recipient)
      );

      // An event is emitted for the release of each payment.
      emit Released(payment, _recipient, _amount, currentBlockNumber);
    }
  }

  /// @notice Cancels the given list of payments.
  /// @param payments The list of payments to be forfeited.
  function forfeit(uint256[] calldata payments) public {
    // The current admin is read from storage.
    address _admin = admin;

    // Only the current admin is permitted to run this function.
    require(msg.sender == _admin, OnlyByAdmin(msg.sender, _admin));

    // The total amount of nofee to be transferred from this contract to admin.
    // Incremented with each forfeited payment.
    uint256 total;

    // A for loop over all of the payments.
    uint256 length = payments.length;
    for (uint256 k = 0; k < length; ++k) {
      // The payment number is loaded from calldata.
      uint256 payment = payments[k];

      // The corresponding recipient is read from storage.
      // 'address(0)' indicates that the payment has either been forfeited or
      // already released.
      // The storage value is then set to 0.
      address _recipient = recipients[payment];
      require(
        _recipient != address(0),
        PaymentReleasedOrForfeitedAlready(payment)
      );
      recipients[payment] = address(0);

      // The amount to be forfeited is read from storage.
      // The storage value is then set to 0.
      uint256 _amount = amounts[payment];
      amounts[payment] = 0;

      // The corresponding block number is set to 0.
      blockNumbers[payment] = 0;

      // The total amount of nofee to be transferred from
      // 'address(this)' to admin is incremented with each payment.
      total += _amount;

      // An event is emitted to announce the forfeiture of each payment.
      emit Forfeited(payment, _recipient, _amount, uint32(block.number));
    }

    // Lastly, the total amount is transferred to the admin.
    nofee.transfer(msg.sender, total);
  }
}