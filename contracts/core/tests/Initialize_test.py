# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, DeployerHelper
from sympy import Integer, floor, exp
from Nofee import logTest, _hookData_, _msgSender_, _hookDataByteCount_, encode, toInt, twosComplementInt8, encodeKernelCompact, encodeKernel, encodeCurve, dataGeneration, outgoing, getMaxIntegrals, getPoolId

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

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

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**120, owner, {'from': owner})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**120, owner, {'from': owner})

    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (123 << 208) + (456 << 160) + int(root.address, 16)
    ), {'from': root})

    return root, owner, other, nofeeswap, delegatee, access, hook, token0, token1

@pytest.mark.parametrize('n', range(len(initializations['kernel'])))
def test_initialize(deployment, n, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, nofeeswap, delegatee, access, hook, token0, token1 = deployment

    kernel = initializations['kernel'][n]
    curve = initializations['curve'][n]
    lower = min(curve[0], curve[1])
    upper = max(curve[0], curve[1])
    spacing = upper - lower
    current = curve[-1]

    logOffset = -5
    unsaltedPoolId = (n << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    hookData = b"HookData"

    # initialization
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
          unsaltedPoolId,
          min(toInt(token0.address), toInt(token1.address)),
          max(toInt(token0.address), toInt(token1.address)),
          0x800000000000,
          encodeKernelCompact(kernel),
          encodeCurve(curve),
          hookData
      ),
      {'from': owner}
    )

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    curveArray = list(access._readCurve(nofeeswap, poolId, logPriceCurrent).return_value)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId, staticParamsStoragePointer)
    kernelArray = list(access._readKernel(nofeeswap, poolId, staticParamsStoragePointer))
    growthLower = access._readGrowthMultiplier(nofeeswap, poolId, lower)
    growthUpper = access._readGrowthMultiplier(nofeeswap, poolId, upper)

    assert staticParamsStoragePointerExtension == 0
    assert growth == 1 << 111
    assert abs(integral0 - outgoing(curve, kernel, current, upper)) <= 2 ** 32
    assert abs(integral1 - outgoing(curve, kernel, lower, current)) <= 2 ** 32
    assert sharesTotal == 0
    assert staticParamsStoragePointer == 0
    assert logPriceCurrent == current
    assert curveArray == encodeCurve(curve)
    assert tag0 == min(toInt(token0.address), toInt(token1.address))
    assert tag1 == max(toInt(token0.address), toInt(token1.address))
    assert sqrtOffset == floor((2 ** 127) * exp(Integer(logOffset) / 2))
    assert sqrtInverseOffset == floor((2 ** 127) / exp(Integer(logOffset) / 2))
    assert sqrtSpacing == floor((2 ** 216) * exp(- Integer(spacing) / (2 ** 60)))
    assert sqrtInverseSpacing == floor((2 ** 216) * exp(- 16 + Integer(spacing) / (2 ** 60)))
    assert kernelArray == encodeKernel(kernel)
    _outgoingMax, _incomingMax = getMaxIntegrals(kernel)
    assert abs(outgoingMax - _outgoingMax) <= 2 ** 32
    assert abs(incomingMax - _incomingMax) <= 2 ** 48
    _outgoingMaxModularInverse = outgoingMax
    while _outgoingMaxModularInverse % 2 != 1:
        _outgoingMaxModularInverse >>= 1
    _outgoingMaxModularInverse = pow(_outgoingMaxModularInverse, -1, 2**256)
    assert outgoingMaxModularInverse == _outgoingMaxModularInverse
    assert poolGrowthPortion == 0x800000000000
    assert maxPoolGrowthPortion == 123
    assert protocolGrowthPortion == 456
    assert pendingKernelLength == 0
    assert abs(growthLower - floor((2 ** 208) * exp(+ Integer(lower - (2 ** 63)) / (2 ** 60)) / (1 - exp(- Integer(spacing) / (2 ** 60))))) <= 2 ** 24
    assert abs(growthUpper - floor((2 ** 208) * exp(- Integer(upper - (2 ** 63)) / (2 ** 60)) / (1 - exp(- Integer(spacing) / (2 ** 60))))) <= 2 ** 24

    assert tx.events['Initialize']['poolId'] == poolId
    assert tx.events['Initialize']['tag0'] == tag0
    assert tx.events['Initialize']['tag1'] == tag1

    _eventData = toInt(tx.events['Initialize']['data'].hex())

    eventData = tag0

    eventData <<= 256
    eventData += tag1

    eventData <<= 256
    eventData += sqrtOffset

    eventData <<= 256
    eventData += sqrtInverseOffset

    eventData <<= 64
    eventData += spacing

    eventData <<= 216
    eventData += sqrtSpacing

    eventData <<= 216
    eventData += sqrtInverseSpacing

    eventData <<= 216
    eventData += outgoingMax

    eventData <<= 256
    eventData += outgoingMaxModularInverse

    eventData <<= 216
    eventData += incomingMax

    eventData <<= 48
    eventData += poolGrowthPortion

    eventData <<= 48
    eventData += maxPoolGrowthPortion

    eventData <<= 48
    eventData += protocolGrowthPortion

    eventData <<= 16
    eventData += pendingKernelLength

    _encodedKernel = encodeKernel(kernel)
    for k in range(len(_encodedKernel), ((32 * len(encodeKernelCompact(kernel))) // 5)):
        _encodedKernel = _encodedKernel + [0]

    for k in _encodedKernel:
        eventData <<= 256
        eventData += k

    for k in encodeKernelCompact(kernel):
        eventData <<= 256
        eventData += k

    for k in encodeCurve(curve):
        eventData <<= 256
        eventData += k

    eventData <<= 64

    assert eventData == _eventData

    hookDataPlacement = toInt(hook.preInitializeData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.preInitializeData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.preInitializeData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.postInitializeData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.postInitializeData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.postInitializeData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]