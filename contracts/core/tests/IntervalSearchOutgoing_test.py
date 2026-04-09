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
@pytest.mark.parametrize('horizontalStart', [1, thirtyTwoX59 // 2, thirtyTwoX59 - 1])
@pytest.mark.parametrize('verticalStart', [0, oneX15 // 2, oneX15])
@pytest.mark.parametrize('horizontalGap', [1, 3, 1 << 40, 1 << 63])
@pytest.mark.parametrize('verticalGap', [0, 1, oneX15 // 3, oneX15])
@pytest.mark.parametrize('_begin', ['begin', 'mid'])
@pytest.mark.parametrize('_end', ['mid', 'end'])
@pytest.mark.parametrize('_solution', ['begin + 1', 'mid', 'end - 1'])
def test_searchOutgoingTarget(wrapper, zeroForOne, horizontalStart, horizontalGap, verticalStart, verticalGap, _begin, _end, _solution, request, worker_id):
    logTest(request, worker_id)
    
    wrapper = IntervalWrapper.deploy({'from': accounts[0]})
    total0Log = horizontalStart
    total0Height = verticalStart

    if zeroForOne:
        total1Log = horizontalStart - horizontalGap
    else:
        total1Log = horizontalStart + horizontalGap
    total1Height = verticalStart + verticalGap

    if _begin == 'begin':
        begin = total0Log
    if _begin == 'mid':
        begin = (total0Log + total1Log) // 2

    if _end == 'mid':
        end = (total0Log + total1Log) // 2
    if _end == 'end':
        end = total1Log

    if zeroForOne:
        if _solution == 'begin + 1':
            solution = begin - 1
        if _solution == 'mid':
            solution = (begin + end) // 2
        if _solution == 'end - 1':
            solution = end + 1
    else:
        if _solution == 'begin + 1':
            solution = begin + 1
        if _solution == 'mid':
            solution = (begin + end) // 2
        if _solution == 'end - 1':
            solution = end - 1

    if ((
            total0Height <= total1Height
        ) and (
            0 < total1Height <= oneX15
        ) and (
            (
                not(zeroForOne) and (0 < total0Log <= begin < solution <= end <= total1Log < thirtyTwoX59)
            ) or (
                zeroForOne and (0 < total1Log <= end <= solution < begin <= total0Log < thirtyTwoX59)
            )
        )):

        h = Symbol('h', real = True)
        c0 = Integer(total0Height) / X15
        c1 = Integer(total1Height) / X15
        b0 = Integer(total0Log) / X59
        b1 = Integer(total1Log) / X59
        
        qBegin = Integer(begin) / X59
        qSolution = Integer(solution) / X59

        if zeroForOne:
            integral = integrate(
                (exp(- 16 + (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
                (h, qSolution, qBegin)
            )
        else:
            integral = integrate(
                (exp(- (h / 2)) / 2) * (c0 + (c1 - c0) * (h - b0) / (b1 - b0)), 
                (h, qBegin, qSolution)
            )

        sqrtBegin = floor((2 ** 216) * exp(- Integer(begin) / (2 ** 60)))
        sqrtInverseBegin = floor((2 ** 216) * exp(- 16 + Integer(begin) / (2 ** 60)))
        beginContent0 = (0 << 240) + (begin << 176) + (sqrtBegin >> 40)
        beginContent1 = ((sqrtBegin % (1 << 40)) << 216) + sqrtInverseBegin

        sqrtEnd = floor((2 ** 216) * exp(- Integer(end) / (2 ** 60)))
        sqrtInverseEnd = floor((2 ** 216) * exp(- 16 + Integer(end) / (2 ** 60)))
        endContent0 = (0 << 240) + (end << 176) + (sqrtEnd >> 40)
        endContent1 = ((sqrtEnd % (1 << 40)) << 216) + sqrtInverseEnd

        sqrtTotal0 = floor((2 ** 216) * exp(- Integer(total0Log) / (2 ** 60)))
        sqrtInverseTotal0 = floor((2 ** 216) * exp(- 16 + Integer(total0Log) / (2 ** 60)))
        total0Content0 = (total0Height << 240) + (total0Log << 176) + (sqrtTotal0 >> 40)
        total0Content1 = ((sqrtTotal0 % (1 << 40)) << 216) + sqrtInverseTotal0

        sqrtTotal1 = floor((2 ** 216) * exp(- Integer(total1Log) / (2 ** 60)))
        sqrtInverseTotal1 = floor((2 ** 216) * exp(- 16 + Integer(total1Log) / (2 ** 60)))
        total1Content0 = (total1Height << 240) + (total1Log << 176) + (sqrtTotal1 >> 40)
        total1Content1 = ((sqrtTotal1 % (1 << 40)) << 216) + sqrtInverseTotal1

        integralLimit = floor(X216 * integral)

        tx = wrapper._searchOutgoingTarget(
            integralLimit,
            0,
            zeroForOne,
            [
                beginContent0,
                beginContent1,
                endContent0,
                endContent1,
                total0Content0,
                total0Content1,
                total1Content0,
                total1Content1,
            ]
        )

        exactAmount, outgoing, output = tx.return_value

        _overshootContent0 = output[0]
        _overshootContent1 = output[1]
        overshootLogPrice = (_overshootContent0 >> 176) % (1 << 64)
        overshootSqrtPrice = ((_overshootContent0 % (1 << 176)) << 40) + (_overshootContent1 >> 216)
        overshootSqrtInversePrice = _overshootContent1 % (1 << 216)

        _targetContent0 = output[2]
        _targetContent1 = output[3]
        targetLogPrice = (_targetContent0 >> 176) % (1 << 64)
        targetSqrtPrice = ((_targetContent0 % (1 << 176)) << 40) + (_targetContent1 >> 216)
        targetSqrtInversePrice = _targetContent1 % (1 << 216)
    
        if exactAmount:
            assert overshootLogPrice == targetLogPrice
            assert overshootSqrtPrice == targetSqrtPrice
            assert overshootSqrtInversePrice == targetSqrtInversePrice
            assert abs(targetLogPrice - solution) <= 1
            assert integralLimit <= outgoing