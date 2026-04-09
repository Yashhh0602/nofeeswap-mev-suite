// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {Access} from "@core/helpers/Access.sol";
import {Nofeeswap} from "@core/Nofeeswap.sol";
import {NofeeswapDelegatee} from "@core/NofeeswapDelegatee.sol";
import {MockHook} from "@core/helpers/MockHook.sol";
import {ERC20FixedSupply} from "@core/helpers/ERC20FixedSupply.sol";

contract AccessHelper is Access {}
contract NofeeswapHelper is Nofeeswap {
  constructor(
    address delegatee,
    address admin
  ) Nofeeswap(delegatee, admin) {}
}
contract NofeeswapDelegateeHelper is NofeeswapDelegatee {
  constructor(address nofeeswap) NofeeswapDelegatee(nofeeswap) {}
}
contract MockHookHelper is MockHook {}
contract ERC20FixedSupplyHelper is ERC20FixedSupply {
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply,
    address owner
  ) ERC20FixedSupply(name, symbol, initialSupply, owner) {}
}