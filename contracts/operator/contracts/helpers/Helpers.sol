// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {Access} from "@core/helpers/Access.sol";
import {Nofeeswap} from "@core/Nofeeswap.sol";
import {NofeeswapDelegatee} from "@core/NofeeswapDelegatee.sol";
import {MockHook} from "@core/helpers/MockHook.sol";
import {ERC20FixedSupply} from "@core/helpers/ERC20FixedSupply.sol";
import {ERC6909FixedSupply} from "@core/helpers/ERC6909FixedSupply.sol";
import {ERC1155FixedSupply} from "@core/helpers/ERC1155FixedSupply.sol";
import {Deployer} from "@governance/Deployer.sol";

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
contract ERC6909FixedSupplyHelper is ERC6909FixedSupply {
  constructor(
    uint256 initialSupply,
    uint256 id,
    address owner
  ) ERC6909FixedSupply(initialSupply, id, owner) {}
}
contract ERC1155FixedSupplyHelper is ERC1155FixedSupply {
  constructor(
    string memory uri,
    uint256 initialSupply,
    uint256 id,
    address owner
  ) ERC1155FixedSupply(uri, initialSupply, id, owner) {}
}
contract DeployerHelper is Deployer {
  constructor(address admin) Deployer(admin) {}
}