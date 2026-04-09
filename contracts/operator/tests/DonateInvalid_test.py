# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, Operator, Deployer
from eth_abi import encode
from eth_abi.packed import encode_packed
from Nofee import logTest, PUSH32, REVERT, DONATE, address0, mintSequence, donateSequence, keccak, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, getPoolId

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    root = accounts[0]
    owner = accounts[1]
    other = accounts[2]
    deployer = Deployer.deploy(root, {'from': root})
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
    operator = Operator.deploy(nofeeswap, address0, address0, address0, {'from': root})

    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (123 << 208) + (456 << 160) + int(root.address, 16)
    ), {'from': root})

    return root, owner, other, nofeeswap, delegatee, access, hook, operator

def test_invalid(deployment, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, nofeeswap, delegatee, access, hook, operator = deployment

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**120, root, {'from': root})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**120, root, {'from': root})
    token0.approve(operator, 2**120, {'from': root})
    token1.approve(operator, 2**120, {'from': root})
    nofeeswap.setOperator(operator, True, {'from': root})
    if toInt(token0.address) > toInt(token1.address):
        token0, token1 = token1, token0
    tag0 = toInt(token0.address)
    tag1 = toInt(token1.address)

    logOffset = -5
    kernel = [
      [0, 0],
      [2 ** 40, 2 ** 15]
    ]
    lower = 2 ** 40 + 1
    upper = 2 ** 40 + 1 + 2 ** 40
    spacing = upper - lower
    curve = [lower, upper, (lower + upper) // 2]

    # initialization
    unsaltedPoolId = (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    deadline = 2 ** 32 - 1

    qMin = lower - (1 << 63) + (logOffset * (1 << 59))
    qMax = upper - (1 << 63) + (logOffset * (1 << 59))
    shares = 1000000
    hookData = b"HookData"

    sharesSlot = 1

    successSlot = 2

    amount0Slot = 3
    amount1Slot = 4

    sequence = [0] * 3
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, shares, sharesSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [DONATE, poolId, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    sequence[2] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('PoolDoesNotExist: ' + str(poolId)):
        tx = nofeeswap.unlock(operator, data, {'from': root})
    
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
        unsaltedPoolId,
        tag0,
        tag1,
        0,
        encodeKernelCompact(kernel),
        encodeCurve(curve),
        b""
      ),
      {'from': owner}
    )

    with brownie.reverts('CannotDonateToEmptyInterval: '):
        tx = nofeeswap.unlock(operator, data, {'from': root})

    tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

    data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline)
    amount0 = token0.balanceOf(owner)
    amount1 = token1.balanceOf(owner)
    tx = nofeeswap.unlock(operator, data, {'from': root})
    amount0 -= token0.balanceOf(owner)
    amount1 -= token1.balanceOf(owner)

    sequence = [0] * 3
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, 0, sharesSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [DONATE, poolId, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    sequence[2] = encode_packed(
      ['uint8'],
      [REVERT]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('InvalidNumberOfShares: 0'):
        tx = nofeeswap.unlock(operator, data, {'from': root})

    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, 1 << 127, sharesSlot]
    )

    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('InvalidNumberOfShares: ' + str(1 << 127)):
        tx = nofeeswap.unlock(operator, data, {'from': root})

    data = donateSequence(nofeeswap, token0, token1, poolId, shares, hookData, deadline)
    _amount0 = token0.balanceOf(owner)
    _amount1 = token1.balanceOf(owner)
    tx = nofeeswap.unlock(operator, data, {'from': root})
    assert _amount0 == token0.balanceOf(owner) + amount0
    assert _amount1 == token1.balanceOf(owner) + amount1