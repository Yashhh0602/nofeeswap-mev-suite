# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, DeployerHelper
from Nofee import logTest, encode, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, dataGeneration

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    root = accounts[0]
    owner = accounts[1]
    other = accounts[2]
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
    hook = MockHook.deploy({'from': root})

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**120, owner, {'from': owner})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**120, owner, {'from': owner})

    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (123 << 208) + (456 << 160) + int(root.address, 16)
    ), {'from': root})

    return root, owner, other, nofeeswap, delegatee, access, hook, token0, token1

@pytest.mark.parametrize('n', range(len(kernelsInvalid)))
def test_invalidKernel(deployment, n, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, nofeeswap, delegatee, access, hook, token0, token1 = deployment

    kernel = kernelsInvalid[n]
    curve = [kernel[-1][0] + 1, kernel[-1][0] + 1 + kernel[-1][0]]

    if kernel[-1][0] + 1 + kernel[-1][0] <= 2 ** 64 - 1:
        with brownie.reverts():
            tx = nofeeswap.dispatch(
              delegatee.initialize.encode_input(
                  (twosComplementInt8(-5) << 180),
                  min(toInt(token0.address), toInt(token1.address)),
                  max(toInt(token0.address), toInt(token1.address)),
                  0x800000000000,
                  encodeKernelCompact(kernel),
                  encodeCurve(curve),
                  b""
              ),
              {'from': owner}
            )