# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, Operator, Deployer
from eth_abi import encode
from eth_abi.packed import encode_packed
from Nofee import logTest, NEG, PUSH32, REVERT, TRANSFER_FROM_PAYER_ERC20, SYNC_TOKEN, SETTLE, MODIFY_SINGLE_BALANCE, MODIFY_POSITION, address0, thirtyTwoX59, keccak, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, getPoolId

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

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**120, owner, {'from': owner})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**120, owner, {'from': owner})
    token0.approve(operator, 2**256 - 1, {'from': owner})
    token1.approve(operator, 2**256 - 1, {'from': owner})
    nofeeswap.setOperator(operator, True, {'from': owner})
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

    sequence = [0] * 3
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
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    sequence[2] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('PoolDoesNotExist: ' + str(poolId)):
        nofeeswap.unlock(operator, data, {'from': owner})

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

    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, 0, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('LogPriceOutOfRange: ' + str(0 - (1 << 63) + (logOffset * (1 << 59)))):
        nofeeswap.unlock(operator, data, {'from': owner})

    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, 0, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('LogPriceOutOfRange: ' + str(0 - (1 << 63) + (logOffset * (1 << 59)))):
        nofeeswap.unlock(operator, data, {'from': owner})

    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower + 1, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('LogPriceMinIsNotSpaced: ' + str(lower + 1)):
        nofeeswap.unlock(operator, data, {'from': owner})

    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, upper + 1, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('LogPriceMaxIsNotSpaced: ' + str(upper + 1)):
        nofeeswap.unlock(operator, data, {'from': owner})

    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, 0, sharesSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('InvalidNumberOfShares: ' + str(0)):
        nofeeswap.unlock(operator, data, {'from': owner})

    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, 1 << 127, sharesSlot]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('InvalidNumberOfShares: ' + str(1 << 127)):
        nofeeswap.unlock(operator, data, {'from': owner})

    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, -(1 << 127), sharesSlot]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('InvalidNumberOfShares: ' + str(-(1 << 127))):
        nofeeswap.unlock(operator, data, {'from': owner})

    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, shares, sharesSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower % spacing, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('LogPriceMinIsInBlankArea: ' + str(lower % spacing)):
        nofeeswap.unlock(operator, data, {'from': owner})

    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, thirtyTwoX59 - ((thirtyTwoX59 - lower) % spacing), sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('LogPriceMaxIsInBlankArea: ' + str(thirtyTwoX59 - ((thirtyTwoX59 - lower) % spacing))):
        nofeeswap.unlock(operator, data, {'from': owner})

    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, upper, lower, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('LogPricesOutOfOrder: ' + str(upper) + ', ' + str(lower)):
        nofeeswap.unlock(operator, data, {'from': owner})

    sequence = [0] * 7
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, shares, sharesSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, sharesSlot, sharesSlot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    sequence[4] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, sharesSlot, sharesSlot]
    )
    sequence[5] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    sequence[6] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    with brownie.reverts('CannotMintAfterBurning: ' + str(poolId) + ', ' + str(lower) + ', '  + str(upper)):
        nofeeswap.unlock(operator, data, {'from': owner})

    tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

    successSlotTransfer0 = 7
    successSlotTransfer1 = 8

    valueSlotSettle0 = 9
    successSlotSettle0 = 10
    resultSlotSettle0 = 11

    valueSlotSettle1 = 12
    successSlotSettle1 = 13
    resultSlotSettle1 = 14

    sharesSuccessSlot = 15

    sequence = [0] * 9
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, shares, sharesSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    sequence[2] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token0.address]
    )
    sequence[3] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token0.address, amount0Slot, nofeeswap.address, successSlotTransfer0, 0]
    )
    sequence[4] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle0, successSlotSettle0, resultSlotSettle0]
    )
    sequence[5] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token1.address]
    )
    sequence[6] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token1.address, amount1Slot, nofeeswap.address, successSlotTransfer1, 0]
    )
    sequence[7] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle1, successSlotSettle1, resultSlotSettle1]
    )
    sequence[8] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8'],
      [MODIFY_SINGLE_BALANCE, tagShares, sharesSlot, sharesSuccessSlot]
    )
    data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
    _amount0 = token0.balanceOf(owner)
    _amount1 = token1.balanceOf(owner)
    tx = nofeeswap.unlock(operator, data, {'from': owner})
    assert _amount0 > token0.balanceOf(owner)
    assert _amount1 > token1.balanceOf(owner)