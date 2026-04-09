# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, IntervalWrapper
from sympy import Integer, floor, exp
from Nofee import logTest, thirtyTwoX59, X59, X216, dataGeneration

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

@pytest.mark.parametrize('zeroForOne', [False, True])
@pytest.mark.parametrize('currentToOrigin', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('currentToOvershoot', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('currentToTarget', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('incomingCurrentToTarget', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('originToOvershoot', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('targetToOvershoot', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('integral0Incremented', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('integral1Incremented', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('target', [thirtyTwoX59 // 5, thirtyTwoX59 // 3])
@pytest.mark.parametrize('overshoot', [thirtyTwoX59 // 5, thirtyTwoX59 // 3])
@pytest.mark.parametrize('origin', [thirtyTwoX59 // 5, thirtyTwoX59 // 3])
def test_getMismatch(
    wrapper, 
    zeroForOne,
    currentToOrigin,
    currentToOvershoot,
    currentToTarget,
    incomingCurrentToTarget,
    originToOvershoot,
    targetToOvershoot,
    integral0Incremented,
    integral1Incremented,
    target,
    overshoot,
    origin,
    request,
    worker_id
):
    logTest(request, worker_id)
    
    tx = wrapper._getMismatch(
        zeroForOne,
        currentToOrigin,
        currentToOvershoot,
        currentToTarget,
        incomingCurrentToTarget,
        originToOvershoot,
        targetToOvershoot,
        integral0Incremented,
        integral1Incremented,
        target,
        overshoot,
        origin
    )

    mismatch = tx.return_value

    currentToOrigin = Integer(currentToOrigin) / X216
    currentToOvershoot = Integer(currentToOvershoot) / X216
    currentToTarget = Integer(currentToTarget) / X216
    incomingCurrentToTarget = Integer(incomingCurrentToTarget) / X216
    originToOvershoot = Integer(originToOvershoot) / X216
    targetToOvershoot = Integer(targetToOvershoot) / X216
    integral0Incremented = Integer(integral0Incremented) / X216
    integral1Incremented = Integer(integral1Incremented) / X216
    target = - 16 + (Integer(target) / X59)
    overshoot = - 16 + (Integer(overshoot) / X59)
    origin = - 16 + (Integer(origin) / X59)

    integral0AmendedMinusIntegral0Incremented = currentToTarget + targetToOvershoot - currentToOvershoot

    if zeroForOne:
        integral1AmendedMinusIntegral1Incremented =  \
            exp(- (origin + overshoot) / 2) * originToOvershoot - \
            exp(- (target + overshoot) / 2) * targetToOvershoot - \
            incomingCurrentToTarget - currentToOrigin
        
        _mismatch = \
            integral1AmendedMinusIntegral1Incremented * integral1Incremented - \
            integral0AmendedMinusIntegral0Incremented * integral0Incremented
    else:
        integral1AmendedMinusIntegral1Incremented =  \
            exp(+ (origin + overshoot) / 2) * originToOvershoot - \
            exp(+ (target + overshoot) / 2) * targetToOvershoot - \
            incomingCurrentToTarget - currentToOrigin
        
        _mismatch = \
            integral1AmendedMinusIntegral1Incremented * integral0Incremented - \
            integral0AmendedMinusIntegral0Incremented * integral1Incremented
    
    assert abs(floor(X216 * _mismatch) - mismatch) <= 1 << 32