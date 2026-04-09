# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, DeployerHelper
from eth_abi import encode
from Nofee import logTest

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    root = accounts[0]
    owner = accounts[1]
    deployer = DeployerHelper.deploy(root, {'from': root})
    delegatee = deployer.addressOf(1)
    nofeeswap = deployer.addressOf(2)
    deployer.create3(
        1,
        NofeeswapDelegatee.bytecode + encode(
            ['address'],
            [nofeeswap]
        ).hex(), 
        {'from': root}
    )
    deployer.create3(
        2,
        Nofeeswap.bytecode + encode(
            ['address', 'address'],
            [delegatee, root.address]
        ).hex(), 
        {'from': root}
    )
    delegatee = NofeeswapDelegatee.at(delegatee)
    nofeeswap = Nofeeswap.at(nofeeswap)
    access = Access.deploy({'from': root})

    return root, owner, nofeeswap, delegatee, access

def test_modifyProtocol(deployment, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, nofeeswap, delegatee, access = deployment

    maxPoolGrowthPortionDefault = 0x700000000000
    protocolGrowthPortionDefault = 0x35000000000

    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (maxPoolGrowthPortionDefault << 208) + (protocolGrowthPortionDefault << 160) + int(owner.address, 16)
    ), {'from': root})

    assert access._readProtocol(nofeeswap) == (maxPoolGrowthPortionDefault << 208) + (protocolGrowthPortionDefault << 160) + int(owner.address, 16)

    with brownie.reverts('InvalidGrowthPortion: ' + str((1 << 47) + 1)):
        nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
            (((1 << 47) + 1) << 208) + (protocolGrowthPortionDefault << 160) + int(root.address, 16)
        ), {'from': owner})

    with brownie.reverts('InvalidGrowthPortion: ' + str((1 << 47) + 2)):
        nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
            (maxPoolGrowthPortionDefault << 208) + (((1 << 47) + 2) << 160) + int(root.address, 16)
        ), {'from': owner})

    with brownie.reverts('OnlyByProtocol: ' + root.address.lower() + ', ' + owner.address.lower()):
        nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
            (maxPoolGrowthPortionDefault << 208) + (protocolGrowthPortionDefault << 160) + int(root.address, 16)
        ), {'from': root})

