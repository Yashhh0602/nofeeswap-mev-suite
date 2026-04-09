# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, IntervalWrapper
from sympy import Integer, floor, exp
from Nofee import logTest, thirtyTwoX59, dataGeneration, toInt

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

def test_clearInterval(wrapper):
    tx = wrapper._clearInterval()
    pre, post = tx.return_value

    assert pre == (1 << 256) - 1
    assert post == (1 << 256) - 1
    assert toInt(tx.events['(unknown)']['data'].hex()) == 0

@pytest.mark.parametrize('left', [False, True])
@pytest.mark.parametrize('overshoot', [1, thirtyTwoX59 // 3, (2 * thirtyTwoX59) // 3, thirtyTwoX59 - 1])
def test_moveOvershootByEpsilon(wrapper, left, overshoot, request, worker_id):
    logTest(request, worker_id)
    
    tx = wrapper._moveOvershootByEpsilon(overshoot, left)

    if left:
        overshoot = overshoot - 1
    else:
        overshoot = overshoot + 1

    if (overshoot > 0) and (overshoot < thirtyTwoX59):
        overshootContent0, overshootContent1 = tx.return_value

        overshootLog = (overshootContent0 >> 176) % (1 << 64)
        overshootSqrt = ((overshootContent0 % (1 << 176)) << 40) + (overshootContent1 >> 216)
        overshootSqrtInverse = overshootContent1 % (1 << 216)

        assert overshootLog == overshoot
        assert abs(overshootSqrt - floor((2 ** 216) * exp(- Integer(overshoot) / (2 ** 60)))) <= (1 << 32)
        assert abs(overshootSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(overshoot) / (2 ** 60)))) <= (1 << 32)