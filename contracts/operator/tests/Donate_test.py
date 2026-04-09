# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, Operator, Deployer
from sympy import Integer, floor
from eth_abi import encode
from Nofee import logTest, _hookData_, _msgSender_, _hookDataByteCount_, address0, collectSequence, mintSequence, burnSequence, donateSequence, keccak, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, dataGeneration, getPoolId

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

@pytest.mark.parametrize('n', range(len(initializations['kernel'])))
def test_donate(deployment, n, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, nofeeswap, delegatee, access, hook, operator, poolGrowthPortion, protocolGrowthPortion = deployment

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**120, root, {'from': root})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**120, root, {'from': root})
    token0.approve(operator, 2**120, {'from': root})
    token1.approve(operator, 2**120, {'from': root})
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

    qMin = lower - (1 << 63) + (logOffset * (1 << 59))
    qMax = upper - (1 << 63) + (logOffset * (1 << 59))
    shares = 1000000
    hookData = b"HookData"
    tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
        unsaltedPoolId,
        tag0,
        tag1,
        (1 << 47) // 5,
        encodeKernelCompact(kernel),
        encodeCurve(curve),
        b""
      ),
      {'from': owner}
    )

    ##############################

    data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})
    amount0 = token0.balanceOf(nofeeswap)
    amount1 = token1.balanceOf(nofeeswap)

    ##############################

    data = donateSequence(nofeeswap, token0, token1, poolId, shares, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})
    _amount0 = token0.balanceOf(nofeeswap)
    _amount1 = token1.balanceOf(nofeeswap)

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)

    q = Integer(poolGrowthPortion) / (1 << 47)
    p = Integer(protocolGrowthPortion) / (1 << 47)

    assert growth == floor((1 << 111) * (1 + (1 - p) * (1 - q)))
    assert _amount0 == 2 * amount0
    assert _amount1 == 2 * amount1

    assert tx.events['Donate']['poolId'] == poolId
    assert tx.events['Donate']['caller'] == operator.address
    assert toInt(tx.events['Donate']['data'].hex()) == growth << 128

    hookDataPlacement = toInt(hook.preDonateData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.preDonateData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.preDonateData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.midDonateData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.midDonateData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.midDonateData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.postDonateData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.postDonateData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.postDonateData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

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