# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, CalldataWrapper
from sympy import Integer, floor, exp
from eth_abi import encode
from Nofee import logTest, _swapInput_, _shares_, _hookData_, _hookDataByteCount_, _hookInputByteCount_, _freeMemoryPointer_, _msgSender_, _poolId_, _tag0_, _tag1_, _sqrtOffset_, _sqrtInverseOffset_, _poolGrowthPortion_, _kernel_, _endOfStaticParams_, _curve_, toInt, twosComplementInt8, twosComplement, encodeCurve, encodeKernelCompact, getPoolId
from Tag_test import tag2, tag3

maxCurveIndex = 0xFFFF
maxKernelIndex = 1020
maxHookDataByteCount = 0xFFFF

zeroForOne0 = 0
zeroForOne1 = 1
zeroForOne2 = 2
zeroForOne3 = 3
zeroForOne4 = 4

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

portion0 = 0x000000000000
portion1 = 0x400000000000
portion2 = 0x800000000000
portion3 = 0xFFFFFFFFFFFF

balance0 = 0x00000000000000000000000000000000
balance1 = 0x00000000000000000000000000000001
balance2 = 0xF00FF00FF00FF00FF00FF00FF00FF00F
balance3 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance5 = 0 - 0x00000000000000000000000000000001
balance6 = 0 - 0xF00FF00FF00FF00FF00FF00FF00FF00F
balance7 = 0 - 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
balance8 = 0 - 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

logPrice0 = 0x0000000000000000
logPrice1 = 0x0000000000000001
logPrice2 = 0xF00FF00FF00FF00F
logPrice3 = 0x8FFFFFFFFFFFFFFF
logPrice4 = 0xFFFFFFFFFFFFFFFF
logPrice5 = 0x10000000000000000

poolId0 = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(-89) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
poolId1 = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(-8 ) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
poolId2 = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(+0 ) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
poolId3 = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(+8 ) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
poolId4 = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(+89) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F

