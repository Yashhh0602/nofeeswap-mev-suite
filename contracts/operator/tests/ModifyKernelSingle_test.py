# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, Access, NofeeswapCheatCode, Manipulator, NofeeswapDelegatee, ERC20FixedSupply, MockHook, Operator, Deployer
from sympy import Integer, floor, exp
from eth_abi import encode
from eth_abi.packed import encode_packed
from Nofee import logTest, address0, _hookData_, _msgSender_, _hookDataByteCount_, keccak256, keccakPacked, mintSequence, swapSequence, keccak, toInt, twosComplementInt8, encodeKernelCompact, encodeKernel, encodeCurve, dataGeneration, outgoing, getMaxIntegrals, getPoolId

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    root = accounts[0]
    owner = accounts[1]
    other = accounts[2]
    deployer = Deployer.deploy(root, {'from': root})
    access = Access.deploy({'from': root})
    hook = MockHook.deploy({'from': root})

    delegatee = deployer.addressOf(1)
    nofeeswap = deployer.addressOf(2)
    manipulator = deployer.addressOf(3)
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
        NofeeswapCheatCode.bytecode + encode(
            ['address', 'address'],
            [delegatee, root.address]
        ).hex(), 
        {'from': root}
    )
    deployer.create3(
        3,
        Manipulator.bytecode,
        {'from': root}
    )
    delegatee = NofeeswapDelegatee.at(delegatee)
    nofeeswap = NofeeswapCheatCode.at(nofeeswap)
    manipulator = Manipulator.at(manipulator)
    operator = Operator.deploy(nofeeswap, address0, address0, address0, {'from': root})
    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (123 << 208) + (456 << 160) + int(root.address, 16)
    ), {'from': root})

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**120, root, {'from': root})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**120, root, {'from': root})

    token0.approve(operator, 2**128, {'from': root})
    token1.approve(operator, 2**128, {'from': root})

    if toInt(token0.address) > toInt(token1.address):
        token0, token1 = token1, token0

    return root, owner, other, access, hook, token0, token1, nofeeswap, manipulator, delegatee, operator

