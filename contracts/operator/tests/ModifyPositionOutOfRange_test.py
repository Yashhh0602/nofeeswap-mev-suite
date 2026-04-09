# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, Operator, Deployer
from sympy import Integer, ceiling
from eth_abi import encode
from eth_abi.packed import encode_packed
from Nofee import logTest, PUSH32, NEG, ADD, TAKE_TOKEN, MODIFY_SINGLE_BALANCE, MODIFY_POSITION, address0, mintSequence, keccak, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, dataGeneration, getPoolId, Pool

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

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

@pytest.mark.parametrize('n', range(len(initializations['kernel'])))
def test_outOfRange(deployment, n, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, nofeeswap, delegatee, access, hook, operator = deployment

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**120, owner, {'from': owner})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**120, owner, {'from': owner})
    token0.approve(operator, 2** 120, {'from': owner})
    token1.approve(operator, 2** 120, {'from': owner})
    if toInt(token0.address) > toInt(token1.address):
        token0, token1 = token1, token0
    tag0 = toInt(token0.address)
    tag1 = toInt(token1.address)

    kernel = initializations['kernel'][n]
    curve = initializations['curve'][n]
    lower = min(curve[0], curve[1])
    upper = max(curve[0], curve[1])
    spacing = upper - lower

    if spacing < lower - 2 * spacing and upper + 2 * spacing < (1 << 64) - spacing - 1:
        logOffset = -5

        # initialization
        unsaltedPoolId = (n << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
        poolId = getPoolId(owner.address, unsaltedPoolId)

        deadline = 2 ** 32 - 1

        qMin = lower - (1 << 63) + (logOffset * (1 << 59))
        qMax = upper - (1 << 63) + (logOffset * (1 << 59))
        shares = 1000000
        hookData = b"HookData"

        pool = Pool(
            logOffset,
            curve,
            kernel,
            Integer(0),
            Integer(0),
            5
        )
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

        amount0 = pool.amount0
        amount1 = pool.amount1
        pool.modifyPosition(qMin, qMax + 2 * spacing, shares)
        amount0 = pool.amount0 - amount0
        amount1 = pool.amount1 - amount1

        _amount0 = token0.balanceOf(nofeeswap)
        _amount1 = token1.balanceOf(nofeeswap)
        tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax + 2 * spacing])
        data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax + 2 * spacing, shares, hookData, deadline)
        tx = nofeeswap.unlock(operator, data, {'from': owner})
        _amount0 = token0.balanceOf(nofeeswap) - _amount0
        _amount1 = token1.balanceOf(nofeeswap) - _amount1

        assert _amount0 == ceiling(_amount0)
        assert _amount1 == ceiling(_amount1)

        staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
        sharesGross = access._readSharesGross(nofeeswap, poolId)
        sharesDeltaLower = access._readSharesDelta(nofeeswap, poolId, lower)
        sharesDeltaUpper = access._readSharesDelta(nofeeswap, poolId, upper + 2 * spacing)

        assert sharesTotal == shares
        assert sharesGross == 3 * shares
        assert sharesDeltaLower == shares
        assert sharesDeltaUpper == - shares

        ##############################

        amount0 = pool.amount0
        amount1 = pool.amount1
        pool.modifyPosition(qMin - 2 * spacing, qMax, shares)
        amount0 = pool.amount0 - amount0
        amount1 = pool.amount1 - amount1

        _amount0 = token0.balanceOf(nofeeswap)
        _amount1 = token1.balanceOf(nofeeswap)
        tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin - 2 * spacing, qMax])
        data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin - 2 * spacing, qMax, shares, hookData, deadline)
        tx = nofeeswap.unlock(operator, data, {'from': owner})
        _amount0 = token0.balanceOf(nofeeswap) - _amount0
        _amount1 = token1.balanceOf(nofeeswap) - _amount1

        assert _amount0 == ceiling(_amount0)
        assert _amount1 == ceiling(_amount1)

        staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
        sharesGross = access._readSharesGross(nofeeswap, poolId)
        sharesDeltaLower = access._readSharesDelta(nofeeswap, poolId, lower - 2 * spacing)
        sharesDeltaUpper = access._readSharesDelta(nofeeswap, poolId, upper)

        assert sharesTotal == 2 * shares
        assert sharesGross == 6 * shares
        assert sharesDeltaLower == shares
        assert sharesDeltaUpper == - shares

        ##############################

        amount0 = pool.amount0
        amount1 = pool.amount1
        pool.modifyPosition(qMin - 2 * spacing, qMax + 2 * spacing, 2 * shares)
        amount0 = pool.amount0 - amount0
        amount1 = pool.amount1 - amount1

        _amount0 = token0.balanceOf(nofeeswap)
        _amount1 = token1.balanceOf(nofeeswap)
        tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin - 2 * spacing, qMax + 2 * spacing])
        data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin - 2 * spacing, qMax + 2 * spacing, 2 * shares, hookData, deadline)
        tx = nofeeswap.unlock(operator, data, {'from': owner})
        _amount0 = token0.balanceOf(nofeeswap) - _amount0
        _amount1 = token1.balanceOf(nofeeswap) - _amount1

        assert _amount0 == ceiling(_amount0)
        assert _amount1 == ceiling(_amount1)

        staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
        sharesGross = access._readSharesGross(nofeeswap, poolId)
        sharesDeltaLower = access._readSharesDelta(nofeeswap, poolId, lower - 2 * spacing)
        sharesDeltaUpper = access._readSharesDelta(nofeeswap, poolId, upper + 2 * spacing)

        assert sharesTotal == 4 * shares
        assert sharesGross == 16 * shares
        assert sharesDeltaLower == 3 * shares
        assert sharesDeltaUpper == - 3 * shares

        ##############################

        nofeeswap.setOperator(operator, True, {'from': owner})

        sharesSlot = 1

        successSlot = 2

        amount0Slot = 3
        amount1Slot = 4

        amount0Slot_ = 50
        amount1Slot_ = 51

        sharesSuccessSlot = 5
        successSlotSettle0 = 8
        successSlotSettle1 = 9

        sequence = [0] * 16
        sequence[0] = encode_packed(
          ['uint8', 'int256', 'uint8'],
          [PUSH32, -shares, sharesSlot]
        )
        sequence[1] = encode_packed(
          ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
          [MODIFY_POSITION, poolId, lower, upper + 2*spacing, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
        )
        sequence[2] = encode_packed(
          ['uint8', 'uint256', 'uint8', 'uint8'],
          [MODIFY_SINGLE_BALANCE, keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax + 2*spacing]), sharesSlot, sharesSuccessSlot]
        )
        sequence[3] = encode_packed(
          ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
          [MODIFY_POSITION, poolId, lower - 2*spacing, upper, sharesSlot, successSlot, amount0Slot_, amount1Slot_, len(hookData), hookData]
        )
        sequence[4] = encode_packed(
          ['uint8', 'uint256', 'uint8', 'uint8'],
          [MODIFY_SINGLE_BALANCE, keccak(['uint256', 'int256', 'int256'], [poolId, qMin - 2*spacing, qMax]), sharesSlot, sharesSuccessSlot]
        )
        sequence[5] = encode_packed(
          ['uint8', 'uint8', 'uint8', 'uint8'],
          [ADD, amount0Slot, amount0Slot_, amount0Slot]
        )
        sequence[6] = encode_packed(
          ['uint8', 'uint8', 'uint8', 'uint8'],
          [ADD, amount1Slot, amount1Slot_, amount1Slot]
        )
        sequence[7] = encode_packed(
          ['uint8', 'int256', 'uint8'],
          [PUSH32, -2*shares, sharesSlot]
        )
        sequence[8] = encode_packed(
          ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
          [MODIFY_POSITION, poolId, lower - 2*spacing, upper + 2*spacing, sharesSlot, successSlot, amount0Slot_, amount1Slot_, len(hookData), hookData]
        )
        sequence[9] = encode_packed(
          ['uint8', 'uint256', 'uint8', 'uint8'],
          [MODIFY_SINGLE_BALANCE, keccak(['uint256', 'int256', 'int256'], [poolId, qMin - 2*spacing, qMax + 2*spacing]), sharesSlot, sharesSuccessSlot]
        )
        sequence[10] = encode_packed(
          ['uint8', 'uint8', 'uint8', 'uint8'],
          [ADD, amount0Slot, amount0Slot_, amount0Slot]
        )
        sequence[11] = encode_packed(
          ['uint8', 'uint8', 'uint8', 'uint8'],
          [ADD, amount1Slot, amount1Slot_, amount1Slot]
        )
        sequence[12] = encode_packed(
          ['uint8', 'uint8', 'uint8'],
          [NEG, amount0Slot, amount0Slot]
        )
        sequence[13] = encode_packed(
          ['uint8', 'uint8', 'uint8'],
          [NEG, amount1Slot, amount1Slot]
        )
        sequence[14] = encode_packed(
          ['uint8', 'address', 'address', 'uint8', 'uint8'],
          [TAKE_TOKEN, token0.address, owner.address, amount0Slot, successSlotSettle0]
        )
        sequence[15] = encode_packed(
          ['uint8', 'address', 'address', 'uint8', 'uint8'],
          [TAKE_TOKEN, token1.address, owner.address, amount1Slot, successSlotSettle1]
        )

        data = encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)
        tx = nofeeswap.unlock(operator, data, {'from': owner})

        staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
        sharesGross = access._readSharesGross(nofeeswap, poolId)

        sharesDeltaMin = access._readSharesDelta(nofeeswap, poolId, lower - 2 * spacing)
        sharesDeltaLower = access._readSharesDelta(nofeeswap, poolId, lower)
        sharesDeltaUpper = access._readSharesDelta(nofeeswap, poolId, upper)
        sharesDeltaMax = access._readSharesDelta(nofeeswap, poolId, upper + 2 * spacing)

        assert sharesTotal == 0
        assert sharesGross == 0
        assert sharesDeltaMin == 0
        assert sharesDeltaLower == 0
        assert sharesDeltaUpper == 0
        assert sharesDeltaMax == 0