# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, Operator, Deployer
from sympy import Integer, ceiling
from eth_abi import encode
from Nofee import logTest, address0, collectSequence, mintSequence, burnSequence, swapSequence, keccak, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, dataGeneration, checkPool, getPoolId, Pool

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    root = accounts[0]
    owner = accounts[1]
    other = accounts[2]
    access = Access.deploy({'from': root})

    return root, owner, other, access

@pytest.mark.parametrize('shares', [2**10, 2**20, 2**30, 2**40])
@pytest.mark.parametrize('zeroForOne', [False, True])
@pytest.mark.parametrize('specified', ['outgoing', 'incoming'])
@pytest.mark.parametrize('amount', [1, 100, 10000, 1000000, 100000000])
@pytest.mark.parametrize('logOffset', [-89, -20, 0, 20, 89])
def test_swapAmountSpecified(deployment, shares, zeroForOne, specified, amount, logOffset, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, access = deployment

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

    protocolGrowthPortion = (1 << 47) // 10000
    poolGrowthPortion = (1 << 47) // 5000

    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (poolGrowthPortion << 208) + (protocolGrowthPortion << 160) + int(root.address, 16)
    ), {'from': root})

    operator = Operator.deploy(nofeeswap, address0, address0, address0, {'from': root})

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**128, root, {'from': root})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**128, root, {'from': root})
    token0.approve(operator, 2**128, {'from': root})
    token1.approve(operator, 2**128, {'from': root})
    if toInt(token0.address) > toInt(token1.address):
        token0, token1 = token1, token0
    tag0 = toInt(token0.address)
    tag1 = toInt(token1.address)

    kernel = [
      [0, 0],
      [2 ** 55, 2 ** 15]
    ]
    curve = [2 ** 61, 2 ** 61 + 2 ** 55, 2 ** 61 + 2 ** 54]
    amountSpecified = +amount if specified == 'incoming' else -amount
    lower = min(curve[0], curve[1])
    upper = max(curve[0], curve[1])
    current = curve[-1]

    # initialization
    unsaltedPoolId = (1 << 188) + (twosComplementInt8(logOffset) << 180)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    deadline = 2 ** 32 - 1

    pool = Pool(
        logOffset,
        curve,
        kernel,
        Integer(protocolGrowthPortion) / (1 << 47),
        Integer(poolGrowthPortion) / (1 << 47),
        20
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
    hookData = b"HookData"
    tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

    pool.modifyPosition(qMin, qMax, shares)
    data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    ##############################

    target = lower if zeroForOne else upper
    limit = target - (1 << 63) + (logOffset * (1 << 59))
    zeroForOne = 2

    _amount0 = token0.balanceOf(nofeeswap)
    _amount1 = token1.balanceOf(nofeeswap)
    data = swapSequence(nofeeswap, token0, token1, root, poolId, amountSpecified, limit, zeroForOne, hookData, deadline)
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

    if _amount0 != 0 and _amount1 != 0:
        if qMin < current < qMax:
            if _amount0 > 0 and specified == 'incoming':
                assert _amount0 <= amount

            if _amount1 > 0 and specified == 'incoming':
                assert _amount1 <= amount

            if _amount0 < 0 and specified == 'outgoing':
                assert -_amount0 >= amount

            if _amount1 < 0 and specified == 'outgoing':
                assert -_amount1 >= amount

    ##############################

    nofeeswap.setOperator(operator, True, {'from': root})

    data = burnSequence(token0, token1, owner, tagShares, poolId, qMin, qMax, shares, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    pool.modifyPosition(qMin, qMax, -shares)

    nofeeswap.setOperator(operator, False, {'from': root})

    ##############################

    tx = nofeeswap.dispatch(
        delegatee.collectProtocol.encode_input(poolId), {'from': root}
    )
    amount0 = -tx.return_value[0]
    amount1 = -tx.return_value[1]

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

    nofeeswap.setOperator(operator, True, {'from': owner})

    data = collectSequence(token0, token1, tag0, tag1, root, amount0, amount1, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': owner})

    nofeeswap.setOperator(operator, False, {'from': owner})

    ##############################

    assert token0.balanceOf(nofeeswap) <= 10
    assert token1.balanceOf(nofeeswap) <= 10