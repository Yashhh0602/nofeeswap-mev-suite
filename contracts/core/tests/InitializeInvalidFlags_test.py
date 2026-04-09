# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, DeployerHelper
from Nofee import logTest, encode, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, getPoolId

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

def test_invalidFlags(deployment, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, nofeeswap, delegatee, access, hook = deployment

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**120, owner, {'from': owner})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**120, owner, {'from': owner})

    kernel = [
      [0, 0],
      [2 ** 40, 2 ** 15]
    ]
    curve = [2 ** 40 + 1, 2 ** 40 + 1 + 2 ** 40]

    unsaltedPoolId = (twosComplementInt8(-5) << 180) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )

    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000010000000000000 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )

    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000001000000000000 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )

    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000100000000000 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )

    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000000000000100 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )

    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00010000000000000000 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00001000000000000000 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000100000000000000 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00010000000000000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00001000000000000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000100000000000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000010000000000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000001000000000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000100000000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000010000000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000001000000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000000100000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000000010000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000000001000000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000000000100000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId  = (twosComplementInt8(-5) << 180) + (0b00000000000000010000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000000000001000 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000000000000100 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000000000000010 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts('InvalidFlags: ' + str(poolId)):
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180) + (0b00000000000000000001 << 160)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    with brownie.reverts():
        tx = nofeeswap.dispatch(
          delegatee.initialize.encode_input(
              unsaltedPoolId,
              min(toInt(token0.address), toInt(token1.address)),
              max(toInt(token0.address), toInt(token1.address)),
              0x800000000000,
              encodeKernelCompact(kernel),
              encodeCurve(curve),
              b""
          ),
          {'from': owner}
        )
    
    unsaltedPoolId = (twosComplementInt8(-5) << 180)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
          unsaltedPoolId,
          min(toInt(token0.address), toInt(token1.address)),
          max(toInt(token0.address), toInt(token1.address)),
          0x800000000000,
          encodeKernelCompact(kernel),
          encodeCurve(curve),
          b""
      ),
      {'from': owner}
    )