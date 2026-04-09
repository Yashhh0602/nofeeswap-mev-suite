# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, IntervalWrapper
from sympy import Integer, floor, exp, Symbol, integrate
from Nofee import logTest, thirtyTwoX59, X15, X59, X216, dataGeneration
from X15_test import oneX15

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
@pytest.mark.parametrize('originLog', [(1 * thirtyTwoX59) // 9])
@pytest.mark.parametrize('total0Log', [(2 * thirtyTwoX59) // 9])
@pytest.mark.parametrize('targetLog', [(3 * thirtyTwoX59) // 9])
@pytest.mark.parametrize('forward0Log', [(4 * thirtyTwoX59) // 9])
@pytest.mark.parametrize('beginLog', [(5 * thirtyTwoX59) // 9])
@pytest.mark.parametrize('overshootLog', [(6 * thirtyTwoX59) // 9])
@pytest.mark.parametrize('total1Log', [(7 * thirtyTwoX59) // 9])
@pytest.mark.parametrize('forward1Log', [(8 * thirtyTwoX59) // 9])
@pytest.mark.parametrize('forward0Height', [(1 * oneX15) // 5])
@pytest.mark.parametrize('total0Height', [(2 * oneX15) // 5])
@pytest.mark.parametrize('forward1Height', [(3 * oneX15) // 5])
@pytest.mark.parametrize('total1Height', [(4 * oneX15) // 5])
@pytest.mark.parametrize('integral0Incremented', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('integral1Incremented', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('currentToTarget', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('currentToOvershoot', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('targetToOvershoot', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('originToOvershoot', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('currentToOrigin', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('incomingCurrentToTarget', [X216 // 5, X216 // 3])
def test_newIntegrals(
    wrapper,
    zeroForOne,
    originLog,
    total0Log,
    targetLog,
    forward0Log,
    beginLog,
    overshootLog,
    total1Log,
    forward1Log,
    forward0Height,
    total0Height,
    forward1Height,
    total1Height,
    integral0Incremented,
    integral1Incremented,
    currentToTarget,
    currentToOvershoot,
    targetToOvershoot,
    originToOvershoot,
    currentToOrigin,
    incomingCurrentToTarget,
    request,
    worker_id
):
    logTest(request, worker_id)
    
    if zeroForOne:
        originLog, total0Log, targetLog, forward0Log, beginLog, overshootLog, total1Log, forward1Log = \
        forward1Log, total1Log, overshootLog, beginLog, forward0Log, targetLog, total0Log, originLog

    sqrtTotal0 = floor((2 ** 216) * exp(- Integer(total0Log) / (2 ** 60)))
    sqrtInverseTotal0 = floor((2 ** 216) * exp(- 16 + Integer(total0Log) / (2 ** 60)))
    total0Content0 = (total0Height << 240) + (total0Log << 176) + (sqrtTotal0 >> 40)
    total0Content1 = ((sqrtTotal0 % (1 << 40)) << 216) + sqrtInverseTotal0

    sqrtTotal1 = floor((2 ** 216) * exp(- Integer(total1Log) / (2 ** 60)))
    sqrtInverseTotal1 = floor((2 ** 216) * exp(- 16 + Integer(total1Log) / (2 ** 60)))
    total1Content0 = (total1Height << 240) + (total1Log << 176) + (sqrtTotal1 >> 40)
    total1Content1 = ((sqrtTotal1 % (1 << 40)) << 216) + sqrtInverseTotal1

    sqrtForward0 = floor((2 ** 216) * exp(- Integer(forward0Log) / (2 ** 60)))
    sqrtInverseForward0 = floor((2 ** 216) * exp(- 16 + Integer(forward0Log) / (2 ** 60)))
    forward0Content0 = (forward0Height << 240) + (forward0Log << 176) + (sqrtForward0 >> 40)
    forward0Content1 = ((sqrtForward0 % (1 << 40)) << 216) + sqrtInverseForward0

    sqrtForward1 = floor((2 ** 216) * exp(- Integer(forward1Log) / (2 ** 60)))
    sqrtInverseForward1 = floor((2 ** 216) * exp(- 16 + Integer(forward1Log) / (2 ** 60)))
    forward1Content0 = (forward1Height << 240) + (forward1Log << 176) + (sqrtForward1 >> 40)
    forward1Content1 = ((sqrtForward1 % (1 << 40)) << 216) + sqrtInverseForward1

    tx = wrapper._newIntegrals(
        zeroForOne,
        beginLog,
        originLog,
        targetLog,
        overshootLog,
        [
            integral0Incremented,
            integral1Incremented,
            currentToTarget,
            currentToOvershoot,
            targetToOvershoot,
            originToOvershoot,
            currentToOrigin,
            incomingCurrentToTarget,
        ],
        [
            total0Content0,
            total0Content1,
            total1Content0,
            total1Content1,
            forward0Content0,
            forward0Content1,
            forward1Content0,
            forward1Content1,
        ]
    )

    integral0Amended, integral1Amended = tx.return_value

    h = Symbol('h', real = True)
    qBegin = Integer(beginLog) / X59
    qOvershoot = Integer(overshootLog) / X59
    c0 = Integer(total0Height) / X15
    c1 = Integer(total1Height) / X15
    b0 = Integer(total0Log) / X59
    b1 = Integer(total1Log) / X59
    if zeroForOne:
        outgoingTotal = integrate(
            (exp(- 16 + (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
            (h, qOvershoot, qBegin)
        )
    else:
        outgoingTotal = integrate(
            (exp(- (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
            (h, qBegin, qOvershoot)
        )
    outgoingTotal = floor(X216 * outgoingTotal)

    c0 = Integer(forward0Height) / X15
    c1 = Integer(forward1Height) / X15
    b0 = Integer(forward0Log) / X59
    b1 = Integer(forward1Log) / X59
    if zeroForOne:
        outgoingForward = integrate(
            (exp(- 16 + (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
            (h, qOvershoot, qBegin)
        )
    else:
        outgoingForward = integrate(
            (exp(- (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
            (h, qBegin, qOvershoot)
        )
    outgoingForward = floor(X216 * outgoingForward)
    
    qOrigin = - 16 + (Integer(originLog) / X59)
    qTarget = - 16 + (Integer(targetLog) / X59)
    qOvershoot = - 16 + (Integer(overshootLog) / X59)
    if zeroForOne:
        originToTarget = \
            floor(exp(- (qOrigin + qOvershoot) / 2) * (originToOvershoot + outgoingTotal)) - \
            floor(exp(- (qTarget + qOvershoot) / 2) * (targetToOvershoot + outgoingForward))
    else:
        originToTarget = \
            floor(exp(+ (qOrigin + qOvershoot) / 2) * (originToOvershoot + outgoingTotal)) - \
            floor(exp(+ (qTarget + qOvershoot) / 2) * (targetToOvershoot + outgoingForward))

    if zeroForOne:
        integral0Incremented, integral1Incremented = integral1Incremented, integral0Incremented

    _integral0Amended = integral0Incremented + currentToTarget \
      - (currentToOvershoot + outgoingTotal) \
      + (targetToOvershoot + outgoingForward)

    _integral1Amended = integral1Incremented + originToTarget \
      - currentToOrigin \
      - incomingCurrentToTarget

    _integral0Amended = max(0, _integral0Amended)
    _integral1Amended = max(0, _integral1Amended)

    if zeroForOne:
        _integral0Amended, _integral1Amended = _integral1Amended, _integral0Amended

    assert integral0Amended == _integral0Amended
    assert integral1Amended == _integral1Amended