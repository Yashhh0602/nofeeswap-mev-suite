# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, IntervalWrapper
from sympy import Integer, floor, exp, Symbol
from Nofee import logTest, _interval_, _incomingCurrentToTarget_, _currentToTarget_, _currentToOrigin_, _currentToOvershoot_, _targetToOvershoot_, _originToOvershoot_, _current_, _direction_, _origin_, _begin_, _end_, _target_, _overshoot_, _total0_, _total1_, _forward0_, _forward1_, _indexCurve_, _indexKernelTotal_, _indexKernelForward_, _logPriceLimitOffsettedWithinInterval_, X15, X59, X216, amend, outgoing, incoming, dataGeneration, toInt, encodeCurve, encodeKernel
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

@pytest.mark.parametrize('limitPlacement', [0])
@pytest.mark.parametrize('p5', ['skip'])
@pytest.mark.parametrize('p4', ['skip', 'break', 'jump'])
@pytest.mark.parametrize('p3', ['skip', 'break', 'jump'])
@pytest.mark.parametrize('p2', ['skip', 'break', 'jump'])
@pytest.mark.parametrize('p1', ['skip', 'break', 'jump'])
@pytest.mark.parametrize('orientation', [False, True])
def test_movements(wrapper, orientation, p1, p2, p3, p4, p5, limitPlacement, request, worker_id):
    logTest(request, worker_id)
    
    if orientation:
        curve = [
            midpoint + points[6],
            midpoint + points[0],
            midpoint + points[4],
            midpoint + points[2],
        ]
    else:
        curve = [
            midpoint + points[0],
            midpoint + points[6],
            midpoint + points[2],
            midpoint + points[4],
        ]

    kernel = [[0, 0]]

    if p1 != 'skip':
        kernel += [[points[1], (1 * oneX15) // 11]]
    if p1 == 'jump':
        kernel += [[points[1], (2 * oneX15) // 11]]

    if p2 != 'skip':
        kernel += [[points[2], (3 * oneX15) // 11]]
    if p2 == 'jump':
        kernel += [[points[2], (4 * oneX15) // 11]]

    if p3 != 'skip':
        kernel += [[points[3], (5 * oneX15) // 11]]
    if p3 == 'jump':
        kernel += [[points[3], (6 * oneX15) // 11]]

    if p4 != 'skip':
        kernel += [[points[4], (7 * oneX15) // 11]]
    if p4 == 'jump':
        kernel += [[points[4], (8 * oneX15) // 11]]

    if p5 != 'skip':
        kernel += [[points[5], (9 * oneX15) // 11]]
    if p5 == 'jump':
        kernel += [[points[5], (10 * oneX15) // 11]]

    kernel += [[points[6], oneX15]]

    limit = midpoint + points[limitPlacement]

    qLower = min(curve[0], curve[1])
    qUpper = max(curve[0], curve[1])
    qCurrent = curve[-1]

    if limit != qCurrent:
        zeroForOne = limit < qCurrent
        integral0 = outgoing(curve, kernel, qCurrent, qUpper)
        integral1 = outgoing(curve, kernel, qLower, qCurrent)

        tx = wrapper._movements(
            integral0,
            integral1,
            limit,
            len(curve),
            encodeKernel(kernel),
            encodeCurve(curve)
        )

        kk = 0

        size = len(tx.events['(unknown)'])

        snapshots = []
        for jj in range(len(tx.trace)):
            if tx.trace[jj]['op'] == 'LOG4':
                ii = 0
                data = ''
                while ii < len(tx.trace[jj]['memory']):
                    data += tx.trace[jj]['memory'][ii]
                    ii += 1
                data = int(data, 16).to_bytes(len(data) // 2, 'big')
                snapshots += [data[_interval_ : (_originToOvershoot_ + 27)]]

        while True:
            if kk >= size:
                break
            
            if toInt(tx.events['(unknown)'][kk]['topic1']) != 0xA:
                break

            data = snapshots[kk]

            direction = toInt(data[_direction_ - _interval_ : _direction_ - _interval_ + 1].hex()) > 0
            indexCurve = toInt(data[_indexCurve_ - _interval_ : _indexCurve_ - _interval_ + 2].hex())
            indexKernelTotal = toInt(data[_indexKernelTotal_ - _interval_ : _indexKernelTotal_ - _interval_ + 2].hex())
            indexKernelForward = toInt(data[_indexKernelForward_ - _interval_ : _indexKernelForward_ - _interval_ + 2].hex())
            logPriceLimitOffsettedWithinInterval = toInt(data[_logPriceLimitOffsettedWithinInterval_ - _interval_ : _logPriceLimitOffsettedWithinInterval_ - _interval_ + 8].hex())
            current = toInt(data[_current_ - _interval_ : _current_ - _interval_ + 8].hex())
            origin = toInt(data[_origin_ - _interval_ : _origin_ - _interval_ + 8].hex())
            begin = toInt(data[_begin_ - _interval_ : _begin_ - _interval_ + 8].hex())
            end = toInt(data[_end_ - _interval_ : _end_ - _interval_ + 8].hex())
            target = toInt(data[_target_ - _interval_ : _target_ - _interval_ + 8].hex())
            overshoot = toInt(data[_overshoot_ - _interval_ : _overshoot_ - _interval_ + 8].hex())
            currentSqrt = toInt(data[_current_ - _interval_ + 8 : _current_ - _interval_ + 35].hex())
            originSqrt = toInt(data[_origin_ - _interval_ + 8 : _origin_ - _interval_ + 35].hex())
            beginSqrt = toInt(data[_begin_ - _interval_ + 8 : _begin_ - _interval_ + 35].hex())
            endSqrt = toInt(data[_end_ - _interval_ + 8 : _end_ - _interval_ + 35].hex())
            targetSqrt = toInt(data[_target_ - _interval_ + 8 : _target_ - _interval_ + 35].hex())
            overshootSqrt = toInt(data[_overshoot_ - _interval_ + 8 : _overshoot_ - _interval_ + 35].hex())
            currentSqrtInverse = toInt(data[_current_ - _interval_ + 35 : _current_ - _interval_ + 62].hex())
            originSqrtInverse = toInt(data[_origin_ - _interval_ + 35 : _origin_ - _interval_ + 62].hex())
            beginSqrtInverse = toInt(data[_begin_ - _interval_ + 35 : _begin_ - _interval_ + 62].hex())
            endSqrtInverse = toInt(data[_end_ - _interval_ + 35 : _end_ - _interval_ + 62].hex())
            targetSqrtInverse = toInt(data[_target_ - _interval_ + 35 : _target_ - _interval_ + 62].hex())
            overshootSqrtInverse = toInt(data[_overshoot_ - _interval_ + 35 : _overshoot_ - _interval_ + 62].hex())
            total0Log = toInt(data[_total0_ - _interval_ : _total0_ - _interval_ + 8].hex())
            total1Log = toInt(data[_total1_ - _interval_ : _total1_ - _interval_ + 8].hex())
            forward0Log = toInt(data[_forward0_ - _interval_ : _forward0_ - _interval_ + 8].hex())
            forward1Log = toInt(data[_forward1_ - _interval_ : _forward1_ - _interval_ + 8].hex())
            total0Height = toInt(data[_total0_ - _interval_ - 2 : _total0_ - _interval_].hex())
            total1Height = toInt(data[_total1_ - _interval_ - 2 : _total1_ - _interval_].hex())
            forward0Height = toInt(data[_forward0_ - _interval_ - 2 : _forward0_ - _interval_].hex())
            forward1Height = toInt(data[_forward1_ - _interval_ - 2 : _forward1_ - _interval_].hex())
            total0Sqrt = toInt(data[_total0_ - _interval_ + 8 : _total0_ - _interval_ + 35].hex())
            total1Sqrt = toInt(data[_total1_ - _interval_ + 8 : _total1_ - _interval_ + 35].hex())
            forward0Sqrt = toInt(data[_forward0_ - _interval_ + 8 : _forward0_ - _interval_ + 35].hex())
            forward1Sqrt = toInt(data[_forward1_ - _interval_ + 8 : _forward1_ - _interval_ + 35].hex())
            total0SqrtInverse = toInt(data[_total0_ - _interval_ + 35 : _total0_ - _interval_ + 62].hex())
            total1SqrtInverse = toInt(data[_total1_ - _interval_ + 35 : _total1_ - _interval_ + 62].hex())
            forward0SqrtInverse = toInt(data[_forward0_ - _interval_ + 35 : _forward0_ - _interval_ + 62].hex())
            forward1SqrtInverse = toInt(data[_forward1_ - _interval_ + 35 : _forward1_ - _interval_ + 62].hex())
            incomingCurrentToTarget = toInt(data[_incomingCurrentToTarget_ - _interval_ : _incomingCurrentToTarget_ - _interval_ + 27].hex())
            currentToTarget = toInt(data[_currentToTarget_ - _interval_ : _currentToTarget_ - _interval_ + 27].hex())
            currentToOrigin = toInt(data[_currentToOrigin_ - _interval_ : _currentToOrigin_ - _interval_ + 27].hex())
            currentToOvershoot = toInt(data[_currentToOvershoot_ - _interval_ : _currentToOvershoot_ - _interval_ + 27].hex())
            targetToOvershoot = toInt(data[_targetToOvershoot_ - _interval_ : _targetToOvershoot_ - _interval_ + 27].hex())
            originToOvershoot = toInt(data[_originToOvershoot_ - _interval_ : _originToOvershoot_ - _interval_ + 27].hex())

            assert direction == (origin > end)

            assert logPriceLimitOffsettedWithinInterval == limit

            assert current == curve[-1]
            assert abs(currentSqrt - floor((2 ** 216) * exp(- Integer(current) / (2 ** 60)))) <= 1 << 32
            assert abs(currentSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(current) / (2 ** 60)))) <= 1 << 32

            assert origin == curve[indexCurve + 1]
            assert abs(originSqrt - floor((2 ** 216) * exp(- Integer(origin) / (2 ** 60)))) <= 1 << 32
            assert abs(originSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(origin) / (2 ** 60)))) <= 1 << 32

            if direction:
                assert begin == min(curve[min(indexCurve + 2, len(curve) - 1)], total0Log)
            else:
                assert begin == max(curve[min(indexCurve + 2, len(curve) - 1)], total0Log)
            assert abs(beginSqrt - floor((2 ** 216) * exp(- Integer(begin) / (2 ** 60)))) <= 1 << 32
            assert abs(beginSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(begin) / (2 ** 60)))) <= 1 << 32

            assert end == curve[indexCurve]
            assert abs(endSqrt - floor((2 ** 216) * exp(- Integer(end) / (2 ** 60)))) <= 1 << 32
            assert abs(endSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(end) / (2 ** 60)))) <= 1 << 32

            if direction == zeroForOne:
                if direction:
                    assert target == max(max(end, total1Log), limit)
                else:
                    assert target == min(min(end, total1Log), limit)
            else:
                if direction:
                    assert target == max(end, total1Log)
                else:
                    assert target == min(end, total1Log)
            assert abs(targetSqrt - floor((2 ** 216) * exp(- Integer(target) / (2 ** 60)))) <= 1 << 32
            assert abs(targetSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(target) / (2 ** 60)))) <= 1 << 32

            assert total0Height == kernel[indexKernelTotal - 1][1]
            if direction:
                assert total0Log == origin - kernel[indexKernelTotal - 1][0]
            else:
                assert total0Log == origin + kernel[indexKernelTotal - 1][0]
            assert abs(total0Sqrt - floor((2 ** 216) * exp(- Integer(total0Log) / (2 ** 60)))) <= 1 << 32
            assert abs(total0SqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(total0Log) / (2 ** 60)))) <= 1 << 32

            assert total1Height == kernel[indexKernelTotal][1]
            if direction:
                assert total1Log == origin - kernel[indexKernelTotal][0]
            else:
                assert total1Log == origin + kernel[indexKernelTotal][0]
            assert abs(total1Sqrt - floor((2 ** 216) * exp(- Integer(total1Log) / (2 ** 60)))) <= 1 << 32
            assert abs(total1SqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(total1Log) / (2 ** 60)))) <= 1 << 32

            if direction == zeroForOne:
                if direction:
                    assert abs(incomingCurrentToTarget - incoming(curve, kernel, target, current)) <= 1 << 32
                    assert abs(currentToTarget - outgoing(curve, kernel, target, current)) <= 1 << 32
                    assert abs(currentToOrigin - outgoing(curve, kernel, current, origin)) <= 1 << 32
                else:
                    assert abs(incomingCurrentToTarget - incoming(curve, kernel, current, target)) <= 1 << 32
                    assert abs(currentToTarget - outgoing(curve, kernel, current, target)) <= 1 << 32
                    assert abs(currentToOrigin - outgoing(curve, kernel, origin, current)) <= 1 << 32

            kk += 1

        while True:
            if kk >= size:
                break
            
            mismatch = toInt(tx.events['(unknown)'][kk]['topic1'])
            if mismatch >= (1 << 255):
                mismatch -= (1 << 256)
            step = toInt(tx.events['(unknown)'][kk]['topic2'])
            if step >= (1 << 255):
                step -= (1 << 256)
            integral0Amended = toInt(tx.events['(unknown)'][kk]['topic3'])
            integral1Amended = toInt(tx.events['(unknown)'][kk]['topic4'])

            data = snapshots[kk]

            direction = toInt(data[_direction_ - _interval_ : _direction_ - _interval_ + 1].hex()) > 0
            indexCurve = toInt(data[_indexCurve_ - _interval_ : _indexCurve_ - _interval_ + 2].hex())
            indexKernelTotal = toInt(data[_indexKernelTotal_ - _interval_ : _indexKernelTotal_ - _interval_ + 2].hex())
            indexKernelForward = toInt(data[_indexKernelForward_ - _interval_ : _indexKernelForward_ - _interval_ + 2].hex())
            logPriceLimitOffsettedWithinInterval = toInt(data[_logPriceLimitOffsettedWithinInterval_ - _interval_ : _logPriceLimitOffsettedWithinInterval_ - _interval_ + 8].hex())
            current = toInt(data[_current_ - _interval_ : _current_ - _interval_ + 8].hex())
            origin = toInt(data[_origin_ - _interval_ : _origin_ - _interval_ + 8].hex())
            begin = toInt(data[_begin_ - _interval_ : _begin_ - _interval_ + 8].hex())
            end = toInt(data[_end_ - _interval_ : _end_ - _interval_ + 8].hex())
            target = toInt(data[_target_ - _interval_ : _target_ - _interval_ + 8].hex())
            overshoot = toInt(data[_overshoot_ - _interval_ : _overshoot_ - _interval_ + 8].hex())
            currentSqrt = toInt(data[_current_ - _interval_ + 8 : _current_ - _interval_ + 35].hex())
            originSqrt = toInt(data[_origin_ - _interval_ + 8 : _origin_ - _interval_ + 35].hex())
            beginSqrt = toInt(data[_begin_ - _interval_ + 8 : _begin_ - _interval_ + 35].hex())
            endSqrt = toInt(data[_end_ - _interval_ + 8 : _end_ - _interval_ + 35].hex())
            targetSqrt = toInt(data[_target_ - _interval_ + 8 : _target_ - _interval_ + 35].hex())
            overshootSqrt = toInt(data[_overshoot_ - _interval_ + 8 : _overshoot_ - _interval_ + 35].hex())
            currentSqrtInverse = toInt(data[_current_ - _interval_ + 35 : _current_ - _interval_ + 62].hex())
            originSqrtInverse = toInt(data[_origin_ - _interval_ + 35 : _origin_ - _interval_ + 62].hex())
            beginSqrtInverse = toInt(data[_begin_ - _interval_ + 35 : _begin_ - _interval_ + 62].hex())
            endSqrtInverse = toInt(data[_end_ - _interval_ + 35 : _end_ - _interval_ + 62].hex())
            targetSqrtInverse = toInt(data[_target_ - _interval_ + 35 : _target_ - _interval_ + 62].hex())
            overshootSqrtInverse = toInt(data[_overshoot_ - _interval_ + 35 : _overshoot_ - _interval_ + 62].hex())
            total0Log = toInt(data[_total0_ - _interval_ : _total0_ - _interval_ + 8].hex())
            total1Log = toInt(data[_total1_ - _interval_ : _total1_ - _interval_ + 8].hex())
            forward0Log = toInt(data[_forward0_ - _interval_ : _forward0_ - _interval_ + 8].hex())
            forward1Log = toInt(data[_forward1_ - _interval_ : _forward1_ - _interval_ + 8].hex())
            total0Height = toInt(data[_total0_ - _interval_ - 2 : _total0_ - _interval_].hex())
            total1Height = toInt(data[_total1_ - _interval_ - 2 : _total1_ - _interval_].hex())
            forward0Height = toInt(data[_forward0_ - _interval_ - 2 : _forward0_ - _interval_].hex())
            forward1Height = toInt(data[_forward1_ - _interval_ - 2 : _forward1_ - _interval_].hex())
            total0Sqrt = toInt(data[_total0_ - _interval_ + 8 : _total0_ - _interval_ + 35].hex())
            total1Sqrt = toInt(data[_total1_ - _interval_ + 8 : _total1_ - _interval_ + 35].hex())
            forward0Sqrt = toInt(data[_forward0_ - _interval_ + 8 : _forward0_ - _interval_ + 35].hex())
            forward1Sqrt = toInt(data[_forward1_ - _interval_ + 8 : _forward1_ - _interval_ + 35].hex())
            total0SqrtInverse = toInt(data[_total0_ - _interval_ + 35 : _total0_ - _interval_ + 62].hex())
            total1SqrtInverse = toInt(data[_total1_ - _interval_ + 35 : _total1_ - _interval_ + 62].hex())
            forward0SqrtInverse = toInt(data[_forward0_ - _interval_ + 35 : _forward0_ - _interval_ + 62].hex())
            forward1SqrtInverse = toInt(data[_forward1_ - _interval_ + 35 : _forward1_ - _interval_ + 62].hex())
            incomingCurrentToTarget = toInt(data[_incomingCurrentToTarget_ - _interval_ : _incomingCurrentToTarget_ - _interval_ + 27].hex())
            currentToTarget = toInt(data[_currentToTarget_ - _interval_ : _currentToTarget_ - _interval_ + 27].hex())
            currentToOrigin = toInt(data[_currentToOrigin_ - _interval_ : _currentToOrigin_ - _interval_ + 27].hex())
            currentToOvershoot = toInt(data[_currentToOvershoot_ - _interval_ : _currentToOvershoot_ - _interval_ + 27].hex())
            targetToOvershoot = toInt(data[_targetToOvershoot_ - _interval_ : _targetToOvershoot_ - _interval_ + 27].hex())
            originToOvershoot = toInt(data[_originToOvershoot_ - _interval_ : _originToOvershoot_ - _interval_ + 27].hex())

            assert direction == (origin > end)

            assert logPriceLimitOffsettedWithinInterval == limit

            assert current == curve[-1]
            assert abs(currentSqrt - floor((2 ** 216) * exp(- Integer(current) / (2 ** 60)))) <= 1 << 32
            assert abs(currentSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(current) / (2 ** 60)))) <= 1 << 32

            assert origin == curve[indexCurve + 1]
            assert abs(originSqrt - floor((2 ** 216) * exp(- Integer(origin) / (2 ** 60)))) <= 1 << 32
            assert abs(originSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(origin) / (2 ** 60)))) <= 1 << 32

            if direction == zeroForOne:
                if direction:
                    assert begin == min(min(curve[min(indexCurve + 2, len(curve) - 1)], total0Log), forward0Log)
                else:
                    assert begin == max(max(curve[min(indexCurve + 2, len(curve) - 1)], total0Log), forward0Log)
            else:
                if direction:
                    assert begin == min(curve[min(indexCurve + 2, len(curve) - 1)], total0Log)
                else:
                    assert begin == max(curve[min(indexCurve + 2, len(curve) - 1)], total0Log)
            assert abs(beginSqrt - floor((2 ** 216) * exp(- Integer(begin) / (2 ** 60)))) <= 1 << 32
            assert abs(beginSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(begin) / (2 ** 60)))) <= 1 << 32

            assert end == curve[indexCurve]
            assert abs(endSqrt - floor((2 ** 216) * exp(- Integer(end) / (2 ** 60)))) <= 1 << 32
            assert abs(endSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(end) / (2 ** 60)))) <= 1 << 32

            assert target == limit
            assert abs(targetSqrt - floor((2 ** 216) * exp(- Integer(target) / (2 ** 60)))) <= 1 << 32
            assert abs(targetSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(target) / (2 ** 60)))) <= 1 << 32

            if direction == zeroForOne:
                if direction:
                    assert overshoot == max(max(end, total1Log), forward1Log)
                else:
                    assert overshoot == min(min(end, total1Log), forward1Log)
            else:
                if direction:
                    assert overshoot == max(end, total1Log)
                else:
                    assert overshoot == min(end, total1Log)
            assert abs(overshootSqrt - floor((2 ** 216) * exp(- Integer(overshoot) / (2 ** 60)))) <= 1 << 32
            assert abs(overshootSqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(overshoot) / (2 ** 60)))) <= 1 << 32

            assert total0Height == kernel[indexKernelTotal - 1][1]
            if direction:
                assert total0Log == origin - kernel[indexKernelTotal - 1][0]
            else:
                assert total0Log == origin + kernel[indexKernelTotal - 1][0]
            assert abs(total0Sqrt - floor((2 ** 216) * exp(- Integer(total0Log) / (2 ** 60)))) <= 1 << 32
            assert abs(total0SqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(total0Log) / (2 ** 60)))) <= 1 << 32

            assert total1Height == kernel[indexKernelTotal][1]
            if direction:
                assert total1Log == origin - kernel[indexKernelTotal][0]
            else:
                assert total1Log == origin + kernel[indexKernelTotal][0]
            assert abs(total1Sqrt - floor((2 ** 216) * exp(- Integer(total1Log) / (2 ** 60)))) <= 1 << 32
            assert abs(total1SqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(total1Log) / (2 ** 60)))) <= 1 << 32

            if direction == zeroForOne:
                assert forward0Height == kernel[indexKernelForward - 1][1]
                if zeroForOne:
                    assert forward0Log == target - kernel[indexKernelForward - 1][0]
                else:
                    assert forward0Log == target + kernel[indexKernelForward - 1][0]
                assert abs(forward0Sqrt - floor((2 ** 216) * exp(- Integer(forward0Log) / (2 ** 60)))) <= 1 << 32
                assert abs(forward0SqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(forward0Log) / (2 ** 60)))) <= 1 << 32

                assert forward1Height == kernel[indexKernelForward][1]
                if zeroForOne:
                    assert forward1Log == target - kernel[indexKernelForward][0]
                else:
                    assert forward1Log == target + kernel[indexKernelForward][0]
                assert abs(forward1Sqrt - floor((2 ** 216) * exp(- Integer(forward1Log) / (2 ** 60)))) <= 1 << 32
                assert abs(forward1SqrtInverse - floor((2 ** 216) * exp(- 16 + Integer(forward1Log) / (2 ** 60)))) <= 1 << 32

                if direction:
                    assert abs(incomingCurrentToTarget - incoming(curve, kernel, target, current)) <= 1 << 32
                    assert abs(currentToTarget - outgoing(curve, kernel, target, current)) <= 1 << 32
                    assert abs(currentToOrigin - outgoing(curve, kernel, current, origin)) <= 1 << 32
                    assert abs(currentToOvershoot - outgoing(curve, kernel, overshoot, current)) <= 1 << 32
                    assert abs(targetToOvershoot - outgoing([overshoot + spacing, overshoot, target], kernel, overshoot, target)) <= 1 << 32
                    assert abs(originToOvershoot - outgoing([overshoot + spacing, overshoot, origin], kernel, overshoot, origin)) <= 1 << 32
                else:
                    assert abs(incomingCurrentToTarget - incoming(curve, kernel, current, target)) <= 1 << 32
                    assert abs(currentToTarget - outgoing(curve, kernel, current, target)) <= 1 << 32
                    assert abs(currentToOrigin - outgoing(curve, kernel, origin, current)) <= 1 << 32
                    assert abs(currentToOvershoot - outgoing(curve, kernel, current, overshoot)) <= 1 << 32
                    assert abs(targetToOvershoot - outgoing([overshoot - spacing, overshoot, target], kernel, target, overshoot)) <= 1 << 32
                    assert abs(originToOvershoot - outgoing([overshoot - spacing, overshoot, origin], kernel, origin, overshoot)) <= 1 << 32

            if direction == zeroForOne:
                if (total0Log != total1Log) and (forward0Log != forward1Log):
                    curveAmended = amend(amend(curve, overshoot), target)
                    assert abs(integral0Amended - outgoing(curveAmended, kernel, target, qUpper)) <= 1 << 32
                    assert abs(integral1Amended - outgoing(curveAmended, kernel, qLower, target)) <= 1 << 32

                    if zeroForOne:
                        integral0Incremented = integral0 + incomingCurrentToTarget
                        integral1Incremented = integral1 - currentToTarget

                        assert abs(mismatch - floor((
                            outgoing(curveAmended, kernel, target, qUpper) * integral1Incremented - \
                            outgoing(curveAmended, kernel, qLower, target) * integral0Incremented
                        ) / X216)) <= 1 << 32

                        h = Symbol('h', real = True)
                        qOrigin = Integer(origin) / X59
                        qTarget = Integer(target) / X59
                        qOvershoot = Integer(overshoot) / X59
                        c0 = Integer(total0Height) / X15
                        c1 = Integer(total1Height) / X15
                        b0 = Integer(total0Log) / X59
                        b1 = Integer(total1Log) / X59
                        overshootMinusOrigin = floor(X216 * (exp(- 8) / 2) * (c0 + (c1 - c0) * (qOvershoot - b0) / (b1 - b0)))
                        c0 = Integer(forward0Height) / X15
                        c1 = Integer(forward1Height) / X15
                        b0 = Integer(forward0Log) / X59
                        b1 = Integer(forward1Log) / X59
                        overshootMinusTarget = floor(X216 * (exp(- 8) / 2) * (c0 + (c1 - c0) * (qOvershoot - b0) / (b1 - b0)))

                        qOrigin = -16 + Integer(origin) / X59
                        qTarget = -16 + Integer(target) / X59
                        qOvershoot = -16 + Integer(overshoot) / X59
                        dmismatch = floor(
                            2 * (
                                (
                                    (exp(+ (qOvershoot / 2)) * Integer(overshootMinusTarget)) - \
                                    (exp(+ (qOvershoot / 2)) * Integer(overshootMinusOrigin))
                                ) * Integer(integral0Incremented) - (
                                    (exp(- ((qOrigin + qOvershoot) / 2)) * (Integer(originToOvershoot) / 2)) - \
                                    (exp(- ((qTarget + qOvershoot) / 2)) * (Integer(targetToOvershoot) / 2)) + \
                                    (exp(- (qOrigin / 2)) * Integer(overshootMinusOrigin)) - \
                                    (exp(- (qTarget / 2)) * Integer(overshootMinusTarget))
                                ) * Integer(integral1Incremented)
                            ) / X216
                        )
                    else:
                        integral0Incremented = integral0 - currentToTarget
                        integral1Incremented = integral1 + incomingCurrentToTarget

                        assert abs(mismatch - floor((
                            outgoing(curveAmended, kernel, qLower, target) * integral0Incremented - \
                            outgoing(curveAmended, kernel, target, qUpper) * integral1Incremented
                        ) / X216)) <= 1 << 32

                        h = Symbol('h', real = True)
                        qOrigin = Integer(origin) / X59
                        qTarget = Integer(target) / X59
                        qOvershoot = Integer(overshoot) / X59
                        c0 = Integer(total0Height) / X15
                        c1 = Integer(total1Height) / X15
                        b0 = Integer(total0Log) / X59
                        b1 = Integer(total1Log) / X59
                        overshootMinusOrigin = floor(X216 * (exp(- 8) / 2) * (c0 + (c1 - c0) * (qOvershoot - b0) / (b1 - b0)))
                        c0 = Integer(forward0Height) / X15
                        c1 = Integer(forward1Height) / X15
                        b0 = Integer(forward0Log) / X59
                        b1 = Integer(forward1Log) / X59
                        overshootMinusTarget = floor(X216 * (exp(- 8) / 2) * (c0 + (c1 - c0) * (qOvershoot - b0) / (b1 - b0)))

                        qOrigin = -16 + Integer(origin) / X59
                        qTarget = -16 + Integer(target) / X59
                        qOvershoot = -16 + Integer(overshoot) / X59
                        dmismatch = floor(
                            2 * (
                                (
                                    (exp(+ ((qOrigin + qOvershoot) / 2)) * (Integer(originToOvershoot) / 2)) - \
                                    (exp(+ ((qTarget + qOvershoot) / 2)) * (Integer(targetToOvershoot) / 2)) + \
                                    (exp(+ (qOrigin / 2)) * Integer(overshootMinusOrigin)) - \
                                    (exp(+ (qTarget / 2)) * Integer(overshootMinusTarget))
                                ) * Integer(integral0Incremented) - (
                                    (exp(- (qOvershoot / 2)) * Integer(overshootMinusTarget)) - \
                                    (exp(- (qOvershoot / 2)) * Integer(overshootMinusOrigin))
                                ) * Integer(integral1Incremented)
                            ) / X216
                        )

                    assert abs(step) == floor(abs(((1 << 38) * mismatch) / (dmismatch / (1 << 22))))

            kk += 1