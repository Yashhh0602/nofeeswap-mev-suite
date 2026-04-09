# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import accounts, IntervalWrapper
from sympy import Integer
from Nofee import logTest, amend, outgoing, incoming, dataGeneration, encodeCurve, encodeKernel
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

@pytest.mark.parametrize('limitPlacement', [3])
@pytest.mark.parametrize('p5', ['skip'])
@pytest.mark.parametrize('p4', ['skip', 'break', 'jump'])
@pytest.mark.parametrize('p3', ['skip', 'break', 'jump'])
@pytest.mark.parametrize('p2', ['skip', 'break', 'jump'])
@pytest.mark.parametrize('p1', ['skip', 'break', 'jump'])
@pytest.mark.parametrize('orientation', [False, True])
def test_searchOvershoot(wrapper, orientation, p1, p2, p3, p4, p5, limitPlacement, request, worker_id):
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

    target = midpoint + points[limitPlacement]

    qLower = min(curve[0], curve[1])
    qUpper = max(curve[0], curve[1])
    qCurrent = curve[-1]

    if target != qCurrent:
        zeroForOne = target < qCurrent
        integral0 = outgoing(curve, kernel, qCurrent, qUpper)
        integral1 = outgoing(curve, kernel, qLower, qCurrent)

        tx = wrapper._searchOvershoot(
            integral0,
            integral1,
            target,
            len(curve),
            encodeKernel(kernel),
            encodeCurve(curve)
        )

        overshoot, integral0Amended, integral1Amended = tx.return_value

        curveAmended = amend(amend(curve, overshoot), target)
        _integral0Amended = outgoing(curveAmended, kernel, target, qUpper)
        _integral1Amended = outgoing(curveAmended, kernel, qLower, target)
        assert abs(integral0Amended - _integral0Amended) <= 1 << 32
        assert abs(integral1Amended - _integral1Amended) <= 1 << 32

        if zeroForOne:
            integral0Incremented = integral0 + incoming(curve, kernel, target, qCurrent)
            integral1Incremented = integral1 - outgoing(curve, kernel, target, qCurrent)

            if _integral0Amended == 0:
                growth = Integer(integral1Incremented) / Integer(_integral1Amended)
            if _integral1Amended == 0:
                growth = Integer(integral0Incremented) / Integer(_integral0Amended)
            if (_integral0Amended != 0) and (_integral1Amended != 0):
                growth = min(Integer(integral0Incremented) / Integer(_integral0Amended), Integer(integral1Incremented) / Integer(_integral1Amended))

            if qLower < overshoot:
                curveAmendedMinus = amend(amend(curve, overshoot - 1), target)
                integral0AmendedMinus = outgoing(curveAmendedMinus, kernel, target, qUpper)
                integral1AmendedMinus = outgoing(curveAmendedMinus, kernel, qLower, target)

                if integral0AmendedMinus == 0:
                    growthMinus = Integer(integral1Incremented) / Integer(integral1AmendedMinus)
                if integral1AmendedMinus == 0:
                    growthMinus = Integer(integral0Incremented) / Integer(integral0AmendedMinus)
                if (integral0AmendedMinus != 0) and (integral1AmendedMinus != 0):
                    growthMinus = min(Integer(integral0Incremented) / Integer(integral0AmendedMinus), Integer(integral1Incremented) / Integer(integral1AmendedMinus))

                assert growth >= growthMinus

            if overshoot < target:
                curveAmendedPlus = amend(amend(curve, overshoot + 1), target)
                integral0AmendedPlus = outgoing(curveAmendedPlus, kernel, target, qUpper)
                integral1AmendedPlus = outgoing(curveAmendedPlus, kernel, qLower, target)

                if integral0AmendedPlus == 0:
                    growthPlus = Integer(integral1Incremented) / Integer(integral1AmendedPlus)
                if integral1AmendedPlus == 0:
                    growthPlus = Integer(integral0Incremented) / Integer(integral0AmendedPlus)
                if (integral0AmendedPlus != 0) and (integral1AmendedPlus != 0):
                    growthPlus = min(Integer(integral0Incremented) / Integer(integral0AmendedPlus), Integer(integral1Incremented) / Integer(integral1AmendedPlus))

                assert growth >= growthPlus

        else:
            integral0Incremented = integral0 - outgoing(curve, kernel, qCurrent, target)
            integral1Incremented = integral1 + incoming(curve, kernel, qCurrent, target)

            if _integral0Amended == 0:
                growth = Integer(integral1Incremented) / Integer(_integral1Amended)
            if _integral1Amended == 0:
                growth = Integer(integral0Incremented) / Integer(_integral0Amended)
            if (_integral0Amended != 0) and (_integral1Amended != 0):
                growth = min(Integer(integral0Incremented) / Integer(_integral0Amended), Integer(integral1Incremented) / Integer(_integral1Amended))

            if target < overshoot:
                curveAmendedMinus = amend(amend(curve, overshoot - 1), target)
                integral0AmendedMinus = outgoing(curveAmendedMinus, kernel, target, qUpper)
                integral1AmendedMinus = outgoing(curveAmendedMinus, kernel, qLower, target)

                if integral0AmendedMinus == 0:
                    growthMinus = Integer(integral1Incremented) / Integer(integral1AmendedMinus)
                if integral1AmendedMinus == 0:
                    growthMinus = Integer(integral0Incremented) / Integer(integral0AmendedMinus)
                if (integral0AmendedMinus != 0) and (integral1AmendedMinus != 0):
                    growthMinus = min(Integer(integral0Incremented) / Integer(integral0AmendedMinus), Integer(integral1Incremented) / Integer(integral1AmendedMinus))

                assert growth >= growthMinus

            if overshoot < qUpper:
                curveAmendedPlus = amend(amend(curve, overshoot + 1), target)
                integral0AmendedPlus = outgoing(curveAmendedPlus, kernel, target, qUpper)
                integral1AmendedPlus = outgoing(curveAmendedPlus, kernel, qLower, target)

                if integral0AmendedPlus == 0:
                    growthPlus = Integer(integral1Incremented) / Integer(integral1AmendedPlus)
                if integral1AmendedPlus == 0:
                    growthPlus = Integer(integral0Incremented) / Integer(integral0AmendedPlus)
                if (integral0AmendedPlus != 0) and (integral1AmendedPlus != 0):
                    growthPlus = min(Integer(integral0Incremented) / Integer(integral0AmendedPlus), Integer(integral1Incremented) / Integer(integral1AmendedPlus))

                assert growth >= growthPlus