poolId0Invalid = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(-90) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
poolId1Invalid = (0xF0F0F0F0F0F0F0F0F << 188) + (twosComplementInt8(+90) << 180) + 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return CalldataWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('poolId', [poolId0Invalid, poolId1Invalid])
@pytest.mark.parametrize('_tag0', [tag2])
@pytest.mark.parametrize('_tag1', [tag3])
@pytest.mark.parametrize('portion', [portion0])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('kernelLength', [2])
@pytest.mark.parametrize('curveLength', [2])
@pytest.mark.parametrize('hookDataByteCount', [maxHookDataByteCount // 2])
def test_readInitializeInvalidOffset(wrapper, poolId, _tag0, _tag1, portion, content, kernelLength, curveLength, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    qOffset = (poolId >> 180) & 0xFF
    if qOffset >= 128:
        qOffset -= 256

    kernelCompactArray = encodeKernelCompact([[content >> 192, content >> 240]] * kernelLength)
    curveArray = encodeCurve([content >> 192] * curveLength)

    kernelCompactBytes = encode(['uint256[]'], [kernelCompactArray])[32:]
    curveBytes = encode(['uint256[]'], [curveArray])[32:]
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfKernelCompact = 7 * 0x20 + gap
    startOfCurve = startOfKernelCompact + len(kernelCompactBytes) + gap
    startOfHookData = startOfCurve + len(curveBytes) + gap

    calldata = wrapper._readInitializeInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        _tag0.to_bytes(32, 'big').hex() + \
        _tag1.to_bytes(32, 'big').hex() + \
        portion.to_bytes(32, 'big').hex() + \
        startOfKernelCompact.to_bytes(32, 'big').hex() + \
        startOfCurve.to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        kernelCompactBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        curveBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('LogOffsetOutOfRange: ' + str(qOffset * (1 << 59))):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('_tag0', [tag3])
@pytest.mark.parametrize('_tag1', [tag2])
@pytest.mark.parametrize('portion', [portion0])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('kernelLength', [2])
@pytest.mark.parametrize('curveLength', [2])
@pytest.mark.parametrize('hookDataByteCount', [maxHookDataByteCount // 2])
def test_readInitializeInputTagsOutOfOrder(wrapper, poolId, _tag0, _tag1, portion, content, kernelLength, curveLength, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    kernelCompactArray = encodeKernelCompact([[content >> 192, content >> 240]] * kernelLength)
    curveArray = encodeCurve([content >> 192] * curveLength)

    kernelCompactBytes = encode(['uint256[]'], [kernelCompactArray])[32:]
    curveBytes = encode(['uint256[]'], [curveArray])[32:]
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfKernelCompact = 7 * 0x20 + gap
    startOfCurve = startOfKernelCompact + len(kernelCompactBytes) + gap
    startOfHookData = startOfCurve + len(curveBytes) + gap

    calldata = wrapper._readInitializeInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        _tag0.to_bytes(32, 'big').hex() + \
        _tag1.to_bytes(32, 'big').hex() + \
        portion.to_bytes(32, 'big').hex() + \
        startOfKernelCompact.to_bytes(32, 'big').hex() + \
        startOfCurve.to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        kernelCompactBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        curveBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('TagsOutOfOrder: ' + str(_tag0) + ', ' + str(_tag1)):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('_tag0', [tag2])
@pytest.mark.parametrize('_tag1', [tag3])
@pytest.mark.parametrize('portion', [portion3])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('kernelLength', [2])
@pytest.mark.parametrize('curveLength', [2])
@pytest.mark.parametrize('hookDataByteCount', [maxHookDataByteCount // 2])
def test_readInitializeInputInvalidPortion(wrapper, poolId, _tag0, _tag1, portion, content, kernelLength, curveLength, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    kernelCompactArray = encodeKernelCompact([[content >> 192, content >> 240]] * kernelLength)
    curveArray = encodeCurve([content >> 192] * curveLength)

    kernelCompactBytes = encode(['uint256[]'], [kernelCompactArray])[32:]
    curveBytes = encode(['uint256[]'], [curveArray])[32:]
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfKernelCompact = 7 * 0x20 + gap
    startOfCurve = startOfKernelCompact + len(kernelCompactBytes) + gap
    startOfHookData = startOfCurve + len(curveBytes) + gap

    calldata = wrapper._readInitializeInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        _tag0.to_bytes(32, 'big').hex() + \
        _tag1.to_bytes(32, 'big').hex() + \
        portion.to_bytes(32, 'big').hex() + \
        startOfKernelCompact.to_bytes(32, 'big').hex() + \
        startOfCurve.to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        kernelCompactBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        curveBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('InvalidGrowthPortion: ' + str(portion)):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('_tag0', [tag2])
@pytest.mark.parametrize('_tag1', [tag3])
@pytest.mark.parametrize('portion', [portion0])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('kernelLength', [2])
@pytest.mark.parametrize('curveLength', [0])
@pytest.mark.parametrize('hookDataByteCount', [maxHookDataByteCount // 2])
def test_readInitializeInputCurveZero(wrapper, poolId, _tag0, _tag1, portion, content, kernelLength, curveLength, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    kernelCompactArray = encodeKernelCompact([[content >> 192, content >> 240]] * kernelLength)
    curveArray = encodeCurve([content >> 192] * curveLength)

    kernelCompactBytes = encode(['uint256[]'], [kernelCompactArray])[32:]
    curveBytes = encode(['uint256[]'], [curveArray])[32:]
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfKernelCompact = 7 * 0x20 + gap
    startOfCurve = startOfKernelCompact + len(kernelCompactBytes) + gap
    startOfHookData = startOfCurve + len(curveBytes) + gap

    calldata = wrapper._readInitializeInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        _tag0.to_bytes(32, 'big').hex() + \
        _tag1.to_bytes(32, 'big').hex() + \
        portion.to_bytes(32, 'big').hex() + \
        startOfKernelCompact.to_bytes(32, 'big').hex() + \
        startOfCurve.to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        kernelCompactBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        curveBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('CurveLengthIsZero: '):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('_tag0', [tag2])
@pytest.mark.parametrize('_tag1', [tag3])
@pytest.mark.parametrize('portion', [portion0])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('kernelLength', [2])
@pytest.mark.parametrize('curveLength', [2])
@pytest.mark.parametrize('hookDataByteCount', [maxHookDataByteCount + 1])
def test_readInitializeInputLongHookData(wrapper, poolId, _tag0, _tag1, portion, content, kernelLength, curveLength, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    kernelCompactArray = encodeKernelCompact([[content >> 192, content >> 240]] * kernelLength)
    curveArray = encodeCurve([content >> 192] * curveLength)

    kernelCompactBytes = encode(['uint256[]'], [kernelCompactArray])[32:]
    curveBytes = encode(['uint256[]'], [curveArray])[32:]
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfKernelCompact = 7 * 0x20 + gap
    startOfCurve = startOfKernelCompact + len(kernelCompactBytes) + gap
    startOfHookData = startOfCurve + len(curveBytes) + gap

    calldata = wrapper._readInitializeInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        _tag0.to_bytes(32, 'big').hex() + \
        _tag1.to_bytes(32, 'big').hex() + \
        portion.to_bytes(32, 'big').hex() + \
        startOfKernelCompact.to_bytes(32, 'big').hex() + \
        startOfCurve.to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        kernelCompactBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        curveBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('HookDataTooLong: ' + str(hookDataByteCount)):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2, poolId3, poolId4])
@pytest.mark.parametrize('_tag0', [tag2])
@pytest.mark.parametrize('_tag1', [tag3])
@pytest.mark.parametrize('portion', [portion0, portion1, portion2])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('kernelLength', [2, maxKernelIndex // 2, maxKernelIndex])
@pytest.mark.parametrize('curveLength', [2, maxCurveIndex // 2, maxCurveIndex])
@pytest.mark.parametrize('hookDataByteCount', [0, maxHookDataByteCount // 2, maxHookDataByteCount])
def test_readInitializeInput(wrapper, poolId, _tag0, _tag1, portion, content, kernelLength, curveLength, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    qOffset = (poolId >> 180) & 0xFF
    if qOffset >= 128:
        qOffset -= 256

    kernelCompactArray = encodeKernelCompact([[content >> 192, content >> 240]] * kernelLength)
    curveArray = encodeCurve([content >> 192] * curveLength)

    kernelCompactBytes = encode(['uint256[]'], [kernelCompactArray])[32:]
    curveBytes = encode(['uint256[]'], [curveArray])[32:]
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfKernelCompact = 7 * 0x20 + gap
    startOfCurve = startOfKernelCompact + len(kernelCompactBytes) + gap
    startOfHookData = startOfCurve + len(curveBytes) + gap

    calldata = wrapper._readInitializeInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        _tag0.to_bytes(32, 'big').hex() + \
        _tag1.to_bytes(32, 'big').hex() + \
        portion.to_bytes(32, 'big').hex() + \
        startOfKernelCompact.to_bytes(32, 'big').hex() + \
        startOfCurve.to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        kernelCompactBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        curveBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    tx = root.transfer(
        to=wrapper.address,
        gas_price=0,
        data=calldata
    )

    kernelCompact = tx.return_value
    memoryContent = tx.events[0]['data']

    assert memoryContent[_msgSender_ : _msgSender_ + 20].hex() == root.address.lower()[2:]
    assert toInt(memoryContent[_poolId_ : _poolId_ + 32].hex()) == getPoolId(root.address, poolId)
    assert toInt(memoryContent[_tag0_ : _tag0_ + 32].hex()) == _tag0
    assert toInt(memoryContent[_tag1_ : _tag1_ + 32].hex()) == _tag1
    assert toInt(memoryContent[_sqrtOffset_ : _sqrtOffset_ + 32].hex()) == floor((1 << 127)*exp( + Integer(qOffset) / 2))
    assert toInt(memoryContent[_sqrtInverseOffset_ : _sqrtInverseOffset_ + 32].hex()) == floor((1 << 127)*exp( - Integer(qOffset) / 2))
    assert toInt(memoryContent[_poolGrowthPortion_ : _poolGrowthPortion_ + 6].hex()) == portion

    kernelCompactByteCount = len(kernelCompactArray) << 5
    kernelByteCount = ((kernelCompactByteCount // 5) << 5)
    curveByteCount = len(curveArray) << 5
    hookDataByteCount = len(hookDataBytes) - 32
    hookInputByteCount = _endOfStaticParams_ + kernelByteCount + kernelCompactByteCount + curveByteCount + 8 + hookDataByteCount - _hookInputByteCount_ - 32

    kernelPlacement = _endOfStaticParams_
    kernelCompactPlacement = kernelPlacement + kernelByteCount
    curvePlacement = kernelCompact + kernelCompactByteCount
    hookDataPlacement = curvePlacement + curveByteCount + 8
    freeMemoryPointer = hookDataPlacement + hookDataByteCount

    assert toInt(memoryContent[_kernel_ : _kernel_ + 32].hex()) == kernelPlacement
    assert kernelCompact == kernelCompactPlacement
    assert toInt(memoryContent[_curve_ : _curve_ + 32].hex()) == curvePlacement
    assert toInt(memoryContent[_hookData_ : _hookData_ + 32].hex()) == hookDataPlacement
    assert toInt(memoryContent[_freeMemoryPointer_ : _freeMemoryPointer_ + 32].hex()) == freeMemoryPointer

    assert toInt(memoryContent[_hookDataByteCount_ : _hookDataByteCount_ + 2].hex()) == hookDataByteCount
    assert toInt(memoryContent[_hookInputByteCount_ : _hookInputByteCount_ + 32].hex()) == hookInputByteCount

    assert memoryContent[kernelCompactPlacement : kernelCompactPlacement + kernelCompactByteCount] == kernelCompactBytes[32:]
    assert memoryContent[curvePlacement : curvePlacement + curveByteCount] == curveBytes[32:]
    assert memoryContent[hookDataPlacement : hookDataPlacement + hookDataByteCount] == hookDataBytes[32:]

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('qMin', [logPrice0, logPrice5])
@pytest.mark.parametrize('qMax', [logPrice0, logPrice5])
@pytest.mark.parametrize('shares', [balance1])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('hookDataByteCount', [2])
def test_readModifyPositionInputInvalidLogPrices(wrapper, poolId, qMin, qMax, shares, content, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    qOffset = (poolId >> 180) & 0xFF
    if qOffset >= 128:
        qOffset -= 256

    logPriceMin = qMin + (qOffset * (1 << 59)) - (1 << 63)
    logPriceMax = qMax + (qOffset * (1 << 59)) - (1 << 63)
    
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfHookData = 5 * 0x20 + gap

    calldata = wrapper._readModifyPositionInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        twosComplement(logPriceMin).to_bytes(32, 'big').hex() + \
        twosComplement(logPriceMax).to_bytes(32, 'big').hex() + \
        twosComplement(shares).to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    if qMin <= 0 or qMin >= (1 << 64):
        with brownie.reverts('LogPriceOutOfRange: ' + str(logPriceMin)):
            tx = root.transfer(
                to=wrapper.address,
                gas_price=0,
                data=calldata
            )
    elif qMax <= 0 or qMax >= (1 << 64):
        with brownie.reverts('LogPriceOutOfRange: ' + str(logPriceMax)):
            tx = root.transfer(
                to=wrapper.address,
                gas_price=0,
                data=calldata
            )

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('qMin', [logPrice1])
@pytest.mark.parametrize('qMax', [logPrice2])
@pytest.mark.parametrize('shares', [balance0, balance2, balance4, balance6, balance8])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('hookDataByteCount', [2])
def test_readModifyPositionInputInvalidShares(wrapper, poolId, qMin, qMax, shares, content, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    qOffset = (poolId >> 180) & 0xFF
    if qOffset >= 128:
        qOffset -= 256

    logPriceMin = qMin + (qOffset * (1 << 59)) - (1 << 63)
    logPriceMax = qMax + (qOffset * (1 << 59)) - (1 << 63)
    
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfHookData = 5 * 0x20 + gap

    calldata = wrapper._readModifyPositionInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        twosComplement(logPriceMin).to_bytes(32, 'big').hex() + \
        twosComplement(logPriceMax).to_bytes(32, 'big').hex() + \
        twosComplement(shares).to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('InvalidNumberOfShares: ' + str(shares)):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('qMin', [logPrice1])
@pytest.mark.parametrize('qMax', [logPrice2])
@pytest.mark.parametrize('shares', [balance1])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('hookDataByteCount', [maxHookDataByteCount + 1])
def test_readModifyPositionInputHookDataTooLong(wrapper, poolId, qMin, qMax, shares, content, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    qOffset = (poolId >> 180) & 0xFF
    if qOffset >= 128:
        qOffset -= 256

    logPriceMin = qMin + (qOffset * (1 << 59)) - (1 << 63)
    logPriceMax = qMax + (qOffset * (1 << 59)) - (1 << 63)
    
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfHookData = 5 * 0x20 + gap

    calldata = wrapper._readModifyPositionInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        twosComplement(logPriceMin).to_bytes(32, 'big').hex() + \
        twosComplement(logPriceMax).to_bytes(32, 'big').hex() + \
        twosComplement(shares).to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('HookDataTooLong: ' + str(hookDataByteCount)):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('shares', [balance0, balance2, balance4, balance6, balance8])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('hookDataByteCount', [2])
def test_readDonateInputInvalidShares(wrapper, poolId, shares, content, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    qOffset = (poolId >> 180) & 0xFF
    if qOffset >= 128:
        qOffset -= 256
    
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfHookData = 3 * 0x20 + gap

    calldata = wrapper._readDonateInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        twosComplement(shares).to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('InvalidNumberOfShares: ' + str(shares)):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('shares', [balance1])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('hookDataByteCount', [maxHookDataByteCount + 1])
def test_readDonateInputHookDataTooLong(wrapper, poolId, shares, content, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    qOffset = (poolId >> 180) & 0xFF
    if qOffset >= 128:
        qOffset -= 256
    
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfHookData = 3 * 0x20 + gap

    calldata = wrapper._readDonateInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        twosComplement(shares).to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('HookDataTooLong: ' + str(hookDataByteCount)):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2, poolId3, poolId4])
@pytest.mark.parametrize('shares', [balance1, balance3])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('hookDataByteCount', [0, maxHookDataByteCount // 2, maxHookDataByteCount])
def test_readDonateInput(wrapper, poolId, shares, content, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]
    
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfHookData = 3 * 0x20 + gap

    calldata = wrapper._readDonateInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        twosComplement(shares).to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    tx = root.transfer(
        to=wrapper.address,
        gas_price=0,
        data=calldata
    )

    memoryContent = tx.events[0]['data']

    assert memoryContent[_msgSender_ : _msgSender_ + 20].hex() == root.address.lower()[2:]
    assert toInt(memoryContent[_poolId_ : _poolId_ + 32].hex()) == poolId
    assert toInt(memoryContent[_shares_ : _shares_ + 32].hex()) == twosComplement(shares)

    hookDataByteCount = len(hookDataBytes) - 32
    hookInputByteCount = _endOfStaticParams_ + 32 + hookDataByteCount - _hookInputByteCount_ - 32

    curvePlacement = _endOfStaticParams_
    hookDataPlacement = curvePlacement + 32
    freeMemoryPointer = hookDataPlacement + hookDataByteCount

    assert toInt(memoryContent[_curve_ : _curve_ + 32].hex()) == curvePlacement
    assert toInt(memoryContent[_hookData_ : _hookData_ + 32].hex()) == hookDataPlacement
    assert toInt(memoryContent[_freeMemoryPointer_ : _freeMemoryPointer_ + 32].hex()) == freeMemoryPointer

    assert toInt(memoryContent[_hookDataByteCount_ : _hookDataByteCount_ + 2].hex()) == hookDataByteCount
    assert toInt(memoryContent[_hookInputByteCount_ : _hookInputByteCount_ + 32].hex()) == hookInputByteCount

    assert memoryContent[hookDataPlacement : hookDataPlacement + hookDataByteCount] == hookDataBytes[32:]

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('content', [value2])
@pytest.mark.parametrize('kernelLength', [2])
@pytest.mark.parametrize('hookDataByteCount', [maxHookDataByteCount + 1])
def test_readModifyKernelInputLongHookData(wrapper, poolId, content, kernelLength, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    kernelCompactArray = encodeKernelCompact([[content >> 192, content >> 240]] * kernelLength)
    kernelCompactBytes = encode(['uint256[]'], [kernelCompactArray])[32:]
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfKernelCompact = 3 * 0x20 + gap
    startOfHookData = startOfKernelCompact + len(kernelCompactBytes) + gap

    calldata = wrapper._readModifyKernelInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        startOfKernelCompact.to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        kernelCompactBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('HookDataTooLong: ' + str(hookDataByteCount)):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2, poolId3, poolId4])
@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('kernelLength', [2, maxKernelIndex // 2, maxKernelIndex])
@pytest.mark.parametrize('hookDataByteCount', [0, maxHookDataByteCount // 2, maxHookDataByteCount])
def test_readModifyKernelInputInput(wrapper, poolId, content, kernelLength, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    kernelCompactArray = encodeKernelCompact([[content >> 192, content >> 240]] * kernelLength)
    kernelCompactBytes = encode(['uint256[]'], [kernelCompactArray])[32:]
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfKernelCompact = 3 * 0x20 + gap
    startOfHookData = startOfKernelCompact + len(kernelCompactBytes) + gap

    calldata = wrapper._readModifyKernelInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        startOfKernelCompact.to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        kernelCompactBytes.hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    tx = root.transfer(
        to=wrapper.address,
        gas_price=0,
        data=calldata
    )

    kernelCompact = tx.return_value
    memoryContent = tx.events[0]['data']

    assert memoryContent[_msgSender_ : _msgSender_ + 20].hex() == root.address.lower()[2:]
    assert toInt(memoryContent[_poolId_ : _poolId_ + 32].hex()) == poolId

    kernelCompactByteCount = len(kernelCompactArray) << 5
    kernelByteCount = ((kernelCompactByteCount // 5) << 5)
    hookDataByteCount = len(hookDataBytes) - 32
    hookInputByteCount = _endOfStaticParams_ + kernelByteCount + kernelCompactByteCount + hookDataByteCount - _hookInputByteCount_ - 32

    kernelPlacement = _endOfStaticParams_
    kernelCompactPlacement = kernelPlacement + kernelByteCount
    hookDataPlacement = kernelCompact + kernelCompactByteCount
    freeMemoryPointer = hookDataPlacement + hookDataByteCount

    assert toInt(memoryContent[_kernel_ : _kernel_ + 32].hex()) == kernelPlacement
    assert kernelCompact == kernelCompactPlacement
    assert toInt(memoryContent[_hookData_ : _hookData_ + 32].hex()) == hookDataPlacement
    assert toInt(memoryContent[_freeMemoryPointer_ : _freeMemoryPointer_ + 32].hex()) == freeMemoryPointer

    assert toInt(memoryContent[_hookDataByteCount_ : _hookDataByteCount_ + 2].hex()) == hookDataByteCount
    assert toInt(memoryContent[_hookInputByteCount_ : _hookInputByteCount_ + 32].hex()) == hookInputByteCount

    assert memoryContent[kernelCompactPlacement : kernelCompactPlacement + kernelCompactByteCount] == kernelCompactBytes[32:]
    assert memoryContent[hookDataPlacement : hookDataPlacement + hookDataByteCount] == hookDataBytes[32:]

@pytest.mark.parametrize('poolId', [poolId1])
@pytest.mark.parametrize('portion', [portion3])
def test_readModifyPoolGrowthPortionInputInvalid(wrapper, poolId, portion, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    calldata = wrapper._readModifyPoolGrowthPortionInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        portion.to_bytes(32, 'big').hex()

    with brownie.reverts('InvalidGrowthPortion: ' + str(portion3)):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2, poolId3, poolId4])
@pytest.mark.parametrize('portion', [portion0, portion1, portion2])
def test_readModifyPoolGrowthPortionInput(wrapper, poolId, portion, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    calldata = wrapper._readModifyPoolGrowthPortionInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        portion.to_bytes(32, 'big').hex()

    tx = root.transfer(
        to=wrapper.address,
        gas_price=0,
        data=calldata
    )

    memoryContent = tx.events[0]['data']

    assert memoryContent[_msgSender_ : _msgSender_ + 20].hex() == root.address.lower()[2:]
    assert toInt(memoryContent[_poolId_ : _poolId_ + 32].hex()) == poolId
    assert toInt(memoryContent[_poolGrowthPortion_ : _poolGrowthPortion_ + 6].hex()) == portion

    hookInputByteCount = _endOfStaticParams_ - _hookInputByteCount_ - 32

    freeMemoryPointer = _endOfStaticParams_

    assert toInt(memoryContent[_freeMemoryPointer_ : _freeMemoryPointer_ + 32].hex()) == freeMemoryPointer
    assert toInt(memoryContent[_hookInputByteCount_ : _hookInputByteCount_ + 32].hex()) == hookInputByteCount

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2, poolId3, poolId4])
def test_readUpdateGrowthPortionsInput(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    calldata = wrapper._readUpdateGrowthPortionsInput.signature + \
        poolId.to_bytes(32, 'big').hex()

    tx = root.transfer(
        to=wrapper.address,
        gas_price=0,
        data=calldata
    )

    memoryContent = tx.events[0]['data']

    assert toInt(memoryContent[_poolId_ : _poolId_ + 32].hex()) == poolId

    hookInputByteCount = _endOfStaticParams_ - _hookInputByteCount_ - 32

    freeMemoryPointer = _endOfStaticParams_

    assert toInt(memoryContent[_freeMemoryPointer_ : _freeMemoryPointer_ + 32].hex()) == freeMemoryPointer
    assert toInt(memoryContent[_hookInputByteCount_ : _hookInputByteCount_ + 32].hex()) == hookInputByteCount

@pytest.mark.parametrize('poolId', [poolId0])
@pytest.mark.parametrize('amountSpecified', [balance1])
@pytest.mark.parametrize('qLimit', [logPrice1])
@pytest.mark.parametrize('zeroForOne', [zeroForOne1])
@pytest.mark.parametrize('crossThreshold', [balance1])
@pytest.mark.parametrize('content', [value1])
@pytest.mark.parametrize('hookDataByteCount', [maxHookDataByteCount + 1])
def test_readSwapInputHookDataTooLong(wrapper, poolId, amountSpecified, qLimit, zeroForOne, crossThreshold, content, hookDataByteCount, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    qOffset = (poolId >> 180) & 0xFF
    if qOffset >= 128:
        qOffset -= 256

    logPriceLimit = qLimit + (qOffset * (1 << 59)) - (1 << 63)
    
    hookDataBytes = encode(['uint256'] * (hookDataByteCount + 1), [hookDataByteCount] + [content] * hookDataByteCount)[0 : hookDataByteCount + 32]

    gap = 100

    startOfHookData = 5 * 0x20 + gap

    calldata = wrapper._readSwapInput.signature + \
        poolId.to_bytes(32, 'big').hex() + \
        twosComplement(amountSpecified).to_bytes(32, 'big').hex() + \
        twosComplement(logPriceLimit).to_bytes(32, 'big').hex() + \
        twosComplement((crossThreshold << 128) + zeroForOne).to_bytes(32, 'big').hex() + \
        startOfHookData.to_bytes(32, 'big').hex() + \
        (0).to_bytes(gap, 'big').hex() + \
        hookDataBytes.hex()

    with brownie.reverts('HookDataTooLong: ' + str(hookDataByteCount)):
        tx = root.transfer(
            to=wrapper.address,
            gas_price=0,
            data=calldata
        )

@pytest.mark.parametrize('poolId', [poolId0, poolId1, poolId2, poolId3, poolId4])
def test_readCollectInput(wrapper, poolId, request, worker_id):
    logTest(request, worker_id)
    
    root = accounts[0]

    calldata = wrapper._readCollectInput.signature + \
        poolId.to_bytes(32, 'big').hex()

    tx = root.transfer(
        to=wrapper.address,
        gas_price=0,
        data=calldata
    )

    memoryContent = tx.events[0]['data']

    assert toInt(memoryContent[_poolId_ : _poolId_ + 32].hex()) == poolId

    freeMemoryPointer = _swapInput_

    assert toInt(memoryContent[_freeMemoryPointer_ : _freeMemoryPointer_ + 32].hex()) == freeMemoryPointer