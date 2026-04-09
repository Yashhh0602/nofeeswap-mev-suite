# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, Operator, Deployer
from sympy import Integer, ceiling
from eth_abi import encode
from Nofee import logTest, address0, _hookData_, _msgSender_, _hookDataByteCount_, collectSequence, mintSequence, burnSequence, swapSequence, keccak, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, dataGeneration, checkPool, getPoolId, Pool

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

    protocolGrowthPortion = (1 << 47) // 10
    poolGrowthPortion = (1 << 47) // 5

    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (poolGrowthPortion << 208) + (protocolGrowthPortion << 160) + int(root.address, 16)
    ), {'from': root})

    return root, owner, other, nofeeswap, delegatee, access, hook, operator, poolGrowthPortion, protocolGrowthPortion

@pytest.mark.parametrize('n', range(len(swaps['kernel'])))
def test_swapExactInput(deployment, n, request, worker_id):
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
    current = curve[-1]

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
    shares = 1000000
    hookData = b"HookData"
    tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

    pool.modifyPosition(qMin, qMax, shares)
    data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    ##############################

    amountSpecified = + 1000
    limit = (lower if target < current else upper) - (1 << 63) + (logOffset * (1 << 59))
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