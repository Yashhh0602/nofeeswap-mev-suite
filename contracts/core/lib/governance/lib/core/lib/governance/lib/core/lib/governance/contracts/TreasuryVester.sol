// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {INofee} from "./interfaces/INofee.sol";

// Treasury Vester
// Credit to dYdX Foundation under MIT license:
//
// https://github.com/dydxfoundation/governance-contracts/blob/
// 804a6e41f96f8b67daeff1d681b4c1c66ceb2547/contracts/treasury/
// TreasuryVester.sol
//
// This contract vests a 'vestingAmount' of nofee starting at 'vestingCliff'.
// After 'vestingEnd', the entire amount can be claimed by the
// 'recipient' through any account. At any time
// 'vestingCliff <= t <= vestingEnd', up to a total of:
//
//                       t - vestingBegin
//  vestingAmount x ---------------------------
//                   vestingEnd - vestingBegin
//
// nofee can be claimed by 'recipient' through any account.

/// @notice Emitted when a new recipient is set.
/// @param oldRecipient The previous recipient.
/// @param newRecipient The new recipient.
event NewRecipient(
  address indexed oldRecipient,
  address indexed newRecipient
);

/// @notice Emitted upon deployment of this contract.
/// @param nofee Token address to be vested.
/// @param recipient The recipient of the vested tokens.
/// @param vestingAmount The total vesting amount.
/// @param vestingBegin The beginning time of the vesting period.
/// @param vestingCliff The cliff time after which tokens can be claimed.
/// @param vestingEnd The end time of the vesting period after which the
/// entirety of the vested amount can be claimed. 
event Vested(
  INofee indexed nofee,
  address indexed recipient,
  uint256 vestingAmount,
  uint256 vestingBegin,
  uint256 vestingCliff,
  uint256 vestingEnd
);

/// @notice Emitted when any portion of the vesting amount is claimed.
/// @param caller The caller of the claim method.
/// @param recipient The recipient of the amount claimed.
/// @param amount The amount claimed.
event Claimed(
  address indexed caller,
  address indexed recipient,
  uint256 amount
);

/// @notice Thrown if the deployment block time is ahead of the vesting begin
/// time.
error VestingBeginTooEarly(uint256 vestingBegin, uint256 currentTime);

/// @notice Thrown if the vesting begin time is ahead of the vesting cliff
/// time.
error VestingCliffBeforeBegin(uint256 vestingCliff, uint256 vestingBegin);

/// @notice Thrown if the vesting end time is not ahead of the vesting cliff.
error VestingEndBeforeCliff(uint256 vestingEnd, uint256 vestingCliff);

/// @notice Thrown when any account other than the recipient attempts to change
/// the recipient.
error OnlyByRecipient(address attemptingAddress, address recipient);

/// @notice Thrown when attempting to claim a payment before vestingCliff.
error TooEarly(uint256 currentBlockTimestamp, uint256 vestingCliff);

contract TreasuryVester {
  /// @notice Token address to be vested.
  INofee public immutable nofee;

  /// @notice The total vesting amount to be held by this contract and
  /// claimed by the recipient.
  uint256 public immutable vestingAmount;

  /// @notice The beginning time of the vesting period.
  uint256 public immutable vestingBegin;

  /// @notice The cliff time after which tokens can be claimed.
  uint256 public immutable vestingCliff;

  /// @notice The end time after which the entire vesting amount can be
  /// claimed.
  uint256 public immutable vestingEnd;

  /// @notice The recipient of the vested tokens.
  address public recipient;

  /// @notice The last time a claim was made.
  uint256 public lastUpdate;

  constructor(
    INofee nofee_,
    address recipient_,
    uint256 vestingAmount_,
    uint256 vestingBegin_,
    uint256 vestingCliff_,
    uint256 vestingEnd_
  ) {
    // The vesting period must begin in the future.
    require(
      vestingBegin_ >= block.timestamp,
      VestingBeginTooEarly(vestingBegin_, block.timestamp)
    );

    // The vesting cliff should be greater than or equal to the beginning of
    // the vesting period.
    require(
      vestingCliff_ >= vestingBegin_,
      VestingCliffBeforeBegin(vestingCliff_, vestingBegin_)
    );

    // The vesting cliff should be less than the end of the vesting period.
    require(
      vestingEnd_ > vestingCliff_,
      VestingEndBeforeCliff(vestingEnd_, vestingCliff_)
    );

    // Immutable parameters are set.
    nofee = nofee_;
    vestingAmount = vestingAmount_;
    vestingBegin = vestingBegin_;
    vestingCliff = vestingCliff_;
    vestingEnd = vestingEnd_;

    // The 'recipient' and 'lastUpdate' variables are set in storage.
    recipient = recipient_;
    lastUpdate = vestingBegin_;

    // An event is emitted for the vesting period.
    emit Vested(
      nofee_,
      recipient_,
      vestingAmount_,
      vestingBegin_,
      vestingCliff_,
      vestingEnd_
    );
  }

  /// @notice Sets a new recipient for this contract.
  /// @param newRecipient The new recipient.
  function setRecipient(address newRecipient) public {
    // The current recipient is read from storage.
    address currentRecipient = recipient;

    // Only the current recipient is permitted to run this function.
    require(
      msg.sender == currentRecipient,
      OnlyByRecipient(msg.sender, currentRecipient)
    );

    // The new recipient is set in storage.
    recipient = newRecipient;

    // An event is emitted to announce the new recipient.
    emit NewRecipient(currentRecipient, newRecipient);
  }

  /// @notice Any address can call this function no earlier than the vesting
  /// cliff to transfer
  ///
  ///                   block.timestamp - lastUpdate
  ///  vestingAmount x ------------------------------
  ///                     vestingEnd - vestingBegin
  ///
  /// tokens to the recipient.
  function claim() public {
    // The current block time should be at or after the vesting cliff.
    require(
      block.timestamp >= vestingCliff,
      TooEarly(block.timestamp, vestingCliff)
    );

    // The amount to be transferred.
    uint256 amount;

    if (block.timestamp >= vestingEnd) {
      // If we are past the vesting end, the entire balance of this account
      // should be transferred.
      amount = nofee.balanceOf(address(this));
    } else {
      // The amount to be transferred is proportional to the time passed since
      // 'lastUpdate'.
      amount = (
        vestingAmount * (block.timestamp - lastUpdate)
      ) / (vestingEnd - vestingBegin);

      // 'lastUpdated' is modified in storage.
      lastUpdate = block.timestamp;
    }

    // The amount is transferred to the recipient.
    nofee.transfer(recipient, amount);

    // An event is emitted to announce the claimed amount.
    emit Claimed(msg.sender, recipient, amount);
  }
}
