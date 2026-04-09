# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, IntervalWrapper
from sympy import Integer, floor, exp
from Nofee import logTest, _endOfStaticParams_, X60, X216, dataGeneration, toInt, encodeCurve

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

@pytest.mark.parametrize('content', [value0, value1, value2, value3, value4])
@pytest.mark.parametrize('curveLength', [2, maxCurveIndex // 2, maxCurveIndex])
@pytest.mark.parametrize('curve', [_endOfStaticParams_ + 128, _endOfStaticParams_ + 1000, _endOfStaticParams_ + 10000])
@pytest.mark.parametrize('position', ['min', 'mid', 'max'])
def test_initiateInterval(wrapper, content, curveLength, curve, position, request, worker_id):
    logTest(request, worker_id)
    
    curveSequence = [
        content >> 192,
        (content >> 128) & 0xFFFFFFFFFFFFFFFF,
        (content >> 64) & 0xFFFFFFFFFFFFFFFF,
        content & 0xFFFFFFFFFFFFFFFF
    ] * curveLength
    curveSequence = curveSequence[0 : curveLength]
    curveSequence[-1] = min(max(1, curveSequence[-1]), (1 << 64) - 1)
    curveArray = encodeCurve(curveSequence)

    qLower = min(curveSequence[0], curveSequence[1])
    qUpper = max(curveSequence[0], curveSequence[1])
    qCurrent = curveSequence[-1]
    if position == 'min':
        qLimit = 1
    if position == 'mid':
        qLimit = (curveSequence[0] + curveSequence[1]) // 2
        qLimit = min(max(1, qLimit), (1 << 64) - 1)
    if position == 'max':
        qLimit = (1 << 64) - 1

    tx = wrapper._initiateInterval(curve, curveLength, qLimit, curveArray)

    logPriceLimitOffsettedWithinInterval, indexCurve, direction = tx.return_value

    assert logPriceLimitOffsettedWithinInterval == min(max(qLower, qLimit), qUpper)
    assert indexCurve == curveLength - 1
    assert direction == (qCurrent < curveSequence[curveLength - 2])

    for kk in range(5):
        assert toInt(tx.events[kk]['topic1']) == qCurrent
        assert abs(toInt(tx.events[kk]['topic2']) - floor(X216 * exp(- Integer(qCurrent) / X60))) <= 100
        assert abs(toInt(tx.events[kk]['topic3']) - floor(X216 * exp(- 16 + Integer(qCurrent) / X60))) <= 100

    assert toInt(tx.events[5]['topic1']) == 0
    assert toInt(tx.events[5]['topic2']) == qCurrent
    assert abs(toInt(tx.events[5]['topic3']) - floor(X216 * exp(- Integer(qCurrent) / X60))) <= 100
    assert abs(toInt(tx.events[5]['topic4']) - floor(X216 * exp(- 16 + Integer(qCurrent) / X60))) <= 100

    assert toInt(tx.events[6]['topic1']) == 0
    assert toInt(tx.events[6]['topic2']) == qCurrent
    assert abs(toInt(tx.events[6]['topic3']) - floor(X216 * exp(- Integer(qCurrent) / X60))) <= 100
    assert abs(toInt(tx.events[6]['topic4']) - floor(X216 * exp(- 16 + Integer(qCurrent) / X60))) <= 100