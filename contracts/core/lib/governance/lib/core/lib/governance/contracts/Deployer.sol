// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {CREATE3} from "@solady/utils/CREATE3.sol";

contract Deployer {
  address public immutable admin;

  constructor(address _admin) {
    admin = _admin;
  }

  function create3(
    bytes32 _salt,
    bytes memory _creationCode
  ) public returns (address addr) {
    require(msg.sender == admin);
    return CREATE3.deployDeterministic(_creationCode, _salt);
  }

  function create3(
    bytes32 _salt,
    bytes memory _creationCode,
    uint256 _value
  ) public returns (address addr) {
    require(msg.sender == admin);
    return CREATE3.deployDeterministic(_value, _creationCode, _salt);
  }

  function addressOf(
    bytes32 _salt
  ) public view returns (address) {
    return CREATE3.predictDeterministicAddress(_salt);
  }
}