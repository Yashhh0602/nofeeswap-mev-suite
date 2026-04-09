# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, DeployerHelper
from Nofee import logTest, encode, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve

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

    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (123 << 208) + (456 << 160) + int(root.address, 16)
    ), {'from': root})

    return root, owner, other, nofeeswap, delegatee, access, hook

def test_invalidOffset(deployment, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, nofeeswap, delegatee, access, hook = deployment

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**120, owner, {'from': owner})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**120, owner, {'from': owner})

    kernel = [
      [0, 0],
      [2 ** 40, 2 ** 15]
    ]
    curve = [2 ** 40 + 1, 2 ** 40 + 1 + 2 ** 40]

    # initialization
    unsaltedPoolId = (twosComplementInt8(-90) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    with brownie.reverts('LogOffsetOutOfRange: ' + str((-90) * (1 << 59))):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(+90) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    with brownie.reverts('LogOffsetOutOfRange: ' + str((+90) * (1 << 59))):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-89) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
          unsaltedPoolId,
          min(toInt(token0.address), toInt(token1.address)),
          max(toInt(token0.address), toInt(token1.address)),
          0,
          encodeKernelCompact(kernel),
          encodeCurve(curve),
          b""
      ),
      {'from': owner}
    )

    unsaltedPoolId = (1 << 188) + (twosComplementInt8(+89) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
          unsaltedPoolId,
          min(toInt(token0.address), toInt(token1.address)),
          max(toInt(token0.address), toInt(token1.address)),
          0,
          encodeKernelCompact(kernel),
          encodeCurve(curve),
          b""
      ),
      {'from': owner}
    )