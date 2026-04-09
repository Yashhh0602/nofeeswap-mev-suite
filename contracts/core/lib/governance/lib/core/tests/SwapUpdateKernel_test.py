# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, SwapWrapper
from eth_abi import encode
from Nofee import logTest, _poolGrowthPortion_, _maxPoolGrowthPortion_, _staticParams_, _endOfStaticParams_, dataGeneration, toInt

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

int256max = (1 << 255) - 1

maxCurveIndex = 0xFFF

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

height0 = 0x0000
height1 = 0x0111
height2 = 0x1F0F
height3 = 0x3FFF
height4 = 0x8000

midpoint = 0x8000000000000000
spacing = 0x0800000000000000

points = [
    (0 * spacing) // 10,
    (1 * spacing) // 10,
    (2 * spacing) // 10,
    (3 * spacing) // 10,
    (4 * spacing) // 10,
    (5 * spacing) // 10,
    (6 * spacing) // 10,
]

@pytest.fixture(autouse=True)
def wrapper(fn_isolation):
    return SwapWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('poolId', [value1, value2, value2, value3])
@pytest.mark.parametrize('storagePointer', [1 << 255, 0, 111])
@pytest.mark.parametrize('kernelLength0', [50, 91])
@pytest.mark.parametrize('kernelLength1', [50, 91])
@pytest.mark.parametrize('content0', [value2, value3, value4])
@pytest.mark.parametrize('content1', [value2, value3, value4])
def test_updateKernel(wrapper, poolId, storagePointer, kernelLength0, kernelLength1, content0, content1, request, worker_id):
    logTest(request, worker_id)
    
    contentLength0 = 64 * (kernelLength0 - 1) + (_endOfStaticParams_ - _staticParams_)
    contentLength1 = 64 * (kernelLength1 - 1) + (_endOfStaticParams_ - _staticParams_)

    contentBytes0 = encode(['uint256'] * contentLength0, [content0] * contentLength0)[0 : contentLength0]
    contentBytes1 = encode(['uint256'] * contentLength1, [content1] * contentLength1)[0 : contentLength1]
    tx = wrapper._updateKernel(
        poolId,
        storagePointer,
        kernelLength0,
        kernelLength1,
        contentBytes0,
        contentBytes1
    )

    data = tx.events['(unknown)'][0]['data']
    length = toInt(tx.events['(unknown)'][0]['topic1'])
    storagePointerUpdated = toInt(tx.events['(unknown)'][0]['topic2'])

    pointer0 = _poolGrowthPortion_ + _endOfStaticParams_ - _staticParams_
    pointer1 = _maxPoolGrowthPortion_ + _endOfStaticParams_ - _staticParams_

    if toInt(contentBytes1[pointer0 : pointer0 + 6].hex()) > toInt(contentBytes1[pointer1 : pointer1 + 6].hex()):
        contentBytes1 = contentBytes1[0 : pointer0] + contentBytes1[pointer1 : pointer1 + 6] + contentBytes1[pointer1 : pointer1 + 6] + contentBytes1[pointer0 + 12 : ]

    assert contentBytes1.hex() == data.hex()
    assert length == kernelLength1
    assert storagePointerUpdated == storagePointer + 1