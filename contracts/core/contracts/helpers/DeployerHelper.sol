// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {Deployer} from "@governance/Deployer.sol";

contract DeployerHelper is Deployer {
  constructor(address admin) Deployer(admin) {}
}