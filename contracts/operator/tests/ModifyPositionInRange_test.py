# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, Operator, Deployer
from sympy import Integer, ceiling
from eth_abi import encode
from Nofee import logTest, address0, _hookData_, _msgSender_, _hookDataByteCount_, mintSequence, burnSequence, keccak, toInt, twosComplement, twosComplementInt8, encodeKernelCompact, encodeCurve, dataGeneration, getPoolId, Pool

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
def test_inRange(deployment, n, request, worker_id):
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

    logOffset = -5

    # initialization
    unsaltedPoolId = (n << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    deadline = 2 ** 32 - 1
    hookData = b"HookData"

    qMin = lower - (1 << 63) + (logOffset * (1 << 59))
    qMax = upper - (1 << 63) + (logOffset * (1 << 59))
    shares = 1000000
    tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

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

    ##############################

    data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': owner})

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    sharesGross = access._readSharesGross(nofeeswap, poolId)
    sharesDeltaLower = access._readSharesDelta(nofeeswap, poolId, lower)
    sharesDeltaUpper = access._readSharesDelta(nofeeswap, poolId, upper)

    assert sharesTotal == shares
    assert sharesGross == shares
    assert sharesDeltaLower == shares
    assert sharesDeltaUpper == - shares

    pool.modifyPosition(qMin, qMax, shares)
    amount0 = token0.balanceOf(nofeeswap)
    amount1 = token1.balanceOf(nofeeswap)

    assert amount0 == ceiling(pool.amount0)
    assert amount1 == ceiling(pool.amount1)

    assert tx.events['ModifyPosition']['poolId'] == poolId
    assert tx.events['ModifyPosition']['caller'] == operator.address

    _eventData = ''
    for kk in range(len(tx.events['ModifyPosition']['data'])):
        _eventData += tx.events['ModifyPosition']['data'][kk].hex()
    _eventData = toInt(_eventData)

    eventData = qMin + (1 << 63) - (logOffset * (1 << 59))

    eventData <<= 64
    eventData += qMax + (1 << 63) - (logOffset * (1 << 59))

    eventData <<= 256
    eventData += twosComplement(shares)

    eventData <<= 256
    eventData += twosComplement(qMin)

    eventData <<= 256
    eventData += twosComplement(qMax)

    eventData <<= 256
    eventData += twosComplement(amount0)

    eventData <<= 256
    eventData += twosComplement(amount1)

    eventData <<= 128

    assert eventData == _eventData

    hookDataPlacement = toInt(hook.preMintData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.preMintData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.preMintData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.midMintData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.midMintData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.midMintData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.postMintData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.postMintData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.postMintData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    ##############################

    tx = nofeeswap.unlock(operator, data, {'from': owner})
    pool.modifyPosition(qMin, qMax, shares)

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    sharesGross = access._readSharesGross(nofeeswap, poolId)
    sharesDeltaLower = access._readSharesDelta(nofeeswap, poolId, lower)
    sharesDeltaUpper = access._readSharesDelta(nofeeswap, poolId, upper)

    assert sharesTotal == 2 * shares
    assert sharesGross == 2 * shares
    assert sharesDeltaLower == 2 * shares
    assert sharesDeltaUpper == - 2 * shares

    ##############################

    nofeeswap.setOperator(operator, True, {'from': owner})

    data = burnSequence(token0, token1, owner, tagShares, poolId, qMin, qMax, 2 * shares, hookData, deadline)

    amount0 = pool.amount0
    amount1 = pool.amount1
    pool.modifyPosition(qMin, qMax, - 2 * shares)
    amount0 = pool.amount0 - amount0
    amount1 = pool.amount1 - amount1

    _amount0 = token0.balanceOf(nofeeswap)
    _amount1 = token1.balanceOf(nofeeswap)
    tx = nofeeswap.unlock(operator, data, {'from': owner})
    _amount0 = token0.balanceOf(nofeeswap) - _amount0
    _amount1 = token1.balanceOf(nofeeswap) - _amount1

    assert _amount0 == ceiling(_amount0)
    assert _amount1 == ceiling(_amount1)

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    sharesGross = access._readSharesGross(nofeeswap, poolId)
    sharesDeltaLower = access._readSharesDelta(nofeeswap, poolId, lower)
    sharesDeltaUpper = access._readSharesDelta(nofeeswap, poolId, upper)

    assert sharesTotal == 0
    assert sharesGross == 0
    assert sharesDeltaLower == 0
    assert sharesDeltaUpper == 0

    hookDataPlacement = toInt(hook.preBurnData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.preBurnData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.preBurnData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.midBurnData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.midBurnData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.midBurnData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.postBurnData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.postBurnData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.postBurnData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]