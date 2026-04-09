# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, Operator, Deployer
from sympy import Integer, floor, exp, ceiling
from eth_abi import encode
from Nofee import logTest, address0, _hookData_, _msgSender_, _hookDataByteCount_, Pool, donateSequence, collectSequence, mintSequence, burnSequence, swapSequence, keccak, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, dataGeneration, checkPool, getMaxIntegrals, getPoolId

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

    protocolGrowthPortion = (2 * (1 << 47)) // 100
    poolGrowthPortion = (1 << 47) // 100

    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (poolGrowthPortion << 208) + (protocolGrowthPortion << 160) + int(root.address, 16)
    ), {'from': root})

    return root, owner, other, nofeeswap, delegatee, access, hook, operator, poolGrowthPortion, protocolGrowthPortion

@pytest.mark.parametrize('n', range(len(swaps['kernel'])))
def test_swapCollectProtocolFirst(deployment, n, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, nofeeswap, delegatee, access, hook, operator, poolGrowthPortion, protocolGrowthPortion = deployment

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**128, root, {'from': root})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**128, root, {'from': root})
    token0.approve(operator, 2**128, {'from': root})
    token1.approve(operator, 2**128, {'from': root})
    if toInt(token0.address) > toInt(token1.address):
        token0, token1 = token1, token0
    tag0 = toInt(token0.address)
    tag1 = toInt(token1.address)

    kernel = swaps['kernel'][n]
    curve = swaps['curve'][n]
    target = swaps['target'][n]
    lower = min(curve[0], curve[1])
    upper = max(curve[0], curve[1])

    logOffset = -5

    # initialization
    unsaltedPoolId = (n << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    deadline = 2 ** 32 - 1

    pool = Pool(
        logOffset,
        curve,
        kernel,
        Integer(protocolGrowthPortion) / (1 << 47),
        Integer(poolGrowthPortion) / (1 << 47),
        2
    )
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
        unsaltedPoolId,
        tag0,
        tag1,
        poolGrowthPortion,
        encodeKernelCompact(kernel),
        encodeCurve(curve),
        b""
      ),
      {'from': owner}
    )

    ##############################

    qMin = lower - (1 << 63) + (logOffset * (1 << 59))
    qMax = upper - (1 << 63) + (logOffset * (1 << 59))
    shares = 1000000000000000000000000000
    hookData = b"HookData"
    tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

    pool.modifyPosition(qMin, qMax, shares)

    data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    ##############################

    amountSpecified = - (1 << 120)
    limit = target - (1 << 63) + (logOffset * (1 << 59))
    zeroForOne = 2

    data = swapSequence(nofeeswap, token0, token1, root, poolId, amountSpecified, limit, zeroForOne, hookData, deadline)

    _amount0 = token0.balanceOf(nofeeswap)
    _amount1 = token1.balanceOf(nofeeswap)
    tx = nofeeswap.unlock(operator, data, {'from': root})
    _amount0 = token0.balanceOf(nofeeswap) - _amount0
    _amount1 = token1.balanceOf(nofeeswap) - _amount1

    _target = (toInt(tx.events['Swap']['data'].hex()) >> 128) % (2 ** 64)
    _overshoot = (toInt(tx.events['Swap']['data'].hex()) >> 192)

    amount0 = pool.amount0
    amount1 = pool.amount1
    g, g_minus, g_plus = pool.swap(_target, _overshoot)
    assert g_minus <= g
    assert g_plus <= g
    amount0 = pool.amount0 - amount0
    amount1 = pool.amount1 - amount1

    assert ceiling(amount0) == _amount0
    assert ceiling(amount1) == _amount1
    checkPool(nofeeswap, access, poolId, pool)

    hookDataPlacement = toInt(hook.preSwapData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.preSwapData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.preSwapData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.midSwapData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.midSwapData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.midSwapData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.postSwapData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.postSwapData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.postSwapData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    ##############################

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    growth = Integer(growth) / (1 << 111)
    integral0 = Integer(integral0) / (1 << 216)
    integral1 = Integer(integral1) / (1 << 216)

    outgoingMax, incomingMax = getMaxIntegrals(kernel)
    outgoingMax = Integer(outgoingMax) / (1 << 216)

    protocolPortion = Integer(protocolGrowthPortion) / (1 << 47)
    poolPortion = Integer(poolGrowthPortion) / (1 << 47)

    fullGrowth = 1 + ((growth - 1) / ((1 - protocolPortion) * (1 - poolPortion)))

    sharesDonate = shares // 2

    accrued0SwapRef = floor((protocolPortion + poolPortion * (1 - protocolPortion)) * shares * (fullGrowth - 1) * (integral0 / outgoingMax) / exp(Integer(logOffset) / 2))
    accrued1SwapRef = floor((protocolPortion + poolPortion * (1 - protocolPortion)) * shares * (fullGrowth - 1) * (integral1 / outgoingMax) * exp(Integer(logOffset) / 2))
    accrued0DonateRef = floor((protocolPortion + poolPortion * (1 - protocolPortion)) * sharesDonate * growth * (integral0 / outgoingMax) / exp(Integer(logOffset) / 2))
    accrued1DonateRef = floor((protocolPortion + poolPortion * (1 - protocolPortion)) * sharesDonate * growth * (integral1 / outgoingMax) * exp(Integer(logOffset) / 2))
    accrued0Ref = accrued0DonateRef + accrued0SwapRef
    accrued1Ref = accrued1DonateRef + accrued1SwapRef

    ##############################

    data = donateSequence(nofeeswap, token0, token1, poolId, sharesDonate, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    ##############################

    poolRatio0, poolRatio1, accrued0, accrued1 = access._readAccruedParams(nofeeswap, poolId)

    poolRatio0Ref = floor(((poolPortion * (1 - protocolPortion)) / (protocolPortion + poolPortion * (1 - protocolPortion))) * (1 << 23))
    poolRatio1Ref = floor(((poolPortion * (1 - protocolPortion)) / (protocolPortion + poolPortion * (1 - protocolPortion))) * (1 << 23))
    protocol0Ref = floor(((1 << 23) - poolRatio0Ref) * accrued0Ref / (1 << 23))
    protocol1Ref = floor(((1 << 23) - poolRatio1Ref) * accrued1Ref / (1 << 23))
    pool0Ref = floor(poolRatio0Ref * accrued0Ref / (1 << 23))
    pool1Ref = floor(poolRatio1Ref * accrued1Ref / (1 << 23))

    assert accrued0 == accrued0Ref
    assert accrued1 == accrued1Ref
    if accrued0 != 0:
        assert poolRatio0 == floor(poolRatio0Ref)
    if accrued1 != 0:
        assert poolRatio1 == floor(poolRatio1Ref)

    ##############################

    nofeeswap.setOperator(operator, True, {'from': root})

    data = burnSequence(token0, token1, owner, tagShares, poolId, qMin, qMax, shares, hookData, deadline)

    tx = nofeeswap.unlock(operator, data, {'from': root})

    nofeeswap.setOperator(operator, False, {'from': root})

    ##############################

    tx = nofeeswap.dispatch(
        delegatee.collectProtocol.encode_input(poolId), {'from': root}
    )
    amount0 = -tx.return_value[0]
    amount1 = -tx.return_value[1]

    assert amount0 == -protocol0Ref
    assert amount1 == -protocol1Ref

    nofeeswap.setOperator(operator, True, {'from': root})

    data = collectSequence(token0, token1, tag0, tag1, root, amount0, amount1, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    nofeeswap.setOperator(operator, False, {'from': root})

    ##############################

    tx = nofeeswap.dispatch(
        delegatee.collectPool.encode_input(poolId), {'from': owner}
    )
    amount0 = -tx.return_value[0]
    amount1 = -tx.return_value[1]

    assert amount0 == -pool0Ref
    assert amount1 == -pool1Ref

    nofeeswap.setOperator(operator, True, {'from': owner})

    data = collectSequence(token0, token1, tag0, tag1, root, amount0, amount1, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': owner})

    nofeeswap.setOperator(operator, False, {'from': owner})

    ##############################

    assert token0.balanceOf(nofeeswap) <= 10
    assert token1.balanceOf(nofeeswap) <= 10

@pytest.mark.parametrize('n', range(len(swaps['kernel'])))
def test_swapCollectPoolFirst(deployment, n, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, nofeeswap, delegatee, access, hook, operator, poolGrowthPortion, protocolGrowthPortion = deployment

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**128, root, {'from': root})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**128, root, {'from': root})
    token0.approve(operator, 2**128, {'from': root})
    token1.approve(operator, 2**128, {'from': root})
    if toInt(token0.address) > toInt(token1.address):
        token0, token1 = token1, token0
    tag0 = toInt(token0.address)
    tag1 = toInt(token1.address)

    kernel = swaps['kernel'][n]
    curve = swaps['curve'][n]
    target = swaps['target'][n]
    lower = min(curve[0], curve[1])
    upper = max(curve[0], curve[1])

    logOffset = -5

    # initialization
    unsaltedPoolId = (1 << 254) + (n << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    deadline = 2 ** 32 - 1

    pool = Pool(
        logOffset,
        curve,
        kernel,
        Integer(protocolGrowthPortion) / (1 << 47),
        Integer(poolGrowthPortion) / (1 << 47),
        2
    )
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
        unsaltedPoolId,
        tag0,
        tag1,
        poolGrowthPortion,
        encodeKernelCompact(kernel),
        encodeCurve(curve),
        b""
      ),
      {'from': owner}
    )

    ##############################

    qMin = lower - (1 << 63) + (logOffset * (1 << 59))
    qMax = upper - (1 << 63) + (logOffset * (1 << 59))
    shares = 1000000000000000000000000000
    hookData = b"HookData"
    tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

    pool.modifyPosition(qMin, qMax, shares)

    data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    ##############################

    amountSpecified = - (1 << 120)
    limit = target - (1 << 63) + (logOffset * (1 << 59))
    zeroForOne = 2

    data = swapSequence(nofeeswap, token0, token1, root, poolId, amountSpecified, limit, zeroForOne, hookData, deadline)

    _amount0 = token0.balanceOf(nofeeswap)
    _amount1 = token1.balanceOf(nofeeswap)
    tx = nofeeswap.unlock(operator, data, {'from': root})
    _amount0 = token0.balanceOf(nofeeswap) - _amount0
    _amount1 = token1.balanceOf(nofeeswap) - _amount1

    _target = (toInt(tx.events['Swap']['data'].hex()) >> 128) % (2 ** 64)
    _overshoot = (toInt(tx.events['Swap']['data'].hex()) >> 192)

    amount0 = pool.amount0
    amount1 = pool.amount1
    g, g_minus, g_plus = pool.swap(_target, _overshoot)
    assert g_minus <= g
    assert g_plus <= g
    amount0 = pool.amount0 - amount0
    amount1 = pool.amount1 - amount1

    assert ceiling(amount0) == _amount0
    assert ceiling(amount1) == _amount1
    checkPool(nofeeswap, access, poolId, pool)
    length = len(hook.preSwapData().hex())

    hookDataPlacement = toInt(hook.preSwapData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.preSwapData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.preSwapData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.midSwapData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.midSwapData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.midSwapData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.postSwapData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.postSwapData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.postSwapData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    ##############################

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    growth = Integer(growth) / (1 << 111)
    integral0 = Integer(integral0) / (1 << 216)
    integral1 = Integer(integral1) / (1 << 216)

    outgoingMax, incomingMax = getMaxIntegrals(kernel)
    outgoingMax = Integer(outgoingMax) / (1 << 216)

    protocolPortion = Integer(protocolGrowthPortion) / (1 << 47)
    poolPortion = Integer(poolGrowthPortion) / (1 << 47)

    fullGrowth = 1 + ((growth - 1) / ((1 - protocolPortion) * (1 - poolPortion)))

    sharesDonate = shares // 2

    accrued0SwapRef = floor((protocolPortion + poolPortion * (1 - protocolPortion)) * shares * (fullGrowth - 1) * (integral0 / outgoingMax) / exp(Integer(logOffset) / 2))
    accrued1SwapRef = floor((protocolPortion + poolPortion * (1 - protocolPortion)) * shares * (fullGrowth - 1) * (integral1 / outgoingMax) * exp(Integer(logOffset) / 2))
    accrued0DonateRef = floor((protocolPortion + poolPortion * (1 - protocolPortion)) * sharesDonate * growth * (integral0 / outgoingMax) / exp(Integer(logOffset) / 2))
    accrued1DonateRef = floor((protocolPortion + poolPortion * (1 - protocolPortion)) * sharesDonate * growth * (integral1 / outgoingMax) * exp(Integer(logOffset) / 2))
    accrued0Ref = accrued0DonateRef + accrued0SwapRef
    accrued1Ref = accrued1DonateRef + accrued1SwapRef

    ##############################

    data = donateSequence(nofeeswap, token0, token1, poolId, sharesDonate, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    ##############################

    poolRatio0, poolRatio1, accrued0, accrued1 = access._readAccruedParams(nofeeswap, poolId)

    poolRatio0Ref = floor(((poolPortion * (1 - protocolPortion)) / (protocolPortion + poolPortion * (1 - protocolPortion))) * (1 << 23))
    poolRatio1Ref = floor(((poolPortion * (1 - protocolPortion)) / (protocolPortion + poolPortion * (1 - protocolPortion))) * (1 << 23))
    protocol0Ref = floor(((1 << 23) - poolRatio0Ref) * accrued0Ref / (1 << 23))
    protocol1Ref = floor(((1 << 23) - poolRatio1Ref) * accrued1Ref / (1 << 23))
    pool0Ref = floor(poolRatio0Ref * accrued0Ref / (1 << 23))
    pool1Ref = floor(poolRatio1Ref * accrued1Ref / (1 << 23))

    assert accrued0 == accrued0Ref
    assert accrued1 == accrued1Ref
    if accrued0 != 0:
        assert poolRatio0 == floor(poolRatio0Ref)
    if accrued1 != 0:
        assert poolRatio1 == floor(poolRatio1Ref)

    ##############################

    nofeeswap.setOperator(operator, True, {'from': root})

    data = burnSequence(token0, token1, owner, tagShares, poolId, qMin, qMax, shares, hookData, deadline)

    tx = nofeeswap.unlock(operator, data, {'from': root})

    nofeeswap.setOperator(operator, False, {'from': root})

    ##############################

    tx = nofeeswap.dispatch(
        delegatee.collectPool.encode_input(poolId), {'from': owner}
    )
    amount0 = -tx.return_value[0]
    amount1 = -tx.return_value[1]

    assert amount0 == -pool0Ref
    assert amount1 == -pool1Ref

    nofeeswap.setOperator(operator, True, {'from': owner})

    data = collectSequence(token0, token1, tag0, tag1, root, amount0, amount1, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': owner})

    nofeeswap.setOperator(operator, False, {'from': owner})

    ##############################

    tx = nofeeswap.dispatch(
        delegatee.collectProtocol.encode_input(poolId), {'from': root}
    )
    amount0 = -tx.return_value[0]
    amount1 = -tx.return_value[1]

    assert amount0 == -protocol0Ref
    assert amount1 == -protocol1Ref

    nofeeswap.setOperator(operator, True, {'from': root})

    data = collectSequence(token0, token1, tag0, tag1, root, amount0, amount1, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    nofeeswap.setOperator(operator, False, {'from': root})

    ##############################

    assert token0.balanceOf(nofeeswap) <= 10
    assert token1.balanceOf(nofeeswap) <= 10