# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
import brownie
from brownie import accounts, KernelCompactWrapper
from eth_abi.packed import encode_packed
from Nofee import logTest, _kernelLength_, minLogStep, toInt, dataGeneration, encodeKernel, encodeKernelCompact
from X15_test import oneX15

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

maxKernelIndex = 0xFFF

value0 = 0x0000000000000000000000000000000000000000000000000000000000000000
value1 = 0x0000000000000000000000000000000000000000000000000000000000000001
value2 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F
value3 = 0x8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
value4 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

logPrice0 = 0x0000000000000000
logPrice1 = 0x0000000000000001
logPrice2 = 0xF00FF00FF00FF00F
logPrice3 = 0x8FFFFFFFFFFFFFFF
logPrice4 = 0xFFFFFFFFFFFFFFFF

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return KernelCompactWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('kernelCompactLength', [2, maxKernelIndex // 2, maxKernelIndex])
@pytest.mark.parametrize('kernelCompact', [128, 1000, 10000])
def test_member(wrapper, content, kernelCompactLength, kernelCompact, request, worker_id):
    logTest(request, worker_id)
    
    kernelCompactContent = 0
    for kk in range(1 + ((80 * kernelCompactLength) // 256)):
        kernelCompactContent = kernelCompactContent << 250
        kernelCompactContent = kernelCompactContent + (content >> 6)

    kernelCompactContent = kernelCompactContent % (1 << (80 * (kernelCompactLength - 1)))
    content = kernelCompactContent

    content = kernelCompactContent
    height = [0 for kk in range(kernelCompactLength)]
    logShift = [0 for kk in range(kernelCompactLength)]
    for kk in range(kernelCompactLength - 1, 0, -1):
        logShift[kk] = content % (1 << 64)
        content = content >> 64
        height[kk] = content % (1 << 16)
        content = content >> 16

    kernelCompactArray = encodeKernelCompact([[logShift[kk], height[kk]] for kk in range(kernelCompactLength)])

    tx = wrapper._member(kernelCompact, kernelCompactLength, kernelCompactArray)
    
    assert tx.events[0]['data'].hex() == encode_packed(['uint256'] * kernelCompactLength, height).hex()
    assert tx.events[1]['data'].hex() == encode_packed(['uint256'] * kernelCompactLength, logShift).hex()

@pytest.mark.parametrize('content', [value1, value2, value3, value4])
@pytest.mark.parametrize('kernelCompactLength', [2, maxKernelIndex // 2, maxKernelIndex])
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_expand(wrapper, content, kernelCompactLength, kernelCompact, request, worker_id):
    logTest(request, worker_id)
    
    kernelCompactContent = 0
    for kk in range(1 + ((80 * kernelCompactLength) // 256)):
        kernelCompactContent = kernelCompactContent << 250
        kernelCompactContent = kernelCompactContent + (content >> 6)

    kernelCompactContent = kernelCompactContent % (1 << (80 * (kernelCompactLength - 1)))
    content = kernelCompactContent

    content = kernelCompactContent
    _height = [0 for kk in range(kernelCompactLength)]
    _logShift = [0 for kk in range(kernelCompactLength)]
    for kk in range(kernelCompactLength - 1, 0, -1):
        _logShift[kk] = content % (1 << 64)
        content = content >> 64
        _height[kk] = content % (1 << 16)
        content = content >> 16

    height = [0]
    logShift = [0]
    for kk in range(len(_logShift)):
        if _logShift[kk] != 0:
            height = height + [_height[kk]]
            logShift = logShift + [_logShift[kk]]
    
    kernelCompactLength = len(logShift)

    kernelCompactArray = encodeKernelCompact([[logShift[kk], height[kk]] for kk in range(kernelCompactLength)])
    kernelArray = [int(member) for member in encodeKernel([[logShift[kk], height[kk]] for kk in range(kernelCompactLength)])]

    if kernelCompactLength > 1:
        tx = wrapper._expand(kernelCompact, kernelCompactLength, kernelCompactArray)
        result = tx.events[0]['data'].hex()
        kernelContent = encode_packed(['uint256'] * (2 * (kernelCompactLength - 1)), kernelArray).hex()

        while len(result) != 0:
            assert abs(toInt(result[-54:]) - toInt(kernelContent[-54:])) < 100
            result = result[0:-54]
            kernelContent = kernelContent[0:-54]

            assert abs(toInt(result[-54:]) - toInt(kernelContent[-54:])) < 100
            result = result[0:-54]
            kernelContent = kernelContent[0:-54]

            assert result[-16:] == kernelContent[-16:]
            result = result[0:-16]
            kernelContent = kernelContent[0:-16]

            assert result[-4:] == kernelContent[-4:]
            result = result[0:-4]
            kernelContent = kernelContent[0:-4]

@pytest.mark.parametrize('kernelArray', [
    [[0, 0], [0, 0]],
    [[0, 0], [0, 1]],
])
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_validateSecondHorizontalCoordinateIsZero(wrapper, kernelCompact, kernelArray, request, worker_id):
    logTest(request, worker_id)
    
    with brownie.reverts('SecondHorizontalCoordinateIsZero: '):
        tx = wrapper._validate(kernelCompact, kernelArray[-1][0], encodeKernelCompact(kernelArray))

@pytest.mark.parametrize('kernelArray', [
    [[0, 0], [minLogStep - 1, 1]],
    [[0, 0], [minLogStep - 1, oneX15]],
])
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_validateSlopeTooHigh(wrapper, kernelCompact, kernelArray, request, worker_id):
    logTest(request, worker_id)
    
    with brownie.reverts('SlopeTooHigh: ' + str(kernelArray[0][0]) + ', ' + str(kernelArray[1][0])):
        tx = wrapper._validate(kernelCompact, kernelArray[-1][0], encodeKernelCompact(kernelArray))

@pytest.mark.parametrize('qSpacing', [logPrice2, logPrice3])
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_validateHorizontalCoordinatesMayNotExceedLogSpacing(wrapper, kernelCompact, qSpacing, request, worker_id):
    logTest(request, worker_id)
    
    kernelArray = [[0, 0], [qSpacing + 1, 1]]
    with brownie.reverts('HorizontalCoordinatesMayNotExceedLogSpacing: ' + str(kernelArray[1][0]) + ', ' + str(qSpacing)):
        tx = wrapper._validate(kernelCompact, qSpacing, encodeKernelCompact(kernelArray))

@pytest.mark.parametrize('kernelArray', [
    [[0, 0], [minLogStep, 0]],
])
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_validateSlopeTooHigh(wrapper, kernelCompact, kernelArray, request, worker_id):
    logTest(request, worker_id)
    
    with brownie.reverts('LastVerticalCoordinateMismatch: ' + str(0)):
        tx = wrapper._validate(kernelCompact, kernelArray[-1][0], encodeKernelCompact(kernelArray))

@pytest.mark.parametrize('kernelArray', [
    [[0, 0], [minLogStep, 0], [minLogStep, 0], [minLogStep + minLogStep, oneX15]],
])
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_validateSlopeTooHigh(wrapper, kernelCompact, kernelArray, request, worker_id):
    logTest(request, worker_id)
    
    with brownie.reverts('RepetitiveVerticalCoordinates: ' + str(0)):
        tx = wrapper._validate(kernelCompact, kernelArray[-1][0], encodeKernelCompact(kernelArray))

@pytest.mark.parametrize('kernelArray', [
    [[0, 0], [minLogStep, 1], [minLogStep - 1, 2], [2 * minLogStep, oneX15]],
])
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_validateNonMonotonicHorizontalCoordinates(wrapper, kernelCompact, kernelArray, request, worker_id):
    logTest(request, worker_id)
    
    with brownie.reverts('NonMonotonicHorizontalCoordinates: ' + str(kernelArray[1][0]) + ', ' + str(kernelArray[2][0])):
        tx = wrapper._validate(kernelCompact, kernelArray[-1][0], encodeKernelCompact(kernelArray))

@pytest.mark.parametrize('kernelArray', [
    [[0, 0], [minLogStep, 2], [minLogStep + 1, 1], [2 * minLogStep, oneX15]],
])
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_validateNonMonotonicVerticalCoordinates(wrapper, kernelCompact, kernelArray, request, worker_id):
    logTest(request, worker_id)
    
    with brownie.reverts('NonMonotonicVerticalCoordinates: ' + str(kernelArray[1][1]) + ', ' + str(kernelArray[2][1])):
        tx = wrapper._validate(kernelCompact, kernelArray[-1][0], encodeKernelCompact(kernelArray))

@pytest.mark.parametrize('kernelArray', [
    [[0, 0], [minLogStep, 1], [minLogStep, 1], [2 * minLogStep, oneX15]],
])
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_validateRepetitiveKernelPoints(wrapper, kernelCompact, kernelArray, request, worker_id):
    logTest(request, worker_id)
    
    with brownie.reverts('RepetitiveKernelPoints: ' + str(kernelArray[1][1]) + ', ' + str(kernelArray[1][0])):
        tx = wrapper._validate(kernelCompact, kernelArray[-1][0], encodeKernelCompact(kernelArray))

@pytest.mark.parametrize('kernelArray', [
    [[0, 0], [minLogStep, 1], [minLogStep, 2], [minLogStep, 3], [2 * minLogStep, oneX15]],
])
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_validateRepetitiveHorizontalCoordinates(wrapper, kernelCompact, kernelArray, request, worker_id):
    logTest(request, worker_id)
    
    with brownie.reverts('RepetitiveHorizontalCoordinates: ' + str(kernelArray[1][0])):
        tx = wrapper._validate(kernelCompact, kernelArray[-1][0], encodeKernelCompact(kernelArray))

@pytest.mark.parametrize('n', range(len(swaps['kernel'])))
@pytest.mark.parametrize('kernelCompact', [_kernelLength_ + 100, _kernelLength_ + 1000, _kernelLength_ + 10000])
def test_validate(wrapper, kernelCompact, n, request, worker_id):
    logTest(request, worker_id)
    
    kernelArray = swaps['kernel'][n]
    tx = wrapper._validate(kernelCompact, kernelArray[-1][0], encodeKernelCompact(kernelArray))
    length = tx.return_value
    assert length == len(kernelArray)