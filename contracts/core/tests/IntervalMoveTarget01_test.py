# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, IntervalWrapper
from sympy import Integer, floor, exp, Symbol, integrate
from Nofee import logTest, X15, X59, X216, dataGeneration
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

@pytest.mark.parametrize('direction', [False])
@pytest.mark.parametrize('zeroForOne', [True])
@pytest.mark.parametrize('originToOvershoot', [X216 // 5, X216 // 3])
@pytest.mark.parametrize('_total0', ['begin', 'afterBegin', 'middle', 'beforeEnd', 'end', 'afterEnd'])
@pytest.mark.parametrize('_total1', ['begin', 'afterBegin', 'middle', 'beforeEnd', 'end', 'afterEnd'])
@pytest.mark.parametrize('_total2', ['begin', 'afterBegin', 'middle', 'beforeEnd', 'end', 'afterEnd'])
@pytest.mark.parametrize('_limit', ['begin', 'afterBegin', 'middle', 'beforeEnd', 'end', 'afterEnd'])
def test_moveTarget(wrapper, direction, zeroForOne, originToOvershoot, _total0, _total1, _total2, _limit, request, worker_id):
    logTest(request, worker_id)
    
    if direction == False:
        before = 0x8100000000000000
        origin = 0x8200000000000000
        begin = 0x8300000000000000
        end = 0x8400000000000000

        if _total0 == 'begin':
            total0Log = begin
        if _total0 == 'afterBegin':
            total0Log = begin + 1
        if _total0 == 'middle':
            total0Log = (begin + end) // 2
        if _total0 == 'beforeEnd':
            total0Log = end - 1
        if _total0 == 'end':
            total0Log = end
        if _total0 == 'afterEnd':
            total0Log = end + 1

        if _total1 == 'begin':
            total1Log = begin
        if _total1 == 'afterBegin':
            total1Log = begin + 1
        if _total1 == 'middle':
            total1Log = (begin + end) // 2
        if _total1 == 'beforeEnd':
            total1Log = end - 1
        if _total1 == 'end':
            total1Log = end
        if _total1 == 'afterEnd':
            total1Log = end + 1

        if _total2 == 'begin':
            total2Log = begin
        if _total2 == 'afterBegin':
            total2Log = begin + 1
        if _total2 == 'middle':
            total2Log = (begin + end) // 2
        if _total2 == 'beforeEnd':
            total2Log = end - 1
        if _total2 == 'end':
            total2Log = end
        if _total2 == 'afterEnd':
            total2Log = end + 1

        l = [total0Log, total1Log, total2Log]
        l.sort()
        total0Log, total1Log, total2Log = l

    else:
        end = 0x8100000000000000
        begin = 0x8200000000000000
        origin = 0x8300000000000000
        before = 0x8400000000000000

        if _total0 == 'begin':
            total0Log = begin
        if _total0 == 'afterBegin':
            total0Log = begin - 1
        if _total0 == 'middle':
            total0Log = (begin + end) // 2
        if _total0 == 'beforeEnd':
            total0Log = end + 1
        if _total0 == 'end':
            total0Log = end
        if _total0 == 'afterEnd':
            total0Log = end - 1

        if _total1 == 'begin':
            total1Log = begin
        if _total1 == 'afterBegin':
            total1Log = begin - 1
        if _total1 == 'middle':
            total1Log = (begin + end) // 2
        if _total1 == 'beforeEnd':
            total1Log = end + 1
        if _total1 == 'end':
            total1Log = end
        if _total1 == 'afterEnd':
            total1Log = end - 1

        if _total2 == 'begin':
            total2Log = begin
        if _total2 == 'afterBegin':
            total2Log = begin - 1
        if _total2 == 'middle':
            total2Log = (begin + end) // 2
        if _total2 == 'beforeEnd':
            total2Log = end + 1
        if _total2 == 'end':
            total2Log = end
        if _total2 == 'afterEnd':
            total2Log = end - 1

        l = [total0Log, total1Log, total2Log]
        l.sort()
        total2Log, total1Log, total0Log = l

    if direction == zeroForOne:
        if direction == True:
            if _limit == 'begin':
                limit = begin
            if _limit == 'afterBegin':
                limit = begin - 1
            if _limit == 'middle':
                limit = (begin + end) // 2
            if _limit == 'beforeEnd':
                limit = end + 1
            if _limit == 'end':
                limit = end
            if _limit == 'afterEnd':
                limit = end - 1

            target = max(max(end, total1Log), limit)
        else:
            if _limit == 'begin':
                limit = begin
            if _limit == 'afterBegin':
                limit = begin + 1
            if _limit == 'middle':
                limit = (begin + end) // 2
            if _limit == 'beforeEnd':
                limit = end - 1
            if _limit == 'end':
                limit = end
            if _limit == 'afterEnd':
                limit = end + 1

            target = min(min(end, total1Log), limit)
    else:
        limit = origin
        if direction == True:
            target = max(end, total1Log)
        else:
            target = min(end, total1Log)

    total0Height = oneX15 // 3
    sqrtTotal0 = floor((2 ** 216) * exp(- Integer(total0Log) / (2 ** 60)))
    sqrtInverseTotal0 = floor((2 ** 216) * exp(- 16 + Integer(total0Log) / (2 ** 60)))
    total0Content0 = (total0Height << 240) + (total0Log << 176) + (sqrtTotal0 >> 40)
    total0Content1 = ((sqrtTotal0 % (1 << 40)) << 216) + sqrtInverseTotal0

    total1Height = (2 * oneX15) // 3
    sqrtTotal1 = floor((2 ** 216) * exp(- Integer(total1Log) / (2 ** 60)))
    sqrtInverseTotal1 = floor((2 ** 216) * exp(- 16 + Integer(total1Log) / (2 ** 60)))
    total1Content0 = (total1Height << 240) + (total1Log << 176) + (sqrtTotal1 >> 40)
    total1Content1 = ((sqrtTotal1 % (1 << 40)) << 216) + sqrtInverseTotal1

    total2Height = oneX15
    sqrtTotal2 = floor((2 ** 216) * exp(- Integer(total2Log) / (2 ** 60)))
    sqrtInverseTotal2 = floor((2 ** 216) * exp(- 16 + Integer(total2Log) / (2 ** 60)))
    total2Content0 = (total2Height << 240) + (total2Log << 176) + (sqrtTotal2 >> 40)
    total2Content1 = ((sqrtTotal2 % (1 << 40)) << 216) + sqrtInverseTotal2

    if target != limit:
        tx = wrapper._moveTarget(
            direction,
            zeroForOne,
            limit,
            originToOvershoot,
            [
                (before << 192) + (end << 128) + (origin << 64) + begin,
                total0Content0,
                total0Content1,
                total1Content0,
                total1Content1,
                total2Content0,
                total2Content1
            ]
        )

        _direction, output, integrals = tx.return_value

        _total0Content0 = output[0]
        _total0Content1 = output[1]
        _total0Height = (_total0Content0 >> 240)
        _total0Log = (_total0Content0 >> 176) % (1 << 64)
        _total0Sqrt = ((_total0Content0 % (1 << 176)) << 40) + (_total0Content1 >> 216)
        _total0SqrtInverse = _total0Content1 % (1 << 216)

        _total1Content0 = output[2]
        _total1Content1 = output[3]
        _total1Height = (_total1Content0 >> 240)
        _total1Log = (_total1Content0 >> 176) % (1 << 64)
        _total1Sqrt = ((_total1Content0 % (1 << 176)) << 40) + (_total1Content1 >> 216)
        _total1SqrtInverse = _total1Content1 % (1 << 216)

        _beginContent0 = output[4]
        _beginContent1 = output[5]
        _beginLog = (_beginContent0 >> 176) % (1 << 64)
        _beginSqrt = ((_beginContent0 % (1 << 176)) << 40) + (_beginContent1 >> 216)
        _beginSqrtInverse = _beginContent1 % (1 << 216)

        _endContent0 = output[6]
        _endContent1 = output[7]
        _endLog = (_endContent0 >> 176) % (1 << 64)
        _endSqrt = ((_endContent0 % (1 << 176)) << 40) + (_endContent1 >> 216)
        _endSqrtInverse = _endContent1 % (1 << 216)

        _originContent0 = output[8]
        _originContent1 = output[9]
        _originLog = (_originContent0 >> 176) % (1 << 64)
        _originSqrt = ((_originContent0 % (1 << 176)) << 40) + (_originContent1 >> 216)
        _originSqrtInverse = _originContent1 % (1 << 216)

        _targetContent0 = output[10]
        _targetContent1 = output[11]
        _targetLog = (_targetContent0 >> 176) % (1 << 64)
        _targetSqrt = ((_targetContent0 % (1 << 176)) << 40) + (_targetContent1 >> 216)
        _targetSqrtInverse = _targetContent1 % (1 << 216)

        _currentToTarget = integrals[0]
        _incomingCurrentToTarget = integrals[1]
        _originToOvershoot = integrals[2]
        _currentToOrigin = integrals[3]

        if target == total1Log:
            if target == end:
                assert _total1Height == total2Height
                assert _total1Log == origin - total2Log + end
                assert abs(_total1Sqrt - floor((2 ** 216) * exp(- Integer(_total1Log) / (2 ** 60)))) <= 1 << 32
                assert abs(_total1SqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(_total1Log) / (2 ** 60)))) <= 1 << 32

                assert _total0Height == total1Height
                assert _total0Log == origin - total1Log + end
                assert abs(_total0Sqrt - floor((2 ** 216) * exp(- Integer(_total0Log) / (2 ** 60)))) <= 1 << 32
                assert abs(_total0SqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(_total0Log) / (2 ** 60)))) <= 1 << 32
            else:
                assert _total1Height == total2Height
                assert _total1Log == total2Log
                assert abs(_total1Sqrt - sqrtTotal2) <= 1 << 32
                assert abs(_total1SqrtInverse - sqrtInverseTotal2) <= 1 << 32

                assert _total0Height == total1Height
                assert _total0Log == total1Log
                assert abs(_total0Sqrt - sqrtTotal1) <= 1 << 32
                assert abs(_total0SqrtInverse - sqrtInverseTotal1) <= 1 << 32

        if target == end:
            assert _direction != direction

            if _direction:
                assert _beginLog == min(origin, _total0Log)
            else:
                assert _beginLog == max(origin, _total0Log)
            assert abs(_beginSqrt - floor((2 ** 216) * exp(- Integer(_beginLog) / (2 ** 60)))) <= 1 << 32
            assert abs(_beginSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(_beginLog) / (2 ** 60)))) <= 1 << 32

            assert _originLog == end
            assert abs(_originSqrt - floor((2 ** 216) * exp(- Integer(_originLog) / (2 ** 60)))) <= 1 << 32
            assert abs(_originSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(_originLog) / (2 ** 60)))) <= 1 << 32

            assert _endLog == before
            assert abs(_endSqrt - floor((2 ** 216) * exp(- Integer(_endLog) / (2 ** 60)))) <= 1 << 32
            assert abs(_endSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(_endLog) / (2 ** 60)))) <= 1 << 32

        if _direction == zeroForOne:
            if _direction == True:
                assert _targetLog == max(max(_endLog, _total1Log), limit)
            else:
                assert _targetLog == min(min(_endLog, _total1Log), limit)
        else:
            if _direction == True:
                assert _targetLog == max(_endLog, _total1Log)
            else:
                assert _targetLog == min(_endLog, _total1Log)
        assert abs(_targetSqrt - floor((2 ** 216) * exp(- Integer(_targetLog) / (2 ** 60)))) <= 1 << 32
        assert abs(_targetSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(_targetLog) / (2 ** 60)))) <= 1 << 32

        h = Symbol('h', real = True)
        c0 = Integer(_total0Height) / X15
        c1 = Integer(_total1Height) / X15
        b0 = Integer(_total0Log) / X59
        b1 = Integer(_total1Log) / X59
        
        qBegin = Integer(_beginLog) / X59
        qTarget = Integer(_targetLog) / X59

        if _total0Log != _total1Log:
            if _direction:
                outgoing = integrate(
                    (exp(- 16 + (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
                    (h, qTarget, qBegin)
                )
                incoming = integrate(
                    (exp(- (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
                    (h, qTarget, qBegin)
                )
            else:
                outgoing = integrate(
                    (exp(- (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
                    (h, qBegin, qTarget)
                )
                incoming = integrate(
                    (exp(- 16 + (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
                    (h, qBegin, qTarget)
                )

            outgoing = floor(X216 * outgoing)
            incoming = floor(X216 * incoming)

            if _direction == zeroForOne:
                assert abs(_currentToTarget - outgoing) <= 1 << 64
                assert abs(_incomingCurrentToTarget - incoming) <= 1 << 96
            else:
                assert abs(_currentToOrigin - outgoing) <= 1 << 64

            if target == end:                
                qTarget = - 16 + (Integer(target) / X59)
                qOrigin = - 16 + (Integer(origin) / X59)

                if direction:
                    originToOvershoot = outgoing + floor(exp(- (qOrigin + qTarget) / 2) * originToOvershoot)
                else:
                    originToOvershoot = outgoing + floor(exp(+ (qOrigin + qTarget) / 2) * originToOvershoot)

                assert abs(_originToOvershoot - originToOvershoot) <= 1 << 64
            else:
                assert abs(_originToOvershoot - originToOvershoot - outgoing) <= 1 << 64