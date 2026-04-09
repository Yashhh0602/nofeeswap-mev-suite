# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, IntervalWrapper
from Nofee import logTest, getMaxIntegrals, dataGeneration, toInt, encodeKernel

initializations, swaps, kernelsValid, kernelsInvalid = dataGeneration(1000)

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
    return IntervalWrapper.deploy({'from': accounts[0]})

@pytest.mark.parametrize('n', range(len(initializations['kernel'])))
def test_calculateMaxIntegrals(wrapper, n, request, worker_id):
    logTest(request, worker_id)
    
    kernel = initializations['kernel'][n]
    tx = wrapper._calculateMaxIntegrals(encodeKernel(kernel))
    outgoingMax, incomingMax, outgoingMaxModularInverse = tx.return_value

    _outgoingMax, _incomingMax = getMaxIntegrals(kernel)
    assert abs(outgoingMax - _outgoingMax) <= 2 ** 32
    assert abs(incomingMax - _incomingMax) <= 2 ** 48
    _outgoingMaxModularInverse = outgoingMax
    while _outgoingMaxModularInverse % 2 != 1:
        _outgoingMaxModularInverse >>= 1
    _outgoingMaxModularInverse = pow(_outgoingMaxModularInverse, -1, 2**256)
    assert outgoingMaxModularInverse == _outgoingMaxModularInverse
    assert toInt(tx.events['(unknown)']['data'].hex()) == 0