@pytest.mark.parametrize('n', range(len(initializations['kernel'])))
def test_modifyKernelOdd(deployment, n, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, access, hook, token0, token1, nofeeswap, manipulator, delegatee, operator = deployment

    kernel = initializations['kernel'][n]
    curve = initializations['curve'][n]
    lower = min(curve[0], curve[1])
    upper = max(curve[0], curve[1])
    spacing = upper - lower
    current = curve[-1]

    tag0 = toInt(token0.address)
    tag1 = toInt(token1.address)

    logOffset = -5
    unsaltedPoolId = (n << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    # initialization
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
          unsaltedPoolId,
          tag0,
          tag1,
          0x800000000000,
          encodeKernelCompact(kernel),
          encodeCurve(curve),
          b"HookData"
      ),
      {'from': owner}
    )

    deadline = 2 ** 32 - 1

    qMin = lower - (1 << 63) + (logOffset * (1 << 59))
    qMax = upper - (1 << 63) + (logOffset * (1 << 59))
    shares = 123456789
    hookData = b"HookData"
    tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

    data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    _integral0 = outgoing(curve, kernel, current, upper)
    _integral1 = outgoing(curve, kernel, lower, current)
    _outgoingMax, _incomingMax = getMaxIntegrals(kernel)

    ##############################

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId, staticParamsStoragePointer)
    kernelArray = list(access._readKernel(nofeeswap, poolId, 0))

    storagePointer = (1 << 16) - 3
    content = encode_packed(
        [
            'uint256',
            'uint256',
            'uint256',
            'uint256',
            'uint64',
            'uint216',
            'uint216',
            'uint216',
            'uint256',
            'uint216',
            'uint48',
            'uint48',
            'uint48',
            'uint16',
            'bytes'
        ],
        [
            tag0,
            tag1,
            sqrtOffset,
            sqrtInverseOffset,
            spacing,
            sqrtSpacing,
            sqrtInverseSpacing,
            outgoingMax,
            outgoingMaxModularInverse,
            incomingMax,
            poolGrowthPortion,
            maxPoolGrowthPortion,
            protocolGrowthPortion,
            pendingKernelLength,
            encode_packed(['uint256'] * len(kernelArray), kernelArray)
        ]
    )

    nofeeswap.callManipulator(
        manipulator,
        manipulator.deploy.encode_input(poolId, len(kernel), storagePointer, content),
        {'from': root}
    )
    nofeeswap.callManipulator(
        manipulator,
        manipulator.manipulate.encode_input(
            keccakPacked(['uint256', 'uint128'], [poolId, (keccak256('dynamicParams') - 1) % (1 << 128)]),
            (storagePointer << (256 - 16)) + (logPriceCurrent << (256 - 16 - 64)) + (sharesTotal << (256 - 16 - 64 - 128)) + (growth >> 80)
        ),
        {'from': root}
    )

    ##############################

    newKernel = [kernel[0], kernel[-1]]
    tx = nofeeswap.dispatch(
      delegatee.modifyKernel.encode_input(
          poolId,
          encodeKernelCompact(newKernel),
          b"HookData"
      ),
      {'from': owner}
    )

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId, staticParamsStoragePointer)
    kernelArray = list(access._readKernel(nofeeswap, poolId, staticParamsStoragePointer))

    assert staticParamsStoragePointerExtension == 0
    assert growth == 1 << 111
    assert abs(integral0 - outgoing(curve, kernel, current, upper)) <= 2 ** 32
    assert abs(integral1 - outgoing(curve, kernel, lower, current)) <= 2 ** 32
    assert sharesTotal == shares
    assert staticParamsStoragePointer == storagePointer + 1
    assert logPriceCurrent == current
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
    assert pendingKernelLength == len(newKernel)

    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId, staticParamsStoragePointer + 1)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId, staticParamsStoragePointer + 1)
    kernelArray = list(access._readKernel(nofeeswap, poolId, staticParamsStoragePointer + 1))

    assert tag0 == min(toInt(token0.address), toInt(token1.address))
    assert tag1 == max(toInt(token0.address), toInt(token1.address))
    assert sqrtOffset == floor((2 ** 127) * exp(Integer(logOffset) / 2))
    assert sqrtInverseOffset == floor((2 ** 127) / exp(Integer(logOffset) / 2))
    assert sqrtSpacing == floor((2 ** 216) * exp(- Integer(spacing) / (2 ** 60)))
    assert sqrtInverseSpacing == floor((2 ** 216) * exp(- 16 + Integer(spacing) / (2 ** 60)))
    assert kernelArray == encodeKernel(newKernel)
    _outgoingMax, _incomingMax = getMaxIntegrals(newKernel)
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

    assert tx.events['ModifyKernel']['poolId'] == poolId
    assert tx.events['ModifyKernel']['caller'] == owner.address

    _eventData = toInt(tx.events['ModifyKernel']['data'].hex())

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

    _encodedKernel = encodeKernel(newKernel)
    for k in range(len(_encodedKernel), ((32 * len(encodeKernelCompact(newKernel))) // 5)):
        _encodedKernel = _encodedKernel + [0]

    for k in _encodedKernel:
        eventData <<= 256
        eventData += k

    for k in encodeKernelCompact(newKernel):
        eventData <<= 256
        eventData += k

    assert eventData == _eventData

    hookDataPlacement = toInt(hook.preModifyKernelData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.preModifyKernelData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.preModifyKernelData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.midModifyKernelData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.midModifyKernelData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.midModifyKernelData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.postModifyKernelData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.postModifyKernelData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.postModifyKernelData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    ##############################

    amountSpecified = - (1 << 120)
    limit = upper + 1 - (1 << 63) + (logOffset * (1 << 59))
    zeroForOne = 2

    data = swapSequence(nofeeswap, token0, token1, root, poolId, amountSpecified, limit, zeroForOne, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId, staticParamsStoragePointer)
    kernelArray = list(access._readKernel(nofeeswap, poolId, staticParamsStoragePointer))

    assert staticParamsStoragePointerExtension == (1 << 16) - 1
    assert staticParamsStoragePointer == (1 << 16) - 1
    assert tag0 == min(toInt(token0.address), toInt(token1.address))
    assert tag1 == max(toInt(token0.address), toInt(token1.address))
    assert sqrtOffset == floor((2 ** 127) * exp(Integer(logOffset) / 2))
    assert sqrtInverseOffset == floor((2 ** 127) / exp(Integer(logOffset) / 2))
    assert sqrtSpacing == floor((2 ** 216) * exp(- Integer(spacing) / (2 ** 60)))
    assert sqrtInverseSpacing == floor((2 ** 216) * exp(- 16 + Integer(spacing) / (2 ** 60)))
    assert kernelArray == encodeKernel(newKernel)
    _outgoingMax, _incomingMax = getMaxIntegrals(newKernel)
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

@pytest.mark.parametrize('n', range(len(initializations['kernel'])))
def test_modifyKernelEven(deployment, n, request, worker_id):
    logTest(request, worker_id)
    
    root, owner, other, access, hook, token0, token1, nofeeswap, manipulator, delegatee, operator = deployment

    kernel = initializations['kernel'][n]
    curve = initializations['curve'][n]
    lower = min(curve[0], curve[1])
    upper = max(curve[0], curve[1])
    spacing = upper - lower
    current = curve[-1]

    tag0 = toInt(token0.address)
    tag1 = toInt(token1.address)

    logOffset = -5
    unsaltedPoolId = (n << 188) + (twosComplementInt8(logOffset) << 180) + (0b11111111111111111111 << 160) + toInt(hook.address)
    poolId = getPoolId(owner.address, unsaltedPoolId)

    # initialization
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
          unsaltedPoolId,
          tag0,
          tag1,
          0x800000000000,
          encodeKernelCompact(kernel),
          encodeCurve(curve),
          b"HookData"
      ),
      {'from': owner}
    )

    deadline = 2 ** 32 - 1

    qMin = lower - (1 << 63) + (logOffset * (1 << 59))
    qMax = upper - (1 << 63) + (logOffset * (1 << 59))
    shares = 123456789
    hookData = b"HookData"
    tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

    data = mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    _integral0 = outgoing(curve, kernel, current, upper)
    _integral1 = outgoing(curve, kernel, lower, current)
    _outgoingMax, _incomingMax = getMaxIntegrals(kernel)

    ##############################

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId, staticParamsStoragePointer)
    kernelArray = list(access._readKernel(nofeeswap, poolId, 0))

    storagePointer = (1 << 16) - 2
    content = encode_packed(
        [
            'uint256',
            'uint256',
            'uint256',
            'uint256',
            'uint64',
            'uint216',
            'uint216',
            'uint216',
            'uint256',
            'uint216',
            'uint48',
            'uint48',
            'uint48',
            'uint16',
            'bytes'
        ],
        [
            tag0,
            tag1,
            sqrtOffset,
            sqrtInverseOffset,
            spacing,
            sqrtSpacing,
            sqrtInverseSpacing,
            outgoingMax,
            outgoingMaxModularInverse,
            incomingMax,
            poolGrowthPortion,
            maxPoolGrowthPortion,
            protocolGrowthPortion,
            pendingKernelLength,
            encode_packed(['uint256'] * len(kernelArray), kernelArray)
        ]
    )

    nofeeswap.callManipulator(
        manipulator,
        manipulator.deploy.encode_input(poolId, len(kernel), storagePointer, content),
        {'from': root}
    )
    nofeeswap.callManipulator(
        manipulator,
        manipulator.manipulate.encode_input(
            keccakPacked(['uint256', 'uint128'], [poolId, (keccak256('dynamicParams') - 1) % (1 << 128)]),
            (storagePointer << (256 - 16)) + (logPriceCurrent << (256 - 16 - 64)) + (sharesTotal << (256 - 16 - 64 - 128)) + (growth >> 80)
        ),
        {'from': root}
    )

    ##############################

    newKernel = [kernel[0], kernel[-1]]
    tx = nofeeswap.dispatch(
      delegatee.modifyKernel.encode_input(
          poolId,
          encodeKernelCompact(newKernel),
          b"HookData"
      ),
      {'from': owner}
    )

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId, staticParamsStoragePointer)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId, staticParamsStoragePointer)
    kernelArray = list(access._readKernel(nofeeswap, poolId, staticParamsStoragePointer))

    assert staticParamsStoragePointerExtension == (1 << 16) - 1
    assert growth == 1 << 111
    assert abs(integral0 - outgoing(curve, kernel, current, upper)) <= 2 ** 32
    assert abs(integral1 - outgoing(curve, kernel, lower, current)) <= 2 ** 32
    assert sharesTotal == shares
    assert staticParamsStoragePointer == storagePointer + 1
    assert logPriceCurrent == current
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
    assert pendingKernelLength == len(newKernel)

    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId, staticParamsStoragePointer + 1)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId, staticParamsStoragePointer + 1)
    kernelArray = list(access._readKernel(nofeeswap, poolId, staticParamsStoragePointer + 1))

    assert tag0 == min(toInt(token0.address), toInt(token1.address))
    assert tag1 == max(toInt(token0.address), toInt(token1.address))
    assert sqrtOffset == floor((2 ** 127) * exp(Integer(logOffset) / 2))
    assert sqrtInverseOffset == floor((2 ** 127) / exp(Integer(logOffset) / 2))
    assert sqrtSpacing == floor((2 ** 216) * exp(- Integer(spacing) / (2 ** 60)))
    assert sqrtInverseSpacing == floor((2 ** 216) * exp(- 16 + Integer(spacing) / (2 ** 60)))
    assert kernelArray == encodeKernel(newKernel)
    _outgoingMax, _incomingMax = getMaxIntegrals(newKernel)
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

    assert tx.events['ModifyKernel']['poolId'] == poolId
    assert tx.events['ModifyKernel']['caller'] == owner.address

    _eventData = toInt(tx.events['ModifyKernel']['data'].hex())

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

    _encodedKernel = encodeKernel(newKernel)
    for k in range(len(_encodedKernel), ((32 * len(encodeKernelCompact(newKernel))) // 5)):
        _encodedKernel = _encodedKernel + [0]

    for k in _encodedKernel:
        eventData <<= 256
        eventData += k

    for k in encodeKernelCompact(newKernel):
        eventData <<= 256
        eventData += k

    assert eventData == _eventData

    hookDataPlacement = toInt(hook.preModifyKernelData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.preModifyKernelData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.preModifyKernelData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.midModifyKernelData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.midModifyKernelData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.midModifyKernelData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    hookDataPlacement = toInt(hook.postModifyKernelData()[_hookData_ - _msgSender_ : _hookData_ - _msgSender_ + 32].hex()) - _msgSender_
    hookDataByteCount = toInt(hook.postModifyKernelData()[_hookDataByteCount_ - _msgSender_ : _hookDataByteCount_ - _msgSender_ + 2].hex())
    assert hookData == hook.postModifyKernelData()[hookDataPlacement : hookDataPlacement + hookDataByteCount]

    ##############################

    amountSpecified = - (1 << 120)
    limit = upper + 1 - (1 << 63) + (logOffset * (1 << 59))
    zeroForOne = 2

    data = swapSequence(nofeeswap, token0, token1, root, poolId, amountSpecified, limit, zeroForOne, hookData, deadline)
    tx = nofeeswap.unlock(operator, data, {'from': root})

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    tag0, tag1, sqrtOffset, sqrtInverseOffset, sqrtSpacing, sqrtInverseSpacing = access._readStaticParams0(nofeeswap, poolId, staticParamsStoragePointerExtension)
    outgoingMax, outgoingMaxModularInverse, incomingMax, poolGrowthPortion, maxPoolGrowthPortion, protocolGrowthPortion, pendingKernelLength = access._readStaticParams1(nofeeswap, poolId, staticParamsStoragePointerExtension)
    kernelArray = list(access._readKernel(nofeeswap, poolId, staticParamsStoragePointerExtension))

    assert staticParamsStoragePointerExtension == (1 << 16)
    assert staticParamsStoragePointer == (1 << 16) - 1
    assert tag0 == min(toInt(token0.address), toInt(token1.address))
    assert tag1 == max(toInt(token0.address), toInt(token1.address))
    assert sqrtOffset == floor((2 ** 127) * exp(Integer(logOffset) / 2))
    assert sqrtInverseOffset == floor((2 ** 127) / exp(Integer(logOffset) / 2))
    assert sqrtSpacing == floor((2 ** 216) * exp(- Integer(spacing) / (2 ** 60)))
    assert sqrtInverseSpacing == floor((2 ** 216) * exp(- 16 + Integer(spacing) / (2 ** 60)))
    assert kernelArray == encodeKernel(newKernel)
    _outgoingMax, _incomingMax = getMaxIntegrals(newKernel)
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
